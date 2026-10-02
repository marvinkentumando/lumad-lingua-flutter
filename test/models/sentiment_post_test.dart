import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/models/sentiment_post.dart';

void main() {
  group('SentimentPost Model Unit Tests', () {
    test('creates SentimentPost from Firestore map correctly', () {
      final now = DateTime.now();
      final data = {
        'originalText': 'Madyaw na buntag kanatun tanan!',
        'filipinoTranslation': 'Magandang umaga sa ating lahat!',
        'englishTranslation': 'Good morning to us all!',
        'sentimentCategory': 'positive',
        'publishedAt': Timestamp.fromDate(now),
        'sourceUrl': 'https://facebook.com/123',
        'keywords': ['Madyaw', 'Buntag'],
        'linkedDictionaryEntryIds': ['dict1'],
        'sentimentScore': 0.85,
        'sparkCount': 5,
        'likedBy': ['u1', 'u2'],
      };

      final post = SentimentPost.fromFirestore(data, 'post123');

      expect(post.id, equals('post123'));
      expect(post.originalText, equals('Madyaw na buntag kanatun tanan!'));
      expect(post.filipinoTranslation, equals('Magandang umaga sa ating lahat!'));
      expect(post.englishTranslation, equals('Good morning to us all!'));
      expect(post.sentimentCategory, equals('positive'));
      expect(post.keywords, contains('Madyaw'));
      expect(post.linkedDictionaryEntryIds, contains('dict1'));
      expect(post.sentimentScore, equals(0.85));
      expect(post.sparkCount, equals(5));
    });

    test('normalizes category from numeric score correctly', () {
      final posPost = SentimentPost.fromFirestore({'sentimentScore': 0.6}, 'p1');
      final neuPost = SentimentPost.fromFirestore({'sentimentScore': 0.0}, 'p2');
      final negPost = SentimentPost.fromFirestore({'sentimentScore': -0.5}, 'p3');

      expect(posPost.sentimentCategory, equals('positive'));
      expect(neuPost.sentimentCategory, equals('neutral'));
      expect(negPost.sentimentCategory, equals('negative'));
    });

    test('serializes toFirestore Map correctly', () {
      final post = SentimentPost(
        id: 'p1',
        originalText: 'Salamat sa pagtudlo',
        sentimentCategory: 'positive',
        keywords: ['Salamat'],
      );

      final map = post.toFirestore();

      expect(map['originalText'], equals('Salamat sa pagtudlo'));
      expect(map['sentimentCategory'], equals('positive'));
      expect(map['keywords'], equals(['Salamat']));
    });
  });
}
