import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/providers/student_provider.dart';
import 'package:lumad_lingua/services/upload_queue_service.dart';

void main() {
  group('StudentState Offline Leveling & Streak Calculations', () {
    test('StudentState level calculation and titles', () {
      final state0 = StudentState(
        mistCrystals: 0,
        xp: 0,
        dailyStreak: 0,
        hearts: 5,
        streakShields: 0,
        lessonProgress: {},
      );
      expect(state0.level, equals(1));
      expect(state0.levelTitle, equals('Novice Shaman'));

      final stateXp200 = StudentState(
        mistCrystals: 50,
        xp: 200,
        dailyStreak: 3,
        hearts: 5,
        streakShields: 0,
        lessonProgress: {},
      );
      // level = floor(sqrt(200 / 50)) + 1 = floor(sqrt(4)) + 1 = 3
      expect(stateXp200.level, equals(3));
      expect(stateXp200.levelTitle, equals('Novice Shaman'));

      final stateXp1000 = StudentState(
        mistCrystals: 100,
        xp: 1000,
        dailyStreak: 10,
        hearts: 5,
        streakShields: 1,
        lessonProgress: {},
      );
      // level = floor(sqrt(1000 / 50)) + 1 = floor(sqrt(20)) + 1 = 5
      expect(stateXp1000.level, equals(5));
      expect(stateXp1000.levelTitle, equals('Spiritual Seeker'));
    });

    test('StudentState levelProgress clamping', () {
      final state = StudentState(
        mistCrystals: 0,
        xp: 75,
        dailyStreak: 1,
        hearts: 5,
        streakShields: 0,
        lessonProgress: {},
      );
      expect(state.levelProgress, greaterThanOrEqualTo(0.0));
      expect(state.levelProgress, lessThanOrEqualTo(1.0));
    });

    test('StudentState streak display with shields', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      final activeYesterday = StudentState(
        mistCrystals: 0,
        xp: 100,
        dailyStreak: 5,
        hearts: 5,
        streakShields: 0,
        lessonProgress: {},
        lastActive: yesterday,
      );
      expect(activeYesterday.displayedStreak, equals(5));

      final inactiveWithShield = StudentState(
        mistCrystals: 0,
        xp: 100,
        dailyStreak: 5,
        hearts: 5,
        streakShields: 1,
        lessonProgress: {},
        lastActive: threeDaysAgo,
      );
      // Streak preserved visually by shield
      expect(inactiveWithShield.displayedStreak, equals(5));

      final inactiveNoShield = StudentState(
        mistCrystals: 0,
        xp: 100,
        dailyStreak: 5,
        hearts: 5,
        streakShields: 0,
        lessonProgress: {},
        lastActive: threeDaysAgo,
      );
      expect(inactiveNoShield.displayedStreak, equals(0));
    });

    test('StudentState copyWith immutability', () {
      final original = StudentState(
        mistCrystals: 100,
        xp: 500,
        dailyStreak: 7,
        hearts: 3,
        streakShields: 1,
        lessonProgress: {'lesson_1': {'stars': 3}},
        claimedMilestones: [3],
      );

      final modified = original.copyWith(
        mistCrystals: 150,
        hearts: 5,
      );

      expect(original.mistCrystals, equals(100));
      expect(original.hearts, equals(3));
      expect(modified.mistCrystals, equals(150));
      expect(modified.hearts, equals(5));
      expect(modified.dailyStreak, equals(7));
      expect(modified.claimedMilestones, contains(3));
    });
  });

  group('Sync Conflict & Upload Queue Data Models', () {
    test('SyncConflict initialization', () {
      final conflict = SyncConflict(
        lessonId: 'lesson_101',
        lessonTitle: 'Greetings in Mansaka',
        localData: {'score': 90, 'stars': 3},
        serverData: {'bestScore': 70, 'stars': 2},
      );

      expect(conflict.lessonId, equals('lesson_101'));
      expect(conflict.lessonTitle, equals('Greetings in Mansaka'));
      expect(conflict.localData['stars'], equals(3));
      expect(conflict.serverData['stars'], equals(2));
    });

    test('UploadQueueState copyWith handles conflict queue updates', () {
      final initialState = UploadQueueState(isSyncing: false, conflicts: []);
      expect(initialState.isSyncing, isFalse);
      expect(initialState.conflicts, isEmpty);

      final conflict = SyncConflict(
        lessonId: 'lesson_101',
        lessonTitle: 'Greetings in Mansaka',
        localData: {'score': 90, 'stars': 3},
        serverData: {'bestScore': 70, 'stars': 2},
      );

      final syncingState = initialState.copyWith(
        isSyncing: true,
        conflicts: [conflict],
      );

      expect(syncingState.isSyncing, isTrue);
      expect(syncingState.conflicts.length, equals(1));
      expect(syncingState.conflicts.first.lessonId, equals('lesson_101'));
    });
  });

  group('Pending Action Action Mapping Invariants', () {
    test('Supported pending sync action structure', () {
      final pendingAction = {
        'id': '1700000000000',
        'type': 'addMistCrystals',
        'payload': {'uid': 'user_123', 'amount': 50},
        'timestamp': '2026-09-28T12:00:00.000Z',
      };

      expect(pendingAction['type'], equals('addMistCrystals'));
      final payload = pendingAction['payload'] as Map<String, dynamic>;
      expect(payload['uid'], equals('user_123'));
      expect(payload['amount'], equals(50));
    });

    test('Claim milestone payload format', () {
      final action = {
        'type': 'claimMilestone',
        'payload': {'uid': 'user_123', 'days': 7, 'crystals': 100},
      };

      final payload = action['payload'] as Map<String, dynamic>;
      expect(payload['days'], equals(7));
      expect(payload['crystals'], equals(100));
    });
  });
}
