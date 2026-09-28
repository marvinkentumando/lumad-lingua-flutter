import 'package:flutter_test/flutter_test.dart';

import 'package:lumad_lingua/models/duel_models.dart';
import 'package:lumad_lingua/services/duel_service.dart';

void main() {
  group('Round deadline math (server-anchored turn timeouts)', () {
    final start = DateTime(2026, 9, 28, 12, 0, 0);

    test('deadline is round length × (round + 1) after battle start', () {
      expect(
        DuelService.deadlineForRound(start, 0),
        start.add(const Duration(seconds: 15)),
      );
      expect(
        DuelService.deadlineForRound(start, 2),
        start.add(const Duration(seconds: 45)),
      );
    });

    test('seconds left never goes negative', () {
      final expired = start.add(const Duration(hours: 1));
      expect(DuelService.secondsLeftForRound(expired, start, 0), 0);
      expect(DuelService.secondsLeftForRound(expired, start, 9), 0);
    });

    test('seconds left counts down within the round window', () {
      expect(DuelService.secondsLeftForRound(start, start, 0), 15);
      expect(
        DuelService.secondsLeftForRound(
          start.add(const Duration(seconds: 14)),
          start,
          0,
        ),
        1,
      );
      // Round 1 keeps its full window even though the battle started long ago.
      expect(
        DuelService.secondsLeftForRound(
          start.add(const Duration(seconds: 15)),
          start,
          1,
        ),
        15,
      );
    });

    test('lifecycle resume re-syncs correctly from the anchored deadline', () {
      // A client backgrounded for 7 seconds mid-round resumes with the right
      // remaining time instead of the drifted local timer value.
      final resumeAt = start.add(const Duration(seconds: 7));
      expect(DuelService.secondsLeftForRound(resumeAt, start, 0), 8);
    });
  });

  group('Winner determination (server-side, single source of truth)', () {
    test('player dropping to zero HP loses', () {
      expect(
        DuelService.winnerFromHp('p1', 'p2', 0.0, 0.5),
        'p2',
      );
      expect(
        DuelService.winnerFromHp('p1', 'p2', 0.5, 0.0),
        'p1',
      );
    });

    test('both alive means no winner yet', () {
      expect(DuelService.winnerFromHp('p1', 'p2', 0.5, 0.5), isNull);
      expect(DuelService.winnerFromHp('p1', 'p2', 1.0, 1.0), isNull);
    });

    test('double-KO resolves to the opponent of the first zero', () {
      // player1Hp is evaluated first, so simultaneous zeros favor p2 — a
      // deterministic, identical result on both clients.
      expect(DuelService.winnerFromHp('p1', 'p2', 0.0, 0.0), 'p2');
    });
  });

  group('Opponent staleness (abandonment detection)', () {
    final now = DateTime(2026, 9, 28, 12, 0, 0);

    DuelMatch matchWithLastSeen(Map<String, DateTime> lastSeen) => DuelMatch(
          id: 'm1',
          player1Id: 'p1',
          player2Id: 'p2',
          player1Name: 'P1',
          player2Name: 'P2',
          player1Avatar: '👤',
          player2Avatar: '👤',
          status: DuelStatus.active,
          questions: const [],
          createdAt: now,
          lastSeen: lastSeen,
        );

    test('fresh heartbeat is not stale', () {
      final match = matchWithLastSeen({
        'p1': now.subtract(const Duration(seconds: 5)),
        'p2': now.subtract(const Duration(seconds: 5)),
      });
      expect(DuelService.isOpponentStale(match, 'p1', now), isFalse);
    });

    test('silent opponent past the window is stale', () {
      final match = matchWithLastSeen({
        'p1': now,
        'p2': now.subtract(const Duration(seconds: 46)),
      });
      expect(DuelService.isOpponentStale(match, 'p1', now), isTrue);
    });

    test('missing heartbeat record is treated as still present', () {
      // The field may not exist on legacy matches; never forfeit on absence.
      final match = matchWithLastSeen({'p1': now});
      expect(DuelService.isOpponentStale(match, 'p1', now), isFalse);
    });

    test('opponentIdOf resolves from both sides', () {
      final match = matchWithLastSeen(const {});
      expect(match.opponentIdOf('p1'), 'p2');
      expect(match.opponentIdOf('p2'), 'p1');
    });
  });

  group('Sync config invariants', () {
    test('damage rounds finish a duel in at most 4 hits', () {
      expect(DuelMatch.damagePerHit * 4, 1.0);
    });

    test('staleness window is safely above the heartbeat interval', () {
      expect(
        DuelSyncConfig.opponentStaleAfter,
        greaterThan(DuelSyncConfig.heartbeatInterval * 2),
      );
    });

    test('waiting-lobby TTL sweeps before a joiner can ever see a ghost', () {
      expect(
        DuelSyncConfig.waitingMatchTtl,
        lessThan(const Duration(minutes: 5)),
      );
    });
  });
}
