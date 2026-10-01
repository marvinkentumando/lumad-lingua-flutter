import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/models/community_comment.dart';

void main() {
  group('CommunityComment Model Unit Tests', () {
    test('creates CommunityComment from Firestore Map with all fields', () {
      final now = DateTime.now();
      final data = {
        'userId': 'user123',
        'userName': 'Tribe Elder',
        'userPhotoUrl': 'https://example.com/photo.png',
        'text': 'Madyaw na buntag!',
        'createdAt': Timestamp.fromDate(now),
      };

      final comment = CommunityComment.fromFirestore(data, 'comment123');

      expect(comment.id, equals('comment123'));
      expect(comment.userId, equals('user123'));
      expect(comment.userName, equals('Tribe Elder'));
      expect(comment.userPhotoUrl, equals('https://example.com/photo.png'));
      expect(comment.text, equals('Madyaw na buntag!'));
      expect(comment.createdAt, isNotNull);
    });

    test('handles missing or null Firestore fields gracefully', () {
      final data = <String, dynamic>{};

      final comment = CommunityComment.fromFirestore(data, 'comment456');

      expect(comment.id, equals('comment456'));
      expect(comment.userId, isEmpty);
      expect(comment.userName, equals('Anonymous'));
      expect(comment.userPhotoUrl, isNull);
      expect(comment.text, isEmpty);
      expect(comment.createdAt, isNull);
    });

    test('formats relativeTime correctly', () {
      final commentNow = CommunityComment(
        id: '1',
        userId: 'u1',
        userName: 'User',
        text: 'Hello',
        createdAt: DateTime.now(),
      );

      final comment10m = CommunityComment(
        id: '2',
        userId: 'u1',
        userName: 'User',
        text: 'Hello',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final comment2h = CommunityComment(
        id: '3',
        userId: 'u1',
        userName: 'User',
        text: 'Hello',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final commentNull = CommunityComment(
        id: '4',
        userId: 'u1',
        userName: 'User',
        text: 'Hello',
        createdAt: null,
      );

      expect(commentNow.relativeTime, equals('just now'));
      expect(comment10m.relativeTime, equals('10m ago'));
      expect(comment2h.relativeTime, equals('2h ago'));
      expect(commentNull.relativeTime, equals('just now'));
    });

    test('serializes toFirestore Map correctly', () {
      final comment = CommunityComment(
        id: '1',
        userId: 'u1',
        userName: 'User',
        userPhotoUrl: 'https://photo.jpg',
        text: 'Great post!',
      );

      final map = comment.toFirestore();

      expect(map['userId'], equals('u1'));
      expect(map['userName'], equals('User'));
      expect(map['userPhotoUrl'], equals('https://photo.jpg'));
      expect(map['text'], equals('Great post!'));
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
