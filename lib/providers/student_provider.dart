import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class StudentState {
  final int mistCrystals;
  final int xp;
  final int dailyStreak;
  final int hearts;
  final int streakShields;
  final Map<String, dynamic> lessonProgress;
  final DateTime? lastActive;

  StudentState({
    required this.mistCrystals,
    required this.xp,
    required this.dailyStreak,
    required this.hearts,
    required this.streakShields,
    required this.lessonProgress,
    this.lastActive,
  });

  StudentState copyWith({
    int? mistCrystals,
    int? xp,
    int? dailyStreak,
    int? hearts,
    int? streakShields,
    Map<String, dynamic>? lessonProgress,
    DateTime? lastActive,
  }) {
    return StudentState(
      mistCrystals: mistCrystals ?? this.mistCrystals,
      xp: xp ?? this.xp,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      hearts: hearts ?? this.hearts,
      streakShields: streakShields ?? this.streakShields,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // Leveling Logic
  int get level {
    if (xp <= 0) return 1;
    // Level = floor(sqrt(xp / 50)) + 1
    return (sqrt(xp / 50)).floor() + 1;
  }

  String get levelTitle {
    final l = level;
    if (l < 5) return "Novice Shaman";
    if (l < 10) return "Spiritual Seeker";
    if (l < 20) return "Tribal Guardian";
    if (l < 40) return "Ancestral Sage";
    return "Elder Guardian";
  }

  double get levelProgress {
    final currentLevelXp = pow(level - 1, 2) * 50;
    final nextLevelXp = pow(level, 2) * 50;
    final progressXp = xp - currentLevelXp;
    final totalXpNeeded = nextLevelXp - currentLevelXp;
    return (progressXp / totalXpNeeded).clamp(0.0, 1.0);
  }

  int get displayedStreak {
    if (lastActive == null) return 0;
    final now = DateTime.now();
    final difference = DateTime(now.year, now.month, now.day)
        .difference(
          DateTime(lastActive!.year, lastActive!.month, lastActive!.day),
        )
        .inDays;
    // If more than 1 day has passed, the streak is effectively broken in the UI
    if (difference > 1) return 0;
    return dailyStreak;
  }
}

class StudentNotifier extends Notifier<StudentState> {
  @override
  StudentState build() {
    final profile = ref.watch(userProfileProvider).value;
    final user = ref.watch(authStateProvider).value;

    Map<String, dynamic> progress = {};
    if (user != null) {
      progress = ref.watch(userProgressStreamProvider(user.uid)).value ?? {};
    }

    // Fix #3: Resolve hearts with TTL refill logic.
    // Hearts are stored in Firestore. They refill to 5 after 8+ hours of inactivity.
    final int storedHearts = profile?['hearts'] as int? ?? 5;
    final Timestamp? lastHeartTime = profile?['lastHeartLossAt'] as Timestamp?;
    int resolvedHearts = storedHearts;
    if (lastHeartTime != null) {
      final hoursSinceLoss = DateTime.now()
          .difference(lastHeartTime.toDate())
          .inHours;
      if (hoursSinceLoss >= 8) {
        resolvedHearts = 5; // Auto-refill after 8 hours
      }
    }

    return StudentState(
      mistCrystals: profile?['mistCrystals'] ?? 0,
      xp: profile?['xp'] ?? 0,
      dailyStreak: profile?['streak'] ?? 0,
      hearts: resolvedHearts,
      streakShields: profile?['streakShields'] ?? 0,
      lessonProgress: progress,
      lastActive: (profile?['lastActive'] as Timestamp?)?.toDate(),
    );
  }

  void addMistCrystals(int amount) {
    state = state.copyWith(mistCrystals: state.mistCrystals + amount);
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(firebaseServiceProvider).addMistCrystals(user.uid, amount);
    }
  }

  void spendMistCrystals(int amount) {
    if (state.mistCrystals >= amount) {
      state = state.copyWith(mistCrystals: state.mistCrystals - amount);
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(firebaseServiceProvider).addMistCrystals(user.uid, -amount);
      }
    }
  }

  void addXp(int amount) {
    state = state.copyWith(xp: state.xp + amount);
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(firebaseServiceProvider).addXp(user.uid, amount);
    }
  }

  void incrementStreak() {
    final now = DateTime.now();
    final lastActive = state.lastActive;
    
    bool shouldIncrementLocally = false;
    if (lastActive == null) {
      shouldIncrementLocally = true;
    } else {
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastActive.year, lastActive.month, lastActive.day))
          .inDays;
      if (difference >= 1) {
        shouldIncrementLocally = true;
      }
    }

    if (shouldIncrementLocally) {
      state = state.copyWith(
        dailyStreak: state.dailyStreak + 1,
        lastActive: now,
      );
    }
    
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(firebaseServiceProvider).incrementStreak(user.uid);
    }
  }

  void decrementHeart() {
    if (state.hearts > 0) {
      final newHearts = state.hearts - 1;
      state = state.copyWith(hearts: newHearts);
      // Fix #3: Persist heart loss to Firestore so it survives app restarts.
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref
            .read(firebaseServiceProvider)
            .db
            .collection('users')
            .doc(user.uid)
            .update({
              'hearts': newHearts,
              'lastHeartLossAt': FieldValue.serverTimestamp(),
            });
      }
    }
  }

  void refillHearts() {
    state = state.copyWith(hearts: 5);
    // Fix #3: Persist refill to Firestore.
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref
          .read(firebaseServiceProvider)
          .db
          .collection('users')
          .doc(user.uid)
          .update({'hearts': 5, 'lastHeartLossAt': null});
    }
  }

  void gainHeart(int amount) {
    final newHearts = min(5, state.hearts + amount);
    state = state.copyWith(hearts: newHearts);
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref
          .read(firebaseServiceProvider)
          .db
          .collection('users')
          .doc(user.uid)
          .update({
            'hearts': newHearts,
            'lastHeartLossAt': newHearts == 5
                ? null
                : FieldValue.serverTimestamp(),
          });
    }
  }
}

final studentProvider = NotifierProvider<StudentNotifier, StudentState>(() {
  return StudentNotifier();
});



