import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumad_lingua/widgets/streak_reminder_settings_dialog.dart';

void main() {
  testWidgets('StreakReminderSettingsDialog renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StreakReminderSettingsDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('DAILY STREAK REMINDERS'), findsOneWidget);
    expect(find.text('REMINDER TIME'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
  });
}
