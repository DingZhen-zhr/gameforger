/// 9 维度 GameSpec — 思维链最终输出
class GameSpec {
  final String? theme;
  final String? genre;
  final String? artStyle;
  final String? cameraView;
  final String? coreMechanic;
  final String? playerAbility;
  final String? goal;
  final String? musicVibe;
  final String? difficulty;

  const GameSpec({
    this.theme,
    this.genre,
    this.artStyle,
    this.cameraView,
    this.coreMechanic,
    this.playerAbility,
    this.goal,
    this.musicVibe,
    this.difficulty,
  });

  bool get isComplete =>
      theme != null &&
      genre != null &&
      artStyle != null &&
      cameraView != null &&
      coreMechanic != null &&
      playerAbility != null &&
      goal != null &&
      musicVibe != null &&
      difficulty != null;

  String? getValue(String key) {
    switch (key) {
      case 'theme': return theme;
      case 'genre': return genre;
      case 'art_style': return artStyle;
      case 'camera_view': return cameraView;
      case 'core_mechanic': return coreMechanic;
      case 'player_ability': return playerAbility;
      case 'goal': return goal;
      case 'music_vibe': return musicVibe;
      case 'difficulty': return difficulty;
      default: return null;
    }
  }

  int get filledCount => [
        theme,
        genre,
        artStyle,
        cameraView,
        coreMechanic,
        playerAbility,
        goal,
        musicVibe,
        difficulty,
      ].where((e) => e != null).length;

  List<String> get missingDimensions {
    final result = <String>[];
    if (theme == null) result.add('主题/故事背景');
    if (genre == null) result.add('玩法类型');
    if (artStyle == null) result.add('美术风格');
    if (cameraView == null) result.add('视角');
    if (coreMechanic == null) result.add('核心机制');
    if (playerAbility == null) result.add('玩家能力');
    if (goal == null) result.add('目标');
    if (musicVibe == null) result.add('音乐氛围');
    if (difficulty == null) result.add('难度');
    return result;
  }

  factory GameSpec.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GameSpec();
    return GameSpec(
      theme: json['theme'] as String?,
      genre: json['genre'] as String?,
      artStyle: json['art_style'] as String?,
      cameraView: json['camera_view'] as String?,
      coreMechanic: json['core_mechanic'] as String?,
      playerAbility: json['player_ability'] as String?,
      goal: json['goal'] as String?,
      musicVibe: json['music_vibe'] as String?,
      difficulty: json['difficulty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (theme != null) 'theme': theme,
      if (genre != null) 'genre': genre,
      if (artStyle != null) 'art_style': artStyle,
      if (cameraView != null) 'camera_view': cameraView,
      if (coreMechanic != null) 'core_mechanic': coreMechanic,
      if (playerAbility != null) 'player_ability': playerAbility,
      if (goal != null) 'goal': goal,
      if (musicVibe != null) 'music_vibe': musicVibe,
      if (difficulty != null) 'difficulty': difficulty,
    };
  }

  GameSpec copyWith({
    String? theme,
    String? genre,
    String? artStyle,
    String? cameraView,
    String? coreMechanic,
    String? playerAbility,
    String? goal,
    String? musicVibe,
    String? difficulty,
  }) {
    return GameSpec(
      theme: theme ?? this.theme,
      genre: genre ?? this.genre,
      artStyle: artStyle ?? this.artStyle,
      cameraView: cameraView ?? this.cameraView,
      coreMechanic: coreMechanic ?? this.coreMechanic,
      playerAbility: playerAbility ?? this.playerAbility,
      goal: goal ?? this.goal,
      musicVibe: musicVibe ?? this.musicVibe,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
