class HeritageArtifact {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String type;
  final String? culturalNote;
  final String tier;
  final int rarity;

  const HeritageArtifact({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.type,
    this.culturalNote,
    this.tier = 'Common',
    this.rarity = 1,
  });

  factory HeritageArtifact.fromFirestore(Map<String, dynamic> data, String id) {
    return HeritageArtifact(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? 'artifact',
      culturalNote: data['culturalNote'],
      tier: data['tier'] ?? 'Common',
      rarity: data['rarity'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'type': type,
      'culturalNote': culturalNote,
      'tier': tier,
      'rarity': rarity,
    };
  }
}

class GalleryBadge {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String colorHex;
  final bool isEarned;
  final int currentCount;
  final int tier; // 1, 2, or 3

  const GalleryBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorHex,
    this.isEarned = false,
    this.currentCount = 0,
    this.tier = 1,
  });

  GalleryBadge copyWith({bool? isEarned, int? currentCount, int? tier}) {
    return GalleryBadge(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      colorHex: colorHex,
      isEarned: isEarned ?? this.isEarned,
      currentCount: currentCount ?? this.currentCount,
      tier: tier ?? this.tier,
    );
  }

  factory GalleryBadge.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    bool isEarned = false,
  }) {
    return GalleryBadge(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'help_outline',
      colorHex: data['colorHex'] ?? '#FFD700',
      isEarned: isEarned,
      currentCount: data['currentCount'] ?? 0,
      tier: data['tier'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }
}



