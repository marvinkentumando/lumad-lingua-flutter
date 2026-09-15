// No imports needed currently

enum QuestType { xp, pronunciation, lesson, flashcard, duel }

class Quest {
  final String id;
  final String title;
  final String description;
  final int target;
  final int current;
  final int reward;
  final QuestType type;
  final bool isClaimed;
  final String? nextQuestId;
  final bool isDynamic;
  final Map<String, dynamic>? metadata;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.current = 0,
    required this.reward,
    required this.type,
    this.isClaimed = false,
    this.nextQuestId,
    this.isDynamic = false,
    this.metadata,
  });

  bool get isCompleted => current >= target;

  double get progress => (current / target).clamp(0.0, 1.0);

  Quest copyWith({
    int? current,
    bool? isClaimed,
    String? nextQuestId,
    bool? isDynamic,
    Map<String, dynamic>? metadata,
  }) {
    return Quest(
      id: id,
      title: title,
      description: description,
      target: target,
      current: current ?? this.current,
      reward: reward,
      type: type,
      isClaimed: isClaimed ?? this.isClaimed,
      nextQuestId: nextQuestId ?? this.nextQuestId,
      isDynamic: isDynamic ?? this.isDynamic,
      metadata: metadata ?? this.metadata,
    );
  }

  factory Quest.fromMap(Map<String, dynamic> map, String id) {
    return Quest(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      target: map['target'] ?? 1,
      current: map['current'] ?? 0,
      reward: map['reward'] ?? 10,
      type: QuestType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestType.xp,
      ),
      isClaimed: map['isClaimed'] ?? false,
      nextQuestId: map['nextQuestId'],
      isDynamic: map['isDynamic'] ?? false,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'target': target,
      'current': current,
      'reward': reward,
      'type': type.name,
      'isClaimed': isClaimed,
      'nextQuestId': nextQuestId,
      'isDynamic': isDynamic,
      'metadata': metadata,
    };
  }
}



