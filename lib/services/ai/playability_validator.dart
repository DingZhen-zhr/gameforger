import 'game_design_document.dart';
import 'templates/template_registry.dart';

/// Result of playability validation with categorized issues.
class PlayabilityResult {
  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;
  bool get isValid => errors.isEmpty;

  const PlayabilityResult({
    this.errors = const [],
    this.warnings = const [],
  });

  /// Format issues for injection into the retry prompt.
  String formatForRetry() {
    final parts = <String>[];
    if (errors.isNotEmpty) {
      parts.add('CRITICAL (game will be unplayable):');
      for (final e in errors) {
        parts.add('  - $e');
      }
    }
    if (warnings.isNotEmpty) {
      parts.add('Warnings (likely unplayable):');
      for (final w in warnings) {
        parts.add('  - $w');
      }
    }
    return parts.join('\n');
  }

  /// Merge another result into this one.
  PlayabilityResult merge(PlayabilityResult other) {
    return PlayabilityResult(
      errors: [...errors, ...other.errors],
      warnings: [...warnings, ...other.warnings],
    );
  }
}

/// Validates that a generated game is actually playable and completable.
///
/// **Architecture**: This class runs **universal** checks that apply to all
/// game genres (game loop, controls, canvas, win/lose states, restart, etc.).
/// Genre-specific checks (jump geometry, wave balance, grid solvability, etc.)
/// are delegated to the per-genre [GenrePlayabilityValidator] returned by
/// each [GameTemplate].
///
/// To add validation for a new genre:
/// 1. Implement [GenrePlayabilityValidator] with genre-specific checks
/// 2. Override [GameTemplate.playabilityValidator] to return an instance
/// 3. Register the template in [TemplateRegistry]
///
/// No changes to this file are needed — the dispatcher picks it up automatically.
class PlayabilityValidator {
  PlayabilityValidator._();

  // ═══════════════════════════════════════════════════════════════════════
  // Design Document Validation
  // ═══════════════════════════════════════════════════════════════════════

  /// Runs universal design checks, then delegates to the genre-specific
  /// validator for genre-aware playability analysis.
  static PlayabilityResult validateDesign(
    GameDesignDocument doc,
    String genreName,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // ── Universal: Player object ──
    final playerObj =
        doc.objects.where((o) => o.type == 'player').firstOrNull;
    if (playerObj == null) {
      errors.add('No player object in design — game has no controllable entity');
    } else {
      final pw = playerObj.properties['width'] ?? 0;
      final ph = playerObj.properties['height'] ?? 0;
      if (pw <= 0 || ph <= 0) {
        warnings.add(
          'Player dimensions invalid (width=$pw, height=$ph) — collision may break',
        );
      }
    }

    // ── Universal: Level content ──
    if (doc.levels.isEmpty) {
      errors.add('No levels defined — game has no content to play');
    }

    // ── Universal: Win/lose conditions ──
    final winCond = doc.scoring.winCondition;
    if (winCond.isEmpty) {
      errors.add('No win condition defined — player can never complete the game');
    } else if (_isVagueCondition(winCond)) {
      warnings.add(
        'Win condition is vague ("$winCond") — specify a concrete, measurable goal',
      );
    }

    final loseCond = doc.scoring.loseCondition;
    if (loseCond.isEmpty) {
      warnings.add('No lose condition defined — no fail state makes the game feel incomplete');
    }

    // ── Universal: State machine ──
    if (!doc.states.states.any((s) => s.toLowerCase() == 'win')) {
      errors.add('No "win" state in state machine — game cannot be completed');
    }

    // ── Genre-specific checks ──
    final template = TemplateRegistry.resolve(genreName);
    final genreResult = template.playabilityValidator.validateDesign(doc);

    return PlayabilityResult(
      errors: [...errors, ...genreResult.errors],
      warnings: [...warnings, ...genreResult.warnings],
    );
  }

