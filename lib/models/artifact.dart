import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'artifact.g.dart';

@HiveType(typeId: 6)
enum ArtifactTier {
  @HiveField(0)
  common,
  @HiveField(1)
  rare,
  @HiveField(2)
  epic,
  @HiveField(3)
  legendary,
  @HiveField(4)
  sacred,
  @HiveField(5)
  ancient
}

@HiveType(typeId: 7)
enum ArtifactRequirementType {
  @HiveField(0)
  xp,
  @HiveField(1)
  lessons,
  @HiveField(2)
  words,
  @HiveField(3)
  streak,
  @HiveField(4)
  mistCrystals,
}

@HiveType(typeId: 8)
class Artifact {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String emoji;
  @HiveField(4)
  final String imageUrl;
  @HiveField(5)
  final String type;
  @HiveField(6)
  final String? culturalNote;
  @HiveField(7)
  final ArtifactTier tier;
  @HiveField(8)
  final int rarity; // 1-100, used for weighted drops
  @HiveField(9)
  final ArtifactRequirementType requirementType;
  @HiveField(10)
  final int currentProgress;
  @HiveField(11)
  final int targetValue;
  @HiveField(12)
  final bool isEarned;
  @HiveField(13)
  final int crystalCost;
  @HiveField(14)
  final String? passiveBonus;
  @HiveField(15)
  final bool isAvailableInShop;
  @HiveField(16)
  final DateTime? earnedAt;
  @HiveField(17)
  final String? legend;

  Artifact({
    required this.id,
    required this.title,
    required this.description,
    this.emoji = '📜',
    this.imageUrl = '',
    this.type = 'artifact',
    this.culturalNote,
    this.tier = ArtifactTier.common,
    this.rarity = 50,
    this.requirementType = ArtifactRequirementType.xp,
    this.currentProgress = 0,
    this.targetValue = 100,
    this.isEarned = false,
    this.crystalCost = 0,
    this.passiveBonus,
    this.isAvailableInShop = false,
    this.earnedAt,
    this.legend,
  });

  factory Artifact.fromFirestore(Map<String, dynamic> data, String id) {
    ArtifactTier mappedTier = ArtifactTier.common;
    final tierStr = (data['tier'] ?? 'common').toString().toLowerCase();
    for (var value in ArtifactTier.values) {
      if (value.name.toLowerCase() == tierStr) {
        mappedTier = value;
        break;
      }
    }

    ArtifactRequirementType mappedReq = ArtifactRequirementType.xp;
    final reqStr = (data['requirementType'] ?? 'xp').toString().toLowerCase();
    for (var value in ArtifactRequirementType.values) {
      if (value.name.toLowerCase() == reqStr) {
        mappedReq = value;
        break;
      }
    }

    return Artifact(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '📜',
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? 'artifact',
      culturalNote: data['culturalNote'],
      tier: mappedTier,
      rarity: data['rarity'] ?? 50,
      requirementType: mappedReq,
      currentProgress: data['currentProgress'] ?? 0,
      targetValue: data['targetValue'] ?? 100,
      isEarned: data['isEarned'] ?? false,
      crystalCost: data['crystalCost'] ?? 0,
      passiveBonus: data['passiveBonus'],
      isAvailableInShop: data['isAvailableInShop'] ?? false,
      earnedAt: data['earnedAt'] != null
          ? (data['earnedAt'] as Timestamp).toDate()
          : null,
      legend: data['legend'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'emoji': emoji,
      'imageUrl': imageUrl,
      'type': type,
      'culturalNote': culturalNote,
      'tier': tier.name,
      'rarity': rarity,
      'requirementType': requirementType.name,
      'currentProgress': currentProgress,
      'targetValue': targetValue,
      'isEarned': isEarned,
      'crystalCost': crystalCost,
      'passiveBonus': passiveBonus,
      'isAvailableInShop': isAvailableInShop,
      'earnedAt': earnedAt != null ? Timestamp.fromDate(earnedAt!) : null,
      'legend': legend,
    };
  }

  Artifact copyWith({
    int? currentProgress,
    bool? isEarned,
    DateTime? earnedAt,
  }) {
    return Artifact(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      imageUrl: imageUrl,
      type: type,
      culturalNote: culturalNote,
      tier: tier,
      rarity: rarity,
      requirementType: requirementType,
      currentProgress: currentProgress ?? this.currentProgress,
      targetValue: targetValue,
      isEarned: isEarned ?? this.isEarned,
      crystalCost: crystalCost,
      passiveBonus: passiveBonus,
      isAvailableInShop: isAvailableInShop,
      earnedAt: earnedAt ?? this.earnedAt,
      legend: legend,
    );
  }

  double get progress =>
      (currentProgress / (targetValue > 0 ? targetValue : 1)).clamp(0.0, 1.0);
}



