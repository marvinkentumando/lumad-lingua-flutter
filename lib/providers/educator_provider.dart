import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/educator_models.dart';
import '../models/admin_models.dart';
import '../models/lesson.dart';
import 'dart:math' as math;

final educatorStudentsProvider = StreamProvider<List<EducatorStudent>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  
  // 1. Get all users
  return firebaseService.getAllUsers().asyncMap((users) async {
    // 2. Filter for learners
    final learners = users.where((u) => u.role == 'learner').toList();
    
    // 3. Get all lessons to map progress IDs to titles
    final lessons = await firebaseService.getAllLessons().first;
    final lessonMap = {for (var l in lessons) l.id: l};

    final List<EducatorStudent> students = [];

    for (var user in learners) {
      // 4. Get progress subcollection for each learner
      final progressData = await firebaseService.getUserProgress(user.id).first;
      
      final List<StudentLessonProgress> breakdown = [];
      int completedCount = 0;
      double totalProgress = 0;

      progressData.forEach((lessonId, data) {
        final lesson = lessonMap[lessonId];
        if (lesson != null) {
          final isCompleted = data['completed'] == true;
          if (isCompleted) completedCount++;
          
          final bestScore = (data['bestScore'] as num?)?.toDouble() ?? 0.0;
          totalProgress += bestScore / 100.0;
          
          // Calculate accuracy from performance if available
          double accuracy = 0.8; // Default
          final performance = data['performance'] as Map<String, dynamic>?;
          if (performance != null && performance.isNotEmpty) {
             // Heuristic: more recorded mistakes = lower accuracy
             int totalMistakes = 0;
             performance.values.forEach((v) => totalMistakes += (v as num).toInt());
             accuracy = (1.0 - (totalMistakes / (lesson.tasks.length * 5))).clamp(0.1, 1.0);
          }

          breakdown.add(StudentLessonProgress(
            lessonTitle: lesson.title,
            progress: bestScore / 100.0,
            status: isCompleted ? 'Completed' : (bestScore > 0 ? 'In Progress' : 'Not Started'),
            accuracy: accuracy,
          ));
        }
      });

      // Simple heuristic for level title
      String level = 'Beginner';
      if (user.xp > 500) level = 'Expert';
      else if (user.xp > 100) level = 'Intermediate';

      students.add(EducatorStudent(
        id: user.id,
        name: user.name,
        level: level,
        progress: lessons.isEmpty ? 0 : (totalProgress / lessons.length).clamp(0.0, 1.0),
        avatar: user.photoURL ?? 'assets/images/user1.png',
        village: user.indigenousGroup ?? 'Unknown',
        lessonsCompleted: completedCount,
        streakDays: user.streak,
        isStruggling: user.xp < 50 && completedCount < 2, // Sample heuristic
        lessonBreakdown: breakdown,
      ));
    }

    return students;
  });
});
