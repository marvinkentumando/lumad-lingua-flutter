import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class AudioValidator {
  static const int maxSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int minDurationMs = 1000; // 1.0s

  /// Validates an audio file based on size and duration.
  /// Returns null if valid, or an error message if invalid.
  static Future<String?> validate(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return "Audio file not found.";
    }

    // Check size
    final int sizeInBytes = await file.length();
    if (sizeInBytes > maxSizeBytes) {
      return "Audio file is too large (${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)}MB). Max allowed is 10MB.";
    }

    // Check duration
    final player = AudioPlayer();
    try {
      // Using setSource instead of play to just get metadata
      await player.setSourceDeviceFile(path);
      
      // Wait a bit for the duration to be available
      // Some platforms need a moment to parse metadata
      Duration? duration = await player.getDuration();
      
      // Fallback: sometimes getDuration() returns null initially
      int retries = 0;
      while (duration == null && retries < 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        duration = await player.getDuration();
        retries++;
      }

      if (duration == null) {
        return "Could not determine audio duration.";
      }

      if (duration.inMilliseconds < minDurationMs) {
        return "Audio is too short (${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s). Minimum 1.0s required.";
      }
    } catch (e) {
      return "Error validating audio: $e";
    } finally {
      await player.dispose();
    }

    return null;
  }
}
