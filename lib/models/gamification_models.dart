import 'package:cloud_firestore/cloud_firestore.dart';

class LearningSeason {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String badgeId;
  final String? description;
  final bool isActive;

  LearningSeason({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.badgeId,
    this.description,
    this.isActive = false,
  });

  factory LearningSeason.fromFirestore(Map<String, dynamic> data, String id) {
    return LearningSeason(
      id: id,
      title: data['title'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      badgeId: data['badgeId'] ?? '',
      description: data['description'],
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'badgeId': badgeId,
      'description': description,
      'isActive': isActive,
    };
  }
}

class ShopItem {
  final String id;
  final String title;
  final String description;
  final int price;
  final String icon;
  final String type; // 'streak_freeze', 'xp_boost', etc.

  ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.type,
  });

  factory ShopItem.fromFirestore(Map<String, dynamic> data, String id) {
    return ShopItem(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      icon: data['icon'] ?? '💰',
      type: data['type'] ?? 'misc',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'icon': icon,
      'type': type,
    };
  }
}
