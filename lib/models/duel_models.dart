import 'package:cloud_firestore/cloud_firestore.dart';

enum DuelStatus { waiting, active, finished, cancelled }

class DuelMatch {
  /// HP removed per round outcome (correct answer damages the opponent,
  /// wrong/timeout damages the answerer).
  static const double damagePerHit = 0.25;

  final String id;
  final String player1Id;
  final String? player2Id;
  final String player1Name;
  final String? player2Name;
  final String player1Avatar;
  final String? player2Avatar;
  final DuelStatus status;
  final List<DuelQuestion> questions;
  final double player1Hp;
  final double player2Hp;
  final int currentRound;
  final String? winnerId;
  final DateTime createdAt;
  /// Server timestamp written by the host the moment the battle starts.
  /// All round deadlines are anchored to this, so both clients agree on the
  /// clock without needing device-time synchronization.
  final DateTime? battleStartedAt;
  /// Per-player heartbeat timestamps (uid -> last seen). Used to detect an
  /// abandoned match and forfeit it.
  final Map<String, DateTime> lastSeen;
  /// Server timestamp set when the current round was opened (by whichever
  /// client advanced first). Round deadlines anchor to this so both players
  /// share one clock even if they answer at different moments.
  final DateTime? roundStartedAt;
  final DateTime? finishedAt;
  /// True while this snapshot contains uncommitted local writes. Damage
  /// effects must only trigger on remote (committed) changes.
  final bool hasPendingWrites;

  DuelMatch({
    required this.id,
    required this.player1Id,
    this.player2Id,
    required this.player1Name,
    this.player2Name,
    required this.player1Avatar,
    this.player2Avatar,
    required this.status,
    required this.questions,
    this.player1Hp = 1.0,
    this.player2Hp = 1.0,
    this.currentRound = 0,
    this.winnerId,
    required this.createdAt,
    this.battleStartedAt,
    Map<String, DateTime>? lastSeen,
    this.roundStartedAt,
    this.finishedAt,
    this.hasPendingWrites = false,
  }) : lastSeen = lastSeen ?? const {};

  /// The other duelist's uid, from this player's point of view.
  String? opponentIdOf(String myId) =>
      myId == player1Id ? player2Id : player1Id;

  bool isActiveAndStarted(DuelStatus status) =>
      status == DuelStatus.active && battleStartedAt != null;

  factory DuelMatch.fromMap(Map<String, dynamic> data, {String? docId}) {
    final rawQuestions = data['questions'];
    List<DuelQuestion> parsedQuestions = [];
    if (rawQuestions is List) {
      parsedQuestions = rawQuestions.map((q) {
        if (q is Map) return DuelQuestion.fromMap(Map<String, dynamic>.from(q));
        return DuelQuestion(question: '', options: [], correctIndex: 0);
      }).toList();
    }

    return DuelMatch(
      hasPendingWrites: false,
      id: docId ?? data['id']?.toString() ?? '',
      player1Id: data['player1_id'] ?? data['player1Id'] ?? '',
      player2Id: data['player2_id'] ?? data['player2Id'],
      player1Name: data['player1_name'] ?? data['player1Name'] ?? 'Warrior',
      player2Name: data['player2_name'] ?? data['player2Name'],
      player1Avatar: data['player1_avatar'] ?? data['player1Avatar'] ?? '👤',
      player2Avatar: data['player2_avatar'] ?? data['player2Avatar'],
      status: DuelStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'waiting'),
        orElse: () => DuelStatus.waiting,
      ),
      questions: parsedQuestions,
      player1Hp: (data['player1_hp'] ?? data['player1Hp'] ?? 1.0 as num).toDouble(),
      player2Hp: (data['player2_hp'] ?? data['player2Hp'] ?? 1.0 as num).toDouble(),
      currentRound: (data['current_round'] ?? data['currentRound'] ?? 0 as num).toInt(),
      winnerId: data['winner_id'] ?? data['winnerId'],
      createdAt: DuelMatch.parseTimestamp(data['created_at'] ?? data['createdAt']) ?? DateTime.now(),
      battleStartedAt: DuelMatch.parseTimestamp(data['battle_started_at'] ?? data['battleStartedAt']),
      lastSeen: DuelMatch.parseLastSeen(data['last_seen'] ?? data['lastSeen']),
      roundStartedAt: DuelMatch.parseTimestamp(data['round_started_at'] ?? data['roundStartedAt']),
      finishedAt: DuelMatch.parseTimestamp(data['finished_at'] ?? data['finishedAt']),
    );
  }

  factory DuelMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DuelMatch.fromMap(data, docId: doc.id);
  }

  static DateTime? parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static Map<String, DateTime> parseLastSeen(dynamic value) {
    if (value is! Map) return const {};
    final parsed = <String, DateTime>{};
    value.forEach((key, ts) {
      final date = parseTimestamp(ts);
      if (date != null) parsed[key.toString()] = date;
    });
    return parsed;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'player1Id': player1Id,
      'player2Id': player2Id,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'player1Avatar': player1Avatar,
      'player2Avatar': player2Avatar,
      'status': status.name,
      'questions': questions.map((q) => q.toMap()).toList(),
      'player1Hp': player1Hp,
      'player2Hp': player2Hp,
      'currentRound': currentRound,
      'winnerId': winnerId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toSupabase() {
    final lastSeenMap = <String, String>{};
    lastSeen.forEach((key, val) {
      lastSeenMap[key] = val.toIso8601String();
    });

    return {
      'player1_id': player1Id,
      'player2_id': player2Id,
      'player1_name': player1Name,
      'player2_name': player2Name,
      'player1_avatar': player1Avatar,
      'player2_avatar': player2Avatar,
      'status': status.name,
      'questions': questions.map((q) => q.toMap()).toList(),
      'player1_hp': player1Hp,
      'player2_hp': player2Hp,
      'current_round': currentRound,
      'winner_id': winnerId,
      'last_seen': lastSeenMap,
    };
  }
}

class DuelQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String type;

  DuelQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.type = 'multipleChoice',
  });

  factory DuelQuestion.fromMap(Map<String, dynamic> map) {
    return DuelQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: (map['correctIndex'] ?? map['correct_index'] ?? 0 as num).toInt(),
      type: map['type'] ?? 'multipleChoice',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'type': type,
    };
  }
}

class DuelHistoryItem {
  final String id;
  final String opponentId;
  final String opponentName;
  final String opponentAvatar;
  final bool isWinner;
  final double finalPlayerHp;
  final double finalOpponentHp;
  final int roundsPlayed;
  final int xpEarned;
  final int mistCrystalsEarned;
  final DateTime timestamp;

  DuelHistoryItem({
    required this.id,
    required this.opponentId,
    required this.opponentName,
    required this.opponentAvatar,
    required this.isWinner,
    required this.finalPlayerHp,
    required this.finalOpponentHp,
    required this.roundsPlayed,
    required this.xpEarned,
    required this.mistCrystalsEarned,
    required this.timestamp,
  });

  factory DuelHistoryItem.fromMap(Map<String, dynamic> map, String id) {
    return DuelHistoryItem(
      id: id,
      opponentId: map['opponentId'] ?? map['opponent_id'] ?? '',
      opponentName: map['opponentName'] ?? map['opponent_name'] ?? 'Warrior',
      opponentAvatar: map['opponentAvatar'] ?? map['opponent_avatar'] ?? '👤',
      isWinner: map['isWinner'] ?? map['is_winner'] ?? false,
      finalPlayerHp: (map['finalPlayerHp'] ?? map['final_player_hp'] ?? 0.0 as num).toDouble(),
      finalOpponentHp: (map['finalOpponentHp'] ?? map['final_opponent_hp'] ?? 0.0 as num).toDouble(),
      roundsPlayed: (map['roundsPlayed'] ?? map['rounds_played'] ?? 0 as num).toInt(),
      xpEarned: (map['xpEarned'] ?? map['xp_earned'] ?? 0 as num).toInt(),
      mistCrystalsEarned: (map['mistCrystalsEarned'] ?? map['mist_crystals_earned'] ?? 0 as num).toInt(),
      timestamp: DuelMatch.parseTimestamp(map['timestamp'] ?? map['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opponentId': opponentId,
      'opponentName': opponentName,
      'opponentAvatar': opponentAvatar,
      'isWinner': isWinner,
      'finalPlayerHp': finalPlayerHp,
      'finalOpponentHp': finalOpponentHp,
      'roundsPlayed': roundsPlayed,
      'xpEarned': xpEarned,
      'mistCrystalsEarned': mistCrystalsEarned,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toSupabase() {
    return {
      'opponent_id': opponentId,
      'opponent_name': opponentName,
      'opponent_avatar': opponentAvatar,
      'is_winner': isWinner,
      'final_player_hp': finalPlayerHp,
      'final_opponent_hp': finalOpponentHp,
      'rounds_played': roundsPlayed,
      'xp_earned': xpEarned,
      'mist_crystals_earned': mistCrystalsEarned,
      'created_at': timestamp.toIso8601String(),
    };
  }
}
