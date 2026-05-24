import 'dart:convert';

import 'deepseek_proxy.dart';
import 'model_router.dart';
import 'game_design_document.dart';
import 'playability_validator.dart';
import 'templates/game_template.dart';
import 'templates/template_registry.dart';
import '../credits/credit_service.dart';
import '../../features/workspace/domain/game_spec.dart';

class GameGenService {
  final AiProxy _proxy;
  static const _maxRetries = 1;
  static const _maxDesignRetries = 0;

  GameGenService({AiProxy? proxy}) : _proxy = proxy ?? AiProxy();

  /// Per-call timeout for AI requests. Generation should complete within this.
  static const _callTimeout = Duration(seconds: 90);

  // ─── Pass 1: Design Document ───────────────────────────────────────

  /// Generates a structured [GameDesignDocument] from [spec] using the
  /// genre-matched template's design prompt.
  /// Returns null if design generation fails (caller should fall back to
  /// single-pass generation).
  Future<GameDesignDocument?> generateDesign(GameSpec spec) async {
    final template = TemplateRegistry.resolve(spec.genre);
    final prompt = template.buildDesignPrompt(spec);

    for (int attempt = 0; attempt <= _maxDesignRetries; attempt++) {
      try {
        final result = await _proxy
            .chat(
              messages: [
                {'role': 'system', 'content': prompt},
                {
                  'role': 'user',
                  'content': attempt == 0
                      ? 'Generate the design document JSON based on the specification above.'
                      : 'The previous design had validation errors. Please fix them and output a complete, valid JSON design document.',
                },
              ],
              modelType: ModelType.code,
              temperature: 0.7,
              maxTokens: 4096,
            )
            .timeout(_callTimeout);

        final content =
            result['choices']?[0]?['message']?['content'] as String?;
        if (content == null || content.isEmpty) {
          if (attempt >= _maxDesignRetries) return null;
          continue;
        }

        final json = _extractJson(content);
        if (json.isEmpty) {
          if (attempt >= _maxDesignRetries) return null;
          continue;
        }

        final doc = GameDesignDocument.fromJson(json);
        final validation = doc.validate();

        // Run playability checks on the design
        final playability = PlayabilityValidator.validateDesign(
          doc,
          template.genreName,
        );

        if (validation.isValid && !playability.hasErrors) return doc;

        // Merge structural and playability issues for retry feedback
        final allIssues = [
          ...validation.issues,
          ...playability.errors,
          ...playability.warnings,
        ];

        if (attempt >= _maxDesignRetries) {
          // Return doc even if imperfect — code gen can still try
          return doc;
        }

        // Feed issues back for retry
        final feedback = [
          'The design document has these issues:',
          ...allIssues.map((i) => '  - $i'),
        ].join('\n');
        // Store for potential code-gen feedback
        _previousDesignIssues = feedback;
      } on DeductException {
        rethrow;
      } catch (e) {
        if (attempt >= _maxDesignRetries) {
          _logError('Design generation failed: $e');
          return null;
        }
      }
    }

    return null;
  }

  // ─── Pass 2: Code Generation ───────────────────────────────────────

  /// Generates HTML5 game code from a [GameDesignDocument] and [GameSpec].
  Future<String> generateCode(GameDesignDocument doc, GameSpec spec) async {
    final template = TemplateRegistry.resolve(spec.genre);
    return _generateCodeWithRetry(doc, spec, template, 0);
  }

  Future<String> _generateCodeWithRetry(
    GameDesignDocument doc,
    GameSpec spec,
    GameTemplate template,
    int attempt,
  ) async {
    final combinedFeedback = attempt > 0
        ? _previousFailures
        : _previousDesignIssues;
    final prompt = _buildCodePrompt(doc, spec, template,
        feedback: combinedFeedback);

    try {
      final result = await _proxy
          .chat(
            messages: [
              {'role': 'system', 'content': prompt},
              {
                'role': 'user',
                'content': attempt == 0
                    ? 'Generate the complete HTML5 game from the design document above. Output ONLY the HTML code.'
                    : 'The previous generation had issues. Here are the specific problems:\n$_previousFailures\n\nFix these issues and regenerate the complete HTML.',
              },
            ],
            modelType: ModelType.code,
            temperature: 0.3,
            maxTokens: template.suggestedMaxTokens,
          )
          .timeout(_callTimeout);

      final content =
          result['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const GameGenException('AI returned empty code', true);
      }

      final html = _extractHtml(content);
      final validation =
          _validateCode(html, spec, template);

      if (!validation.isValid && attempt < _maxRetries) {
        _previousFailures = validation.issues.join('\n');
        return _generateCodeWithRetry(doc, spec, template, attempt + 1);
      }

      return html;
    } on DeductException {
      rethrow;
    } catch (e) {
      if (attempt >= _maxRetries) {
        throw GameGenException('Code generation failed: $e', true);
      }
      _previousFailures = 'Generation error: $e';
      return _generateCodeWithRetry(doc, spec, template, attempt + 1);
    }
  }

