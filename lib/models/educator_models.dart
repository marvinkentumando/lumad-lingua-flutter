import 'lesson.dart';
import 'lesson_task.dart';

class EducatorLesson {
  final String id;
  String title;
  String subtitle;
  String status; // 'PUBLISHED' or 'DRAFT'
  final String dialect;
  final String level;
  int viewCount;
  int studentCount;
  double completionRate;
  final DateTime createdAt;
  String category;
  String version;
  final String language;
  final int unitNumber;

  EducatorLesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    this.dialect = 'Mansaka',
    this.level = 'Beginner',
    this.viewCount = 0,
    this.studentCount = 0,
    this.completionRate = 0.0,
    this.category = 'General',
    this.version = '1.0',
    this.language = 'Mansaka',
    this.unitNumber = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory EducatorLesson.fromLesson(Lesson lesson) {
    String levelLabel = 'Novice';
    if (lesson.level == 2) {
      levelLabel = 'Intermediate';
    } else if (lesson.level >= 3) {
      levelLabel = 'Expert';
    }

    return EducatorLesson(
      id: lesson.id,
      title: lesson.title,
      subtitle: '$levelLabel • ${lesson.language}',
      status: lesson.status,
      dialect: lesson.language,
      level: levelLabel,
      category: lesson.category,
      language: lesson.language,
      unitNumber: lesson.unitNumber,
    );
  }
}

class EducatorStudent {
  final String id;
  final String name;
  final String level;
  final double progress;
  final String avatar;
  final String municipality;
  final int lessonsCompleted;
  final int streakDays;
  final bool isStruggling;
  final List<StudentLessonProgress> lessonBreakdown;
  final Map<String, bool> activityMap;

  const EducatorStudent({
    required this.id,
    required this.name,
    required this.level,
    required this.progress,
    required this.avatar,
    this.municipality = 'All Municipalities',
    this.lessonsCompleted = 0,
    this.streakDays = 0,
    this.isStruggling = false,
    this.lessonBreakdown = const [],
    this.activityMap = const {},
  });
}

class StudentLessonProgress {
  final String lessonTitle;
  final double progress;
  final double accuracy;
  final String status; // 'Completed', 'In Progress', 'Not Started'

  const StudentLessonProgress({
    required this.lessonTitle,
    required this.progress,
    required this.status,
    this.accuracy = 0.8,
  });
}

class VillageMiniQuiz {
  final String id;
  final String title;
  final String description;
  final String educatorId;
  final String dialect;
  final List<LessonTask> tasks;
  final DateTime createdAt;
  final bool isAssigned;
  final int totalSubmissions;

  const VillageMiniQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.educatorId,
    required this.dialect,
    required this.tasks,
    required this.createdAt,
    this.isAssigned = true,
    this.totalSubmissions = 0,
  });

  factory VillageMiniQuiz.fromFirestore(Map<String, dynamic> data, String id) {
    return VillageMiniQuiz(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      educatorId: data['educatorId'] ?? '',
      dialect: data['dialect'] ?? 'Mansaka',
      tasks: (data['tasks'] as List? ?? [])
          .map((t) => LessonTask.fromFirestore(Map<String, dynamic>.from(t)))
          .toList(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      isAssigned: data['isAssigned'] ?? true,
      totalSubmissions: data['totalSubmissions'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'educatorId': educatorId,
      'dialect': dialect,
      'tasks': tasks.map((t) => t.toFirestore()).toList(),
      'createdAt': createdAt,
      'isAssigned': isAssigned,
      'totalSubmissions': totalSubmissions,
    };
  }

  Lesson toLesson() {
    return Lesson(
      id: id,
      title: title,
      description: description,
      category: 'Mini-Quiz',
      language: dialect,
      level: 1,
      unitNumber: 1,
      tasks: tasks,
      status: isAssigned ? 'PUBLISHED' : 'DRAFT',
    );
  }
}



