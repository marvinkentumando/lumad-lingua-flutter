import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lumad_lingua/models/daily_challenge.dart';
import 'package:lumad_lingua/models/lesson.dart';
import 'package:lumad_lingua/models/lesson_task.dart';
import 'package:lumad_lingua/providers/daily_challenge_provider.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import 'package:lumad_lingua/utils/app_localization.dart';
import 'package:lumad_lingua/widgets/learning_next_action_card.dart';

class TestLearner extends Fake implements User {
  @override
  String get uid => 'learner';
}

void main() {
  const task = LessonTask(id: 'word', type: TaskType.vocabulary, questionText: 'Learn');
  final lesson = Lesson(id: 'lesson', title: 'Greetings', description: '',
    category: 'Basics', language: 'Mansaka', level: 1, unitNumber: 1, tasks: [task]);

  Future<GoRouter> showCard(WidgetTester tester, {int due = 0,
      DailyChallenge? challenge, bool completed = false,
      Stream<List<Lesson>>? lessonStream}) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(
        body: SingleChildScrollView(child: LearningNextActionCard()))),
      GoRoute(path: '/lesson_session', builder: (_, state) =>
        Scaffold(body: Text('Lesson: ${state.uri.queryParameters['lessonId']}'))),
      GoRoute(path: '/flashcards', builder: (_, state) =>
        Scaffold(body: Text('Flashcards: ${state.uri.queryParameters['mode']}'))),
      GoRoute(path: '/daily-challenge', builder: (_, state) =>
        Scaffold(body: Text('Goal: ${(state.extra as DailyChallenge).id}'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      localizationProvider.overrideWithValue(AppLocalization('en')),
      authStateProvider.overrideWith((ref) => Stream.value(TestLearner())),
      userProfileProvider.overrideWith((ref) => Stream.value({
        'completedChallenges': completed && challenge != null ? [challenge.id] : <String>[],
      })),
      userProgressStreamProvider('learner').overrideWith((ref) => Stream.value({})),
      dueSRSCountProvider('learner').overrideWith((ref) => Stream.value(due)),
      lessonsStreamProvider.overrideWith((ref) => lessonStream ?? Stream.value([lesson])),
      dailyChallengeProvider.overrideWith((ref) async => challenge),
    ], child: MaterialApp.router(routerConfig: router)));
    return router;
  }

  testWidgets('new learner sees one main action that opens the recommended lesson', (tester) async {
    await showCard(tester);
    await tester.pumpAndSettle();
    expect(find.text('Mansaka · Greetings'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('learning-next-action')));
    await tester.pumpAndSettle();
    expect(find.text('Lesson: lesson'), findsOneWidget);
  });

  testWidgets('due review action opens review mode', (tester) async {
    await showCard(tester, due: 4);
    await tester.pumpAndSettle();
    expect(find.text('Review words'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('learning-next-action')));
    await tester.pumpAndSettle();
    expect(find.text('Flashcards: review'), findsOneWidget);
  });

  testWidgets('daily goal passes the actual challenge into the route', (tester) async {
    await showCard(tester, challenge: DailyChallenge(id: 'today', tasks: [task]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('learning-next-action')));
    await tester.pumpAndSettle();
    expect(find.text('Goal: today'), findsOneWidget);
  });

  testWidgets('pending lesson data does not offer a misleading first lesson', (tester) async {
    await showCard(tester, lessonStream: const Stream<List<Lesson>>.empty());
    await tester.pump();
    expect(find.byKey(const ValueKey('learning-next-action')), findsNothing);
  });

  testWidgets('lesson errors provide recovery instead of a broken recommendation', (tester) async {
    await showCard(tester, lessonStream: Stream.error(Exception('offline')));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byKey(const ValueKey('learning-next-action')), findsNothing);
  });
}