  String? _previousFailures;
  String? _previousDesignIssues;

  // ─── Combined (backward-compatible) ─────────────────────────────────

  /// Convenience method: tries two-pass generation (design → code).
  /// Falls back to single-pass code generation if the design pass fails,
  /// so the user always gets a game even when the AI can't produce clean JSON.
  Future<String> generateGame(GameSpec spec) async {
    try {
      final doc = await generateDesign(spec);
      if (doc != null) {
        return generateCode(doc, spec);
      }
    } catch (_) {
      // Design pass failed — fall through to single-pass
    }

    // Fallback: single-pass generation from spec directly
    return _generateCodeSinglePass(spec);
  }

  /// Single-pass fallback: generates HTML directly from GameSpec,
  /// bypassing the design document stage. Used when Pass 1 fails.
  /// Includes playability validation with one retry.
  Future<String> _generateCodeSinglePass(GameSpec spec) async {
    final template = TemplateRegistry.resolve(spec.genre);
    String? lastFailureFeedback;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final prompt = _buildSinglePassPrompt(spec, template,
            feedback: lastFailureFeedback);

        final result = await _proxy
            .chat(
              messages: [
                {'role': 'system', 'content': prompt},
                {
                  'role': 'user',
                  'content': attempt == 0
                      ? 'Generate the complete HTML5 game. Output ONLY the HTML code wrapped in ```html.'
                      : 'The previous generation had playability issues. Fix them and regenerate.',
                },
              ],
              modelType: ModelType.code,
              temperature: 0.3,
              maxTokens: 8192,
            )
            .timeout(_callTimeout);

        final content =
            result['choices']?[0]?['message']?['content'] as String?;
        if (content == null || content.isEmpty) {
          if (attempt >= _maxRetries) {
            throw const GameGenException('AI returned empty code', true);
          }
          lastFailureFeedback = 'AI returned empty response';
          continue;
        }

        final html = _extractHtml(content);
        final validation = _validateCode(html, spec, template);

        if (!validation.isValid && attempt < _maxRetries) {
          lastFailureFeedback = validation.issues.join('\n');
          continue;
        }

        return html;
      } catch (e) {
        if (attempt >= _maxRetries) {
          _logError('Single-pass generation failed: $e');
          rethrow;
        }
        lastFailureFeedback = 'Generation error: $e';
      }
    }

    throw const GameGenException(
      'Single-pass generation failed after all retries',
      true,
    );
  }

  String _buildSinglePassPrompt(GameSpec spec, GameTemplate template, {
    String? feedback,
  }) {
    final buf = StringBuffer();
    buf.writeln(
        'You are a senior HTML5 game developer. Generate a complete, self-contained HTML file for a ${template.genreName} game.');
    buf.writeln();

    // Spec summary
    buf.writeln('## Game Specification');
    if (spec.genre != null && spec.genre!.isNotEmpty) {
      buf.writeln('- Genre: ${spec.genre}');
    }
    if (spec.theme != null && spec.theme!.isNotEmpty) {
      buf.writeln('- Theme: ${spec.theme}');
    }
    if (spec.artStyle != null && spec.artStyle!.isNotEmpty) {
      buf.writeln('- Art Style: ${spec.artStyle}');
    }
    if (spec.coreMechanic != null && spec.coreMechanic!.isNotEmpty) {
      buf.writeln('- Core Mechanic: ${spec.coreMechanic}');
    }
    if (spec.playerAbility != null && spec.playerAbility!.isNotEmpty) {
      buf.writeln('- Player Ability: ${spec.playerAbility}');
    }
    if (spec.goal != null && spec.goal!.isNotEmpty) {
      buf.writeln('- Goal: ${spec.goal}');
    }
    if (spec.cameraView != null && spec.cameraView!.isNotEmpty) {
      buf.writeln('- Camera: ${spec.cameraView}');
    }
    if (spec.musicVibe != null && spec.musicVibe!.isNotEmpty) {
      buf.writeln('- Music Vibe: ${spec.musicVibe}');
    }
    if (spec.difficulty != null && spec.difficulty!.isNotEmpty) {
      buf.writeln('- Difficulty: ${spec.difficulty}');
    }

    buf.writeln();
    buf.writeln('## Code Skeleton Reference');
    buf.writeln('```html');
    buf.writeln(template.codeSkeleton
        .replaceAll('{{GRAVITY}}', template.defaultPhysics['gravity']?.toString() ?? '0.5')
        .replaceAll('{{FRICTION}}', template.defaultPhysics['friction']?.toString() ?? '0.8')
        .replaceAll('{{JUMP_FORCE}}', template.defaultPhysics['jumpForce']?.toString() ?? '12')
        .replaceAll('{{MOVE_SPEED}}', template.defaultPhysics['moveSpeed']?.toString() ?? '4')
        .replaceAll('{{SCROLL_SPEED}}', '4')
        .replaceAll('{{SPEED_INCREMENT}}', '0.002')
        .replaceAll('{{ROWS}}', '8')
        .replaceAll('{{COLS}}', '8')
        .replaceAll('{{CELL}}', '48')
        .replaceAll('{{FIRE_RATE}}', '15')
        .replaceAll('{{OBSTACLE_INTERVAL}}', '90'));
    buf.writeln('```');

    // Add physics geometry limits for platformer-like genres
    final physics = template.defaultPhysics;
    final grav = physics['gravity'] ?? 0;
    final jf = physics['jumpForce'] ?? 0;
    final ms = physics['moveSpeed'] ?? 0;
    if (grav > 0 && jf > 0) {
      final maxJumpH = (jf * jf) / (2 * grav);
      final airTime = 2 * jf / grav;
      final maxJumpD = ms * airTime;
      buf.writeln();
      buf.writeln('## CRITICAL: Physics Geometry Limits');
      buf.writeln('Based on GRAVITY=$grav, JUMP_FORCE=$jf, MOVE_SPEED=$ms:');
      buf.writeln('- **MAX JUMP HEIGHT = ${maxJumpH.toInt()} pixels**');
      buf.writeln('- **MAX JUMP DISTANCE = ${maxJumpD.toInt()} pixels**');
      buf.writeln();
      buf.writeln('HARD CONSTRAINT: Every consecutive platform MUST satisfy:');
      buf.writeln('  - Vertical gap (current.y - next.y) ≤ ${maxJumpH.toInt()}px');
      buf.writeln('  - Horizontal gap (next.x - current.right) ≤ ${maxJumpD.toInt()}px');
      buf.writeln('Violating these makes the game LITERALLY UNPLAYABLE.');
      buf.writeln('Mentally verify EVERY platform pair before outputting code.');
    }

    buf.writeln();
    buf.writeln('## Requirements');
    buf.writeln(
        '1. Complete, playable game — immediately works in a browser');
    buf.writeln(
        '2. Responsive canvas: canvas.width = Math.min(innerWidth-16,420); canvas.height = Math.min(innerHeight-16,640);');
    buf.writeln('3. Touch controls for mobile + Keyboard controls (Arrow keys + Space)');
    buf.writeln('4. 60fps game loop with requestAnimationFrame');
    buf.writeln(
        '5. All game states: title, playing, gameOver, win');
    buf.writeln('6. Web Audio API oscillator-based sound effects (no external files)');
    buf.writeln(
        '7. Fill in ALL placeholder comments with real drawing/update logic');
    buf.writeln(
        '8. NO external dependencies, CDN links, or library imports');
    buf.writeln('9. Use descriptive variable names');
    buf.writeln(
        '10. RESPOND ONLY with HTML code wrapped in ```html');

    buf.writeln();
    buf.writeln('## Genre Constraints');
    for (final c in template.getCodeGenConstraints(
        GameDesignDocument(
      title: spec.genre ?? 'Game',
      genre: template.genreName,
      coreLoop: spec.coreMechanic ?? '',
      objects: [],
      physics: PhysicsParams(
        gravity: template.defaultPhysics['gravity'] ?? 0.5,
        friction: template.defaultPhysics['friction'] ?? 0.8,
        jumpForce: template.defaultPhysics['jumpForce'] ?? 12,
        moveSpeed: template.defaultPhysics['moveSpeed'] ?? 4,
      ),
      collision: const CollisionRules(),
      scoring: const ScoringSystem(),
      states: const StateMachine(),
      levels: [],
      visual: const VisualStyle(),
      audioHints: spec.musicVibe ?? '',
    ))) {
      buf.writeln('- $c');
    }

    if (feedback != null && feedback.isNotEmpty) {
      buf.writeln();
      buf.writeln('## CRITICAL: Previous Issues to Fix');
      buf.writeln('The last attempt had these problems. Address EVERY one:');
      for (final line in feedback.split('\n')) {
        buf.writeln('- $line');
      }
    }

    return buf.toString();
  }

  // ─── Prompt Builders ───────────────────────────────────────────────

  String _buildCodePrompt(
    GameDesignDocument doc,
    GameSpec spec,
    GameTemplate template, {
    String? feedback,
  }) {
    final physics = doc.physics;
    final physicsParams = template.defaultPhysics;
    final gravity = physics.gravity;
    final jumpForce = physics.jumpForce;
    final moveSpeed = physics.moveSpeed;

    final buf = StringBuffer();
    buf.writeln('You are a senior HTML5 game developer. '
        'Generate a complete, self-contained HTML file for a ${doc.genre} game.');

    buf.writeln('\n## Game Design Document');
    buf.writeln('- Title: ${doc.title}');
    buf.writeln('- Genre: ${doc.genre}');
    buf.writeln('- Core Loop: ${doc.coreLoop}');

    buf.writeln('\n### Objects');
    for (final obj in doc.objects) {
      buf.writeln('- ${obj.type}: ${obj.name} '
          '(${obj.behaviors.join(', ')}) '
          '[${obj.properties.entries.map((e) => '${e.key}=${e.value}').join(', ')}]');
    }

    buf.writeln('\n### Physics');
    buf.writeln('- Gravity: $gravity, Friction: ${physics.friction}');
    buf.writeln('- Jump Force: $jumpForce, Move Speed: $moveSpeed');
    if (gravity > 0 && jumpForce > 0) {
      final maxJumpH = (jumpForce * jumpForce) / (2 * gravity);
      final airTime = 2 * jumpForce / gravity;
      final maxJumpD = moveSpeed * airTime;
      buf.writeln('- **MAX JUMP HEIGHT: ${maxJumpH.toInt()}px | MAX JUMP DISTANCE: ${maxJumpD.toInt()}px**');
      buf.writeln('- **HARD LIMIT: every platform vertical gap ≤ ${maxJumpH.toInt()}px, horizontal gap ≤ ${maxJumpD.toInt()}px**');
    }

    buf.writeln('\n### Collision Rules');
    buf.writeln('- Platforms: ${doc.collision.platforms}');
    buf.writeln('- Enemies: ${doc.collision.enemies}');
    buf.writeln('- Collectibles: ${doc.collision.collectibles}');

    buf.writeln('\n### Scoring');
    buf.writeln('- Win: ${doc.scoring.winCondition}');
    buf.writeln('- Lose: ${doc.scoring.loseCondition}');

    buf.writeln('\n### Levels');
    for (int i = 0; i < doc.levels.length; i++) {
      final lvl = doc.levels[i];
      buf.writeln('- Level ${i + 1}: '
          '${lvl.platforms.length} platforms, '
          '${lvl.enemies.length} enemies, '
          '${lvl.collectibles.length} collectibles, '
          'spawn at (${lvl.spawnPoint['x']}, ${lvl.spawnPoint['y']})');
    }

    buf.writeln('\n### Visual Style');
    buf.writeln('- Background: ${doc.visual.background}');
    buf.writeln('- Palette: ${doc.visual.colorPalette}');
    buf.writeln('- Player: ${doc.visual.playerAppearance}');
    buf.writeln('- Effects: ${doc.visual.effects}');

    buf.writeln('\n### Audio');
    buf.writeln(doc.audioHints);

    buf.writeln('\n## Code Structure (follow this skeleton)');
    buf.writeln('```html');
    buf.writeln(template.codeSkeleton
        .replaceAll('{{GRAVITY}}', gravity.toString())
        .replaceAll('{{FRICTION}}', physics.friction.toString())
        .replaceAll('{{JUMP_FORCE}}', jumpForce.toString())
        .replaceAll('{{MOVE_SPEED}}', moveSpeed.toString())
        .replaceAll('{{SCROLL_SPEED}}',
            physicsParams['scrollSpeed']?.toString() ?? '4')
        .replaceAll('{{SPEED_INCREMENT}}',
            physicsParams['speedIncrement']?.toString() ?? '0.002')
        .replaceAll('{{ROWS}}', '8')
        .replaceAll('{{COLS}}', '8')
        .replaceAll('{{CELL}}', '48')
        .replaceAll('{{FIRE_RATE}}', '15')
        .replaceAll('{{OBSTACLE_INTERVAL}}', '90'));
    buf.writeln('```');

    buf.writeln('\n## Requirements');
    buf.writeln('1. **Complete, playable game** — immediately works in a browser');
    buf.writeln('2. **Responsive canvas**: '
        '`canvas.width = Math.min(innerWidth - 16, 420); canvas.height = Math.min(innerHeight - 16, 640);`');
    buf.writeln('3. **Touch controls** must work on mobile devices');
    buf.writeln('4. **Keyboard controls**: Arrow keys + Space for primary actions');
    buf.writeln('5. **60fps game loop** with requestAnimationFrame');
    buf.writeln('6. **All game states** implemented: ${doc.states.states.join(', ')}');
    buf.writeln('7. **Restart**: tap or keypress when game over/win resets everything');
    buf.writeln('8. **Web Audio API** sound effects (oscillator-based, no external files)');
    buf.writeln('9. Fill in ALL placeholder comments in the skeleton with real drawing/update logic');

    buf.writeln('\n## Genre-Specific Constraints');
    for (final c in template.getCodeGenConstraints(doc)) {
      buf.writeln('- $c');
    }

    buf.writeln('\n## Rules');
    buf.writeln('- NO external dependencies, CDN links, or library imports');
    buf.writeln('- Use readable, descriptive variable names');
    buf.writeln('- RESPOND ONLY with the HTML code wrapped in ```html');
    buf.writeln('- Make the game fun and playable — test your logic mentally');
    buf.writeln('- The skeleton is a GUIDE — flesh it out with complete implementations');
    buf.writeln('- Replace LEVELS_DATA_PLACEHOLDER, WAVES_DATA_PLACEHOLDER, '
        'PUZZLE_DATA_PLACEHOLDER with real level data from the design document');

    if (feedback != null && feedback.isNotEmpty) {
      buf.writeln('\n## CRITICAL: Previous Issues to Fix');
      buf.writeln('The last attempt had these problems. Address EVERY one:');
      for (final line in feedback.split('\n')) {
        buf.writeln('- $line');
      }
    }

    return buf.toString();
  }

  // ─── HTML Extraction ───────────────────────────────────────────────

  String _extractHtml(String content) {
    final htmlBlock = RegExp(r'```html\s*\n?(.*?)```', dotAll: true);
    final htmlMatch = htmlBlock.firstMatch(content);
    if (htmlMatch != null) return htmlMatch.group(1)!.trim();

    final genericBlock = RegExp(r'```\s*\n?(.*?)```', dotAll: true);
    final genericMatch = genericBlock.firstMatch(content);
    if (genericMatch != null) {
      final code = genericMatch.group(1)!.trim();
      if (_hasEssentialTags(code)) return code;
    }

    final dtStart = content.indexOf('<!DOCTYPE');
    if (dtStart != -1) return content.substring(dtStart).trim();

    final htmlStart = content.indexOf('<html');
    if (htmlStart != -1) return content.substring(htmlStart).trim();

    if (content.length > 800) return content.trim();

    throw GameGenException('Cannot extract valid HTML from AI response', true);
  }

  bool _hasEssentialTags(String html) {
    return html.contains('<canvas') &&
        html.contains('<script') &&
        html.contains('</html>');
  }

  // ─── JSON Extraction ───────────────────────────────────────────────

  Map<String, dynamic> _extractJson(String content) {
    // Try ```json block
    final jsonBlock = RegExp(r'```json\s*\n?(.*?)```', dotAll: true);
    final jsonMatch = jsonBlock.firstMatch(content);
    if (jsonMatch != null) {
      try {
        return jsonDecode(jsonMatch.group(1)!.trim()) as Map<String, dynamic>;
      } catch (_) {
        // Fall through to other strategies
      }
    }

    // Try raw JSON object via brace matching
    final objStart = content.indexOf('{');
    if (objStart != -1) {
      int braceCount = 0;
      int end = -1;
      for (int i = objStart; i < content.length; i++) {
        if (content[i] == '{') braceCount++;
        if (content[i] == '}') braceCount--;
        if (braceCount == 0) {
          end = i + 1;
          break;
        }
      }
      if (end > objStart) {
        try {
          return jsonDecode(content.substring(objStart, end))
              as Map<String, dynamic>;
        } catch (_) {
          // Fall through
        }
      }
    }

    // Could not extract — return empty map so caller can fall back
    return {};
  }

  void _logError(Object e) {
    // ignore: avoid_print
    print('⚠️ [GameGenService] $e');
  }

  // ─── Validation ────────────────────────────────────────────────────

  CodeValidation _validateCode(
      String html, GameSpec spec, GameTemplate template) {
    final issues = <String>[];

    // Structural checks
    if (!html.contains('<!DOCTYPE html>') && !html.contains('<html')) {
      issues.add('Missing DOCTYPE/html tag');
    }
    if (!html.contains('<canvas')) issues.add('Missing canvas element');
    if (!html.contains('</html>')) issues.add('Incomplete HTML structure');
    if (!html.contains('<script')) issues.add('Missing script tag');

    // Game loop check
    if (!html.contains('requestAnimationFrame') &&
        !html.contains('setInterval')) {
      issues.add('Missing game loop (requestAnimationFrame)');
    }

    // Input checks
    final hasTouch =
        html.contains('touchstart') || html.contains('ontouchstart');
    final hasKeyboard =
        html.contains('ArrowLeft') ||
        html.contains('ArrowRight') ||
        html.contains('onkeydown') ||
        html.contains("'key'") ||
        html.contains('"key"');
    if (!hasTouch) issues.add('Missing touch controls');
    if (!hasKeyboard) issues.add('Missing keyboard controls');

    // Code quality
    if (html.length < 2000) {
      issues.add('Code too short (${html.length} chars) — likely incomplete');
    }
    if (html.contains('// TODO') || html.contains('/* TODO')) {
      issues.add('Contains TODO placeholders');
    }
    if (html.contains('your code here') || html.contains('placeholder')) {
      issues.add('Contains placeholder instructions');
    }

    // Template-specific checks
    for (final element in template.requiredCodeElements) {
      if (!html.contains(element)) {
        issues.add('Missing required element for ${template.genreName}: $element');
      }
    }

    // Web Audio check (soft requirement — warn but don't fail)
    if (!html.contains('AudioContext') && !html.contains('webkitAudioContext')) {
      issues.add('Missing Web Audio API — add oscillator-based sound effects');
    }

    // ── Playability validation ──
    final playability = PlayabilityValidator.validateCode(
      html,
      template.genreName,
    );
    // Playability errors are critical — prefix them for emphasis
    for (final e in playability.errors) {
      issues.add('[PLAYABILITY] $e');
    }
    for (final w in playability.warnings) {
      issues.add('[PLAYABILITY] $w');
    }

    return CodeValidation(issues);
  }
}

// ─── Exceptions & Validation ─────────────────────────────────────────

class GameGenException implements Exception {
  final String message;
  final bool isFatal;
  const GameGenException(this.message, this.isFatal);

  @override
  String toString() => message;
}

class CodeValidation {
  final List<String> issues;
  bool get isValid => issues.isEmpty;
  const CodeValidation(this.issues);
}
