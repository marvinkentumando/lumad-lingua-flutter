class UserPreferences {
  final bool audioAutoplay;
  final bool hapticFeedback;
  final bool notificationsEnabled;
  final String preferredDialect;
  final String learningPathView;

  const UserPreferences({
    this.audioAutoplay = true,
    this.hapticFeedback = true,
    this.notificationsEnabled = true,
    this.preferredDialect = 'ALL',
    this.learningPathView = 'MOUNTAIN',
  });

  UserPreferences copyWith({
    bool? audioAutoplay,
    bool? hapticFeedback,
    bool? notificationsEnabled,
    String? preferredDialect,
    String? learningPathView,
  }) {
    return UserPreferences(
      audioAutoplay: audioAutoplay ?? this.audioAutoplay,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredDialect: preferredDialect ?? this.preferredDialect,
      learningPathView: learningPathView ?? this.learningPathView,
    );
  }

  Map<String, dynamic> toJson() => {
        'audioAutoplay': audioAutoplay,
        'hapticFeedback': hapticFeedback,
        'notificationsEnabled': notificationsEnabled,
        'preferredDialect': preferredDialect,
        'learningPathView': learningPathView,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        audioAutoplay: json['audioAutoplay'] ?? true,
        hapticFeedback: json['hapticFeedback'] ?? true,
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        preferredDialect: json['preferredDialect'] ?? 'ALL',
        learningPathView: json['learningPathView'] ?? 'MOUNTAIN',
      );
}
