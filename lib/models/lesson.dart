import 'package:hive/hive.dart';
import 'lesson_task.dart';

part 'lesson.g.dart';

@HiveType(typeId: 3)
class Lesson {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final String language; // e.g., 'Mansaka'
  @HiveField(5)
  final int level;
  @HiveField(6)
  final int unitNumber;
  @HiveField(7)
  final List<LessonTask> tasks;
  @HiveField(8)
  final bool isPremium;
  @HiveField(9)
  final String icon;
  @HiveField(10)
  final String status;
  @HiveField(11)
  final String? prerequisiteId;
  @HiveField(12)
  final bool isMistUnit;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.language,
    required this.level,
    required this.unitNumber,
    required this.tasks,
    this.isPremium = false,
    this.icon = 'psychology',
    this.status = 'PUBLISHED',
    this.prerequisiteId,
    this.isMistUnit = false,
  });

  factory Lesson.fromFirestore(Map<String, dynamic> data, String id) {
    var taskList = <LessonTask>[];
    if (data['tasks'] != null) {
      taskList = (data['tasks'] as List).map((t) {
        // Here we'd need a fromMap in LessonTask
        return _taskFromMap(t as Map<String, dynamic>);
      }).toList();
    }

    return Lesson(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      language: data['language'] ?? 'Mansaka',
      level: data['level'] ?? 1,
      unitNumber: data['unitNumber'] ?? 1,
      tasks: taskList,
      isPremium: data['isPremium'] ?? false,
      icon: data['icon'] ?? 'psychology',
      status: data['status'] ?? 'PUBLISHED',
      prerequisiteId: data['prerequisiteId'],
      isMistUnit:
          data['isMistUnit'] ?? (data['category'] == 'Cultural Stories'),
    );
  }

  static LessonTask _taskFromMap(Map<String, dynamic> map) {
    return LessonTask(
      id: map['id'] ?? '',
      type: TaskType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TaskType.multipleChoice,
      ),
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      pairs:
          (map['pairs'] as List?)
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'language': language,
      'level': level,
      'unitNumber': unitNumber,
      'tasks': tasks.map((t) => t.toFirestore()).toList(),
      'isPremium': isPremium,
      'icon': icon,
      'status': status,
      if (prerequisiteId != null) 'prerequisiteId': prerequisiteId,
      'isMistUnit': isMistUnit,
    };
  }
}


