class UserPreferences {
  final bool audioAutoplay;
  final bool hapticFeedback;
  final bool notificationsEnabled;
  final String preferredDialect;

  const UserPreferences({
    this.audioAutoplay = true,
    this.hapticFeedback = true,
    this.notificationsEnabled = true,
    this.preferredDialect = 'ALL',
  });

  UserPreferences copyWith({
    bool? audioAutoplay,
    bool? hapticFeedback,
    bool? notificationsEnabled,
    String? preferredDialect,
  }) {
    return UserPreferences(
      audioAutoplay: audioAutoplay ?? this.audioAutoplay,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredDialect: preferredDialect ?? this.preferredDialect,
    );
  }

  Map<String, dynamic> toJson() => {
        'audioAutoplay': audioAutoplay,
        'hapticFeedback': hapticFeedback,
        'notificationsEnabled': notificationsEnabled,
        'preferredDialect': preferredDialect,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        audioAutoplay: json['audioAutoplay'] ?? true,
        hapticFeedback: json['hapticFeedback'] ?? true,
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        preferredDialect: json['preferredDialect'] ?? 'ALL',
      );
}
