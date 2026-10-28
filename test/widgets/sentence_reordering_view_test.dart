import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/widgets/activity_views/sentence_reordering_view.dart';

void main() {
  testWidgets('SentenceReorderingView handles duplicate words correctly by index', (tester) async {
    final available = ['madyaw', 'na', 'madyaw'];
    final scrambled = <String>[];
    int? tappedIndex;
    String? tappedWord;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SentenceReorderingView(
                question: 'Translate: Very good',
                scrambledParts: scrambled,
                availableParts: available,
                onWordTap: (index, word) {
                  tappedIndex = index;
                  tappedWord = word;
                  setState(() {
                    if (index >= 0 && index < available.length && available[index] == word) {
                      available.removeAt(index);
                    }
                    scrambled.add(word);
                  });
                },
                onScrambledWordTap: (index, word) {
                  setState(() {
                    if (index >= 0 && index < scrambled.length && scrambled[index] == word) {
                      scrambled.removeAt(index);
                    }
                    available.add(word);
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // Verify initial render: 3 available chips
    expect(find.text('madyaw'), findsNWidgets(2));
    expect(find.text('na'), findsOneWidget);

    // Tap the SECOND duplicate word ("madyaw" at index 2)
    final madyawFinders = find.text('madyaw');
    await tester.tap(madyawFinders.at(1));
    await tester.pumpAndSettle();

    expect(tappedIndex, equals(2));
    expect(tappedWord, equals('madyaw'));
    expect(scrambled, equals(['madyaw']));
    expect(available, equals(['madyaw', 'na']));

    // Tap "na" (now at index 1 of available)
    await tester.tap(find.text('na'));
    await tester.pumpAndSettle();

    expect(tappedIndex, equals(1));
    expect(tappedWord, equals('na'));
    expect(scrambled, equals(['madyaw', 'na']));
    expect(available, equals(['madyaw']));

    // Tap remaining "madyaw" (now at index 0 of available)
    await tester.tap(find.text('madyaw').at(1)); // 0 in available, 0 in scrambled -> second widget in tree is available chip
    await tester.pumpAndSettle();

    expect(tappedIndex, equals(0));
    expect(scrambled, equals(['madyaw', 'na', 'madyaw']));
    expect(available, isEmpty);
  });
}
