import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumad_lingua/services/audio_service.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'test_helpers.dart';

void main() {
  group('TestHelpers Unit & Widget Verification', () {
    test('FakeAudioService methods operate without throwing exceptions', () async {
      final audio = FakeAudioService();

      await audio.playAmbientMusic('forest');
      expect(audio.lastAmbientTheme, equals('forest'));

      await audio.playSFX('success');
      expect(audio.lastSFXPlayed, equals('success'));

      await audio.playFromUrl('https://example.com/audio.mp3');
      expect(audio.lastPlayedUrl, equals('https://example.com/audio.mp3'));

      await audio.speak('Madyaw na buntag');
      expect(audio.lastSpokenText, equals('Madyaw na buntag'));

      await audio.startRecording();
      expect(audio.isRecording, isTrue);

      final recPath = await audio.stopRecording();
      expect(audio.isRecording, isFalse);
      expect(recPath, contains('recording.m4a'));
    });

    test('FakeAuthService returns configured user and empty auth state stream', () async {
      final auth = FakeAuthService();
      expect(auth.currentUser, isNull);

      final authState = await auth.authStateChanges.first;
      expect(authState, isNull);
    });

    testWidgets('createTestProviderScope provides overrides to descendant widgets', (tester) async {
      await tester.pumpWidget(
        createTestWidgetApp(
          home: Consumer(
            builder: (context, ref, child) {
              final audio = ref.watch(audioServiceProvider);
              final profile = ref.watch(userProfileProvider).value;

              return Column(
                children: [
                  Text('User: ${profile?['username']}'),
                  Text('IsFakeAudio: ${audio is FakeAudioService}'),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User: Test Warrior'), findsOneWidget);
      expect(find.text('IsFakeAudio: true'), findsOneWidget);
    });
  });
}
