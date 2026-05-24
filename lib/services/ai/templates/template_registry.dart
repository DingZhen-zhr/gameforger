import 'game_template.dart';
import 'platformer_template.dart';
import 'shooter_template.dart';
import 'puzzle_template.dart';
import 'runner_template.dart';

/// Maps genre strings (Chinese or English) to the best-matching [GameTemplate].
///
/// Matching is fuzzy: we scan the genre string for keywords in both languages,
/// scoring each template by keyword overlap. The highest-scoring template wins.
/// Ties are broken by preferring Platformer as the safest general-purpose fallback.
class TemplateRegistry {
  TemplateRegistry._();

  static final _templates = <GameTemplate>[
    PlatformerTemplate(),
    ShooterTemplate(),
    PuzzleTemplate(),
    RunnerTemplate(),
  ];

  static final _fallback = PlatformerTemplate();

  /// Per-template keyword lists for fuzzy matching.
  /// Keys are lowercase; matched case-insensitively against [genre].
  static final Map<GameTemplate, List<String>> _keywords = {
    _templates[0]: [
      'platformer', 'platform', 'jump', 'side-scroll', 'sidescroll',
      '平台跳跃', '横版跳跃', '跳跃', '平台', '横版', '动作', 'action',
      'platforming', 'mario', 'celeste', '闯关',
    ],
    _templates[1]: [
      'shooter', 'shoot', 'bullet', 'gun', '射击', '枪战', '子弹',
      '弹幕', 'danmaku', 'bullet hell', 'top-down', 'topdown',
      'space shooter', 'stg', 'shmup', '空战', '战机',
    ],
    _templates[2]: [
      'puzzle', 'match', 'match3', 'match-3', '三消', '消除',
      '解谜', '拼图', 'sliding', 'logic', 'grid', 'swap',
      '连连看', 'connect', 'memory', 'sudoku', '数独',
      'sokoban', '推箱子', 'merge', '合成', 'brain', '智力',
    ],
    _templates[3]: [
      'runner', 'endless', 'run', 'dodge', 'avoid',
      '跑酷', '酷跑', '无尽', '奔跑', '闪避', 'auto-scroll',
      'autoscroll', 'side-scrolling runner', '障碍', 'obstacle',
      'jetpack', 'temple run', 'subway surf',
    ],
  };

  /// Returns the best-matching [GameTemplate] for [genre].
  ///
  /// [genre] can be in Chinese, English, or mixed. Returns the template
  /// with the most keyword matches. Falls back to [PlatformerTemplate] if
  /// no keywords match (it's the safest general-purpose skeleton).
  static GameTemplate resolve(String? genre) {
    if (genre == null || genre.trim().isEmpty) return _fallback;

    final lower = genre.toLowerCase().trim();

    GameTemplate? best;
    int bestScore = 0;

    for (final template in _templates) {
      int score = 0;
      for (final kw in _keywords[template]!) {
        if (lower.contains(kw.toLowerCase())) {
          // Longer keyword matches get higher weight
          score += kw.length;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = template;
      }
    }

    if (best == null) return _fallback;

    // If score is very low, the genre might be creative/unusual. Still use
    // the best match because even a weak signal beats a generic platformer.
    return best;
  }

  /// Returns all registered templates for UI display.
  static List<GameTemplate> get all => List.unmodifiable(_templates);

  /// Returns the template at [index], or the fallback.
  static GameTemplate at(int index) {
    if (index >= 0 && index < _templates.length) return _templates[index];
    return _fallback;
  }

  /// Number of registered templates.
  static int get count => _templates.length;
}
