/// Structured game design document produced by Pass 1 of generation.
/// This is fed into Pass 2 as a precise blueprint for code generation.
class GameDesignDocument {
  final String title;
  final String genre;
  final String coreLoop;
  final List<GameObject> objects;
  final PhysicsParams physics;
  final CollisionRules collision;
  final ScoringSystem scoring;
  final StateMachine states;
  final List<LevelDesign> levels;
  final VisualStyle visual;
  final String audioHints;

  const GameDesignDocument({
    required this.title,
    required this.genre,
    required this.coreLoop,
    required this.objects,
    required this.physics,
    required this.collision,
    required this.scoring,
    required this.states,
    required this.levels,
    required this.visual,
    required this.audioHints,
  });

  factory GameDesignDocument.fromJson(Map<String, dynamic> json) {
    return GameDesignDocument(
      title: json['title'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      coreLoop: json['coreLoop'] as String? ?? '',
      objects: (json['objects'] as List<dynamic>?)
              ?.map((e) => GameObject.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      physics: PhysicsParams.fromJson(
          json['physics'] as Map<String, dynamic>? ?? {}),
      collision: CollisionRules.fromJson(
          json['collision'] as Map<String, dynamic>? ?? {}),
      scoring: ScoringSystem.fromJson(
          json['scoring'] as Map<String, dynamic>? ?? {}),
      states: StateMachine.fromJson(
          json['states'] as Map<String, dynamic>? ?? {}),
      levels: (json['levels'] as List<dynamic>?)
              ?.map((e) => LevelDesign.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      visual: VisualStyle.fromJson(
          json['visual'] as Map<String, dynamic>? ?? {}),
      audioHints: json['audioHints'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'genre': genre,
        'coreLoop': coreLoop,
        'objects': objects.map((o) => o.toJson()).toList(),
        'physics': physics.toJson(),
        'collision': collision.toJson(),
        'scoring': scoring.toJson(),
        'states': states.toJson(),
        'levels': levels.map((l) => l.toJson()).toList(),
        'visual': visual.toJson(),
        'audioHints': audioHints,
      };

  DesignValidation validate() {
    final issues = <String>[];
    if (title.isEmpty) issues.add('Missing game title');
    if (coreLoop.isEmpty) issues.add('Missing core gameplay loop');
    if (objects.isEmpty) issues.add('No game objects defined');
    if (objects.every((o) => o.type != 'player')) {
      issues.add('No player object defined');
    }
    if (levels.isEmpty) issues.add('No levels defined');
    if (states.states.isEmpty) issues.add('No game states defined');
    return DesignValidation(issues);
  }
}

class GameObject {
  final String name;
  final String type;
  final Map<String, double> properties;
  final List<String> behaviors;
  final String visual;

  const GameObject({
    required this.name,
    required this.type,
    this.properties = const {},
    this.behaviors = const [],
    this.visual = '',
  });

  factory GameObject.fromJson(Map<String, dynamic> json) => GameObject(
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        properties: (json['properties'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            {},
        behaviors: (json['behaviors'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        visual: json['visual'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'properties': properties,
        'behaviors': behaviors,
        'visual': visual,
      };
}

class PhysicsParams {
  final double gravity;
  final double friction;
  final double jumpForce;
  final double moveSpeed;

  const PhysicsParams({
    this.gravity = 0.5,
    this.friction = 0.8,
    this.jumpForce = 12,
    this.moveSpeed = 4,
  });

  factory PhysicsParams.fromJson(Map<String, dynamic> json) => PhysicsParams(
        gravity: (json['gravity'] as num?)?.toDouble() ?? 0.5,
        friction: (json['friction'] as num?)?.toDouble() ?? 0.8,
        jumpForce: (json['jumpForce'] as num?)?.toDouble() ?? 12,
        moveSpeed: (json['moveSpeed'] as num?)?.toDouble() ?? 4,
      );

  Map<String, dynamic> toJson() => {
        'gravity': gravity,
        'friction': friction,
        'jumpForce': jumpForce,
        'moveSpeed': moveSpeed,
      };
}

class CollisionRules {
  final String platforms;
  final String enemies;
  final String collectibles;

  const CollisionRules({
    this.platforms = 'solid top',
    this.enemies = 'damage player',
    this.collectibles = 'destroy on contact',
  });

  factory CollisionRules.fromJson(Map<String, dynamic> json) => CollisionRules(
        platforms: json['platforms'] as String? ?? 'solid top',
        enemies: json['enemies'] as String? ?? 'damage player',
        collectibles: json['collectibles'] as String? ?? 'destroy on contact',
      );

  Map<String, dynamic> toJson() => {
        'platforms': platforms,
        'enemies': enemies,
        'collectibles': collectibles,
      };
}

class ScoringSystem {
  final int pointsPerCollectible;
  final String winCondition;
  final String loseCondition;

  const ScoringSystem({
    this.pointsPerCollectible = 10,
    this.winCondition = 'collect all items',
    this.loseCondition = 'fall off screen',
  });

  factory ScoringSystem.fromJson(Map<String, dynamic> json) => ScoringSystem(
        pointsPerCollectible: (json['pointsPerCollectible'] as num?)?.toInt() ?? 10,
        winCondition: json['winCondition'] as String? ?? 'collect all items',
        loseCondition: json['loseCondition'] as String? ?? 'fall off screen',
      );

  Map<String, dynamic> toJson() => {
        'pointsPerCollectible': pointsPerCollectible,
        'winCondition': winCondition,
        'loseCondition': loseCondition,
      };
}

class StateMachine {
  final List<String> states;

  const StateMachine({this.states = const ['playing', 'gameOver', 'win']});

  factory StateMachine.fromJson(Map<String, dynamic> json) => StateMachine(
        states: (json['states'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            ['playing', 'gameOver', 'win'],
      );

  Map<String, dynamic> toJson() => {'states': states};
}

class LevelDesign {
  final List<Map<String, double>> platforms;
  final List<Map<String, dynamic>> enemies;
  final List<Map<String, dynamic>> collectibles;
  final Map<String, double> spawnPoint;

  const LevelDesign({
    this.platforms = const [],
    this.enemies = const [],
    this.collectibles = const [],
    this.spawnPoint = const {'x': 50, 'y': 300},
  });

  factory LevelDesign.fromJson(Map<String, dynamic> json) => LevelDesign(
        platforms: (json['platforms'] as List<dynamic>?)
                ?.map((e) => (e as Map<String, dynamic>).map(
                    (k, v) => MapEntry(k, (v as num).toDouble())))
                .toList() ??
            [],
        enemies: (json['enemies'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        collectibles: (json['collectibles'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        spawnPoint: (json['spawnPoint'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            {'x': 50, 'y': 300},
      );

  Map<String, dynamic> toJson() => {
        'platforms': platforms,
        'enemies': enemies,
        'collectibles': collectibles,
        'spawnPoint': spawnPoint,
      };
}

class VisualStyle {
  final String background;
  final String colorPalette;
  final String playerAppearance;
  final String effects;

  const VisualStyle({
    this.background = 'gradient starfield',
    this.colorPalette = 'dark blue/purple/gold',
    this.playerAppearance = '',
    this.effects = 'particles, glow',
  });

  factory VisualStyle.fromJson(Map<String, dynamic> json) => VisualStyle(
        background: json['background'] as String? ?? 'gradient starfield',
        colorPalette: json['colorPalette'] as String? ?? '',
        playerAppearance: json['playerAppearance'] as String? ?? '',
        effects: json['effects'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'background': background,
        'colorPalette': colorPalette,
        'playerAppearance': playerAppearance,
        'effects': effects,
      };
}

class DesignValidation {
  final List<String> issues;
  bool get isValid => issues.isEmpty;
  const DesignValidation(this.issues);
}
