class AdminUser {
  final String id;
  String name;
  String email;
  String role; // 'admin', 'educator', 'validator', 'contributor', 'learner'
  String? indigenousGroup;
  int xp;
  String status; // 'active', 'suspended'
  String? suspensionReason;
  final DateTime joinedAt;
  final DateTime lastActive;
  final int totalContributions;

  String? photoURL;
  int streak;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.indigenousGroup,
    this.xp = 0,
    this.status = 'active',
    this.suspensionReason,
    DateTime? joinedAt,
    DateTime? lastActive,
    this.totalContributions = 0,
    this.photoURL,
    this.streak = 0,
  }) : joinedAt = joinedAt ?? DateTime.now(),
       lastActive = lastActive ?? DateTime.now();

  factory AdminUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AdminUser(
      id: id,
      name: data['username'] ?? data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      role: data['role'] ?? 'learner',
      indigenousGroup: data['indigenousGroup'],
      xp: data['xp'] ?? 0,
      status: data['status'] ?? 'active',
      suspensionReason: data['suspensionReason'],
      joinedAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      lastActive: data['lastLogin'] != null
          ? (data['lastLogin'] as dynamic).toDate()
          : DateTime.now(),
      totalContributions: data['wordCount'] ?? 0,
      photoURL: data['photoURL'],
      streak: data['streak'] ?? 0,
    );
  }
}

class ContentEntry {
  final String id;
  String term;
  String dialect;
  String partOfSpeech;
  String status; // 'pending', 'validated', 'rejected'
  String contributorName;
  String? rejectionReason;
  final DateTime submittedAt;

  ContentEntry({
    required this.id,
    required this.term,
    required this.dialect,
    required this.partOfSpeech,
    required this.status,
    required this.contributorName,
    this.rejectionReason,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();
}

class AuditLogEntry {
  final String action;
  final String actor;
  final String target;
  final DateTime timestamp;
  final String icon;

  const AuditLogEntry({
    required this.action,
    required this.actor,
    required this.target,
    required this.timestamp,
    this.icon = '🔧',
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}



