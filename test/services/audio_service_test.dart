import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channels = [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
      'com.llfbandit.record/messages',
      'plugins.flutter.io/path_provider',
      'flutter_tts',
    ];

    for (final channelName in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel(channelName),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getTemporaryDirectory') {
            return '/fake/temp/path';
          }
          return null;
        },
      );
    }
  });

  group('AudioService Tests', () {
    test('AudioService initializes properly', () {
      final service = AudioService();
      expect(service, isNotNull);
    });

    test('AudioService SFX mapping operates without throwing', () async {
      final service = AudioService();
      // Should handle various sound effect triggers gracefully
      expect(() => service.playSFX('click'), returnsNormally);
      expect(() => service.playSFX('error'), returnsNormally);
      expect(() => service.playSFX('success'), returnsNormally);
    });
  });
}
