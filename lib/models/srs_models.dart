import 'package:cloud_firestore/cloud_firestore.dart';

enum MasteryLevel {
  newCard, // Level 0
  learning, // Level 1
  reviewing, // Level 2
  mastered, // Level 3
}

class SRSProgress {
  final String wordId;
  final int level; // 0 to 5 (Leitner boxes)
  final DateTime nextReview;
  final DateTime? lastReview;
  final DateTime? lastFailure;
  final int timesReviewed;
  final int consecutiveCorrect;
  final double easeFactor;

  const SRSProgress({
    required this.wordId,
    this.level = 0,
    required this.nextReview,
    this.lastReview,
    this.lastFailure,
    this.timesReviewed = 0,
    this.consecutiveCorrect = 0,
    this.easeFactor = 2.5,
  });

  MasteryLevel get mastery {
    if (level == 0) return MasteryLevel.newCard;
    if (level < 3) return MasteryLevel.learning;
    if (level < 5) return MasteryLevel.reviewing;
    return MasteryLevel.mastered;
  }

  factory SRSProgress.fromFirestore(Map<String, dynamic> data) {
    return SRSProgress(
      wordId: data['wordId'] ?? '',
      level: data['level'] ?? 0,
      nextReview: (data['nextReview'] as Timestamp).toDate(),
      lastReview: data['lastReview'] != null
          ? (data['lastReview'] as Timestamp).toDate()
          : null,
      lastFailure: data['lastFailure'] != null
          ? (data['lastFailure'] as Timestamp).toDate()
          : null,
      timesReviewed: data['timesReviewed'] ?? 0,
      consecutiveCorrect: data['consecutiveCorrect'] ?? 0,
      easeFactor: (data['easeFactor'] ?? 2.5).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'wordId': wordId,
      'level': level,
      'nextReview': Timestamp.fromDate(nextReview),
      'lastReview': lastReview != null ? Timestamp.fromDate(lastReview!) : null,
      'lastFailure': lastFailure != null
          ? Timestamp.fromDate(lastFailure!)
          : null,
      'timesReviewed': timesReviewed,
      'consecutiveCorrect': consecutiveCorrect,
      'easeFactor': easeFactor,
    };
  }

  SRSProgress copyWith({
    int? level,
    DateTime? nextReview,
    DateTime? lastReview,
    DateTime? lastFailure,
    int? timesReviewed,
    int? consecutiveCorrect,
    double? easeFactor,
  }) {
    return SRSProgress(
      wordId: wordId,
      level: level ?? this.level,
      nextReview: nextReview ?? this.nextReview,
      lastReview: lastReview ?? this.lastReview,
      lastFailure: lastFailure ?? this.lastFailure,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      easeFactor: easeFactor ?? this.easeFactor,
    );
  }
}



