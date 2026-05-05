import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single activity event in the community feed.
class CommunityActivity {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String
  type; // 'lesson_completed', 'streak', 'contribution', 'validation', 'achievement'
  final String message;
  final String emoji;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy;
  final DateTime? createdAt;

  const CommunityActivity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.message,
    required this.emoji,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedBy = const [],
    this.createdAt,
  });

  factory CommunityActivity.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return CommunityActivity(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'],
      type: data['type'] ?? 'achievement',
      message: data['message'] ?? '',
      emoji: data['emoji'] ?? '🌿',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      if (userPhotoUrl != null) 'userPhotoUrl': userPhotoUrl,
      'type': type,
      'message': message,
      'emoji': emoji,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedBy': likedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a human-readable relative time string.
  String get relativeTime {
    if (createdAt == null) return 'just now';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
