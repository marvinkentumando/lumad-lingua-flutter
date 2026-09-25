import 'dart:math';

class WarriorFriend {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final int xp;
  final int level;
  final int streak;
  final bool isOnline;
  final DateTime? lastActive;
  final String? location;

  WarriorFriend({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.xp,
    required this.level,
    required this.streak,
    required this.isOnline,
    this.lastActive,
    this.location,
  });

  factory WarriorFriend.fromFirestore(Map<String, dynamic> data, String id) {
    final xpVal = (data['xp'] as num?)?.toInt() ?? 0;
    final lvl = (sqrt(xpVal / 50)).floor() + 1;
    final streakVal = (data['streak'] as num?)?.toInt() ?? 0;
    final photo = data['photoURL'] ?? data['avatar'] ?? '👤';
    final nameVal = data['username'] ?? data['name'] ?? 'Tribe Member';

    DateTime? lastAct;
    if (data['lastLogin'] != null) {
      lastAct = (data['lastLogin'] as dynamic).toDate();
    } else if (data['lastActive'] != null) {
      lastAct = (data['lastActive'] as dynamic).toDate();
    }

    // Determine online status (active in the last 15 minutes)
    final bool online = lastAct != null &&
        DateTime.now().difference(lastAct).inMinutes < 15;

    return WarriorFriend(
      id: id,
      name: nameVal,
      email: data['email'] ?? '',
      avatar: photo,
      xp: xpVal,
      level: lvl,
      streak: streakVal,
      isOnline: online,
      lastActive: lastAct,
      location: data['location'] ?? data['municipality'],
    );
  }
}
