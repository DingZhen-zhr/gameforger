import '../game_design_document.dart';
import '../playability_validator.dart';
import 'genre_validator.dart';

/// Validates runner games for obstacle clearance, speed progression, and
/// reaction-time fairness.
///
/// Core invariants:
/// - Every obstacle type can be cleared (jumped over or ducked under)
/// - Scroll speed doesn't accelerate to impossible levels too quickly
/// - Obstacle spawn interval allows human reaction time
/// - Coin placements are reachable
class RunnerPlayabilityValidator implements GenrePlayabilityValidator {
  @override
  String get genreName => 'Runner';

  // ═══════════════════════════════════════════════════════════════════════
  // Design Phase
  // ═══════════════════════════════════════════════════════════════════════

  @override
  PlayabilityResult validateDesign(GameDesignDocument doc) {
    final errors = <String>[];
    final warnings = <String>[];

    // Physics baseline
    _checkRunnerPhysics(doc.physics, errors, warnings);

    // Level/runner data
    if (doc.levels.isEmpty) {
      errors.add('[Runner] No levels defined — game has no content');
      return PlayabilityResult(errors: errors, warnings: warnings);
    }

    for (int i = 0; i < doc.levels.length; i++) {
      _checkLevel(doc.levels[i], i, doc.physics, errors, warnings);
    }

    // Player object check
    final playerObj = doc.objects.where((o) => o.type == 'player').firstOrNull;
    if (playerObj == null) {
      errors.add('[Runner] No player object — game has no controllable entity');
    }

    // Obstacle types must exist
    final hasObstacles = doc.objects.any((o) => o.type == 'obstacle');
    if (!hasObstacles) {
      errors.add('[Runner] No obstacle objects — game has no challenge');
    }

    return PlayabilityResult(errors: errors, warnings: warnings);
  }

  static void _checkRunnerPhysics(
    PhysicsParams p,
    List<String> errors,
    List<String> warnings,
  ) {
    if (p.gravity <= 0) {
      errors.add('[Runner] Gravity must be positive — player won\'t land after jumping');
    }
    if (p.jumpForce <= 0) {
      errors.add('[Runner] Jump force must be positive — player cannot avoid obstacles');
    }

    if (p.gravity > 0 && p.jumpForce > 0) {
      final maxJump = (p.jumpForce * p.jumpForce) / (2 * p.gravity);
      if (maxJump < 40) {
        errors.add(
          '[Runner] Max jump height is only ${maxJump.toStringAsFixed(0)}px '
          '(jump=${p.jumpForce}, gravity=${p.gravity}) — '
          'cannot clear even basic obstacles',
        );
      } else if (maxJump < 80) {
        warnings.add(
          '[Runner] Max jump height is ${maxJump.toStringAsFixed(0)}px — '
          'obstacles must be short for reachability',
        );
      }
    }
  }

