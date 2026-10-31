import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/offline_service.dart';
import '../services/haptic_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class StudentState {
  final int mistCrystals;
  final int xp;
  final int dailyStreak;
  final int previousStreak;
  final DateTime? streakBrokenAt;
  final int hearts;
  final int streakShields;
  final Map<String, dynamic> lessonProgress;
  final DateTime? lastActive;
  final Map<String, bool> activityMap;
  final List<int> claimedMilestones;
  final String? equippedTitle;
  final String? equippedBadge;
  final String? equippedFrame;

  StudentState({
    required this.mistCrystals,
    required this.xp,
    required this.dailyStreak,
    this.previousStreak = 0,
    this.streakBrokenAt,
    required this.hearts,
    required this.streakShields,
    required this.lessonProgress,
    this.lastActive,
    this.activityMap = const {},
    this.claimedMilestones = const [],
    this.equippedTitle,
    this.equippedBadge,
    this.equippedFrame,
  });

  StudentState copyWith({
    int? mistCrystals,
    int? xp,
    int? dailyStreak,
    int? previousStreak,
    DateTime? streakBrokenAt,
    int? hearts,
    int? streakShields,
    Map<String, dynamic>? lessonProgress,
    DateTime? lastActive,
    Map<String, bool>? activityMap,
    List<int>? claimedMilestones,
    String? equippedTitle,
    String? equippedBadge,
    String? equippedFrame,
  }) {
    return StudentState(
      mistCrystals: mistCrystals ?? this.mistCrystals,
      xp: xp ?? this.xp,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      previousStreak: previousStreak ?? this.previousStreak,
      streakBrokenAt: streakBrokenAt ?? this.streakBrokenAt,
      hearts: hearts ?? this.hearts,
      streakShields: streakShields ?? this.streakShields,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      lastActive: lastActive ?? this.lastActive,
      activityMap: activityMap ?? this.activityMap,
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
      equippedTitle: equippedTitle ?? this.equippedTitle,
      equippedBadge: equippedBadge ?? this.equippedBadge,
      equippedFrame: equippedFrame ?? this.equippedFrame,
    );
  }

  // Leveling Logic
  int get level {
    if (xp <= 0) return 1;
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
    if (lastActive == null) return dailyStreak;
    final now = DateTime.now();
    final difference = _calendarDaysBetween(now, lastActive!);

    if (difference > 1) {
      final missedDays = difference - 1;
      if (streakShields >= missedDays) return dailyStreak;
      return 0;
    }
    return dailyStreak;
  }

  bool get canRepairStreak {
    if (previousStreak <= 0) return false;
    if (streakBrokenAt == null) return false;
    final now = DateTime.now();
    final hoursSinceBreak = now.difference(streakBrokenAt!).inHours;
    return hoursSinceBreak <= 72; // Eligible within 3 days (72 hrs) of streak break
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

    if (profile != null && profile.isNotEmpty) {
      final int storedHearts = profile['hearts'] as int? ?? 5;
      final Timestamp? lastHeartTime = profile['lastHeartLossAt'] as Timestamp?;
      int resolvedHearts = storedHearts;
      if (lastHeartTime != null) {
        final hoursSinceLoss = DateTime.now()
            .difference(lastHeartTime.toDate())
            .inHours;
        if (hoursSinceLoss >= 8) {
          resolvedHearts = 5;
        }
      }

      DateTime? lastActiveDt;
      if (profile['lastActive'] is Timestamp) {
        lastActiveDt = (profile['lastActive'] as Timestamp).toDate();
      } else if (profile['lastActive'] is String) {
        lastActiveDt = DateTime.tryParse(profile['lastActive']);
      }

      DateTime? streakBrokenAtDt;
      if (profile['streakBrokenAt'] is Timestamp) {
        streakBrokenAtDt = (profile['streakBrokenAt'] as Timestamp).toDate();
      } else if (profile['streakBrokenAt'] is String) {
        streakBrokenAtDt = DateTime.tryParse(profile['streakBrokenAt']);
      }

      final newState = StudentState(
        mistCrystals: profile['mistCrystals'] ?? 0,
        xp: profile['xp'] ?? 0,
        dailyStreak: profile['streak'] ?? 0,
        previousStreak: profile['previousStreak'] ?? 0,
        streakBrokenAt: streakBrokenAtDt,
        hearts: resolvedHearts,
        streakShields: profile['streakShields'] ?? 0,
        lessonProgress: progress,
        lastActive: lastActiveDt,
        activityMap: Map<String, bool>.from(profile['activityMap'] ?? {}),
        claimedMilestones: List<int>.from(profile['claimedMilestones'] ?? []),
        equippedTitle: profile['equippedTitle'] as String?,
        equippedBadge: profile['equippedBadge'] as String?,
        equippedFrame: profile['equippedFrame'] as String?,
      );

      Future.microtask(() => _persistLocalState());
      return newState;
    }

    // Offline fallback: load cached student profile from Hive
    Future.microtask(() async {
      final cached = await ref.read(offlineServiceProvider).getCachedStudentProfile();
      if (cached != null && state.xp == 0 && state.mistCrystals == 0) {
        DateTime? cachedActive;
        if (cached['lastActive'] is String) {
          cachedActive = DateTime.tryParse(cached['lastActive']);
        }
        DateTime? cachedBrokenAt;
        if (cached['streakBrokenAt'] is String) {
          cachedBrokenAt = DateTime.tryParse(cached['streakBrokenAt']);
        }
        state = StudentState(
          mistCrystals: cached['mistCrystals'] ?? 0,
          xp: cached['xp'] ?? 0,
          dailyStreak: cached['streak'] ?? 0,
          previousStreak: cached['previousStreak'] ?? 0,
          streakBrokenAt: cachedBrokenAt,
          hearts: cached['hearts'] ?? 5,
          streakShields: cached['streakShields'] ?? 0,
          lessonProgress: progress,
          lastActive: cachedActive,
          activityMap: Map<String, bool>.from(cached['activityMap'] ?? {}),
          claimedMilestones: List<int>.from(cached['claimedMilestones'] ?? []),
        );
      }
    });

    return StudentState(
      mistCrystals: 0,
      xp: 0,
      dailyStreak: 0,
      previousStreak: 0,
      streakBrokenAt: null,
      hearts: 5,
      streakShields: 0,
      lessonProgress: progress,
      lastActive: null,
      activityMap: const {},
      claimedMilestones: const [],
    );
  }

  void _persistLocalState() {
    try {
      ref.read(offlineServiceProvider).saveCachedStudentProfile({
        'mistCrystals': state.mistCrystals,
        'xp': state.xp,
        'streak': state.dailyStreak,
        'previousStreak': state.previousStreak,
        'streakBrokenAt': state.streakBrokenAt?.toIso8601String(),
        'hearts': state.hearts,
        'streakShields': state.streakShields,
        'lastActive': state.lastActive?.toIso8601String(),
        'claimedMilestones': state.claimedMilestones,
        'activityMap': state.activityMap,
        'equippedTitle': state.equippedTitle,
        'equippedBadge': state.equippedBadge,
        'equippedFrame': state.equippedFrame,
      });
    } catch (_) {}
  }

  void _queueSyncAction(String type, Map<String, dynamic> payload) {
    try {
      ref.read(offlineServiceProvider).queuePendingSyncAction({
        'type': type,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void claimMilestone(int days, int crystals) {
    if (!state.claimedMilestones.contains(days)) {
      final newClaimed = [...state.claimedMilestones, days];
      state = state.copyWith(
        claimedMilestones: newClaimed,
        mistCrystals: state.mistCrystals + crystals,
      );
      _persistLocalState();

      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(firebaseServiceProvider).db.collection('users').doc(user.uid).update({
          'claimedMilestones': FieldValue.arrayUnion([days]),
          'mistCrystals': FieldValue.increment(crystals),
        }).catchError((_) {
          _queueSyncAction('claimMilestone', {'uid': user.uid, 'days': days, 'crystals': crystals});
        });

        ref.read(firebaseServiceProvider).addNotification(user.uid, {
          'title': 'Milestone Reached! 🏆',
          'message': 'You claimed $crystals crystals for reaching a $days-day streak!',
          'type': 'reward',
        }).catchError((_) {});
      }
    }
  }

  void addMistCrystals(int amount) {
    state = state.copyWith(mistCrystals: state.mistCrystals + amount);
    _persistLocalState();

    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(firebaseServiceProvider).addMistCrystals(user.uid, amount).catchError((_) {
        _queueSyncAction('addMistCrystals', {'uid': user.uid, 'amount': amount});
      });
    }
  }

  void spendMistCrystals(int amount) {
    if (state.mistCrystals >= amount) {
      state = state.copyWith(mistCrystals: state.mistCrystals - amount);
      _persistLocalState();

      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(firebaseServiceProvider).addMistCrystals(user.uid, -amount).catchError((_) {
          _queueSyncAction('addMistCrystals', {'uid': user.uid, 'amount': -amount});
        });
      }
    }
  }

  void addXp(int amount) {
    state = state.copyWith(xp: state.xp + amount);
    _persistLocalState();

    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(firebaseServiceProvider).addXp(user.uid, amount).catchError((_) {
        _queueSyncAction('addXp', {'uid': user.uid, 'amount': amount});
      });
    }
  }

  void incrementStreak() {
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
      HapticService.streak();
      final newActivityMap = Map<String, bool>.from(state.activityMap);
      newActivityMap[dateKey] = true;

      int nextStreak = state.dailyStreak + 1;
      int nextShields = state.streakShields;
      int nextPreviousStreak = state.previousStreak;
      DateTime? nextBrokenAt = state.streakBrokenAt;

      if (lastActive != null) {
        final difference = DateTime(now.year, now.month, now.day)
            .difference(
              DateTime(lastActive.year, lastActive.month, lastActive.day),
            )
            .inDays;

        if (difference > 1) {
          final missedDays = difference - 1;
          if (state.streakShields >= missedDays) {
            // Multi-Day Shield covers all missed days
            nextShields = state.streakShields - missedDays;
            nextStreak = state.dailyStreak + 1;
          } else {
            // Not enough shields: streak breaks, record previous streak for recovery
            nextPreviousStreak = state.dailyStreak;
            nextBrokenAt = now;
            nextShields = 0;
            nextStreak = 1;
          }
        }
      }

      state = state.copyWith(
        dailyStreak: nextStreak,
        previousStreak: nextPreviousStreak,
        streakBrokenAt: nextBrokenAt,
        streakShields: nextShields,
        lastActive: now,
        activityMap: newActivityMap,
      );
    } else if (!state.activityMap.containsKey(dateKey)) {
      final newActivityMap = Map<String, bool>.from(state.activityMap);
      newActivityMap[dateKey] = true;
      state = state.copyWith(activityMap: newActivityMap);
    }

    _persistLocalState();
    
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(firebaseServiceProvider).incrementStreak(user.uid).catchError((_) {
        _queueSyncAction('incrementStreak', {'uid': user.uid});
      });
    }
  }

  void repairStreak() {
    HapticService.streak();
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final prev = state.previousStreak > 0 ? state.previousStreak : state.dailyStreak;
    final restoredStreak = (prev > 0 ? prev : 0) + 1;

    final newActivityMap = Map<String, bool>.from(state.activityMap);
    newActivityMap[dateKey] = true;

    state = state.copyWith(
      dailyStreak: restoredStreak,
      previousStreak: 0,
      streakBrokenAt: null,
      lastActive: now,
      activityMap: newActivityMap,
    );
    _persistLocalState();

    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(firebaseServiceProvider).repairStreak(user.uid).catchError((_) {
        _queueSyncAction('repairStreak', {'uid': user.uid});
      });

      ref.read(firebaseServiceProvider).addNotification(user.uid, {
        'title': 'Streak Restored! 🔥',
        'message': 'Your $restoredStreak-day streak has been successfully repaired!',
        'type': 'reward',
      }).catchError((_) {});
    }
  }

  bool buyStreakRepair() {
    if (state.canRepairStreak && state.mistCrystals >= 200) {
      spendMistCrystals(200);
      repairStreak();
      return true;
    }
    return false;
  }

  void completeStreakRecoveryQuest() {
    if (state.canRepairStreak) {
      addXp(50);
      addMistCrystals(30);
      repairStreak();
    }
  }

  void decrementHeart() {
    if (state.hearts > 0) {
      final newHearts = state.hearts - 1;
      state = state.copyWith(hearts: newHearts);
      _persistLocalState();

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
            })
            .catchError((_) {
              _queueSyncAction('updateHearts', {'uid': user.uid, 'hearts': newHearts});
            });
      }
    }
  }

  void refillHearts() {
    state = state.copyWith(hearts: 5);
    _persistLocalState();

    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref
          .read(firebaseServiceProvider)
          .db
          .collection('users')
          .doc(user.uid)
          .update({'hearts': 5, 'lastHeartLossAt': null})
          .catchError((_) {
            _queueSyncAction('updateHearts', {'uid': user.uid, 'hearts': 5});
          });
    }
  }

  void gainHeart(int amount) {
    final newHearts = min(5, state.hearts + amount);
    state = state.copyWith(hearts: newHearts);
    _persistLocalState();

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
          })
          .catchError((_) {
            _queueSyncAction('updateHearts', {'uid': user.uid, 'hearts': newHearts});
          });
    }
  }

  void equipCustomization({String? title, String? emoji, String? frame}) {
    state = state.copyWith(
      equippedTitle: title ?? state.equippedTitle,
      equippedBadge: emoji ?? state.equippedBadge,
      equippedFrame: frame ?? state.equippedFrame,
    );
    _persistLocalState();

    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final Map<String, dynamic> updates = {};
      if (title != null) updates['equippedTitle'] = title;
      if (emoji != null) updates['equippedBadge'] = emoji;
      if (frame != null) updates['equippedFrame'] = frame;

      if (updates.isNotEmpty) {
        ref.read(firebaseServiceProvider).db.collection('users').doc(user.uid).update(updates).catchError((_) {
          _queueSyncAction('equipCustomization', {'uid': user.uid, 'title': title, 'emoji': emoji, 'frame': frame});
        });
      }
    }
  }

  bool buyStreakShield() {
    if (state.mistCrystals >= 100) {
      state = state.copyWith(
        mistCrystals: state.mistCrystals - 100,
        streakShields: state.streakShields + 1,
      );
      _persistLocalState();

      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(firebaseServiceProvider).buyStreakShield(user.uid).catchError((_) {
          _queueSyncAction('buyStreakShield', {'uid': user.uid});
        });
      }
      return true;
    }
    return false;
  }

  bool buyMultiDayShieldBundle() {
    if (state.mistCrystals >= 250) {
      state = state.copyWith(
        mistCrystals: state.mistCrystals - 250,
        streakShields: state.streakShields + 3,
      );
      _persistLocalState();

      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(firebaseServiceProvider).buyMultiDayShieldBundle(user.uid).catchError((_) {
          _queueSyncAction('buyMultiDayShieldBundle', {'uid': user.uid});
        });
      }
      return true;
    }
    return false;
  }

  bool buyHeart() {
    if (state.mistCrystals >= 50 && state.hearts < 5) {
      state = state.copyWith(
        mistCrystals: state.mistCrystals - 50,
        hearts: min(5, state.hearts + 1),
      );
      _persistLocalState();

      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(firebaseServiceProvider).db.collection('users').doc(user.uid).update({
          'mistCrystals': FieldValue.increment(-50),
          'hearts': FieldValue.increment(1),
        }).catchError((_) {
          _queueSyncAction('buyHeart', {'uid': user.uid});
        });
      }
      return true;
    }
    return false;
  }
}

final studentProvider = NotifierProvider<StudentNotifier, StudentState>(() {
  return StudentNotifier();
});
