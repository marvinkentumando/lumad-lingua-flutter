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

  /// Redacts personal names from input text for privacy protection.
  static String redactPersonalNames(String text) {
    if (text.isEmpty) return text;
    String result = text;

    // Known personal names in community posts dataset & mentions
    final knownNames = [
      'Carla Bantasan Cemine',
      'Carla Bantasan',
      'Mario Manaytay Yesan Bantasan',
      'Mario Manaytay',
      'Yesan Bantasan',
      'Danilo Jamorie A. Manlinab',
      'Danilo Jamorie Manlinab',
      'Danilo Manlinab',
      'Jupiter Comania',
      'Cesar Clarion Colina Sr.',
      'Cesar Clarion Colina',
      'Cesar Colina',
      'Tata Albarico',
      'Maricar Zamora Mabanglo',
      'Maricar Zamora',
      'CEPRIANO MAGLINAB',
      'Cepriano Maglinab',
      'Grace Marundan Ilio',
      'Grace Marundan',
      'Larry Bunyogan Sr.',
      'Larry Bunyogan',
      'Bhe-bhe Masunggari Escarlan',
      'Bhe-bhe Escarlan',
      'Bhe-bhe Masunggari',
      'Wiser Jade',
      'Saturnino Hidlay',
      'Ruben Capantoc Comania Jr.',
      'Ruben Comania Jr.',
      'Ruben Comania',
      'Julimar Mante',
      'Lito Bangkiling',
      'Liniel Calibadan',
      'liniel calibadan',
      'Noelita (nday) camana maglimolo',
      'Noelita Camana Maglimolo',
      'Noelita Camana',
      'Noelita Maglimolo',
      'Feliciana sa dalagapa',
      'Feliciana Liganso',
      'Feliciana',
      'Pablo Ampilan',
      'Alopio',
      'Londong Casa Manumbilang',
      'Tiumoh Yu Dakaw',
      'Su Re',
      'Nerio Camana',
      'Kikido EgDaasan',
      'Mang Edo Cabiza',
      'Edo Cabiza',
      'jems maniquez',
      'Jems Maniquez',
      'Romeo Tadian',
    ];

    for (final name in knownNames) {
      final pattern = RegExp(RegExp.escape(name), caseSensitive: false);
      result = result.replaceAll(pattern, '[Redacted Name]');
    }

    // Pattern: Honorific / Title + Name
    final honorificPattern = RegExp(
      r"\b(Sir|Ma'am|Mr|Mrs|Ms|Dr|Hon|IPMR|Capt|Mayor|Cong|Mtkdg|Mktdg|Gbbyn|Gibubayan|Chairman)\.?\s+([A-Z][a-zA-Z\-]+(?:\s+[A-Z][a-zA-Z\-]+|\s+[A-Z]\.){1,4}(?:\s+(?:Sr|Jr|III|II|IV)\.?)?)",
      caseSensitive: false,
    );
    result = result.replaceAllMapped(honorificPattern, (match) {
      final honorific = match.group(1);
      return '$honorific [Redacted Name]';
    });

    // Pattern: Mention prefixes "c <Name>", "si <Name>", "kay <Name>", "kang <Name>"
    final cSiMentionPattern = RegExp(
      r'\b(c|si|kay|kang)\s+([A-Za-z\-]+(?:\s+[A-Za-z\-]+){1,3})\b',
      caseSensitive: false,
    );
    result = result.replaceAllMapped(cSiMentionPattern, (match) {
      final prefix = match.group(1);
      final nameCandidate = match.group(2)!;
      final lower = nameCandidate.toLowerCase();
      if (lower == 'ina' ||
          lower == 'ama' ||
          lower == 'bapa' ||
          lower == 'magbabaya' ||
          lower == 'dios' ||
          lower == 'god' ||
          lower.startsWith('mga') ||
          lower == 'tribu') {
        return match.group(0)!;
      }
      return '$prefix [Redacted Name]';
    });

    // Clean up duplicate or contiguous [Redacted Name] tokens
    result = result.replaceAll(RegExp(r'(\[Redacted Name\]\s*)+'), '[Redacted Name]');

    return result;
  }

  /// Returns a copy of originalText with personal names redacted.
  String get redactedOriginalText => redactPersonalNames(originalText);

  /// Returns a copy of filipinoTranslation with personal names redacted.
  String get redactedFilipinoTranslation => redactPersonalNames(filipinoTranslation);

  /// Returns a copy of englishTranslation with personal names redacted.
  String get redactedEnglishTranslation => redactPersonalNames(englishTranslation);

  /// Returns keywords with personal names redacted or filtered out.
  List<String> get redactedKeywords {
    final nameKeywords = {
      'carla', 'bantasan', 'cemine', 'liniel', 'calibadan', 'noelita', 'camana', 'maglimolo',
      'feliciana', 'pablo', 'ambahan', 'alopio', 'danilo', 'manlinab', 'jupiter',
      'comania', 'cesar', 'colina', 'maricar', 'mabanglo', 'cepriano', 'grace',
      'larry', 'bunyogan', 'escarlan', 'ruben', 'julimar', 'mante', 'bangkiling',
      'nerio', 'kikido', 'egdaasan', 'edo', 'cabiza', 'jems', 'maniquez', 'tadian',
      'mario', 'manaytay', 'yesan',
    };
    return keywords.where((k) {
      final cleaned = k.toLowerCase().replaceAll(RegExp(r'\W'), '');
      return !nameKeywords.contains(cleaned);
    }).toList();
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
