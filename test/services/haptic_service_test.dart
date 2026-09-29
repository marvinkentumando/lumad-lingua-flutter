import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/services/haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticService Exception Safety Tests', () {
    test('HapticService.success completes without throwing', () async {
      await expectLater(HapticService.success(), completes);
    });

    test('HapticService.error completes without throwing', () async {
      await expectLater(HapticService.error(), completes);
    });

    test('HapticService.warning completes without throwing', () async {
      await expectLater(HapticService.warning(), completes);
    });

    test('HapticService.combo completes without throwing', () async {
      await expectLater(HapticService.combo(), completes);
    });

    test('HapticService.heavy completes without throwing', () async {
      await expectLater(HapticService.heavy(), completes);
    });

    test('HapticService.medium completes without throwing', () async {
      await expectLater(HapticService.medium(), completes);
    });

    test('HapticService.light completes without throwing', () async {
      await expectLater(HapticService.light(), completes);
    });

    test('HapticService.selection completes without throwing', () async {
      await expectLater(HapticService.selection(), completes);
    });

    test('HapticService.toggle completes without throwing', () async {
      await expectLater(HapticService.toggle(), completes);
    });

    test('HapticService.delete completes without throwing', () async {
      await expectLater(HapticService.delete(), completes);
    });

    test('HapticService.salute completes without throwing', () async {
      await expectLater(HapticService.salute(), completes);
    });

    test('HapticService.celebration completes without throwing', () async {
      await expectLater(HapticService.celebration(), completes);
    });

    test('HapticService.buttonPress completes without throwing', () async {
      await expectLater(HapticService.buttonPress(), completes);
    });

    test('HapticService.levelUp completes without throwing', () async {
      await expectLater(HapticService.levelUp(), completes);
    });

    test('HapticService.artifactUnlock completes without throwing', () async {
      await expectLater(HapticService.artifactUnlock(), completes);
    });

    test('HapticService.navigation completes without throwing', () async {
      await expectLater(HapticService.navigation(), completes);
    });

    test('HapticService.streak completes without throwing', () async {
      await expectLater(HapticService.streak(), completes);
    });
  });
}
