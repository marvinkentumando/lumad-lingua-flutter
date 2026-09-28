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

  factory DuelMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DuelMatch(
      hasPendingWrites: doc.metadata.hasPendingWrites,
      id: doc.id,
      player1Id: data['player1Id'] ?? '',
      player2Id: data['player2Id'],
      player1Name: data['player1Name'] ?? 'Warrior',
      player2Name: data['player2Name'],
      player1Avatar: data['player1Avatar'] ?? '👤',
      player2Avatar: data['player2Avatar'],
      status: DuelStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'waiting'),
        orElse: () => DuelStatus.waiting,
      ),
      questions: (data['questions'] as List? ?? [])
          .map((q) => DuelQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      player1Hp: (data['player1Hp'] as num? ?? 1.0).toDouble(),
      player2Hp: (data['player2Hp'] as num? ?? 1.0).toDouble(),
      currentRound: data['currentRound'] ?? 0,
      winnerId: data['winnerId'],
      createdAt: DuelMatch.parseTimestamp(data['createdAt']) ?? DateTime.now(),
      battleStartedAt: DuelMatch.parseTimestamp(data['battleStartedAt']),
      lastSeen: DuelMatch.parseLastSeen(data['lastSeen']),
      roundStartedAt: DuelMatch.parseTimestamp(data['roundStartedAt']),
      finishedAt: DuelMatch.parseTimestamp(data['finishedAt']),
    );
  }

  static DateTime? parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
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
}

class DuelQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  DuelQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory DuelQuestion.fromMap(Map<String, dynamic> map) {
    return DuelQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}
