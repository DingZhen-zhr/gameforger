import '../game_design_document.dart';
import '../playability_validator.dart';
import 'genre_validator.dart';

/// Validates platformer games for geometric reachability and physics sanity.
///
/// Core invariant: every consecutive platform pair must be reachable given
/// the player's jump physics (max height, max horizontal distance).
class PlatformerPlayabilityValidator implements GenrePlayabilityValidator {
  @override
  String get genreName => 'Platformer';

  // ═══════════════════════════════════════════════════════════════════════
  // Design Phase
  // ═══════════════════════════════════════════════════════════════════════

  @override
  PlayabilityResult validateDesign(GameDesignDocument doc) {
    final errors = <String>[];
    final warnings = <String>[];

    // Physics baseline
    _checkPlatformerPhysics(doc.physics, errors, warnings);

    final jumpParams = _JumpParams.fromPhysics(doc.physics);

    if (doc.levels.isEmpty) {
      errors.add('[Platformer] No levels defined — game has no content');
      return PlayabilityResult(errors: errors, warnings: warnings);
    }

    for (int i = 0; i < doc.levels.length; i++) {
      _checkLevel(doc, i, jumpParams, errors, warnings);
    }

    // Win condition
    if (doc.scoring.winCondition.isEmpty) {
      errors.add('[Platformer] No win condition — player can never complete the game');
    }

    return PlayabilityResult(errors: errors, warnings: warnings);
  }

  static void _checkPlatformerPhysics(
    PhysicsParams p,
    List<String> errors,
    List<String> warnings,
  ) {
    if (p.gravity <= 0) {
      errors.add('[Platformer] Gravity must be positive — objects won\'t fall');
    }
    if (p.jumpForce <= 0) {
      errors.add('[Platformer] Jump force must be positive — player cannot jump');
    }
    if (p.moveSpeed <= 0) {
      errors.add('[Platformer] Move speed must be positive — player cannot move horizontally');
    }
    if (p.gravity > 0 && p.jumpForce > 0) {
      final maxJump = (p.jumpForce * p.jumpForce) / (2 * p.gravity);
      if (maxJump < 30) {
        errors.add(
          '[Platformer] Max jump height is only ${maxJump.toStringAsFixed(0)}px '
          '(jump=${p.jumpForce}, gravity=${p.gravity}) — player can barely leave the ground',
        );
      } else if (maxJump < 60) {
        warnings.add(
          '[Platformer] Max jump height is ${maxJump.toStringAsFixed(0)}px — '
          'platforms must be close together for reachability',
        );
      }
    }
  }

  static void _checkLevel(
    GameDesignDocument doc,
    int levelIndex,
    _JumpParams jumpParams,
    List<String> errors,
    List<String> warnings,
  ) {
    final level = doc.levels[levelIndex];
    final label = 'Level ${levelIndex + 1}';

    if (level.platforms.isEmpty) {
      errors.add('$label: No platforms — player will fall forever');
      return;
    }

    if (level.collectibles.isEmpty) {
      warnings.add(
        '$label: No collectibles — player has no incentive to explore '
        '(win condition: ${doc.scoring.winCondition})',
      );
    }

    // Sort platforms by x for left-to-right reachability analysis
    final sorted = List<Map<String, double>>.from(level.platforms)
      ..sort((a, b) => ((a['x'] ?? 0) - (b['x'] ?? 0)).toInt());

    final spawnX = level.spawnPoint['x'] ?? 50;
    final spawnY = level.spawnPoint['y'] ?? 300;

    // 1. Spawn validity
    _checkSpawnOnPlatform(sorted, spawnX, spawnY, label, errors, warnings);

    // 2. Consecutive platform reachability (geometry vs physics)
    _checkPlatformReachability(
        sorted, jumpParams, doc.physics, label, errors, warnings);

    // 3. Collectibles reachable from at least one platform
    _checkCollectibleReachability(
        level.collectibles, sorted, jumpParams, label, warnings);

    // 4. Enemy placement sanity
    for (final enemy in level.enemies) {
      final ex = enemy['x'] as num? ?? 0;
      final ey = enemy['y'] as num? ?? 0;
      bool onPlatform = false;
      for (final plat in sorted) {
        final px = plat['x'] ?? 0;
        final py = plat['y'] ?? 0;
        final pw = plat['width'] ?? plat['w'] ?? 60;
        if (ex >= px - 5 && ex <= px + pw + 5 && (ey - py).abs() < 10) {
          onPlatform = true;
          break;
        }
      }
      if (!onPlatform) {
        warnings.add(
          '$label: Enemy at ($ex, $ey) is not on any platform — it will fall',
        );
      }
    }
  }

