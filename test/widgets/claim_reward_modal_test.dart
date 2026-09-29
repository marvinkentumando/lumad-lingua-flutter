import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumad_lingua/widgets/claim_reward_modal.dart';

void main() {
  testWidgets('ClaimRewardModal renders title, rewards, and claim button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ClaimRewardModal(
              title: 'Quest Completed!',
              subtitle: 'Daily Challenge Accomplished',
              crystalsReward: 50,
              xpReward: 100,
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Quest Completed!'), findsOneWidget);
    expect(find.text('+50'), findsOneWidget);
    expect(find.text('+100 XP'), findsOneWidget);
    expect(find.text('CLAIM REWARD 🌿'), findsOneWidget);
  });
}
