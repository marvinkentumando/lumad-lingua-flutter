import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumad_lingua/widgets/phonetic_guide_widget.dart';
import 'package:lumad_lingua/services/audio_service.dart';

class FakeAudioService implements AudioService {
  String? lastPlayedUrl;

  @override
  Future<void> playFromUrl(String url) async {
    lastPlayedUrl = url;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAudioService fakeAudioService;

  setUp(() {
    fakeAudioService = FakeAudioService();
  });

  Widget buildTestWidget({
    required String? phonetic,
    String? audioUrl,
    String indigenousWord = 'Buntag',
    bool isDark = false,
  }) {
    return ProviderScope(
      overrides: [
        audioServiceProvider.overrideWithValue(fakeAudioService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhoneticGuideWidget(
              phonetic: phonetic,
              audioUrl: audioUrl,
              indigenousWord: indigenousWord,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }

  group('PhoneticGuideWidget Tests', () {
    testWidgets('1 & 2. Renders valid IPA guide with multiple syllable chips', (tester) async {
      await tester.pumpWidget(buildTestWidget(phonetic: '/mɐŋ.sɐ.kɐ/'));
      await tester.pumpAndSettle();

      expect(find.text('PRONUNCIATION (IPA GUIDE)'), findsOneWidget);
      expect(find.text('/mɐŋ/'), findsOneWidget);
      expect(find.text('/sɐ/'), findsOneWidget);
      expect(find.text('/kɐ/'), findsOneWidget);
    });

    testWidgets('3. Single syllable displays correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(phonetic: '/bʊn/'));
      await tester.pumpAndSettle();

      expect(find.text('/bʊn/'), findsOneWidget);
    });

    testWidgets('4 & 5. Tapping a syllable opens the IPA tooltip with selected syllable', (tester) async {
      await tester.pumpWidget(buildTestWidget(phonetic: '/mɐŋ.sɐ.kɐ/'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('/mɐŋ/'));
      await tester.pumpAndSettle();

      expect(find.text('IPA SYLLABLE GUIDANCE'), findsOneWidget);
      expect(find.text('/mɐŋ/'), findsWidgets); // Found in chip and header
      expect(find.text('DETECTED IPA SYMBOLS'), findsOneWidget);
    });

    testWidgets('6. Supported IPA symbols display their descriptions', (tester) async {
      await tester.pumpWidget(buildTestWidget(phonetic: '/mɐŋ/'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('/mɐŋ/'));
      await tester.pumpAndSettle();

      expect(find.text('ng sound as in \'sing\''), findsOneWidget);
      expect(find.text('bilabial nasal, as in \'man\''), findsOneWidget);
    });

    testWidgets('7. Unsupported symbols do not cause an exception', (tester) async {
      await tester.pumpWidget(buildTestWidget(phonetic: '/mðq/'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('/mðq/'));
      await tester.pumpAndSettle();

      expect(find.text('IPA SYLLABLE GUIDANCE'), findsOneWidget);
      expect(find.text('Pronunciation symbol (standard guide unavailable)'), findsNWidgets(2));
    });

    testWidgets('8. Missing/null phonetic data renders nothing', (tester) async {
      await tester.pumpWidget(buildTestWidget(phonetic: null));
      await tester.pumpAndSettle();

      expect(find.text('PRONUNCIATION (IPA GUIDE)'), findsNothing);
      expect(find.text('IPA guide unavailable for this entry'), findsNothing);

      await tester.pumpWidget(buildTestWidget(phonetic: '  '));
      await tester.pumpAndSettle();

      expect(find.text('PRONUNCIATION (IPA GUIDE)'), findsNothing);
      expect(find.text('IPA guide unavailable for this entry'), findsNothing);
    });

    testWidgets('9. Missing audioUrl does not cause an exception in tooltip', (tester) async {
      await tester.pumpWidget(buildTestWidget(phonetic: '/mɐŋ/', audioUrl: null));
      await tester.pumpAndSettle();

      await tester.tap(find.text('/mɐŋ/'));
      await tester.pumpAndSettle();

      expect(find.text('No reference recording is currently attached for this entry.'), findsOneWidget);
    });

    testWidgets('10. Existing native/full-word audio can be triggered from tooltip', (tester) async {
      const sampleAudioUrl = 'https://example.com/audio/buntag.mp3';
      await tester.pumpWidget(buildTestWidget(
        phonetic: '/bʊn.tɐɡ/',
        audioUrl: sampleAudioUrl,
        indigenousWord: 'Buntag',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('/bʊn/'));
      await tester.pumpAndSettle();

      final playButton = find.text('Native Reference Audio ("Buntag")');
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      await tester.pump();

      expect(fakeAudioService.lastPlayedUrl, equals(sampleAudioUrl));
    });
  });
}
