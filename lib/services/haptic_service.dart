import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  static Future<void> success() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 60, 40, 80],
          intensities: [0, 100, 0, 255],
        ); // "Cha-ching" feel
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> error() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(pattern: [0, 50, 100, 50, 100, 50]); // Warning "pulse"
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> warning() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 60, 60, 60],
          intensities: [0, 120, 0, 180],
        );
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> combo() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 30, 20, 30, 20, 30, 20, 100],
        ); // Rising intensity
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> toggle() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 20, amplitude: 100);
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> delete() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 40, 40, 80],
          intensities: [0, 150, 0, 220],
        );
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> salute() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 40, 30, 60, 30, 100],
          intensities: [0, 100, 0, 180, 0, 255],
        );
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> celebration() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 100, 50, 100, 50, 100, 50, 300],
          intensities: [0, 100, 0, 150, 0, 200, 0, 255],
        );
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Button press feedback — subtle tactile acknowledgment for primary CTAs.
  static Future<void> buttonPress() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 25, amplitude: 80);
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Level-up feedback — dramatic ascending pulse.
  static Future<void> levelUp() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 50, 30, 80, 30, 120, 60, 200],
          intensities: [0, 80, 0, 150, 0, 200, 0, 255],
        );
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Sacred artifact unlock — slow mystical pulse.
  static Future<void> artifactUnlock() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 200, 100, 150, 100, 100, 200, 400],
          intensities: [0, 60, 0, 120, 0, 180, 0, 255],
        );
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Tab/navigation switch — very subtle click.
  static Future<void> navigation() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 15, amplitude: 40);
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Streak milestone — rhythmic heartbeat pattern.
  static Future<void> streak() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 80, 60, 80, 200, 120, 60, 120],
          intensities: [0, 180, 0, 180, 0, 255, 0, 255],
        );
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
