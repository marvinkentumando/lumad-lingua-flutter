import 'package:cloud_firestore/cloud_firestore.dart';

enum DuelStatus { waiting, active, finished, cancelled }

class DuelMatch {
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
  });

  factory DuelMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DuelMatch(
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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
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