  // ── Spawn Validity ───────────────────────────────────────────────────

  static void _checkSpawnOnPlatform(
    List<Map<String, double>> sortedPlatforms,
    double spawnX,
    double spawnY,
    String label,
    List<String> errors,
    List<String> warnings,
  ) {
    bool foundPlatform = false;
    bool insidePlatform = false;

    for (final plat in sortedPlatforms) {
      final px = plat['x'] ?? 0;
      final py = plat['y'] ?? 0;
      final pw = plat['width'] ?? plat['w'] ?? 60;
      final ph = plat['height'] ?? plat['h'] ?? 20;

      // Spawn inside platform body -> stuck
      if (spawnX >= px && spawnX <= px + pw &&
          spawnY >= py && spawnY <= py + ph) {
        insidePlatform = true;
        break;
      }

      // Spawn directly above this platform -> OK
      if (spawnX >= px - 10 && spawnX <= px + pw + 10 &&
          spawnY <= py && spawnY >= py - 80) {
        foundPlatform = true;
      }
    }

    if (insidePlatform) {
      errors.add(
        '$label: Player spawns inside a platform at ($spawnX, $spawnY) — '
        'will be stuck. Move spawn point above the platform surface.',
      );
      return;
    }

    if (!foundPlatform) {
      errors.add(
        '$label: Player spawns at ($spawnX, $spawnY) with no platform below — '
        'will fall to death. Place a platform under the spawn point.',
      );
    }
  }

  // ── Platform Reachability ────────────────────────────────────────────

