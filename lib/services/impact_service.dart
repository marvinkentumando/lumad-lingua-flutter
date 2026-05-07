import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'firebase_service.dart';

class ContributionImpact {
  final int studentsHelpedToday;
  final int totalReach;
  final double accuracyRate;
  final int validatedWords;

  ContributionImpact({
    required this.studentsHelpedToday,
    required this.totalReach,
    required this.accuracyRate,
    required this.validatedWords,
  });
}

final contributionImpactProvider = StreamProvider<ContributionImpact>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  final db = firebase.db;

  // Real-time aggregation from multiple collections
  return CombineLatestStream.combine3(
    // 1. Total Reach (all users)
    db.collection('users').snapshots(),
    // 2. Validated Words & Accuracy (all submissions)
    db.collection('words').snapshots(),
    // 3. Activity (specifically today's completions)
    db.collection('activity')
        .where('type', isEqualTo: 'lesson_completed')
        .snapshots(),
    (usersSnap, wordsSnap, activitySnap) {
      // Calculate students helped today
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      
      final helpedToday = activitySnap.docs.where((doc) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;
        return ts != null && ts.toDate().isAfter(startOfToday);
      }).length;
      final totalReach = usersSnap.docs.length;
      
      int approvedCount = 0;
      int rejectedCount = 0;
      
      for (var doc in wordsSnap.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? '';
        if (status == 'approved') {
          approvedCount++;
        } else if (status == 'rejected') {
          rejectedCount++;
        }
      }
      
      final validatedWords = approvedCount;
      
      // Calculate accuracy: Approved / (Approved + Rejected)
      // This ignores 'pending' and 'flagged' for the rate calculation
      final totalDecisionCount = approvedCount + rejectedCount;
      final accuracyRate = totalDecisionCount > 0 
          ? (approvedCount / totalDecisionCount) 
          : 0.0;

      return ContributionImpact(
        studentsHelpedToday: helpedToday,
        totalReach: totalReach,
        accuracyRate: accuracyRate,
        validatedWords: validatedWords,
      );
    },
  );
});



