import 'package:cloud_firestore/cloud_firestore.dart';

enum ArtifactTier { common, rare, sacred, epic, ancient, legendary }

class Artifact {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String imageUrl;
  final String type;
  final String? culturalNote;
  final ArtifactTier tier;
  final int rarity;
  final int currentProgress;
  final int targetValue;
  final bool isEarned;
  final int crystalCost;
  final String? passiveBonus;
  final bool isAvailableInShop;
  final DateTime? earnedAt;
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
    this.rarity = 1,
    this.currentProgress = 0,
    this.targetValue = 1,
    this.isEarned = false,
    this.crystalCost = 0,
    this.passiveBonus,
    this.isAvailableInShop = false,
    this.earnedAt,
    this.legend,
  });

  factory Artifact.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle tier mapping from string
    ArtifactTier mappedTier = ArtifactTier.common;
    final tierStr = (data['tier'] ?? 'common').toString().toLowerCase();
    for (var value in ArtifactTier.values) {
      if (value.name.toLowerCase() == tierStr) {
        mappedTier = value;
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
      rarity: data['rarity'] ?? 1,
      currentProgress: data['currentProgress'] ?? 0,
      targetValue: data['targetValue'] ?? 1,
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

  double get progress =>
      (currentProgress / (targetValue > 0 ? targetValue : 1)).clamp(0.0, 1.0);
}