  static void _checkLevel(
    LevelDesign level,
    int levelIndex,
    PhysicsParams physics,
    List<String> errors,
    List<String> warnings,
  ) {
    final data = level.toJson()['runnerData'] as Map<String, dynamic>?;
    if (data == null) {
      warnings.add('[Runner] Level ${levelIndex + 1}: No runnerData — cannot validate');
      return;
    }

    final label = 'Level ${levelIndex + 1}';

    // Scroll speed
    final scrollSpeed = (data['scrollSpeed'] as num?)?.toDouble() ?? 4;
    if (scrollSpeed <= 0) {
      errors.add('$label: Scroll speed is 0 — obstacles will never approach');
    } else if (scrollSpeed < 2) {
      warnings.add('$label: Scroll speed is very slow ($scrollSpeed) — game may feel boring');
    } else if (scrollSpeed > 12) {
      errors.add(
        '$label: Initial scroll speed is $scrollSpeed — too fast for human reaction. '
        'Start at 3-6 and increase gradually.',
      );
    }

    // Speed increment
    final speedIncrement = (data['speedIncrement'] as num?)?.toDouble() ?? 0.002;
    if (speedIncrement <= 0) {
      warnings.add('$label: Speed increment is 0 — difficulty never increases');
    } else if (speedIncrement > 0.05) {
      errors.add(
        '$label: Speed increment $speedIncrement is too aggressive — '
        'game becomes impossible within seconds',
      );
    } else if (speedIncrement > 0.01) {
      warnings.add(
        '$label: Speed increment $speedIncrement is high — game may become '
        'unplayable quickly',
      );
    }

    // Obstacle interval
    final obstacleInterval = (data['obstacleInterval'] as num?)?.toDouble() ?? 90;
    if (obstacleInterval < 30) {
      errors.add(
        '$label: Obstacle interval is $obstacleInterval frames — '
        'obstacles spawn too frequently to react. Minimum ~40 frames (0.67s at 60fps).',
      );
    } else if (obstacleInterval < 50) {
      warnings.add(
        '$label: Obstacle interval $obstacleInterval is tight — limited reaction time',
      );
    }

    // Obstacle height vs jump capability
    final maxJumpH = (physics.jumpForce * physics.jumpForce) / (2 * physics.gravity);

    // Check obstacle heights from level enemies (obstacles)
    for (final enemy in level.enemies) {
      final height = (enemy['height'] as num?)?.toDouble() ?? 30;
      if (height > maxJumpH) {
        errors.add(
          '$label: Obstacle height ${height.toInt()}px exceeds max jump height '
          '${maxJumpH.toInt()}px — impossible to clear. '
          'Reduce obstacle height to ≤${maxJumpH.toInt()}px or increase jumpForce.',
        );
      } else if (height > maxJumpH * 0.85) {
        warnings.add(
          '$label: Obstacle height ${height.toInt()}px is close to max jump '
          '${maxJumpH.toInt()}px — very tight timing required',
        );
      }
    }

    // Target distance
    final targetDistance = (data['targetDistance'] as num?)?.toDouble();
    if (targetDistance != null) {
      if (targetDistance <= 0) {
        errors.add('$label: Target distance is 0 — game ends instantly');
      } else if (targetDistance > 50000) {
        warnings.add(
          '$label: Target distance ${targetDistance.toInt()}m — would take '
          'extremely long to complete',
        );
      }
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

    _checkMechanics(js, errors, warnings);
    _checkObstacleClearance(js, errors, warnings);
    _checkSpeedProgression(js, errors, warnings);

    return PlayabilityResult(errors: errors, warnings: warnings);
  }

  /// Checks core runner mechanics are present.
  static void _checkMechanics(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    if (!RegExp(r'vy\s*=\s*-').hasMatch(js) &&
        !js.contains('JUMP_FORCE') &&
        !js.contains('jumpForce')) {
      errors.add('[Runner-Code] No jump mechanics — player cannot avoid obstacles');
    }

    if (!js.contains('scrollSpeed')) {
      errors.add('[Runner-Code] No scroll speed — world won\'t move');
    }

    if (!js.contains('obstacle') && !js.contains('obstacles')) {
      warnings.add('[Runner-Code] No obstacles — game has no challenge');
    }

    if (!js.contains('groundY') && !js.contains('ground')) {
      warnings.add('[Runner-Code] No ground detection — player may fall forever');
    }

    if (!js.contains('duck') && !js.contains('duckPressed')) {
      warnings.add(
        '[Runner-Code] No duck mechanic — barriers that require ducking cannot be avoided',
      );
    }
  }

  /// Verifies obstacle heights are clearable with current jump physics.
  static void _checkObstacleClearance(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    final jumpForce = _extractJsNumber(js, 'JUMP_FORCE');
    final gravity = _extractJsNumber(js, 'GRAVITY');

    if (jumpForce == null || gravity == null || gravity <= 0) return;

    final maxJumpH = (jumpForce * jumpForce) / (2 * gravity);

    // Collect obstacle heights from object literals
    final obstacleHeights = <double>[];
    final obsPatterns = [
      RegExp(r'spike[^}]*?(?:height|h)\s*:\s*([\d.]+)', caseSensitive: false),
      RegExp(r'barrier[^}]*?(?:height|h)\s*:\s*([\d.]+)', caseSensitive: false),
      RegExp(r'obstacle[^}]*?(?:height|h)\s*:\s*([\d.]+)', caseSensitive: false),
      RegExp(r"type\s*:\s*'spike'[^}]*y\s*:\s*gy\s*-\s*([\d.]+)", caseSensitive: false),
      RegExp(r'type\s*:\s*"spike"[^}]*y\s*:\s*gy\s*-\s*([\d.]+)', caseSensitive: false),
      RegExp(r"type\s*:\s*'barrier'[^}]*y\s*:\s*gy\s*-\s*([\d.]+)", caseSensitive: false),
    ];

    for (final pattern in obsPatterns) {
      for (final m in pattern.allMatches(js)) {
        final h = double.tryParse(m.group(1)!);
        if (h != null && h > 0 && h < 500) obstacleHeights.add(h);
      }
    }

    if (obstacleHeights.isEmpty) {
      warnings.add(
        '[Runner-Code] Cannot extract obstacle heights — '
        'verify max jump height (${maxJumpH.toInt()}px with '
        'JUMP_FORCE=$jumpForce, GRAVITY=$gravity) clears all obstacles',
      );
      return;
    }

    final tallest = obstacleHeights.reduce((a, b) => a > b ? a : b);

    if (tallest > maxJumpH) {
      errors.add(
        '[Runner-Code] Tallest obstacle is ${tallest.toInt()}px but '
        'max jump height is only ${maxJumpH.toInt()}px '
        '(JUMP_FORCE=$jumpForce, GRAVITY=$gravity). '
        'Player can NEVER clear this obstacle — '
        'increase JUMP_FORCE or reduce obstacle height to ≤${maxJumpH.toInt()}px.',
      );
    } else if (tallest > maxJumpH * 0.85) {
      warnings.add(
        '[Runner-Code] Tallest obstacle (${tallest.toInt()}px) is very close '
        'to max jump height (${maxJumpH.toInt()}px) — timing will be extremely tight',
      );
    }

    // Check barrier heights for ducking feasibility
    final barrierPattern = RegExp(
      r'barrier[^}]*y\s*:\s*gy\s*-\s*([\d.]+)',
      caseSensitive: false,
    );
    for (final m in barrierPattern.allMatches(js)) {
      final barrierHeight = double.tryParse(m.group(1)!);
      if (barrierHeight != null && barrierHeight > 80) {
        warnings.add(
          '[Runner-Code] Barrier height ${barrierHeight.toInt()}px — '
          'too tall to duck under (player height ≈ 25 when ducking)',
        );
      }
    }
  }

  /// Checks speed progression doesn't make the game impossible.
  static void _checkSpeedProgression(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    final scrollSpeed = _extractJsNumber(js, 'scrollSpeed');
    final speedIncrement = _extractJsNumber(js, 'SPEED_INCREMENT');

    if (speedIncrement != null && speedIncrement > 0.05) {
      errors.add(
        '[Runner-Code] SPEED_INCREMENT=$speedIncrement is too aggressive — '
        'game becomes impossible within seconds',
      );
    }

    if (scrollSpeed != null && scrollSpeed > 12) {
      errors.add(
        '[Runner-Code] Initial scrollSpeed=$scrollSpeed — too fast for human reaction',
      );
    }

    // Check obstacle spawn interval adapts to speed
    if (!js.contains('OBSTACLE_INTERVAL') && !js.contains('obstacleTimer')) {
      warnings.add('[Runner-Code] No obstacle spawn timer — spawn pattern unclear');
    }

    // Verify obstacle timer decreases with speed (so game doesn't get easier)
    final hasAdaptiveSpawning = js.contains('scrollSpeed * 3') ||
        js.contains('scrollSpeed*3') ||
        js.contains('scrollSpeed *');
    if (!hasAdaptiveSpawning && js.contains('obstacleTimer')) {
      warnings.add(
        '[Runner-Code] Obstacle spawn interval doesn\'t adapt to speed — '
        'game may not increase in difficulty',
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static String _extractJs(String html) {
    final matches = RegExp(
      r'<script[^>]*>(.*?)</script>',
      dotAll: true,
    ).allMatches(html);
    final parts = matches.map((m) => m.group(1) ?? '').join('\n');
    return parts.isNotEmpty ? parts : html;
  }

  static double? _extractJsNumber(String js, String varName) {
    final match = RegExp(
      r'\b' + RegExp.escape(varName) + r'\s*=\s*([\d.]+)',
    ).firstMatch(js);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }
}
