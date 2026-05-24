import '../game_design_document.dart';
import '../playability_validator.dart';
import 'genre_validator.dart';

/// Validates shooter games for balance, fairness, and wave feasibility.
///
/// Core invariants:
/// - TTK (time-to-kill): player can kill enemies before being overwhelmed
/// - Survivability: player can survive enough hits to have a fair chance
/// - Wave progression: enemy count/difficulty scales reasonably
/// - Spawn fairness: enemies don't all spawn on top of the player
class ShooterPlayabilityValidator implements GenrePlayabilityValidator {
  @override
  String get genreName => 'Shooter';

  // ═══════════════════════════════════════════════════════════════════════
  // Design Phase
  // ═══════════════════════════════════════════════════════════════════════

  @override
  PlayabilityResult validateDesign(GameDesignDocument doc) {
    final errors = <String>[];
    final warnings = <String>[];

    // Player must exist
    final playerObj = doc.objects.where((o) => o.type == 'player').firstOrNull;
    if (playerObj == null) {
      errors.add('[Shooter] No player object — game has no controllable entity');
      return PlayabilityResult(errors: errors, warnings: warnings);
    }

    final moveSpeed = playerObj.properties['moveSpeed'] ?? doc.physics.moveSpeed;
    if (moveSpeed <= 0) {
      errors.add('[Shooter] Player move speed is 0 — cannot dodge enemy bullets');
    }

    // Fire rate check
    final fireRate = playerObj.properties['fireRate'] ?? 15;
    if (fireRate <= 0) {
      errors.add('[Shooter] Player fire rate is 0 — cannot shoot');
    }

    // Bullet/projectile must exist
    final hasBullet = doc.objects.any((o) => o.type == 'projectile');
    if (!hasBullet) {
      errors.add('[Shooter] No projectile defined — player has no way to damage enemies');
    }

    // Enemy analysis
    final enemies = doc.objects.where((o) => o.type == 'enemy').toList();
    if (enemies.isEmpty) {
      errors.add('[Shooter] No enemies — nothing to shoot at');
    } else {
      for (final enemy in enemies) {
        _checkEnemyBalance(enemy, playerObj, fireRate, errors, warnings);
      }
    }

    // Level/wave content
    if (doc.levels.isEmpty) {
      errors.add('[Shooter] No waves defined — game has no content');
    } else {
      _checkWaveProgression(doc.levels, errors, warnings);
    }

    // Win/lose conditions
    if (doc.scoring.winCondition.isEmpty) {
      errors.add('[Shooter] No win condition — player can never complete the game');
    }
    if (!doc.scoring.loseCondition.toLowerCase().contains('hp') &&
        !doc.scoring.loseCondition.toLowerCase().contains('health')) {
      warnings.add('[Shooter] Lose condition should reference player HP');
    }

    // State machine needs gameOver
    if (!doc.states.states.any((s) => s.toLowerCase() == 'gameover')) {
      errors.add('[Shooter] No "gameOver" state — game cannot end on death');
    }

    return PlayabilityResult(errors: errors, warnings: warnings);
  }

  /// Checks whether an enemy type is fairly balanced against the player.
  static void _checkEnemyBalance(
    GameObject enemy,
    GameObject player,
    num fireRate,
    List<String> errors,
    List<String> warnings,
  ) {
    final enemyHp = enemy.properties['hp'] ?? 20;
    final enemySpeed = enemy.properties['speed'] ?? 2;
    final enemyScore = enemy.properties['score'] ?? 50;
    final bulletDamage = 10.0; // default from template

    // Shots to kill
    final shotsToKill = (enemyHp / bulletDamage).ceil();
    if (shotsToKill > 20) {
      errors.add(
        '[Shooter] Enemy "${enemy.name}" requires $shotsToKill shots to kill '
        '(HP=$enemyHp, bullet damage=$bulletDamage) — too many, player will be overwhelmed',
      );
    } else if (shotsToKill > 10) {
      warnings.add(
        '[Shooter] Enemy "${enemy.name}" takes $shotsToKill shots — consider lowering HP',
      );
    }

    // Enemy speed vs player speed
    final playerSpeed = player.properties['moveSpeed'] ?? 5;
    if (enemySpeed > playerSpeed * 1.5) {
      warnings.add(
        '[Shooter] Enemy "${enemy.name}" speed ($enemySpeed) is much faster '
        'than player ($playerSpeed) — impossible to outrun',
      );
    }

    // Score reward proportionality
    if (enemyScore < shotsToKill * 5) {
      warnings.add(
        '[Shooter] Enemy "${enemy.name}" gives only $enemyScore points but '
        'takes $shotsToKill shots — poor risk/reward ratio',
      );
    }
  }

