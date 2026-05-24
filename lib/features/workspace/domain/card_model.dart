enum CardType {
  story,
  art,
  gameplay,
  asset,
  music,
  question,
  userNote;

  String get label {
    switch (this) {
      case CardType.story:
        return '故事';
      case CardType.art:
        return '美术';
      case CardType.gameplay:
        return '玩法';
      case CardType.asset:
        return '素材';
      case CardType.music:
        return '音乐';
      case CardType.question:
        return '提问';
      case CardType.userNote:
        return '笔记';
    }
  }

  String get apiValue {
    switch (this) {
      case CardType.story:
        return 'story';
      case CardType.art:
        return 'art';
      case CardType.gameplay:
        return 'gameplay';
      case CardType.asset:
        return 'asset';
      case CardType.music:
        return 'music';
      case CardType.question:
        return 'question';
      case CardType.userNote:
        return 'user_note';
    }
  }

  static CardType fromApi(String value) {
    switch (value) {
      case 'story':
        return CardType.story;
      case 'art':
        return CardType.art;
      case 'gameplay':
        return CardType.gameplay;
      case 'asset':
        return CardType.asset;
      case 'music':
        return CardType.music;
      case 'question':
        return CardType.question;
      case 'user_note':
        return CardType.userNote;
      default:
        return CardType.userNote;
    }
  }
}

class CardModel {
  final String id;
  final String projectId;
  final CardType type;
  final Map<String, dynamic> content;
  final String? parentId;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CardModel({
    required this.id,
    required this.projectId,
    required this.type,
    this.content = const {},
    this.parentId,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      type: CardType.fromApi(json['type'] as String),
      content: Map<String, dynamic>.from(json['content'] as Map),
      parentId: json['parent_id'] as String?,
      orderIndex: (json['order_index'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'type': type.apiValue,
      'content': content,
      'parent_id': parentId,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CardModel copyWith({
    String? id,
    String? projectId,
    CardType? type,
    Map<String, dynamic>? content,
    String? parentId,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CardModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
