import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_service.dart';
import '../models/srs_models.dart';
import 'auth_service.dart';
import 'package:rxdart/rxdart.dart';

enum MasteryLevel { newWord, learning, proficient, mastered }

class SRSStats {
  final Map<MasteryLevel, int> counts;
  final double overallMastery;
  final List<double> weeklyProgress;

  SRSStats({
    required this.counts,
    required this.overallMastery,
    required this.weeklyProgress,
  });
}

final srsServiceProvider = Provider((ref) => SRSService(ref));

class SRSService {
  final Ref ref;
  SRSService(this.ref);

  Stream<SRSStats> getStatsStream(String userId) {
    final srsStream = ref.read(firebaseServiceProvider).db
        .collection('users')
        .doc(userId)
        .collection('srs_progress')
        .snapshots();

    final historyStream = ref.read(firebaseServiceProvider).getMasteryHistoryStream(userId);

    return Rx.combineLatest2(srsStream, historyStream, (srsSnap, history) {
      final List<SRSProgress> progressList = srsSnap.docs
          .map((doc) => SRSProgress.fromFirestore(doc.data()))
          .toList();

      final counts = {
        MasteryLevel.newWord: 0,
        MasteryLevel.learning: 0,
        MasteryLevel.proficient: 0,
        MasteryLevel.mastered: 0,
      };

      int masteredTotal = 0;
      for (var p in progressList) {
        if (p.level == 0) {
          counts[MasteryLevel.newWord] = counts[MasteryLevel.newWord]! + 1;
        } else if (p.level < 3) {
          counts[MasteryLevel.learning] = counts[MasteryLevel.learning]! + 1;
        } else if (p.level < 5) {
          counts[MasteryLevel.proficient] = counts[MasteryLevel.proficient]! + 1;
        } else {
          counts[MasteryLevel.mastered] = counts[MasteryLevel.mastered]! + 1;
          masteredTotal++;
        }
      }

      final total = progressList.length;
      double overallMastery = 0.0;
      if (total > 0) {
        final masteredWeight = counts[MasteryLevel.mastered]! * 1.0;
        final proficientWeight = counts[MasteryLevel.proficient]! * 0.7;
        final learningWeight = counts[MasteryLevel.learning]! * 0.3;
        overallMastery = (masteredWeight + proficientWeight + learningWeight) / total;
      }

      // Merge current mastered count into today's history slot if it's more accurate
      final List<double> polishedHistory = List.from(history);
      if (polishedHistory.length == 7) {
        polishedHistory[6] = masteredTotal.toDouble();
      }

      return SRSStats(
        counts: counts,
        overallMastery: overallMastery,
        weeklyProgress: polishedHistory,
      );
    });
  }

  Future<void> recordAttempt(String wordId, bool correct) async {
    final userId = ref.read(authServiceProvider).currentUser?.uid;
    if (userId == null) return;

    final docRef = ref.read(firebaseServiceProvider).db
        .collection('users')
        .doc(userId)
        .collection('srs_progress')
        .doc(wordId);

    final doc = await docRef.get();
    SRSProgress progress;

    if (doc.exists) {
      progress = SRSProgress.fromFirestore(doc.data()!);
    } else {
      progress = SRSProgress(wordId: wordId, nextReview: DateTime.now());
    }

    // Leitner-style logic
    int newLevel;
    if (correct) {
      newLevel = (progress.level + 1).clamp(0, 5);
    } else {
      newLevel = (progress.level - 1).clamp(0, 5);
    }

    // Simple interval calculation
    final intervals = [0, 1, 3, 7, 14, 30]; // Days
    final nextReview = DateTime.now().add(Duration(days: intervals[newLevel]));

    final updated = progress.copyWith(
      level: newLevel,
      nextReview: nextReview,
      lastReview: DateTime.now(),
      timesReviewed: progress.timesReviewed + 1,
      consecutiveCorrect: correct ? progress.consecutiveCorrect + 1 : 0,
      lastFailure: correct ? progress.lastFailure : DateTime.now(),
    );

    await docRef.set(updated.toFirestore());

    // After updating the word, trigger a log of today's total mastered count
    final masteredSnap = await ref.read(firebaseServiceProvider).db
        .collection('users')
        .doc(userId)
        .collection('srs_progress')
        .where('level', isEqualTo: 5)
        .get();

    await ref.read(firebaseServiceProvider).recordMasteryStat(userId, masteredSnap.size);
  }
}

final srsStatsProvider = StreamProvider<SRSStats>((ref) {
  final userId = ref.watch(authServiceProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value(SRSStats(
      counts: {
        MasteryLevel.newWord: 0,
        MasteryLevel.learning: 0,
        MasteryLevel.proficient: 0,
        MasteryLevel.mastered: 0,
      },
      overallMastery: 0,
      weeklyProgress: [],
    ));
  }
  return ref.watch(srsServiceProvider).getStatsStream(userId);
});



