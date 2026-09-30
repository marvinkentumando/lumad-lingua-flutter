import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/widgets/claim_reward_modal.dart';
import '../helpers/test_helpers.dart';

void main() {
  testWidgets('ClaimRewardModal renders title, rewards, and claim button', (WidgetTester tester) async {
    final fakeAudioService = FakeAudioService();

    await tester.pumpWidget(
      createTestWidgetApp(
        fakeAudioService: fakeAudioService,
        home: const Scaffold(
          body: ClaimRewardModal(
            title: 'Quest Completed!',
            subtitle: 'Daily Challenge Accomplished',
            crystalsReward: 50,
            xpReward: 100,
          ),
        ),
      ),
    );

    // Pump duration long enough for delayMs + TweenAnimationBuilder to complete
    await tester.pump(const Duration(milliseconds: 2500));

    expect(find.text('Quest Completed!'), findsOneWidget);
    expect(find.text('Daily Challenge Accomplished'), findsOneWidget);
    expect(find.text('+50'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('CLAIM'), findsOneWidget);
  });
}
