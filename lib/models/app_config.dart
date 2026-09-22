class AppConfig {
  final int wordApprovalXp;
  final int lessonApprovalXp;
  final int voiceApprovalXp;
  final int lessonCompletionBaseXp;
  final int lessonTaskPerfectXp;
  final int lessonTaskRetryXp;
  final int cardReviewXp;
  final int cardCompletionBonusXp;
  final int xpPerLevel;
  final Map<String, String> notifications;
  final String artifactUnlockSfx;
  final int artifactUnlockParticleCount;
  final int artifactUnlockDuration;
  final String levelUpSfx;
  final int levelUpParticleDuration;

  final int streakRewardCycle;
  final Map<String, int> spiritThresholds;
  final String activePronunciationAlgorithm;
  final String activeSentimentAlgorithm;

  AppConfig({
    required this.wordApprovalXp,
    required this.lessonApprovalXp,
    required this.voiceApprovalXp,
    required this.lessonCompletionBaseXp,
    required this.lessonTaskPerfectXp,
    required this.lessonTaskRetryXp,
    required this.cardReviewXp,
    required this.cardCompletionBonusXp,
    required this.xpPerLevel,
    required this.notifications,
    required this.artifactUnlockSfx,
    required this.artifactUnlockParticleCount,
    required this.artifactUnlockDuration,
    required this.levelUpSfx,
    required this.levelUpParticleDuration,
    required this.streakRewardCycle,
    required this.spiritThresholds,
    required this.activePronunciationAlgorithm,
    required this.activeSentimentAlgorithm,
  });

  factory AppConfig.fromFirestore(Map<String, dynamic> data) {
    return AppConfig(
      wordApprovalXp: data['wordApprovalXp'] ?? 100,
      lessonApprovalXp: data['lessonApprovalXp'] ?? 500,
      voiceApprovalXp: data['voiceApprovalXp'] ?? 150,
      lessonCompletionBaseXp: data['lessonCompletionBaseXp'] ?? 50,
      lessonTaskPerfectXp: data['lessonTaskPerfectXp'] ?? 20,
      lessonTaskRetryXp: data['lessonTaskRetryXp'] ?? 10,
      cardReviewXp: data['cardReviewXp'] ?? 15,
      cardCompletionBonusXp: data['cardCompletionBonusXp'] ?? 10,
      xpPerLevel: data['xpPerLevel'] ?? 2000,
      notifications: Map<String, String>.from(data['notifications'] ?? {
        'word_approved_title': 'Entry Approved! 🌟',
        'word_approved_body': 'Your contribution "{term}" has been validated by a {role} and is now live.',
        'lesson_approved_title': 'Curriculum Approved! 📚',
        'lesson_approved_body': 'Your lesson "{title}" is now live for all students.',
        'voice_approved_title': 'Voice Recording Approved! 🎙️',
        'voice_approved_body': 'Your recording "{title}" has been validated and is now part of the ancestral archive.',
      }),
      artifactUnlockSfx: data['artifactUnlockSfx'] ?? 'milestone',
      artifactUnlockParticleCount: data['artifactUnlockParticleCount'] ?? 50,
      artifactUnlockDuration: data['artifactUnlockDuration'] ?? 4,
      levelUpSfx: data['levelUpSfx'] ?? 'level_up',
      levelUpParticleDuration: data['levelUpParticleDuration'] ?? 3,
      streakRewardCycle: data['streakRewardCycle'] ?? 7,
      spiritThresholds: Map<String, int>.from(data['spiritThresholds'] ?? {
        'Legend': 5000,
        'Elder': 2000,
        'Guardian': 1000,
        'Seeker': 500,
        'Novice': 0,
      }),
      activePronunciationAlgorithm: data['activePronunciationAlgorithm'] ?? 'dtw',
      activeSentimentAlgorithm: data['activeSentimentAlgorithm'] ?? 'naiveBayes',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'wordApprovalXp': wordApprovalXp,
      'lessonApprovalXp': lessonApprovalXp,
      'voiceApprovalXp': voiceApprovalXp,
      'lessonCompletionBaseXp': lessonCompletionBaseXp,
      'lessonTaskPerfectXp': lessonTaskPerfectXp,
      'lessonTaskRetryXp': lessonTaskRetryXp,
      'cardReviewXp': cardReviewXp,
      'cardCompletionBonusXp': cardCompletionBonusXp,
      'xpPerLevel': xpPerLevel,
      'notifications': notifications,
      'artifactUnlockSfx': artifactUnlockSfx,
      'artifactUnlockParticleCount': artifactUnlockParticleCount,
      'artifactUnlockDuration': artifactUnlockDuration,
      'levelUpSfx': levelUpSfx,
      'levelUpParticleDuration': levelUpParticleDuration,
      'streakRewardCycle': streakRewardCycle,
      'spiritThresholds': spiritThresholds,
      'activePronunciationAlgorithm': activePronunciationAlgorithm,
      'activeSentimentAlgorithm': activeSentimentAlgorithm,
    };
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
