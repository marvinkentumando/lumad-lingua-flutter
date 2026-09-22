import 'package:hive/hive.dart';

part 'lesson_progress.g.dart';

@HiveType(typeId: 30)
class OfflineProgress {
  @HiveField(0)
  final String lessonId;
  @HiveField(1)
  final int score;
  @HiveField(2)
  final int stars;
  @HiveField(3)
  final Map<String, int> taskPerformance;
  @HiveField(4)
  final int bonusXp;
  @HiveField(5)
  final DateTime timestamp;

  OfflineProgress({
    required this.lessonId,
    required this.score,
    required this.stars,
    required this.taskPerformance,
    required this.bonusXp,
    required this.timestamp,
  });
}
