import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