  /// Checks that wave progression is reasonable.
  static void _checkWaveProgression(
    List<LevelDesign> levels,
    List<String> errors,
    List<String> warnings,
  ) {
    List<int> enemyCounts = [];
    for (int i = 0; i < levels.length; i++) {
      enemyCounts.add(levels[i].enemies.length);
    }

    if (enemyCounts.every((c) => c == 0)) {
      errors.add('[Shooter] All waves have 0 enemies — nothing to fight');
      return;
    }

    // Check for massive jumps in enemy count
    for (int i = 1; i < enemyCounts.length; i++) {
      if (enemyCounts[i - 1] > 0 && enemyCounts[i] > enemyCounts[i - 1] * 5) {
        warnings.add(
          '[Shooter] Wave ${i + 1} has ${enemyCounts[i]} enemies vs '
          '${enemyCounts[i - 1]} in wave $i — 5x+ jump may be unfair',
        );
      }
    }

    // Maximum enemy density check
    final maxEnemies = enemyCounts.reduce((a, b) => a > b ? a : b);
    if (maxEnemies > 50) {
      warnings.add(
        '[Shooter] Wave with $maxEnemies enemies — may cause performance issues '
        'or be impossible to clear',
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

    _checkMechanics(js, errors, warnings);
    _checkBalanceFromCode(js, errors, warnings);
    _checkWaveSystem(js, errors, warnings);

    return PlayabilityResult(errors: errors, warnings: warnings);
  }

  /// Checks core shooter mechanics are present.
  static void _checkMechanics(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    final hasShootMechanic = js.contains('fireBullet') ||
        js.contains('bullets.push') ||
        js.contains('shoot(');
    if (!hasShootMechanic) {
      errors.add(
        '[Shooter-Code] No shooting mechanics — player cannot fire. '
        'Add a fireBullet() function that pushes to the bullets array.',
      );
    }

    if (!js.contains('enemy') || !js.contains('enemies')) {
      errors.add('[Shooter-Code] No enemy system — nothing to shoot at');
    }

    if (!js.contains('player.hp') && !js.contains('playerHp')) {
      warnings.add('[Shooter-Code] No player HP — game over on any hit');
    }

    // Power-up system
    if (!js.contains('powerup') && !js.contains('powerUp')) {
      warnings.add('[Shooter-Code] No power-up system — gameplay may feel flat');
    }
  }

  /// Extracts values from JS and checks balance.
  static void _checkBalanceFromCode(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    final fireRate = _extractJsNumber(js, 'FIRE_RATE');
    final bulletSpeed = _extractJsNumber(js, 'speed') ?? 8;

    // Fire rate sanity
    if (fireRate != null && fireRate > 60) {
      errors.add(
        '[Shooter-Code] FIRE_RATE=$fireRate frames between shots — '
        'player fires less than once per second, too slow',
      );
    }

    // Bullet speed vs enemy speed (approximate)
    final enemySpeeds = <double>[];
    for (final m in RegExp(r'speed\s*:\s*([\d.]+)').allMatches(js)) {
      final s = double.tryParse(m.group(1)!);
      if (s != null && s > 0 && s < 20) enemySpeeds.add(s);
    }
    if (enemySpeeds.isNotEmpty) {
      final avgEnemySpeed = enemySpeeds.reduce((a, b) => a + b) / enemySpeeds.length;
      if (bulletSpeed < avgEnemySpeed * 0.5) {
        warnings.add(
          '[Shooter-Code] Bullet speed ($bulletSpeed) is much slower than '
          'average enemy speed (${avgEnemySpeed.toStringAsFixed(1)}) — '
          'bullets may never catch enemies',
        );
      }
    }

    // Player HP
    final maxHp = _extractJsNumber(js, 'maxHp');
    if (maxHp != null && maxHp < 2) {
      warnings.add(
        '[Shooter-Code] Player has only ${maxHp.toInt()} HP — one-hit death, consider 3-5 HP',
      );
    }
  }

  /// Checks wave spawning and completion.
  static void _checkWaveSystem(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    if (!js.contains('totalWaves') && !js.contains('waves.length')) {
      warnings.add('[Shooter-Code] No wave counter — may not track progression');
    }

    // Check wave completion detection
    if (!js.contains('enemies.length === 0') &&
        !js.contains('enemies.length==0')) {
      warnings.add(
        '[Shooter-Code] No wave-completion check (enemies.length === 0) — '
        'waves may never end',
      );
    }

    // Check enemy spawn positions aren't all at same spot
    final spawnYPattern = RegExp(r'y\s*:\s*([\d.]+)\s*[,\}]');
    final spawnYs = <double>[];
    for (final m in spawnYPattern.allMatches(js)) {
      final y = double.tryParse(m.group(1)!);
      if (y != null && y < 600) spawnYs.add(y);
    }
    if (spawnYs.isNotEmpty && spawnYs.toSet().length <= 1 && spawnYs.length > 3) {
      warnings.add(
        '[Shooter-Code] All enemies spawn at same y position — '
        'no variety in enemy placement',
      );
    }

    // Restart must reset waves
    if (js.contains('function restart') && !js.contains('currentWave')) {
      warnings.add('[Shooter-Code] restart() does not reset wave counter');
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
