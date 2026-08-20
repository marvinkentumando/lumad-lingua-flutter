enum UserRole { learner, staff, educator, admin }

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final UserRole role;

  final int xp;
  final int level;
  final int streak;
  final int lives;

  final bool isPublicProfile;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.role = UserRole.learner,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.lives = 5,
    this.isPublicProfile = true,
  });
}



