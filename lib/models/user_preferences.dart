class UserPreferences {
  final bool audioAutoplay;
  final bool hapticFeedback;
  final bool notificationsEnabled;
  final String preferredDialect;
  final String learningPathView;
  final bool hasCompletedPreTest;
  final String appLanguage; // 'en', 'tl', 'bis'
  final bool streakRemindersEnabled;
  final int streakReminderHour;
  final int streakReminderMinute;

  const UserPreferences({
    this.audioAutoplay = true,
    this.hapticFeedback = true,
    this.notificationsEnabled = true,
    this.preferredDialect = 'ALL',
    this.learningPathView = 'MOUNTAIN',
    this.hasCompletedPreTest = false,
    this.appLanguage = 'en',
    this.streakRemindersEnabled = true,
    this.streakReminderHour = 20, // Default 8:00 PM
    this.streakReminderMinute = 0,
  });

  UserPreferences copyWith({
    bool? audioAutoplay,
    bool? hapticFeedback,
    bool? notificationsEnabled,
    String? preferredDialect,
    String? learningPathView,
    bool? hasCompletedPreTest,
    String? appLanguage,
    bool? streakRemindersEnabled,
    int? streakReminderHour,
    int? streakReminderMinute,
  }) {
    return UserPreferences(
      audioAutoplay: audioAutoplay ?? this.audioAutoplay,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredDialect: preferredDialect ?? this.preferredDialect,
      learningPathView: learningPathView ?? this.learningPathView,
      hasCompletedPreTest: hasCompletedPreTest ?? this.hasCompletedPreTest,
      appLanguage: appLanguage ?? this.appLanguage,
      streakRemindersEnabled:
          streakRemindersEnabled ?? this.streakRemindersEnabled,
      streakReminderHour: streakReminderHour ?? this.streakReminderHour,
      streakReminderMinute: streakReminderMinute ?? this.streakReminderMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'audioAutoplay': audioAutoplay,
        'hapticFeedback': hapticFeedback,
        'notificationsEnabled': notificationsEnabled,
        'preferredDialect': preferredDialect,
        'learningPathView': learningPathView,
        'hasCompletedPreTest': hasCompletedPreTest,
        'appLanguage': appLanguage,
        'streakRemindersEnabled': streakRemindersEnabled,
        'streakReminderHour': streakReminderHour,
        'streakReminderMinute': streakReminderMinute,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        audioAutoplay: json['audioAutoplay'] ?? true,
        hapticFeedback: json['hapticFeedback'] ?? true,
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        preferredDialect: json['preferredDialect'] ?? 'ALL',
        learningPathView: json['learningPathView'] ?? 'MOUNTAIN',
        hasCompletedPreTest: json['hasCompletedPreTest'] ?? false,
        appLanguage: json['appLanguage'] ?? 'en',
        streakRemindersEnabled: json['streakRemindersEnabled'] ?? true,
        streakReminderHour: json['streakReminderHour'] ?? 20,
        streakReminderMinute: json['streakReminderMinute'] ?? 0,
      );
}
