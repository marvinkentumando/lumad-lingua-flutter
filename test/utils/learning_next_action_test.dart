import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/models/daily_challenge.dart';
import 'package:lumad_lingua/models/lesson.dart';
import 'package:lumad_lingua/models/lesson_task.dart';
import 'package:lumad_lingua/utils/learning_next_action.dart';

const task = LessonTask(id: 'task', type: TaskType.vocabulary, questionText: 'Learn');
Lesson lesson(String id, {int unit = 1, String? prerequisite, String language = 'Mansaka',
    String status = 'PUBLISHED', bool empty = false}) => Lesson(
  id: id, title: id, description: '', category: 'Basics', language: language,
  level: 1, unitNumber: unit, tasks: empty ? [] : [task],
  prerequisiteId: prerequisite, status: status,
);

void main() {
  final challenge = DailyChallenge(id: 'today', tasks: [task]);
  LearningNextAction select({List<Lesson> lessons = const [],
      Map<String, dynamic> progress = const {}, int due = 0,
      DailyChallenge? daily, bool completed = false}) => selectLearningNextAction(
    lessons: lessons, progress: progress, dueCount: due,
    challenge: daily, challengeCompleted: completed,
  );

  test('continues the most recent unfinished lesson before reviews and goals', () {
    final result = select(lessons: [lesson('old'), lesson('recent')], progress: {
      'old': {'lastAttempt': Timestamp.fromDate(DateTime(2026, 1, 1))},
      'recent': {'lastAttempt': '2026-01-02', 'completed': false},
    }, due: 4, daily: challenge);
    expect(result.type, LearningNextActionType.resume);
    expect(result.lesson?.id, 'recent');
  });

  test('reviews due words before offering a new lesson or daily goal', () {
    final result = select(lessons: [lesson('new')], due: 3, daily: challenge);
    expect(result.type, LearningNextActionType.review);
    expect(result.dueCount, 3);
    expect(result.location, '/flashcards?mode=review');
  });

  test('offers an available daily goal and preserves its route payload', () {
    final result = select(daily: challenge);
    expect(result.type, LearningNextActionType.dailyGoal);
    expect(result.challenge, same(challenge));
    expect(result.location, '/daily-challenge');
  });

  test('does not repeat completed or empty daily challenges', () {
    expect(select(daily: challenge, completed: true).type, LearningNextActionType.explore);
    expect(select(daily: DailyChallenge(id: 'today', tasks: [])).type,
      LearningNextActionType.explore);
  });

  test('starts the first playable lesson in order without mutating input', () {
    final input = [lesson('second', unit: 2), lesson('first')];
    final result = select(lessons: input);
    expect(result.lesson?.id, 'first');
    expect(result.hasProgress, isFalse);
    expect(input.first.id, 'second');
  });

  test('completion unlocks next lesson even below a perfect score', () {
    final result = select(lessons: [lesson('one'), lesson('two', prerequisite: 'one')],
      progress: {'one': {'completed': true, 'bestScore': 60}});
    expect(result.type, LearningNextActionType.lesson);
    expect(result.lesson?.id, 'two');
    expect(result.hasProgress, isTrue);
  });

  test('never resumes a locked lesson or offers unpublished or empty content', () {
    final result = select(lessons: [
      lesson('locked', prerequisite: 'missing'),
      lesson('draft', status: 'DRAFT'), lesson('empty', empty: true),
    ], progress: {'locked': {'lastAttempt': DateTime(2026)}});
    expect(result.type, LearningNextActionType.explore);
    expect(result.location, '/dictionary');
  });

  test('continues the most recently studied language', () {
    final result = select(lessons: [
      lesson('other', language: 'A language'),
      lesson('done'), lesson('next', unit: 2, prerequisite: 'done'),
    ], progress: {'done': {'completed': true, 'lastAttempt': DateTime(2026)}});
    expect(result.lesson?.id, 'next');
  });

  test('uses a safe fallback when all lessons are completed', () {
    final result = select(lessons: [lesson('done')],
      progress: {'done': {'completed': true}});
    expect(result.type, LearningNextActionType.explore);
  });

  test('lesson navigation encodes the selected ID', () {
    final result = select(lessons: [lesson('a/b & c')]);
    final uri = Uri.parse(result.location);
    expect(uri.path, '/lesson_session');
    expect(uri.queryParameters['lessonId'], 'a/b & c');
  });
}
