import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/educator_models.dart';

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

      for (final entry in progressData.entries) {
        final lessonId = entry.key;
        final data = entry.value;
        final lesson = lessonMap[lessonId];
        if (lesson != null) {
          final isCompleted = data['completed'] == true;
          if (isCompleted) {
            completedCount++;
          }
          
          final bestScore = (data['bestScore'] as num?)?.toDouble() ?? 0.0;
          totalProgress += bestScore / 100.0;
          
          // Calculate accuracy from performance if available
          double accuracy = 0.8; // Default
          final performance = data['performance'] as Map<String, dynamic>?;
          if (performance != null && performance.isNotEmpty) {
             // Heuristic: more recorded mistakes = lower accuracy
             int totalMistakes = 0;
             for (final v in performance.values) {
               totalMistakes += (v as num).toInt();
             }
             accuracy = (1.0 - (totalMistakes / (lesson.tasks.length * 5))).clamp(0.1, 1.0);
          }

          breakdown.add(StudentLessonProgress(
            lessonTitle: lesson.title,
            progress: bestScore / 100.0,
            status: isCompleted ? 'Completed' : (bestScore > 0 ? 'In Progress' : 'Not Started'),
            accuracy: accuracy,
          ));
        }
      }

      // Simple heuristic for level title
      String level = 'Beginner';
      if (user.xp > 500) {
        level = 'Expert';
      } else if (user.xp > 100) {
        level = 'Intermediate';
      }

      students.add(EducatorStudent(
        id: user.id,
        name: user.name,
        level: level,
        progress: lessons.isEmpty ? 0 : (totalProgress / lessons.length).clamp(0.0, 1.0),
        avatar: user.photoURL ?? 'assets/images/user1.png',
        municipality: user.municipality ?? 'Unknown',
        lessonsCompleted: completedCount,
        streakDays: user.streak,
        isStruggling: user.xp < 50 && completedCount < 2, // Sample heuristic
        lessonBreakdown: breakdown,
        activityMap: user.activityMap,
      ));
    }

    return students;
  });
});

final educatorLessonsProvider = StreamProvider<List<EducatorLesson>>((ref) {
  final lessonsAsync = ref.watch(allLessonsStreamProvider);
  final studentsAsync = ref.watch(educatorStudentsProvider);

  return lessonsAsync.when(
    data: (lessons) {
      return studentsAsync.when(
        data: (students) {
          return Stream.value(lessons.map((l) {
            final eduLesson = EducatorLesson.fromLesson(l);
            
            // Calculate real student count and completion rate
            final activeStudents = students.where((s) {
              return s.lessonBreakdown.any((lb) => lb.lessonTitle == l.title);
            }).toList();
            
            final completedStudents = activeStudents.where((s) {
              return s.lessonBreakdown.any((lb) => lb.lessonTitle == l.title && lb.status == 'Completed');
            }).toList();

            return eduLesson..studentCount = activeStudents.length
                           ..completionRate = activeStudents.isEmpty ? 0 : completedStudents.length / activeStudents.length;
          }).toList());
        },
        loading: () => Stream.value(lessons.map((l) => EducatorLesson.fromLesson(l)).toList()),
        error: (_, __) => Stream.value(lessons.map((l) => EducatorLesson.fromLesson(l)).toList()),
      );
    },
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
});
