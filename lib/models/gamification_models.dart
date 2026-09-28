class ShopItem {
  final String id;
  final String title;
  final String description;
  final int price;
  final String icon;
  final String type; // 'streak_freeze', 'xp_boost', etc.
  final bool isAvailable;

  ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.type,
    this.isAvailable = true,
  });

  factory ShopItem.fromFirestore(Map<String, dynamic> data, String id) {
    return ShopItem(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      icon: data['icon'] ?? '💰',
      type: data['type'] ?? 'misc',
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'icon': icon,
      'type': type,
      'isAvailable': isAvailable,
    };
  }
}