  static void _checkPlatformReachability(
    List<Map<String, double>> sorted,
    _JumpParams jp,
    PhysicsParams physics,
    String label,
    List<String> errors,
    List<String> warnings,
  ) {
    if (sorted.length < 2) return;

    if (!jp.isValid) {
      warnings.add(
        '$label: Cannot verify platform reachability — '
        'physics invalid (gravity=${physics.gravity}, jumpForce=${physics.jumpForce})',
      );
      return;
    }

    for (int i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];

      final aX = a['x'] ?? 0;
      final aY = a['y'] ?? 0;
      final aW = a['width'] ?? a['w'] ?? 60;
      final bX = b['x'] ?? 0;
      final bY = b['y'] ?? 0;

      final aRight = aX + aW;
      final horizontalGap = bX - aRight;

      // Overlap or touch — no jump needed
      if (horizontalGap <= 0) continue;

      // verticalGap > 0 means b is higher than a (must jump UP)
      final verticalGap = aY - bY;

      if (verticalGap > jp.maxHeight) {
        errors.add(
          '$label: Platform #${i + 2} (x≈${bX.toInt()}, y≈${bY.toInt()}) '
          'is ${verticalGap.toInt()}px above platform #${i + 1} '
          '(x≈${aX.toInt()}, y≈${aY.toInt()}) — '
          'max jump height is only ${jp.maxHeight.toInt()}px '
          '(jumpForce=${physics.jumpForce}, gravity=${physics.gravity}). '
          'Lower platform #${i + 2} to y≤${(aY - jp.maxHeight).toInt()} '
          'or increase jumpForce.',
        );
      }

      if (horizontalGap > jp.maxDistance) {
        errors.add(
          '$label: Horizontal gap of ${horizontalGap.toInt()}px between '
          'platform #${i + 1} (right edge x≈${aRight.toInt()}) and '
          'platform #${i + 2} (left edge x≈${bX.toInt()}) — '
          'max horizontal jump distance is only ${jp.maxDistance.toInt()}px '
          '(moveSpeed=${physics.moveSpeed}). '
          'Move platform #${i + 2} left to x≤${(aRight + jp.maxDistance).toInt()} '
          'or increase moveSpeed/jumpForce.',
        );
      }

      // Combined difficulty warning
      if (verticalGap > jp.maxHeight * 0.65 &&
          horizontalGap > jp.maxDistance * 0.6) {
        warnings.add(
          '$label: Hard jump #${i + 1}→#${i + 2}: '
          '${verticalGap.toInt()}px up AND ${horizontalGap.toInt()}px across '
          '(max: ${jp.maxHeight.toInt()}px up, ${jp.maxDistance.toInt()}px across).',
        );
      }
    }
  }

  // ── Collectible Reachability ─────────────────────────────────────────

  static void _checkCollectibleReachability(
    List<Map<String, dynamic>> collectibles,
    List<Map<String, double>> sortedPlatforms,
    _JumpParams jp,
    String label,
    List<String> warnings,
  ) {
    if (collectibles.isEmpty || sortedPlatforms.isEmpty) return;
    if (!jp.isValid) return;

    int unreachable = 0;
    for (final item in collectibles) {
      final cx = (item['x'] as num?)?.toDouble() ?? 0;
      final cy = (item['y'] as num?)?.toDouble() ?? 0;

      bool reachable = false;
      for (final plat in sortedPlatforms) {
        final px = plat['x'] ?? 0;
        final py = plat['y'] ?? 0;
        final pw = plat['width'] ?? plat['w'] ?? 60;
        final platCenterX = px + pw / 2;

        final dx = (cx - platCenterX).abs();
        final dy = py - cy;

        if (dy >= 0 && dy <= jp.maxHeight && dx <= jp.maxDistance + pw / 2) {
          reachable = true;
          break;
        }
        if (dy < 0 && dy > -120 && dx <= jp.maxDistance + pw / 2) {
          reachable = true;
          break;
        }
      }

      if (!reachable) unreachable++;
    }

    if (unreachable > 0) {
      warnings.add(
        '$label: $unreachable collectible(s) may be unreachable. '
        'Place them on or near platforms (within ${jp.maxHeight.toInt()}px up, '
        '${jp.maxDistance.toInt()}px across).',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Code Phase
  // ═══════════════════════════════════════════════════════════════════════

  @override
  PlayabilityResult validateCode(String html) {
    final errors = <String>[];
    final warnings = <String>[];

    final js = _extractJs(html);

    // Genre mechanics: jump, gravity, grounded check
    _checkMechanics(js, errors, warnings);

    // Geometric reachability from generated code
    _checkCodeReachability(js, errors, warnings);

    return PlayabilityResult(errors: errors, warnings: warnings);
  }

  static void _checkMechanics(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check for jump mechanics: vy = -JUMP_FORCE, vy = -12, vy -= jumpForce, etc.
    final hasJump = RegExp(r'(?:vy|player\.vy|velocity\.y)\s*[-+]=?\s*(?:-\s*)?(?:JUMP_FORCE|jumpForce|jump_force|\d+)').hasMatch(js);
    if (!hasJump) {
      // Also check for: this.vy = -... inside a jump function
      final hasJumpFunc = js.contains('jump') &&
          RegExp(r'vy\s*=\s*-').hasMatch(js);
      if (!hasJumpFunc) {
        errors.add(
          '[Platformer] No jump mechanics found — player cannot jump. '
          'Add "player.vy = -JUMP_FORCE" when jump is pressed and player is grounded.',
        );
      }
    }
    if (!js.contains('GRAVITY') && !js.contains('gravity')) {
      errors.add('[Platformer] No gravity variable — objects won\'t fall');
    }
    if (!js.contains('grounded') && !js.contains('isGrounded') && !js.contains('onGround')) {
      warnings.add(
        '[Platformer] No grounded check — player may jump infinitely in air. '
        'Add "if (player.grounded && jumpPressed) { player.vy = -JUMP_FORCE; }"',
      );
    }
  }

  static void _checkCodeReachability(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    final gravity = _extractJsNumber(js, 'GRAVITY');
    final jumpForce = _extractJsNumber(js, 'JUMP_FORCE');
    final moveSpeed = _extractJsNumber(js, 'MOVE_SPEED') ?? 4;

    if (gravity == null || jumpForce == null || gravity <= 0) {
      warnings.add(
        '[Platformer-Code] Cannot extract GRAVITY/JUMP_FORCE — '
        'skipping platform reachability check',
      );
      return;
    }

    final maxJumpH = (jumpForce * jumpForce) / (2 * gravity);
    final airTime = 2 * jumpForce / gravity;
    final maxJumpD = moveSpeed * airTime;

    final platforms = _extractPlatformPositions(js);
    if (platforms == null || platforms.length < 2) {
      if (maxJumpH < 50) {
        errors.add(
          '[Platformer-Code] Max jump height is only ${maxJumpH.toInt()}px '
          '(JUMP_FORCE=$jumpForce, GRAVITY=$gravity) — '
          'platforms must be very close together. Increase JUMP_FORCE or decrease GRAVITY.',
        );
      }
      if (maxJumpD < 80) {
        warnings.add(
          '[Platformer-Code] Max horizontal jump is only ${maxJumpD.toInt()}px '
          '(MOVE_SPEED=$moveSpeed, airTime=${airTime.toInt()} frames).',
        );
      }
      return;
    }

    for (int i = 0; i < platforms.length - 1; i++) {
      final a = platforms[i];
      final b = platforms[i + 1];

      final aRight = (a['x'] ?? 0) + (a['w'] ?? 60);
      final bX = b['x'] ?? 0;
      final horizontalGap = bX - aRight;
      if (horizontalGap <= 0) continue;

      final verticalGap = (a['y'] ?? 0) - (b['y'] ?? 0);

      if (verticalGap > maxJumpH) {
        errors.add(
          '[Platformer-Code] Platform at x≈${bX.toInt()}, y≈${(b['y'] ?? 0).toInt()} '
          'is ${verticalGap.toInt()}px above previous — '
          'max jump height is only ${maxJumpH.toInt()}px. '
          'This gap is IMPOSSIBLE — lower the platform or increase JUMP_FORCE.',
        );
      }

      if (horizontalGap > maxJumpD) {
        errors.add(
          '[Platformer-Code] Horizontal gap ${horizontalGap.toInt()}px between '
          'platforms (x≈${aRight.toInt()} → x≈${bX.toInt()}) — '
          'max jump distance only ${maxJumpD.toInt()}px. '
          'Move platforms closer or increase MOVE_SPEED/JUMP_FORCE.',
        );
      }

      if (verticalGap > maxJumpH * 0.65 && horizontalGap > maxJumpD * 0.6) {
        warnings.add(
          '[Platformer-Code] Hard jump: ${verticalGap.toInt()}px up AND '
          '${horizontalGap.toInt()}px across (max: ${maxJumpH.toInt()}/${maxJumpD.toInt()}).',
        );
      }
    }
  }

  // ── JS Extraction Helpers ────────────────────────────────────────────

  static String _extractJs(String html) {
    final matches = RegExp(
      r'<script[^>]*>(.*?)</script>',
      dotAll: true,
    ).allMatches(html);
    final parts = matches.map((m) => m.group(1) ?? '').join('\n');
    return parts.isNotEmpty ? parts : html;
  }

  static double? _extractJsNumber(String js, String varName) {
    // Match: const/let/var VARNAME = NUMBER; (with optional semicolon and whitespace)
    final match = RegExp(
      r'(?:const|let|var)\s+' + RegExp.escape(varName) + r'\s*=\s*([\d.]+)',
    ).firstMatch(js);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    // Also match bare assignment: VARNAME = NUMBER;
    final bareMatch = RegExp(
      r'\b' + RegExp.escape(varName) + r'\s*=\s*([\d.]+)',
    ).firstMatch(js);
    if (bareMatch != null) {
      return double.tryParse(bareMatch.group(1)!);
    }
    return null;
  }

  /// Extracts platform positions from generated JS code.
  ///
  /// Handles multiple code patterns:
  /// - Object literals: `{x:50, y:400, w:100}`, `{x:50,y:400,w:100,h:20}`
  /// - Array format: `[x, y, w, h]`
  /// - Different property names: `width`, `X`, `Y`
  /// - Push patterns: `platforms.push({...})`
  /// - Nested in levels arrays
  static List<Map<String, double>>? _extractPlatformPositions(String js) {
    // Strategy A: Try to find object literals with x/y properties
    final platforms = <Map<String, double>>[];

    // Pattern A1: Object literals with x/X and y/Y keys
    // Matches: {x:50, y:400, w:100}, {x:50,y:400}, {"x":50,"y":400} etc
    final objPattern = RegExp(
      r'\{[^{}]*?[xX]["\s:]*[:\s]+(\d+(?:\.\d+)?)[^{}]*?[yY]["\s:]*[:\s]+(\d+(?:\.\d+)?)[^{}]*?\}',
    );
    final matches = objPattern.allMatches(js).toList();

    for (final m in matches) {
      final obj = m.group(0)!;
      // Skip objects that look like player/character configs
      if (obj.contains('facingRight') ||
          obj.contains('invincible') ||
          obj.contains('grounded') ||
          obj.contains('vx') && obj.contains('vy') && obj.contains('width') && obj.contains('height')) {
        continue;
      }
      final xM = RegExp(r'[xX]["\s:]*[:\s]+(\d+(?:\.\d+)?)').firstMatch(obj);
      final yM = RegExp(r'[yY]["\s:]*[:\s]+(\d+(?:\.\d+)?)').firstMatch(obj);
      final wM = RegExp(r'(?:w(?:idth)?|W(?:idth)?)["\s:]*[:\s]+(\d+(?:\.\d+)?)').firstMatch(obj);
      final hM = RegExp(r'(?:h(?:eight)?|H(?:eight)?)["\s:]*[:\s]+(\d+(?:\.\d+)?)').firstMatch(obj);

      if (xM != null && yM != null) {
        final x = double.tryParse(xM.group(1)!);
        final y = double.tryParse(yM.group(1)!);
        if (x != null && y != null && x >= 0 && x < 5000 && y >= 0 && y < 5000) {
          platforms.add({
            'x': x,
            'y': y,
            'w': wM != null ? double.tryParse(wM.group(1)!) ?? 80 : 80,
            'h': hM != null ? double.tryParse(hM.group(1)!) ?? 20 : 20,
          });
        }
      }
    }

    // Pattern A2: Array format [x, y, w, h] inside platform arrays
    // Matches patterns like: platforms = [[50,400,100,20], [200,300,100,20]]
    // Only used if A1 found nothing
    if (platforms.isEmpty) {
      final arrPattern = RegExp(
        r'\[(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\]',
      );
      for (final m in arrPattern.allMatches(js)) {
        final x = double.tryParse(m.group(1)!);
        final y = double.tryParse(m.group(2)!);
        final w = double.tryParse(m.group(3)!);
        final h = double.tryParse(m.group(4)!);
        if (x != null && y != null && w != null && h != null &&
            x >= 0 && x < 5000 && y >= 0 && y < 5000) {
          platforms.add({'x': x, 'y': y, 'w': w, 'h': h});
        }
      }
    }

    // Deduplicate and sort by x
    if (platforms.length < 2) return null;

    final seen = <String>{};
    final unique = <Map<String, double>>[];
    for (final p in platforms) {
      final key = '${p['x']!.toInt()}_${p['y']!.toInt()}';
      if (seen.add(key)) unique.add(p);
    }

    if (unique.length < 2) return null;
    unique.sort((a, b) => (a['x']! - b['x']!).toInt());
    return unique;
  }
}

/// Pre-computed jump capabilities for geometric reachability checks.
class _JumpParams {
  final double maxHeight;
  final double maxDistance;
  final double gravity;
  final double jumpForce;
  final double moveSpeed;

  const _JumpParams({
    required this.maxHeight,
    required this.maxDistance,
    required this.gravity,
    required this.jumpForce,
    required this.moveSpeed,
  });

  factory _JumpParams.fromPhysics(PhysicsParams p) {
    if (p.gravity <= 0 || p.jumpForce <= 0) {
      return const _JumpParams(
        maxHeight: 0, maxDistance: 0,
        gravity: 0, jumpForce: 0, moveSpeed: 0,
      );
    }
    final maxH = (p.jumpForce * p.jumpForce) / (2 * p.gravity);
    final airTime = 2 * p.jumpForce / p.gravity;
    final maxD = p.moveSpeed * airTime;
    return _JumpParams(
      maxHeight: maxH, maxDistance: maxD,
      gravity: p.gravity, jumpForce: p.jumpForce,
      moveSpeed: p.moveSpeed,
    );
  }

  bool get isValid => maxHeight > 0 && maxDistance > 0;
}
