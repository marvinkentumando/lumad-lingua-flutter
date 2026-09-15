import 'lesson_task.dart';

class DailyChallenge {
  final String id; // Format: YYYY-MM-DD
  final List<LessonTask> tasks;
  final int xpReward;
  final int crystalReward;
  final String title;
  final String description;

  DailyChallenge({
    required this.id,
    required this.tasks,
    this.xpReward = 50,
    this.crystalReward = 10,
    this.title = 'Ancestral Wisdom Challenge',
    this.description = 'Complete today\'s spiritual exercises to keep your streak alive.',
  });

  factory DailyChallenge.fromFirestore(Map<String, dynamic> data, String id) {
    return DailyChallenge(
      id: id,
      tasks: (data['tasks'] as List? ?? [])
          .map((t) => LessonTask.fromFirestore(t as Map<String, dynamic>))
          .toList(),
      xpReward: data['xpReward'] ?? 50,
      crystalReward: data['crystalReward'] ?? 10,
      title: data['title'] ?? 'Ancestral Wisdom Challenge',
      description: data['description'] ?? 'Complete today\'s spiritual exercises to keep your streak alive.',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tasks': tasks.map((t) => t.toFirestore()).toList(),
      'xpReward': xpReward,
      'crystalReward': crystalReward,
      'title': title,
      'description': description,
    };
  }
}
