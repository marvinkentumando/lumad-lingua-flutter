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



