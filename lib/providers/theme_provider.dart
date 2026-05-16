import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  // We keep the method signatures to avoid breaking calls, but disable the toggle logic
  void toggleTheme() {
    // Disabled: App is now Dark Mode only
  }

  void setTheme(ThemeMode mode) {
    // Disabled: App is now Dark Mode only
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
