import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_challenge.dart';
import '../models/lesson.dart';

enum LearningNextActionType { resume, review, dailyGoal, lesson, explore }

class LearningNextAction {
  final LearningNextActionType type;
  final Lesson? lesson;
  final DailyChallenge? challenge;
  final int dueCount;
  final bool hasProgress;

  const LearningNextAction(this.type, {
    this.lesson,
    this.challenge,
    this.dueCount = 0,
    this.hasProgress = false,
  });

  String get location => switch (type) {
    LearningNextActionType.resume || LearningNextActionType.lesson =>
      Uri(path: '/lesson_session', queryParameters: {'lessonId': lesson!.id}).toString(),
    LearningNextActionType.review => '/flashcards?mode=review',
    LearningNextActionType.dailyGoal => '/daily-challenge',
    LearningNextActionType.explore => '/dictionary',
  };
}

/// Selects one activity without mutating the published lesson list.
/// Completion and prerequisite rules match the learning path screen.
LearningNextAction selectLearningNextAction({
  required List<Lesson> lessons,
  required Map<String, dynamic> progress,
  required int dueCount,
  required DailyChallenge? challenge,
  required bool challengeCompleted,
}) {
  DateTime? lastAttempt(Lesson lesson) {
    final value = progress[lesson.id]?['lastAttempt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool unlocked(Lesson lesson) =>
      lesson.prerequisiteId == null ||
      lesson.prerequisiteId!.isEmpty ||
      progress[lesson.prerequisiteId]?['completed'] == true;

  final playable = lessons.where((l) =>
      l.status == 'PUBLISHED' && l.tasks.isNotEmpty).toList();
  final unfinished = playable.where((l) =>
      unlocked(l) && progress[l.id]?['completed'] != true).toList();
  final attempted = unfinished.where((l) => lastAttempt(l) != null).toList()
    ..sort((a, b) => lastAttempt(b)!.compareTo(lastAttempt(a)!));
  if (attempted.isNotEmpty) {
    return LearningNextAction(LearningNextActionType.resume, lesson: attempted.first);
  }
  if (dueCount > 0) {
    return LearningNextAction(LearningNextActionType.review, dueCount: dueCount);
  }
  if (!challengeCompleted && challenge != null && challenge.tasks.isNotEmpty) {
    return LearningNextAction(LearningNextActionType.dailyGoal, challenge: challenge);
  }

  // Stay on the most recently studied language when there are multiple paths.
  final studied = playable.where((l) => lastAttempt(l) != null).toList()
    ..sort((a, b) => lastAttempt(b)!.compareTo(lastAttempt(a)!));
  final language = studied.isEmpty ? null : studied.first.language;
  unfinished.sort((a, b) {
    final preferred = (a.language == language ? 0 : 1)
        .compareTo(b.language == language ? 0 : 1);
    if (preferred != 0) return preferred;
    final languageOrder = a.language.compareTo(b.language);
    if (languageOrder != 0) return languageOrder;
    final unit = a.unitNumber.compareTo(b.unitNumber);
    if (unit != 0) return unit;
    final level = a.level.compareTo(b.level);
    return level != 0 ? level : a.id.compareTo(b.id);
  });
  if (unfinished.isNotEmpty) {
    return LearningNextAction(LearningNextActionType.lesson,
      lesson: unfinished.first, hasProgress: progress.isNotEmpty);
  }
  return const LearningNextAction(LearningNextActionType.explore);
}
