import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    test('NotificationService singleton instance works', () {
      final instance1 = NotificationService();
      final instance2 = NotificationService();
      expect(instance1, same(instance2));
    });

    test('Notification IDs remain constant', () {
      expect(NotificationService.streakNotificationId, equals(100));
      expect(NotificationService.wotdNotificationId, equals(101));
    });
  });
}
