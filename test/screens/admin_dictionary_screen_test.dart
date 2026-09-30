import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumad_lingua/widgets/admin/import_dictionary_modal.dart';

void main() {
  group('Admin Dictionary & CSV Import Modal Tests', () {
    testWidgets('ImportDictionaryModal documents the phonetic IPA column and requirements', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ImportDictionaryModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CSV FORMAT REQUIREMENTS'), findsOneWidget);
      expect(
        find.textContaining('Columns: term, pos, dialect, definition, example_native, example_translation, phonetic'),
        findsOneWidget,
      );
      expect(
        find.textContaining('phonetic column: Optional validated IPA transcription'),
        findsOneWidget,
      );
      expect(
        find.textContaining('IPA must come from validated linguistic/native-speaker sources'),
        findsOneWidget,
      );
    });
  });
}
