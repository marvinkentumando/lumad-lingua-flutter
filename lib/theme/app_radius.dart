import 'package:flutter/material.dart';

/// Standardized border radius tokens across the Lumad Lingua application.
abstract class AppRadius {
  /// Standard border radius for cards & content containers (20.0)
  static const double card = 20.0;

  /// Standard border radius for bottom sheets, dialogs & modals (28.0)
  static const double modal = 28.0;

  /// Standard border radius for chips, badges, tags & small pills (12.0)
  static const double chip = 12.0;

  /// Standard border radius for buttons & text field inputs (16.0)
  static const double button = 16.0;

  /// Standard border radius for small indicators & badges (8.0)
  static const double small = 8.0;

  // Pre-compiled BorderRadius helper getters
  static final BorderRadius cardBorder = BorderRadius.circular(card);
  static final BorderRadius modalBorder = BorderRadius.circular(modal);
  static final BorderRadius chipBorder = BorderRadius.circular(chip);
  static final BorderRadius buttonBorder = BorderRadius.circular(button);
  static final BorderRadius smallBorder = BorderRadius.circular(small);
}
