import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/widgets/streak_reminder_settings_dialog.dart';
import '../helpers/test_helpers.dart';

void main() {
  testWidgets('StreakReminderSettingsDialog renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestWidgetApp(
        home: const Scaffold(
          body: StreakReminderSettingsDialog(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Daily Streak Reminders'), findsOneWidget);
    expect(find.text('Reminder Time'), findsOneWidget);
    expect(find.text('SAVE & CLOSE'), findsOneWidget);
  });
}
