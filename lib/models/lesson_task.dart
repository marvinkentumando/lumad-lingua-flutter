import 'package:hive/hive.dart';

part 'lesson_task.g.dart';

@HiveType(typeId: 4)
enum TaskType {
  @HiveField(0)
  multipleChoice,
  @HiveField(1)
  listening,
  @HiveField(2)
  matching,
  @HiveField(3)
  sentenceReordering,
  @HiveField(4)
  pronunciation,
  @HiveField(5)
  vocabulary,
  @HiveField(6)
  scenario,
  @HiveField(7)
  wordHunt,
  @HiveField(8)
  trueOrFalse,
  @HiveField(9)
  fillInTheBlanks,
}

@HiveType(typeId: 5)
class LessonTask {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final TaskType type;
  @HiveField(2)
  final String questionText;

  // MCQ / Listening
  @HiveField(3)
  final List<String> options;
  @HiveField(4)
  final int correctAnswerIndex;

  // Matching
  @HiveField(5)
  final List<Map<String, String>> pairs;

  // Sentence Reordering
  @HiveField(6)
  final List<String> sentenceParts;
  @HiveField(7)
  final String expectedSentence;

  // Pronunciation
  @HiveField(8)
  final String nativeWord;
  @HiveField(9)
  final String phoneticGuide;

  @HiveField(10)
  final String hintMetadata;
  @HiveField(11)
  final String? audioUrl;
  @HiveField(12)
  final String? imageUrl;

  // Grammar Nuggets
  @HiveField(13)
  final String? grammarTitle;
  @HiveField(14)
  final String? grammarDescription;
  @HiveField(15)
  final List<String>? grammarExamples;

  const LessonTask({
    required this.id,
    required this.type,
    required this.questionText,
    this.options = const [],
    this.correctAnswerIndex = 0,
    this.pairs = const [],
    this.sentenceParts = const [],
    this.expectedSentence = '',
    this.nativeWord = '',
    this.phoneticGuide = '',
    required this.hintMetadata,
    this.audioUrl,
    this.imageUrl,
    this.grammarTitle,
    this.grammarDescription,
    this.grammarExamples,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'pairs': pairs,
      'sentenceParts': sentenceParts,
      'expectedSentence': expectedSentence,
      'nativeWord': nativeWord,
      'phoneticGuide': phoneticGuide,
      'hintMetadata': hintMetadata,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'grammarTitle': grammarTitle,
      'grammarDescription': grammarDescription,
      'grammarExamples': grammarExamples,
    };
  }

  factory LessonTask.fromFirestore(Map<String, dynamic> map) {
    return LessonTask(
      id: map['id'] ?? '',
      type: TaskType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TaskType.multipleChoice,
      ),
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      pairs: (map['pairs'] as List?)
              ?.map((p) => Map<String, String>.from(p))
              .toList() ??
          [],
      sentenceParts: List<String>.from(map['sentenceParts'] ?? []),
      expectedSentence: map['expectedSentence'] ?? '',
      nativeWord: map['nativeWord'] ?? '',
      phoneticGuide: map['phoneticGuide'] ?? '',
      hintMetadata: map['hintMetadata'] ?? '',
      audioUrl: map['audioUrl'],
      imageUrl: map['imageUrl'],
      grammarTitle: map['grammarTitle'],
      grammarDescription: map['grammarDescription'],
      grammarExamples: (map['grammarExamples'] as List?)?.cast<String>(),
    );
  }
}



