import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumad_lingua/services/audio_service.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'package:lumad_lingua/services/offline_service.dart';
import 'package:lumad_lingua/providers/student_provider.dart';
import 'package:lumad_lingua/models/lesson_task.dart';

/// Lightweight fake implementation of [AudioService] for unit and widget tests.
/// Avoids invoking native platform channels (record, audioplayers, flutter_tts).
class FakeAudioService implements AudioService {
  String? lastPlayedUrl;
  String? lastSFXPlayed;
  String? lastSpokenText;
  String? lastAmbientTheme;
  bool isRecording = false;

  @override
  Future<void> playAmbientMusic(String theme) async {
    lastAmbientTheme = theme;
  }

  @override
  Future<void> stopAmbientMusic() async {}

  @override
  Future<void> playSFX(String type) async {
    lastSFXPlayed = type;
  }

  @override
  Future<void> startRecording() async {
    isRecording = true;
  }

  @override
  Future<String?> stopRecording() async {
    isRecording = false;
    return 'fake/path/recording.m4a';
  }

  @override
  Future<void> playRecording(String path) async {
    lastPlayedUrl = path;
  }

  @override
  Future<void> playFromUrl(String url) async {
    lastPlayedUrl = url;
  }

  @override
  Future<void> speak(String text) async {
    lastSpokenText = text;
  }

  @override
  Future<void> preCacheAudio(List<String> urls) async {}

  @override
  Future<bool> isAudioCached(String url) async => true;

  @override
  Future<void> preCacheLessonAudio(List<LessonTask> tasks) async {}

  @override
  Future<void> stopPlayback() async {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lightweight fake implementation of [AuthService] for unit and widget tests.
/// Avoids invoking native Firebase Auth or Firestore instances.
class FakeAuthService implements AuthService {
  User? mockUser;
  UserCredential? mockCredential;
  Object? signInWithGoogleError;
  bool signInWithGoogleCalled = false;

  FakeAuthService({
    this.mockUser,
    this.mockCredential,
    this.signInWithGoogleError,
  });

  @override
  User? get currentUser => mockUser;

  @override
  Stream<User?> get authStateChanges => Stream.value(mockUser);

  @override
  Future<UserCredential?> signInWithEmail(String email, String password) async => null;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    if (signInWithGoogleError != null) {
      throw signInWithGoogleError!;
    }
    return mockCredential;
  }

  @override
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String username, {
    String? location,
    String? tribe,
    String? avatar,
    String? nativeLanguage,
    String? learningGoal,
    String? villageCode,
    Map<String, dynamic>? assessment,
  }) async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> deleteUserAccount() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<bool> reloadUser() async => false;

  @override
  Future<bool> verifyPassword(String password) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lightweight fake implementation of [OfflineService] for unit and widget tests.
/// Avoids invoking Hive boxes or local database storage.
class FakeOfflineService implements OfflineService {
  @override
  Future<void> init() async {}

  @override
  Future<void> saveCachedStudentProfile(Map<String, dynamic> profile) async {}

  @override
  Future<Map<String, dynamic>?> getCachedStudentProfile() async => null;

  @override
  Future<void> queuePendingSyncAction(Map<String, dynamic> action) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lightweight fake implementation of [StudentNotifier] for unit and widget tests.
/// Avoids invoking Firebase Firestore streams or Hive local persistence.
class FakeStudentNotifier extends StudentNotifier {
  final StudentState? _initialState;

  FakeStudentNotifier([this._initialState]);

  @override
  StudentState build() {
    final initialState = _initialState;
    if (initialState != null) {
      return initialState;
    }
    final profile = ref.watch(userProfileProvider).value;
    if (profile != null) {
      return StudentState(
        mistCrystals: profile['mistCrystals'] ?? 50,
        xp: profile['xp'] ?? 100,
        dailyStreak: profile['streak'] ?? 3,
        hearts: profile['hearts'] ?? 5,
        streakShields: profile['streakShields'] ?? 0,
        lessonProgress: const {},
      );
    }
    return StudentState(
      mistCrystals: 50,
      xp: 100,
      dailyStreak: 3,
      hearts: 5,
      streakShields: 0,
      lessonProgress: const {},
    );
  }
}

/// Default mock user profile used for test ProviderScopes.
const Map<String, dynamic> kDefaultTestUserProfile = {
  'username': 'Test Warrior',
  'email': 'test@example.com',
  'role': 'learner',
  'xp': 100,
  'mistCrystals': 50,
  'streak': 3,
  'hearts': 5,
  'displayedStreak': 3,
  'lastActive': null,
  'streakRemindersEnabled': true,
  'streakReminderHour': 20,
  'streakReminderMinute': 0,
};

/// Constructs a [ProviderScope] configured with reusable test-side overrides
/// for [audioServiceProvider], [authServiceProvider], [authStateProvider],
/// [userProfileProvider], [offlineServiceProvider], and [studentProvider].
Widget createTestProviderScope({
  required Widget child,
  FakeAudioService? fakeAudioService,
  FakeAuthService? fakeAuthService,
  User? mockUser,
  Map<String, dynamic>? userProfile,
  bool isLoggedIn = true,
  List<Override> additionalOverrides = const [],
}) {
  final audioService = fakeAudioService ?? FakeAudioService();
  final authService = fakeAuthService ?? FakeAuthService(mockUser: mockUser);
  final profileData = isLoggedIn ? (userProfile ?? kDefaultTestUserProfile) : null;

  return ProviderScope(
    overrides: [
      audioServiceProvider.overrideWithValue(audioService),
      authServiceProvider.overrideWithValue(authService),
      authStateProvider.overrideWith((ref) => Stream.value(isLoggedIn ? mockUser : null)),
      userProfileProvider.overrideWith((ref) => Stream.value(profileData)),
      offlineServiceProvider.overrideWithValue(FakeOfflineService()),
      studentProvider.overrideWith(() => FakeStudentNotifier()),
      ...additionalOverrides,
    ],
    child: child,
  );
}

/// Constructs a [MaterialApp] wrapped inside a test [ProviderScope].
Widget createTestWidgetApp({
  required Widget home,
  FakeAudioService? fakeAudioService,
  FakeAuthService? fakeAuthService,
  User? mockUser,
  Map<String, dynamic>? userProfile,
  bool isLoggedIn = true,
  List<Override> additionalOverrides = const [],
}) {
  return createTestProviderScope(
    fakeAudioService: fakeAudioService,
    fakeAuthService: fakeAuthService,
    mockUser: mockUser,
    userProfile: userProfile,
    isLoggedIn: isLoggedIn,
    additionalOverrides: additionalOverrides,
    child: MaterialApp(
      home: home,
    ),
  );
}
