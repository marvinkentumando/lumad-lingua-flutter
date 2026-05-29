class AdminUser {
  final String id;
  String name;
  String email;
  String role; // 'admin', 'educator', 'validator', 'contributor', 'learner'
  String? indigenousGroup;
  String? municipality;
  int xp;
  String status; // 'active', 'suspended'
  String? suspensionReason;
  final DateTime joinedAt;
  final DateTime lastActive;
  final int totalContributions;

  String? photoURL;
  int streak;
  Map<String, bool> activityMap;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.indigenousGroup,
    this.municipality,
    this.xp = 0,
    this.status = 'active',
    this.suspensionReason,
    DateTime? joinedAt,
    DateTime? lastActive,
    this.totalContributions = 0,
    this.photoURL,
    this.streak = 0,
    this.activityMap = const {},
  }) : joinedAt = joinedAt ?? DateTime.now(),
       lastActive = lastActive ?? DateTime.now();

  factory AdminUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AdminUser(
      id: id,
      name: data['username'] ?? data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      role: data['role'] ?? 'learner',
      indigenousGroup: data['indigenousGroup'] ?? data['dialect'],
      municipality: data['municipality'],
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
      activityMap: Map<String, bool>.from(data['activityMap'] ?? {}),
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
  final String id;
  final String action;
  final String actorId;
  final String actorName;
  final String targetId;
  final String targetName;
  final String targetType; // 'word', 'voice', 'lesson', 'scenario'
  final DateTime timestamp;
  final String icon;
  final Map<String, dynamic>? metadata;

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.targetId,
    required this.targetName,
    required this.targetType,
    required this.timestamp,
    this.icon = '🔧',
    this.metadata,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  factory AuditLogEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return AuditLogEntry(
      id: id,
      action: data['action'] ?? '',
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? 'Unknown',
      targetId: data['targetId'] ?? '',
      targetName: data['targetName'] ?? 'Unknown',
      targetType: data['targetType'] ?? 'unknown',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as dynamic).toDate()
          : DateTime.now(),
      icon: data['icon'] ?? '🔧',
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'actorId': actorId,
      'actorName': actorName,
      'targetId': targetId,
      'targetName': targetName,
      'targetType': targetType,
      'timestamp': timestamp,
      'icon': icon,
      if (metadata != null) 'metadata': metadata,
    };
  }
}



