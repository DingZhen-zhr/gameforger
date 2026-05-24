import '../game_design_document.dart';
import '../playability_validator.dart';
import 'genre_validator.dart';

/// Validates puzzle games for solvability and rule consistency.
///
/// Core invariants:
/// - Grid size allows meaningful play (≥4×4)
/// - Color count is balanced against grid size
/// - Target score is achievable within move limit
/// - Match detection covers both directions
/// - Cascade/refill logic is complete
class PuzzlePlayabilityValidator implements GenrePlayabilityValidator {
  @override
  String get genreName => 'Puzzle';

  // ═══════════════════════════════════════════════════════════════════════
  // Design Phase
  // ═══════════════════════════════════════════════════════════════════════

  @override
  PlayabilityResult validateDesign(GameDesignDocument doc) {
    final errors = <String>[];
    final warnings = <String>[];

    // Grid element must exist
    final gridObj = doc.objects.where((o) => o.type == 'board').firstOrNull;
    final rows = gridObj?.properties['rows'] ?? 8;
    final cols = gridObj?.properties['cols'] ?? 8;

    if (rows < 3 || cols < 3) {
      errors.add(
        '[Puzzle] Grid too small (${rows.toInt()}×${cols.toInt()}) — '
        'no meaningful puzzle play possible. Minimum 4×4.',
      );
    } else if (rows < 4 || cols < 4) {
      warnings.add(
        '[Puzzle] Grid is small (${rows.toInt()}×${cols.toInt()}) — '
        'limited strategic depth',
      );
    }

    // Color count
    final tileObj = doc.objects.where((o) => o.type == 'grid_element').firstOrNull;
    final colorCount = tileObj?.properties['colors'] ?? 6;

    if (colorCount < 3) {
      errors.add(
        '[Puzzle] Only $colorCount colors — matches will happen too frequently, '
        'game plays itself. Use 4-8 colors.',
      );
    } else if (colorCount > 12) {
      errors.add(
        '[Puzzle] $colorCount colors on a ${rows.toInt()}×${cols.toInt()} grid — '
        'matches will be extremely rare, game is frustrating. Use 4-8 colors.',
      );
    } else if (colorCount > 8) {
      warnings.add(
        '[Puzzle] $colorCount colors is high — matches may be infrequent',
      );
    }

    // Color-to-grid ratio
    if (rows > 0 && cols > 0 && colorCount > 0) {
      final cellsPerColor = (rows * cols) / colorCount;
      if (cellsPerColor < 2) {
        warnings.add(
          '[Puzzle] Only ${cellsPerColor.toStringAsFixed(0)} cells per color — '
          'very few matching opportunities',
        );
      }
    }

    // Level validation
    if (doc.levels.isEmpty) {
      errors.add('[Puzzle] No levels defined — game has no content');
    } else {
      for (int i = 0; i < doc.levels.length; i++) {
        _checkLevelFeasibility(doc.levels[i], i, rows.toInt(), cols.toInt(),
            colorCount.toInt(), errors, warnings);
      }
    }

    // Win/lose conditions
    if (doc.scoring.winCondition.isEmpty) {
      errors.add('[Puzzle] No win condition — player can never complete the game');
    }

    // State machine needs gameOver and win
    if (!doc.states.states.any((s) => s.toLowerCase() == 'win')) {
      errors.add('[Puzzle] No "win" state — game cannot be completed');
    }

    return PlayabilityResult(errors: errors, warnings: warnings);
  }

