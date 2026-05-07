class ValidatorStats {
  final int pendingEntries;
  final int pendingVoices;
  final int pendingLessons;
  final int todayVerified;
  final int dailyGoal;
  final String trustScore;
  final String currentRank;

  const ValidatorStats({
    this.pendingEntries = 0,
    this.pendingVoices = 0,
    this.pendingLessons = 0,
    this.todayVerified = 0,
    this.dailyGoal = 20,
    this.trustScore = 'A+',
    this.currentRank = 'Guardian',
  });

  int get totalPending => pendingEntries + pendingVoices + pendingLessons;
  double get goalProgress => (todayVerified / dailyGoal).clamp(0.0, 1.0);
}

class ValidationItem {
  final String id;
  final String type; // 'entry', 'voice', 'lesson'
  final String title;
  final String subtitle;
  final String dialect;
  final String contributor;
  final DateTime submittedAt;
  final String priority; // 'normal', 'high'

  const ValidationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.dialect,
    required this.contributor,
    required this.submittedAt,
    this.priority = 'normal',
  });
}



