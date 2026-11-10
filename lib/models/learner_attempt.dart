class LearnerAttempt {
  final String id;
  final String learnerId;
  final String phraseId;
  final String phraseTitle;
  final double bestScore;
  final int attemptCount;
  final DateTime lastAttemptedAt;

  const LearnerAttempt({
    required this.id,
    required this.learnerId,
    required this.phraseId,
    required this.phraseTitle,
    required this.bestScore,
    required this.attemptCount,
    required this.lastAttemptedAt,
  });

  factory LearnerAttempt.fromMap(Map<String, dynamic> map, String id) {
    return LearnerAttempt(
      id: id,
      learnerId: map['learner_id'] ?? map['learnerId'] ?? '',
      phraseId: map['phrase_id'] ?? map['phraseId'] ?? '',
      phraseTitle: map['phrase_title'] ?? map['phraseTitle'] ?? '',
      bestScore: (map['best_score'] ?? map['bestScore'] ?? 0.0 as num).toDouble(),
      attemptCount: (map['attempt_count'] ?? map['attemptCount'] ?? 1 as num).toInt(),
      lastAttemptedAt: map['last_attempted_at'] != null
          ? DateTime.tryParse(map['last_attempted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'learner_id': learnerId,
      'phrase_id': phraseId,
      'phrase_title': phraseTitle,
      'best_score': bestScore,
      'attempt_count': attemptCount,
      'last_attempted_at': lastAttemptedAt.toIso8601String(),
    };
  }
}
