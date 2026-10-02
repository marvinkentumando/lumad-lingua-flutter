import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a validated community post with sentiment analysis classification data.
class SentimentPost {
  final String id;
  final String originalText;
  final String filipinoTranslation;
  final String englishTranslation;
  final String sentimentCategory; // 'positive', 'neutral', 'negative'
  final DateTime? publishedAt;
  final String? sourceUrl;
  final List<String> keywords;
  final List<String> linkedDictionaryEntryIds;
  final double? sentimentScore;
  final int sparkCount;
  final List<String> likedBy;

  const SentimentPost({
    required this.id,
    required this.originalText,
    this.filipinoTranslation = '',
    this.englishTranslation = '',
    required this.sentimentCategory,
    this.publishedAt,
    this.sourceUrl,
    this.keywords = const [],
    this.linkedDictionaryEntryIds = const [],
    this.sentimentScore,
    this.sparkCount = 0,
    this.likedBy = const [],
  });

  factory SentimentPost.fromFirestore(Map<String, dynamic> data, String id) {
    return SentimentPost(
      id: id,
      originalText: data['originalText'] ?? data['postText'] ?? '',
      filipinoTranslation: data['filipinoTranslation'] ?? '',
      englishTranslation: data['englishTranslation'] ?? '',
      sentimentCategory: _normalizeCategory(data['sentimentCategory'] ?? data['sentimentScore']),
      publishedAt: _parseTimestamp(data['publishedAt'] ?? data['timestamp']),
      sourceUrl: data['sourceUrl'],
      keywords: List<String>.from(data['keywords'] ?? data['detectedKeywords'] ?? []),
      linkedDictionaryEntryIds: List<String>.from(data['linkedDictionaryEntryIds'] ?? []),
      sentimentScore: (data['sentimentScore'] as num?)?.toDouble(),
      sparkCount: data['sparkCount'] ?? data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'originalText': originalText,
      'filipinoTranslation': filipinoTranslation,
      'englishTranslation': englishTranslation,
      'sentimentCategory': sentimentCategory,
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      'keywords': keywords,
      'linkedDictionaryEntryIds': linkedDictionaryEntryIds,
      if (sentimentScore != null) 'sentimentScore': sentimentScore,
      'sparkCount': sparkCount,
      'likedBy': likedBy,
    };
  }

  String get relativeTime {
    if (publishedAt == null) return 'recently';
    final diff = DateTime.now().difference(publishedAt!);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  static String _normalizeCategory(dynamic input) {
    if (input is String) {
      final lower = input.toLowerCase().trim();
      if (lower == 'positive' || lower == 'pos') return 'positive';
      if (lower == 'negative' || lower == 'neg') return 'negative';
      return 'neutral';
    }
    if (input is num) {
      final score = input.toDouble();
      if (score > 0.15) return 'positive';
      if (score < -0.15) return 'negative';
      return 'neutral';
    }
    return 'neutral';
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
