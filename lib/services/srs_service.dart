import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MasteryLevel { newWord, learning, proficient, mastered }

class WordMastery {
  final String wordId;
  final MasteryLevel level;
  final double progress; // 0.0 to 1.0
  final DateTime lastReviewed;
  final DateTime nextReview;

  WordMastery({
    required this.wordId,
    required this.level,
    required this.progress,
    required this.lastReviewed,
    required this.nextReview,
  });
}

class SRSStats {
  final Map<MasteryLevel, int> counts;
  final double overallMastery;
  final List<double> weeklyProgress; // 7 days of master counts

  SRSStats({
    required this.counts,
    required this.overallMastery,
    required this.weeklyProgress,
  });
}

final srsServiceProvider = Provider((ref) => SRSService());

class SRSService {
  // In a real app, this would fetch from a 'user_mastery' collection in Firestore
  Future<SRSStats> getStats() async {
    return SRSStats(
      counts: {
        MasteryLevel.newWord: 45,
        MasteryLevel.learning: 28,
        MasteryLevel.proficient: 15,
        MasteryLevel.mastered: 12,
      },
      overallMastery: 0.35,
      weeklyProgress: [2, 3, 5, 5, 8, 10, 12],
    );
  }

  Future<void> recordAttempt(String wordId, bool correct) async {
    // Logic to update SRS intervals and Firestore would go here
    // In production, use a logger instead of print
  }
}

final srsStatsProvider = FutureProvider<SRSStats>((ref) {
  return ref.read(srsServiceProvider).getStats();
});


