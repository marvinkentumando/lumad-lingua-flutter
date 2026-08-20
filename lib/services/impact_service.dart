import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'firebase_service.dart';
import 'auth_service.dart';

class ContributionImpact {
  final int primaryMetric; // e.g. Students Helped Today (Educator), Digital Vitality Index (Staff)
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
              ImpactStat(label: 'SUCCESS', value: '88%', icon: Icons.auto_graph_rounded), 
              ImpactStat(label: 'SPIRIT', value: _getSpiritTitle(xp), icon: Icons.forest_rounded),
            ],
          );
        },
      );
    } else if (role == 'staff' || role == 'validator' || role == 'contributor') {
      // Staff/Researcher Logic
      return db.collection('social_sentiment_data').snapshots().map((sentimentSnap) {
        final totalPosts = sentimentSnap.docs.length;
        double avgScore = 0.0;
        if (totalPosts > 0) {
          avgScore = sentimentSnap.docs.fold(0.0, (s, d) => s + (d.data()['sentiment_score'] ?? 0.0)) / totalPosts;
        }
        
        return ContributionImpact(
          primaryMetric: (avgScore * 100).toInt(),
          primaryLabel: 'VITALITY INDEX %',
          stats: [
            ImpactStat(label: 'POSTS MONITORED', value: totalPosts.toString(), icon: Icons.analytics_rounded),
            ImpactStat(label: 'REACH', value: (totalPosts * 15).toString(), icon: Icons.people_outline_rounded),
            ImpactStat(label: 'STATUS', value: avgScore > 0 ? 'STABLE' : 'CRITICAL', icon: Icons.health_and_safety_rounded),
          ],
        );
      });
    } else {
      // Learner Logic
      return Stream.value(ContributionImpact(
        primaryMetric: xp,
        primaryLabel: 'TOTAL XP',
        stats: [
          ImpactStat(label: 'SPIRIT', value: _getSpiritTitle(xp), icon: Icons.eco_rounded),
        ],
      ));
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
  if (xp >= 5000) return 'Legend';
  if (xp >= 2000) return 'Elder';
  if (xp >= 1000) return 'Guardian';
  if (xp >= 500) return 'Seeker';
  return 'Novice';
}
