import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'firebase_service.dart';
import 'auth_service.dart';
import '../theme/app_colors.dart';

class ContributionImpact {
  final int primaryMetric; // e.g. Students Helped Today (Educator), Approvals (Validator), Accuracy (Contributor)
  final String primaryLabel;
  final List<ImpactStat> stats;

  ContributionImpact({
    required this.primaryMetric,
    required this.primaryLabel,
    required this.stats,
  });
}

class ImpactStat {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  ImpactStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
}

final roleImpactProvider = StreamProvider.family<ContributionImpact, String>((ref, userId) {
  final firebase = ref.watch(firebaseServiceProvider);
  final db = firebase.db;

  return db.collection('users').doc(userId).snapshots().switchMap((userDoc) {
    if (!userDoc.exists) return Stream.value(ContributionImpact(primaryMetric: 0, primaryLabel: 'IMPACT', stats: []));
    
    final data = userDoc.data()!;
    final role = data['role'] ?? 'learner';
    final xp = data['xp'] ?? 0;

    if (role == 'educator') {
      // Educator Logic
      return CombineLatestStream.combine2(
        db.collection('users').where('role', isEqualTo: 'learner').snapshots(),
        db.collection('community_feed').where('type', isEqualTo: 'lesson_completed').snapshots(),
        (usersSnap, activitySnap) {
          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);
          
          final helpedToday = activitySnap.docs.where((doc) {
            final ts = doc.data()['createdAt'] as Timestamp?;
            return ts != null && ts.toDate().isAfter(startOfToday);
          }).length;
          
          final totalReach = usersSnap.docs.length;
          
          return ContributionImpact(
            primaryMetric: helpedToday,
            primaryLabel: 'STUDENTS HELPED TODAY',
            stats: [
              ImpactStat(label: 'TOTAL REACH', value: totalReach.toString(), icon: Icons.public_rounded),
              ImpactStat(label: 'SUCCESS', value: '88%', icon: Icons.auto_graph_rounded), // Placeholder for quiz success
              ImpactStat(label: 'SPIRIT', value: _getSpiritTitle(xp), icon: Icons.forest_rounded),
            ],
          );
        },
      );
    } else if (role == 'validator') {
      // Validator Logic
      return firebase.getValidatorDailyImpact(userId).map((impact) {
        return ContributionImpact(
          primaryMetric: impact.total,
          primaryLabel: 'DAILY VERIFICATIONS',
          stats: [
            ImpactStat(label: 'APPROVED', value: impact.approved.toString(), icon: Icons.check_circle_outline_rounded, color: AppColors.semanticGreen),
            ImpactStat(label: 'REJECTED', value: impact.rejected.toString(), icon: Icons.highlight_off_rounded, color: AppColors.semanticRed),
            ImpactStat(label: 'FLAGGED', value: impact.flagged.toString(), icon: Icons.flag_outlined, color: AppColors.gold500),
          ],
        );
      });
    } else {
      // Contributor Logic
      return CombineLatestStream.combine2(
        db.collection('words').where('contributorId', isEqualTo: userId).snapshots(),
        db.collection('users').snapshots(),
        (wordsSnap, allUsersSnap) {
          int approved = 0;
          int rejected = 0;
          for (var doc in wordsSnap.docs) {
            final status = doc.data()['status']?.toString().toLowerCase();
            if (status == 'approved') {
              approved++;
            } else if (status == 'rejected') {
              rejected++;
            }
          }
          
          final accuracy = (approved + rejected) > 0 ? (approved / (approved + rejected)) : 0.0;
          
          // Calculate Rank (mock percentile for now or use real logic)
          final totalUsers = allUsersSnap.docs.length;
          int higherXp = allUsersSnap.docs.where((u) => (u.data()['xp'] ?? 0) > xp).length;
          final percentile = totalUsers > 0 ? (1.0 - (higherXp / totalUsers)) : 0.0;
          
          String rank;
          if (percentile >= 0.95) {
            rank = 'Top 5%';
          } else if (percentile >= 0.80) {
            rank = 'Top 20%';
          } else {
            rank = 'Active';
          }

          return ContributionImpact(
            primaryMetric: (accuracy * 100).toInt(),
            primaryLabel: 'ACCURACY RATE %',
            stats: [
              ImpactStat(label: 'COMMUNITY', value: rank, icon: Icons.groups_rounded),
              ImpactStat(label: 'SPIRIT', value: _getSpiritTitle(xp), icon: Icons.eco_rounded),
              ImpactStat(label: 'VALIDATED', value: approved.toString(), icon: Icons.menu_book_rounded),
            ],
          );
        },
      );
    }
  });
});

final contributionImpactProvider = Provider<AsyncValue<ContributionImpact>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) {
    return AsyncValue.data(ContributionImpact(primaryMetric: 0, primaryLabel: 'IMPACT', stats: []));
  }
  return ref.watch(roleImpactProvider(auth.uid));
});

String _getSpiritTitle(int xp) {
  if (xp >= 5000) {
    return 'Legend';
  }
  if (xp >= 2000) {
    return 'Elder';
  }
  if (xp >= 1000) {
    return 'Guardian';
  }
  if (xp >= 500) {
    return 'Seeker';
  }
  return 'Novice';
}



