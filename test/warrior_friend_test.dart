import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/models/warrior_friend.dart';

void main() {
  group('WarriorFriend Model Tests', () {
    test('fromFirestore creates WarriorFriend correctly and computes level', () {
      final data = {
        'username': 'Datu Bago',
        'email': 'datu@bago.org',
        'photoURL': '👑',
        'xp': 450, // sqrt(450/50) = floor(3) + 1 = level 4
        'streak': 12,
        'location': 'Davao City',
      };

      final friend = WarriorFriend.fromFirestore(data, 'user_123');

      expect(friend.id, 'user_123');
      expect(friend.name, 'Datu Bago');
      expect(friend.email, 'datu@bago.org');
      expect(friend.avatar, '👑');
      expect(friend.xp, 450);
      expect(friend.level, 4);
      expect(friend.streak, 12);
      expect(friend.location, 'Davao City');
      expect(friend.isOnline, false);
    });

    test('isOnline evaluates to true when lastLogin is recent', () {
      final now = DateTime.now();
      final data = {
        'username': 'Bai Bibyaon',
        'xp': 1200,
        'streak': 30,
        'lastLogin': FakeTimestamp(now.subtract(const Duration(minutes: 5))),
      };

      final friend = WarriorFriend.fromFirestore(data, 'user_456');

      expect(friend.isOnline, true);
    });

    test('isOnline evaluates to false when lastLogin is stale', () {
      final now = DateTime.now();
      final data = {
        'username': 'Bai Bibyaon',
        'xp': 1200,
        'streak': 30,
        'lastLogin': FakeTimestamp(now.subtract(const Duration(hours: 2))),
      };

      final friend = WarriorFriend.fromFirestore(data, 'user_456');

      expect(friend.isOnline, false);
    });
  });
}

class FakeTimestamp {
  final DateTime date;
  FakeTimestamp(this.date);

  DateTime toDate() => date;
}
