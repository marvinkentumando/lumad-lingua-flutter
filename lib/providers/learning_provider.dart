import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_task.dart';
import '../models/lesson.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../providers/artifact_provider.dart';
import '../services/offline_service.dart';

// ── Lesson Loader Provider (moved here from lesson_session_screen.dart) ──────
final currentLessonProvider = FutureProvider.family<Lesson?, String>((
  ref,
  lessonId,
) async {
  return ref.read(firebaseServiceProvider).getLessonById(lessonId);
});

final cachedLessonIdsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(offlineServiceProvider).watchCachedLessons().map((lessons) {
    return lessons.map((l) => l.id).toSet();
  });
});

final latestLessonProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const AsyncValue.data({});

  final progressAsync = ref.watch(userProgressStreamProvider(user.uid));

  return progressAsync.when(
    data: (progressMap) {
      if (progressMap.isEmpty) return const AsyncValue.data({});

      String? latestId;
      DateTime? latestTime;
      Map<String, dynamic>? latestData;

      progressMap.forEach((id, data) {
        final ts = data['lastAttempt'] as Timestamp?;
        if (ts != null) {
          final time = ts.toDate();
          if (latestTime == null || time.isAfter(latestTime!)) {
            latestTime = time;
            latestId = id;
            latestData = data;
          }
        }
      });

      if (latestId == null) return const AsyncValue.data({});

      return AsyncValue.data({
        'id': latestId,
        'data': latestData,
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final latestLessonDetailsProvider = FutureProvider<Lesson?>((ref) async {
  final latest = ref.watch(latestLessonProvider).value;
  if (latest == null || latest['id'] == null) return null;
  return ref.read(firebaseServiceProvider).getLessonById(latest['id']);
});

// Global XP state
class XpNotifier extends Notifier<int> {
  @override
  int build() {
    // Listen to the user profile and update the state when the profile changes
    final profile = ref.watch(userProfileProvider).value;
    return profile?['xp'] ?? 0;
  }

  Future<void> addXP(int points) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      int finalPoints = points;

      // Apply Passive Bonuses from Artifacts
      final artifacts = ref.read(userArtifactsProvider).value ?? [];
      for (var artifact in artifacts) {
        if (artifact.isEarned &&
            artifact.passiveBonus != null &&
            artifact.passiveBonus!.contains('+5% XP')) {
          finalPoints = (finalPoints * 1.05).round();
        }
      }

      await ref.read(firebaseServiceProvider).addXp(user.uid, finalPoints);
    }
  }
}

final xpProvider = NotifierProvider<XpNotifier, int>(() => XpNotifier());

// Current Quiz Session State
class QuizSessionState {
  final List<LessonTask> queue;
  final LessonTask? currentTask;
  final int totalTasks;
  final int completedCount;
  final int firstTryStreak;
  final bool isCompleted;

  QuizSessionState({
    required this.queue,
    this.currentTask,
    required this.totalTasks,
    required this.completedCount,
    this.firstTryStreak = 0,
    this.isCompleted = false,
  });

  QuizSessionState copyWith({
    List<LessonTask>? queue,
    LessonTask? currentTask,
    int? totalTasks,
    int? completedCount,
    int? firstTryStreak,
    bool? isCompleted,
  }) {
    return QuizSessionState(
      queue: queue ?? this.queue,
      currentTask: currentTask ?? this.currentTask,
      totalTasks: totalTasks ?? this.totalTasks,
      completedCount: completedCount ?? this.completedCount,
      firstTryStreak: firstTryStreak ?? this.firstTryStreak,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class QuizSessionNotifier extends Notifier<QuizSessionState> {
  @override
  QuizSessionState build() {
    return QuizSessionState(queue: [], totalTasks: 0, completedCount: 0);
  }

  void loadTasks(List<LessonTask> tasks) {
    state = QuizSessionState(
      queue: List.from(tasks),
      currentTask: tasks.isNotEmpty ? tasks.first : null,
      totalTasks: tasks.length,
      completedCount: 0,
    );
  }

  /// [logicalTaskId] is the original task ID before any adaptive difficulty rename
  /// (e.g., the task upgraded to `id_harder` should still record mistakes under `id`).
  bool submitAnswer(
    bool isCorrect, {
    bool isFirstTry = true,
    String? logicalTaskId,
  }) {
    if (state.currentTask == null) return false;

    List<LessonTask> newQueue = List.from(state.queue);

    // Track streak for adaptive difficulty
    int newStreak = isCorrect && isFirstTry ? state.firstTryStreak + 1 : 0;

    // Adaptive Difficulty: If streak hits 3, upgrade the next MCQ task in queue if possible.
    // Fix #18: Preserve the original task ID via `logicalTaskId` when upgrading.
    if (newStreak >= 3) {
      for (int i = 0; i < newQueue.length; i++) {
        if (newQueue[i].type == TaskType.multipleChoice && i > 0) {
          final task = newQueue[i];
          final correctText = task.options[task.correctAnswerIndex];

          if (correctText.contains(' ') && correctText.split(' ').length >= 3) {
            // Keep the original ID so _taskMistakes always keys off the source task.
            newQueue[i] = LessonTask(
              id: task
                  .id, // ← Fix #18: Use original ID, NOT '${task.id}_harder'
              type: TaskType.sentenceReordering,
              questionText: 'Reconstruct the correct translation:',
              sentenceParts: List.from(correctText.split(' '))..shuffle(),
              expectedSentence: correctText,
              hintMetadata: task.hintMetadata,
            );
            newStreak = 0;
            break;
          }
        }
      }
    }

    // Always remove from current front
    if (newQueue.isNotEmpty) {
      newQueue.removeAt(0);
    }

    if (!isCorrect) {
      // Re-inject failed task back into the queue for spaced-repetition loop.
      // Insert at index 3 so the user sees it again soon, but not immediately.
      final insertIndex = newQueue.length > 3 ? 3 : newQueue.length;
      newQueue.insert(insertIndex, state.currentTask!);
    }

    int updatedCompleted = isCorrect
        ? state.completedCount + 1
        : state.completedCount;
    bool completed = updatedCompleted == state.totalTasks && newQueue.isEmpty;

    state = state.copyWith(
      queue: newQueue,
      currentTask: newQueue.isNotEmpty ? newQueue.first : null,
      completedCount: updatedCompleted,
      firstTryStreak: newStreak,
      isCompleted: completed,
    );

    return isCorrect;
  }
}

final quizSessionProvider =
    NotifierProvider<QuizSessionNotifier, QuizSessionState>(() {
      return QuizSessionNotifier();
    });



