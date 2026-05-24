/// Client-side depth evaluation for user answers in the Socratic dialogue.
///
/// The AI performs the primary depth evaluation (returned in the JSON response).
/// This engine provides fallback heuristics when the AI fails to return a score,
/// and defines the scoring rubric shared between client and AI prompt.
class SocraticEngine {
  SocraticEngine._();

  // ─── Depth Scoring (1-5) ──────────────────────────────────────────

  /// Evaluates the depth of a user's answer heuristically.
  /// Returns 1-5, where:
  ///   1 — Vague / generic ("make a fun game", "I don't know")
  ///   2 — Has direction but no detail ("a platformer", "something sci-fi")
  ///   3 — Specific mechanics described ("2D platformer, collect coins, 3 lives")
  ///   4 — Clear mechanics with concrete references ("like Celeste dash + wall climb")
  ///   5 — Complete vision with emotional core ("I want players to feel the rush of...")
  static int scoreDepth(String answer, String dimensionLabel) {
    if (answer.isEmpty) return 1;

    final text = answer.trim();
    final len = text.length;

    // Level 1: Very short, non-committal, or just repeating the question
    if (len < 8) return 1;
    if (_isVague(text)) return 1;

    // Level 5: Emotional core language + substantial detail
    if (_hasEmotionalCore(text) && len > 80) return 5;

    // Level 4: Specific references to games/mechanics + substantial detail
    if (_hasConcreteReference(text) && len > 50) return 4;

    // Level 3: Specific enough (mentions concrete elements, has reasonable length)
    if (_hasSpecifics(text) && len > 20) return 3;

    // Level 2: Has some direction but lacks detail
    if (len > 10) return 2;

    return 1;
  }

  /// Rule: proceed to the next dimension only when depth >= 3.
  static bool shouldProceed(int depthScore) => depthScore >= 3;

  /// Maximum follow-up rounds on a single dimension before forced advance.
  static const maxRoundsPerDimension = 5;

  /// Total conversation rounds that trigger a generation suggestion.
  static const suggestGenerationAfterRounds = 30;

  // ─── Dimension & Round Tracking ────────────────────────────────────

  /// Returns a follow-up question prompt tailored to why the answer was shallow.
  static String buildFollowUpHint(String dimensionLabel, int depthScore) {
    switch (depthScore) {
      case 1:
        return '用户对「$dimensionLabel」的回答非常模糊。请用更具体、更简单的问题引导，'
            '给 2-3 个具体的例子让用户选择，降低思考门槛。';
      case 2:
        return '用户对「$dimensionLabel」有了大致方向但缺乏细节。'
            '请追问具体机制/风格/感受，用游戏案例帮助用户具象化想法。';
      default:
        return '';
    }
  }

  /// Returns the dimension label for a given key.
  static String labelForKey(String key) {
    switch (key) {
      case 'genre': return '玩法类型';
      case 'theme': return '主题/故事背景';
      case 'art_style': return '美术风格';
      case 'camera_view': return '视角';
      case 'core_mechanic': return '核心机制';
      case 'player_ability': return '玩家能力';
      case 'goal': return '目标';
      case 'music_vibe': return '音乐氛围';
      case 'difficulty': return '难度';
      default: return key;
    }
  }

  // ─── Heuristic Helpers ─────────────────────────────────────────────

  static bool _isVague(String text) {
    final vague = [
      '不知道', '不确定', '随便', '都行', '无所谓', '你决定',
      '不知道啊', '没想好', '都可以', '看着办',
      'idk', 'not sure', 'whatever', 'anything',
      '好玩', '有趣', 'fun', 'cool',
    ];
    final lower = text.toLowerCase();
    // Only flag as vague if it's short AND contains only vague words
    if (text.length > 30) return false;
    for (final v in vague) {
      if (lower == v) return true;
    }
    // Check if it's just "make it [adjective]" with no substance
    if (RegExp(r'^(make|做).{0,10}(fun|cool|好|棒|厉害)').hasMatch(lower) &&
        text.length < 25) {
      return true;
    }
    return false;
  }

  static bool _hasSpecifics(String text) {
    // Mentions concrete numbers, specific mechanics, or detailed descriptions
    final specifics = [
      '跳', '射击', '收集', '建造', '解谜', '跑', '飞',
      '像素', '3d', '2d', '横版', '俯视', '第一人称',
      'jump', 'shoot', 'collect', 'build', 'puzzle', 'run',
      'platform', 'rpg', 'fps', '像素', '卡通', '写实',
      RegExp(r'\d+'), // contains numbers (lives, levels, etc.)
    ];
    for (final s in specifics) {
      if (s is RegExp) {
        if (s.hasMatch(text)) return true;
      } else if (s is String) {
        if (text.toLowerCase().contains(s.toLowerCase())) return true;
      }
    }
    return text.length > 40; // longer text likely has more substance
  }

  static bool _hasConcreteReference(String text) {
    // References specific games, game mechanics, or design patterns
    final refs = [
      'celeste', 'mario', 'zelda', 'hollow knight', 'dead cells',
      '马里奥', '塞尔达', '黑魂', '空洞骑士', '死亡细胞',
      '星露谷', '我的世界', 'minecraft', 'stardew', 'terraria',
      '东方', 'touhou', 'enter the gungeon', 'hades',
      '像...一样', '类似', '参考', '比如', '例如',
      'like', 'similar to', 'inspired by', 'for example',
    ];
    final lower = text.toLowerCase();
    for (final ref in refs) {
      if (lower.contains(ref.toLowerCase())) return true;
    }
    return false;
  }

  static bool _hasEmotionalCore(String text) {
    final emotional = [
      '感觉', '感受', '体验', '沉浸', '紧张', '兴奋', '成就',
      '自由', '探索', '惊喜', '满足', '放松', '刺激', '压迫',
      'feel', 'sense', 'experience', 'immerse', 'tension',
      'excitement', 'achievement', 'freedom', 'wonder', 'flow',
      '我希望玩家', '想让玩家', 'i want players',
      '核心体验', 'core experience', 'emotional',
    ];
    final lower = text.toLowerCase();
    var hits = 0;
    for (final e in emotional) {
      if (lower.contains(e.toLowerCase())) hits++;
    }
    return hits >= 2;
  }
}