  /// Checks whether a puzzle level's target score is achievable within the move limit.
  static void _checkLevelFeasibility(
    LevelDesign level,
    int levelIndex,
    int rows,
    int cols,
    int colorCount,
    List<String> errors,
    List<String> warnings,
  ) {
    final data = level.toJson()['puzzleData'] as Map<String, dynamic>?;
    if (data == null) {
      warnings.add('[Puzzle] Level ${levelIndex + 1}: No puzzleData — cannot validate');
      return;
    }

    final targetScore = (data['targetScore'] as num?)?.toInt() ?? 1000;
    final moveLimit = (data['moveLimit'] as num?)?.toInt() ?? 30;

    if (targetScore <= 0) {
      errors.add(
        '[Puzzle] Level ${levelIndex + 1}: Target score is $targetScore — '
        'level completes instantly',
      );
      return;
    }

    if (moveLimit <= 0) {
      errors.add(
        '[Puzzle] Level ${levelIndex + 1}: Move limit is $moveLimit — '
        'impossible to make any moves',
      );
      return;
    }

    // Feasibility: estimate max possible score
    // Each match-3 = 30 points. Assume ~30% of moves yield matches (conservative).
    // With cascades, effective matches per move ≈ 1.3
    final scorePerMatch = 30;
    final effectiveMatchesPerMove = 1.3;
    final maxPossibleScore = (moveLimit * effectiveMatchesPerMove * scorePerMatch).toInt();

    if (targetScore > maxPossibleScore) {
      errors.add(
        '[Puzzle] Level ${levelIndex + 1}: Target score $targetScore is '
        'mathematically impossible — max achievable ≈ $maxPossibleScore '
        '($moveLimit moves × ${scorePerMatch}pts/match). '
        'Lower target to ≤$maxPossibleScore or increase move limit.',
      );
    } else if (targetScore > maxPossibleScore * 0.8) {
      warnings.add(
        '[Puzzle] Level ${levelIndex + 1}: Target $targetScore is very tight '
        '(max feasible ≈ $maxPossibleScore) — requires near-perfect play',
      );
    }

    // Move limit sanity
    if (moveLimit < 10) {
      warnings.add(
        '[Puzzle] Level ${levelIndex + 1}: Only $moveLimit moves — very short level',
      );
    }

    if (moveLimit > 200) {
      warnings.add(
        '[Puzzle] Level ${levelIndex + 1}: $moveLimit moves — excessively long',
      );
    }

    // Level-to-level progression
    if (levelIndex > 0 && data['targetScore'] != null) {
      // Target score should increase, not stay flat
      if (targetScore <= 100) {
        warnings.add(
          '[Puzzle] Level ${levelIndex + 1}: Target score too low ($targetScore)',
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
    _checkMatchLogic(js, errors, warnings);
    _checkCascadeLogic(js, errors, warnings);
    _checkWinLoseDetection(js, errors, warnings);

    return PlayabilityResult(errors: errors, warnings: warnings);
  }

  /// Checks core puzzle mechanics are present.
  static void _checkMechanics(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    if (!js.contains('grid') || !js.contains('Grid')) {
      errors.add('[Puzzle-Code] No grid system — puzzle game has no board');
    }

    final hasMatchLogic = js.contains('findMatches') ||
        js.contains('checkMatch') ||
        js.contains('match(');
    if (!hasMatchLogic) {
      errors.add(
        '[Puzzle-Code] No match-detection logic — puzzle cannot detect wins',
      );
    }

    if (!js.contains('swap') && !js.contains('Swap')) {
      errors.add(
        '[Puzzle-Code] No swap/selection mechanic — player cannot interact with tiles',
      );
    }

    // Selection highlight
    if (!js.contains('selected')) {
      warnings.add('[Puzzle-Code] No tile selection state — poor UX feedback');
    }
  }

  /// Verifies match detection covers both horizontal and vertical directions.
  static void _checkMatchLogic(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check for horizontal match detection
    final hasHorizontal = js.contains('c+1') && js.contains('c+2');
    final hasVertical = js.contains('r+1') && js.contains('r+2');

    if (!hasHorizontal && !hasVertical) {
      errors.add(
        '[Puzzle-Code] Match detection incomplete — '
        'must check both horizontal and vertical 3-in-a-row',
      );
    } else if (!hasHorizontal) {
      errors.add('[Puzzle-Code] Missing horizontal match detection');
    } else if (!hasVertical) {
      errors.add('[Puzzle-Code] Missing vertical match detection');
    }

    // Must compare adjacent tiles by color/value, not just position
    if (!js.contains('grid[r][c]') && !js.contains('grid[')) {
      warnings.add('[Puzzle-Code] Match detection may not reference grid values');
    }
  }

  /// Verifies cascade/refill logic after matches are removed.
  static void _checkCascadeLogic(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    // After removing matches, tiles should fall down (gravity)
    final hasGravity = js.contains('writeRow') ||
        js.contains('fall') ||
        js.contains('gravity');

    // Empty cells should be refilled
    final hasRefill = js.contains('-1') || // empty cell marker
        js.contains('Math.random()'); // random new tiles

    if (!hasGravity && !hasRefill) {
      errors.add(
        '[Puzzle-Code] No cascade/refill logic — after matches are removed, '
        'tiles won\'t fall and new tiles won\'t appear. Game will have empty holes.',
      );
    }

    // Chain reactions: after cascade, check for new matches
    final hasChainCheck = js.contains('setTimeout') &&
        (js.contains('findMatches') || js.contains('processMatches'));
    if (!hasChainCheck) {
      warnings.add(
        '[Puzzle-Code] No chain-reaction check — cascading matches won\'t trigger '
        'automatically after tiles settle',
      );
    }
  }

  /// Verifies win/lose conditions are checked.
  static void _checkWinLoseDetection(
    String js,
    List<String> errors,
    List<String> warnings,
  ) {
    if (!js.contains('score >= targetScore') &&
        !js.contains('score>=targetScore')) {
      warnings.add(
        '[Puzzle-Code] No win condition check (score >= targetScore) — '
        'game may never end',
      );
    }

    if (!js.contains('movesLeft <= 0') && !js.contains('movesLeft==0')) {
      warnings.add(
        '[Puzzle-Code] No move-limit game-over check — player may get stuck '
        'with no moves remaining',
      );
    }

    // Initial grid should avoid starting matches
    if (js.contains('wouldMatch') || js.contains('would_match')) {
      // Good: the code tries to avoid initial matches
    } else {
      warnings.add(
        '[Puzzle-Code] No initial-match prevention — game may start with '
        'cascading matches before the player acts',
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
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
