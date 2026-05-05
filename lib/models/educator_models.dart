import 'lesson.dart';

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
    return EducatorLesson(
      id: lesson.id,
      title: lesson.title,
      subtitle:
          '${lesson.level == 1 ? 'Beginner' : 'Advanced'} • ${lesson.language}',
      status: lesson.status,
      dialect: lesson.language,
      level: lesson.level == 1 ? 'Beginner' : 'Advanced',
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
  final String village;
  final int lessonsCompleted;
  final int streakDays;
  final bool isStruggling;
  final List<StudentLessonProgress> lessonBreakdown;

  const EducatorStudent({
    required this.id,
    required this.name,
    required this.level,
    required this.progress,
    required this.avatar,
    this.village = 'All Villages',
    this.lessonsCompleted = 0,
    this.streakDays = 0,
    this.isStruggling = false,
    this.lessonBreakdown = const [],
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


