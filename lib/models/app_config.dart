class AppConfig {
  final int wordApprovalXp;
  final int lessonApprovalXp;
  final Map<String, String> notifications;
  final String artifactUnlockSfx;
  final int artifactUnlockParticleCount;
  final int artifactUnlockDuration;
  final String levelUpSfx;
  final int levelUpParticleDuration;

  AppConfig({
    required this.wordApprovalXp,
    required this.lessonApprovalXp,
    required this.notifications,
    required this.artifactUnlockSfx,
    required this.artifactUnlockParticleCount,
    required this.artifactUnlockDuration,
    required this.levelUpSfx,
    required this.levelUpParticleDuration,
  });

  factory AppConfig.fromFirestore(Map<String, dynamic> data) {
    return AppConfig(
      wordApprovalXp: data['wordApprovalXp'] ?? 100,
      lessonApprovalXp: data['lessonApprovalXp'] ?? 500,
      notifications: Map<String, String>.from(data['notifications'] ?? {
        'word_approved_title': 'Entry Approved! 🌟',
        'word_approved_body': 'Your contribution "{term}" has been validated by a {role} and is now live.',
        'lesson_approved_title': 'Curriculum Approved! 📚',
        'lesson_approved_body': 'Your lesson "{title}" is now live for all students.',
      }),
      artifactUnlockSfx: data['artifactUnlockSfx'] ?? 'milestone',
      artifactUnlockParticleCount: data['artifactUnlockParticleCount'] ?? 50,
      artifactUnlockDuration: data['artifactUnlockDuration'] ?? 4,
      levelUpSfx: data['levelUpSfx'] ?? 'level_up',
      levelUpParticleDuration: data['levelUpParticleDuration'] ?? 3,
    );
  }

  /// Helper to format notification messages
  String formatNotification(String key, Map<String, String> placeholders) {
    String template = notifications[key] ?? '';
    placeholders.forEach((k, v) {
      template = template.replaceAll('{$k}', v);
    });
    return template;
  }
}
