import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

class UserPreferencesNotifier extends Notifier<UserPreferences> {
  static const String _prefKey = 'user_prefs';
  late SharedPreferences _prefs;

  @override
  UserPreferences build() {
    // Initial state is default, will be updated by init()
    // In Riverpod 2.0 Notifier, we can't easily wait for async in build()
    // but we can trigger a load.
    _loadInitial();
    return const UserPreferences();
  }

  Future<void> _loadInitial() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final jsonStr = _prefs.getString(_prefKey);
      if (jsonStr != null) {
        state = UserPreferences.fromJson(jsonDecode(jsonStr));
      }
    } catch (e) {
      // Fallback to default if corrupted or prefs fail
    }
  }

  Future<void> toggleAudioAutoplay() async {
    state = state.copyWith(audioAutoplay: !state.audioAutoplay);
    await _save();
  }

  Future<void> setHapticFeedback(bool enabled) async {
    state = state.copyWith(hapticFeedback: enabled);
    await _save();
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _save();
  }

  Future<void> setLearningPathView(String view) async {
    state = state.copyWith(learningPathView: view);
    await _save();
  }

  Future<void> completePreTest() async {
    state = state.copyWith(hasCompletedPreTest: true);
    await _save();
  }

  Future<void> setAppLanguage(String languageCode) async {
    state = state.copyWith(appLanguage: languageCode);
    await _save();
  }

  Future<void> _save() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setString(_prefKey, jsonEncode(state.toJson()));
    } catch (e) {
      // Silently fail or log
    }
  }
}

final userPreferencesProvider = NotifierProvider<UserPreferencesNotifier, UserPreferences>(
  UserPreferencesNotifier.new,
);
