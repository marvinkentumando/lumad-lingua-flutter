import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  static Future<void> success() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 60, 40, 80],
        intensities: [0, 100, 0, 255],
      ); // "Cha-ching" feel
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static Future<void> error() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 50, 100, 50, 100, 50]); // Warning "pulse"
    } else {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
    }
  }

  static Future<void> combo() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 30, 20, 30, 20, 30, 20, 100],
      ); // Rising intensity
    } else {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      HapticFeedback.heavyImpact();
    }
  }

  static Future<void> heavy() async {
    HapticFeedback.heavyImpact();
  }

  static Future<void> medium() async {
    HapticFeedback.mediumImpact();
  }

  static Future<void> light() async {
    HapticFeedback.lightImpact();
  }

  static Future<void> selection() async {
    HapticFeedback.selectionClick();
  }

  static Future<void> celebration() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 100, 50, 100, 50, 100, 50, 300],
        intensities: [0, 100, 0, 150, 0, 200, 0, 255],
      );
    } else {
      HapticFeedback.vibrate();
    }
  }

  /// Button press feedback — subtle tactile acknowledgment for primary CTAs.
  static Future<void> buttonPress() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 25, amplitude: 80);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Level-up feedback — dramatic ascending pulse.
  static Future<void> levelUp() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 50, 30, 80, 30, 120, 60, 200],
        intensities: [0, 80, 0, 150, 0, 200, 0, 255],
      );
    } else {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.vibrate();
    }
  }

  /// Sacred artifact unlock — slow mystical pulse.
  static Future<void> artifactUnlock() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 200, 100, 150, 100, 100, 200, 400],
        intensities: [0, 60, 0, 120, 0, 180, 0, 255],
      );
    } else {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
    }
  }

  /// Tab/navigation switch — very subtle click.
  static Future<void> navigation() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 15, amplitude: 40);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Streak milestone — rhythmic heartbeat pattern.
  static Future<void> streak() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 80, 60, 80, 200, 120, 60, 120],
        intensities: [0, 180, 0, 180, 0, 255, 0, 255],
      );
    } else {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.heavyImpact();
    }
  }
}