  static bool _isVagueCondition(String condition) {
    final lower = condition.toLowerCase().trim();
    return lower == 'collect all items' ||
        lower == 'reach the end' ||
        lower == 'survive' ||
        lower == 'get high score' ||
        lower == 'complete all levels' ||
        lower.isEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Generated Code Validation
  // ═══════════════════════════════════════════════════════════════════════

  /// Runs universal code checks, then delegates to the genre-specific
  /// validator for genre-aware playability analysis.
  static PlayabilityResult validateCode(String html, String genreName) {
    final errors = <String>[];
    final warnings = <String>[];

    // Extract JS from script tags
    final js = _extractJs(html);

    // 1. Game loop must be started
    _checkGameLoopStarted(js, errors);

    // 2. Win state must be settable
    _checkWinStateReachable(js, errors, warnings);

    // 3. Controls must be wired to player actions
    _checkControlsWired(js, errors, warnings);

    // 4. Level/wave data must be populated (not just skeleton placeholders)
    _checkLevelDataPopulated(js, errors);

    // 5. Canvas must be properly initialized
    _checkCanvasSetup(js, errors, warnings);

    // 6. Player spawn within reasonable bounds
    _checkPlayerSpawn(js, html, warnings);

    // 7. Restart function must work
    _checkRestartFunction(js, warnings);

    // 8. All game states must be rendered
    _checkStateRendering(js, warnings);

    // ── Genre-specific checks ──
    final template = TemplateRegistry.resolve(genreName);
    final genreResult = template.playabilityValidator.validateCode(html);

    return PlayabilityResult(
      errors: [...errors, ...genreResult.errors],
      warnings: [...warnings, ...genreResult.warnings],
    );
  }

  // ── 1. Game Loop ─────────────────────────────────────────────────────

  static void _checkGameLoopStarted(String js, List<String> errors) {
    final hasCall = js.contains('gameLoop()');
    final hasRafTopLevel = RegExp(
      r'(?:^|\n)\s*requestAnimationFrame\s*\(\s*[a-zA-Z]',
      multiLine: true,
    ).hasMatch(js);

    if (!hasCall && !hasRafTopLevel) {
      if (js.contains('function gameLoop')) {
        errors.add(
          'Game loop defined but never started — add "gameLoop();" at the end of the script',
        );
      } else {
        errors.add('No game loop found — add requestAnimationFrame game loop');
      }
    }
  }

  // ── 2. Win State ─────────────────────────────────────────────────────

  static void _checkWinStateReachable(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    final winAssign1 = RegExp(r"state\s*=\s*'win'");
    final winAssign2 = RegExp(r'state\s*=\s*"win"');

    if (!winAssign1.hasMatch(js) && !winAssign2.hasMatch(js)) {
      errors.add(
        'No win state assignment found — game can never be completed. '
        'Add "state = \'win\'" when the player meets the win condition.',
      );
      return;
    }

    // Check win condition isn't unreasonably high
    final winScoreMatch = RegExp(r'score\s*>=\s*(\d{5,})').firstMatch(js);
    if (winScoreMatch != null) {
      final threshold = int.tryParse(winScoreMatch.group(1)!) ?? 0;
      if (threshold > 50000) {
        warnings.add(
          'Win requires score >= $threshold which seems unreachable — use a reasonable target',
        );
      }
    }

    final winDistMatch = RegExp(r'distance\s*>=\s*(\d{5,})').firstMatch(js);
    if (winDistMatch != null) {
      final threshold = int.tryParse(winDistMatch.group(1)!) ?? 0;
      if (threshold > 50000) {
        warnings.add(
          'Win requires distance >= $threshold which would take too long',
        );
      }
    }
  }

  // ── 3. Controls ──────────────────────────────────────────────────────

  static void _checkControlsWired(String js, List<String> errors, List<String> warnings) {
    final hasTouchListener = js.contains('touchstart') ||
        js.contains('touchmove') ||
        js.contains('touchend') ||
        js.contains('ontouchstart');

    if (!hasTouchListener) {
      errors.add(
        'No touch controls — game cannot be played on mobile devices. '
        'Add touchstart/touchend handlers on the canvas.',
      );
    } else {
      final touchHandlerAffectsState = _handlerModifiesGameVars(js, 'touch');
      if (!touchHandlerAffectsState) {
        errors.add(
          'Touch handlers exist but don\'t modify player input variables '
          '(keys, player.x, player.vy, jumpPressed, etc.) — controls won\'t work',
        );
      }
    }

    final hasKeyListener = js.contains('keydown') ||
        js.contains('keyup') ||
        js.contains('onkeydown');

    if (!hasKeyListener) {
      errors.add(
        'No keyboard controls — game cannot be tested on desktop. '
        'Add keydown/keyup handlers.',
      );
    } else {
      final keyHandlerAffectsState = _handlerModifiesGameVars(js, 'key');
      if (!keyHandlerAffectsState) {
        warnings.add(
          'Keyboard handlers exist but may not modify game input variables — '
          'verify ArrowLeft/ArrowRight/Space are wired to player movement',
        );
      }
    }
  }

  static bool _handlerModifiesGameVars(String js, String eventType) {
    final handlerStart = js.indexOf(eventType);
    if (handlerStart == -1) return false;

    final snippet = js.substring(
      handlerStart,
      (handlerStart + 600).clamp(0, js.length),
    );

    final inputPatterns = [
      'keys[', 'keys.', 'jumpPressed', 'player.x', 'player.y',
      'player.vx', 'player.vy', 'moveX', 'moveY', 'touchActive',
      'touchX', 'touchY', 'duckPressed', 'selected',
      'ArrowLeft', 'ArrowRight', 'ArrowUp',
    ];

    return inputPatterns.any((p) => snippet.contains(p));
  }

  // ── 4. Level Data ────────────────────────────────────────────────────

  static void _checkLevelDataPopulated(String js, List<String> errors) {
    final buildFuncs = ['buildLevels', 'buildWaves', 'buildPuzzles'];

    for (final func in buildFuncs) {
      if (!js.contains('function $func')) continue;

      final funcMatch = RegExp(
        'function\\s+$func\\s*\\([^)]*\\)\\s*\\{([^}]*)\\}',
        dotAll: true,
      ).firstMatch(js);

      if (funcMatch != null) {
        final body = funcMatch.group(1)!.trim();
        final codeOnly = body
            .replaceAll(RegExp(r'//[^\n]*'), '')
            .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
            .trim();

        final hasData = codeOnly.length > 20 &&
            (codeOnly.contains('=') ||
                codeOnly.contains('push') ||
                codeOnly.contains('levels') ||
                codeOnly.contains('waves') ||
                codeOnly.contains('['));

        if (!hasData) {
          errors.add(
            '$func() contains only placeholder comments — game will have no levels/waves. '
            'Fill in actual level data (platforms, enemies, collectibles).',
          );
        }
      }
    }

    // Check empty arrays that are never populated
    final emptyArrayPatterns = [
      RegExp(r'let\s+levels\s*=\s*\[\s*\];'),
      RegExp(r'var\s+levels\s*=\s*\[\s*\];'),
      RegExp(r'let\s+waves\s*=\s*\[\s*\];'),
      RegExp(r'var\s+waves\s*=\s*\[\s*\];'),
    ];

    for (final pattern in emptyArrayPatterns) {
      final match = pattern.firstMatch(js);
      if (match != null) {
        final afterInit = js.substring(match.end);
        final arrName = match.group(0)!.contains('levels') ? 'levels' : 'waves';
        final populated = RegExp(
          '$arrName\\s*=\\s*\\[|$arrName\\.push\\(|$arrName\\[\\d+\\]\\s*=',
        ).hasMatch(afterInit);

        if (!populated) {
          errors.add('$arrName array is empty and never populated — game has no content');
        }
      }
    }
  }

  // ── 5. Canvas ────────────────────────────────────────────────────────

  static void _checkCanvasSetup(String js, List<String> errors, List<String> warnings) {
    if (!js.contains('getContext')) {
      errors.add('Canvas context never obtained — nothing can be drawn');
    }
    if (!js.contains("getElementById(") && !js.contains("querySelector(")) {
      errors.add('Canvas element never referenced — rendering target missing');
    }
    if (!js.contains('resize') && !js.contains('innerWidth')) {
      warnings.add('No canvas resize handling — may not fit mobile screens');
    }
  }

  // ── 6. Player Spawn ──────────────────────────────────────────────────

  static void _checkPlayerSpawn(String js, String html, List<String> warnings) {
    final playerInitPatterns = [
      RegExp(r"player\s*=\s*\{[^}]*x\s*:\s*(-?\d+)"),
      RegExp(r"player\.x\s*=\s*(-?\d+)"),
      RegExp(r"spawnX\s*[=:]\s*(-?\d+)"),
    ];

    for (final pattern in playerInitPatterns) {
      final match = pattern.firstMatch(js);
      if (match != null) {
        final x = int.tryParse(match.group(1)!) ?? 0;
        if (x < 0) {
          warnings.add('Player spawns at x=$x (off-screen left)');
        }
        if (x > 800) {
          warnings.add('Player spawns at x=$x (likely off-screen right)');
        }
      }
    }

    final yPatterns = [
      RegExp(r"player\s*=\s*\{[^}]*y\s*:\s*(-?\d+)"),
      RegExp(r"player\.y\s*=\s*(-?\d+)"),
      RegExp(r"spawnY\s*[=:]\s*(-?\d+)"),
    ];

    for (final pattern in yPatterns) {
      final match = pattern.firstMatch(js);
      if (match != null) {
        final y = int.tryParse(match.group(1)!) ?? 0;
        if (y < -100) {
          warnings.add('Player spawns at y=$y (far above screen)');
        }
        if (y > 1200) {
          warnings.add('Player spawns at y=$y (far below screen) — may die instantly');
        }
      }
    }
  }

  // ── 7. Restart ───────────────────────────────────────────────────────

  static void _checkRestartFunction(String js, List<String> warnings) {
    if (!js.contains('function restart')) {
      warnings.add('No restart function — player cannot replay after game over/win');
      return;
    }

    final restartMatch = RegExp(
      r'function\s+restart\s*\([^)]*\)\s*\{(.*?)\n\}',
      dotAll: true,
    ).firstMatch(js);

    if (restartMatch != null) {
      final body = restartMatch.group(1) ?? '';

      if (!body.contains("state") || !body.contains('playing')) {
        warnings.add(
          'restart() does not set state to "playing" — game won\'t resume after restart',
        );
      }

      if (!body.contains('score') && !body.contains('Score')) {
        warnings.add('restart() does not reset score — scores will accumulate across plays');
      }
    }
  }

  // ── 8. State Rendering ───────────────────────────────────────────────

  static void _checkStateRendering(String js, List<String> warnings) {
    final requiredStates = ['playing', 'gameOver', 'win'];
    final missingStates = <String>[];

    for (final state in requiredStates) {
      final hasStateRender = js.contains("'$state'") || js.contains('"$state"');
      if (!hasStateRender) {
        missingStates.add(state);
      }
    }

    if (missingStates.isNotEmpty) {
      warnings.add(
        'No rendering for states: ${missingStates.join(', ')} — '
        'these states will show a blank screen',
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static String _extractJs(String html) {
    final scriptMatches = RegExp(
      r'<script[^>]*>(.*?)</script>',
      dotAll: true,
    ).allMatches(html);
    final jsParts = scriptMatches.map((m) => m.group(1) ?? '').join('\n');
    return jsParts.isNotEmpty ? jsParts : html;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
