import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _bgPlayer = AudioPlayer();
  final _sfxPlayer = AudioPlayer();

  AudioService() {
    _bgPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playAmbientMusic(String theme) async {
    try {
      // Mapping to actual file: forest_bg.MP3
      String assetPath = 'audio/forest_bg.MP3';
      
      await _bgPlayer.stop();
      await _bgPlayer.play(AssetSource(assetPath), volume: 0.4);
    } catch (e) {
      debugPrint("Error playing ambient music: $e");
    }
  }

  Future<void> stopAmbientMusic() async {
    await _bgPlayer.stop();
  }

  Future<void> playSFX(String type) async {
    try {
      String assetPath = 'audio/success.MP3';
      switch (type) {
        case 'error':
          assetPath = 'audio/error.MP3';
          break;
        case 'level_up':
        case 'milestone':
          assetPath = 'audio/success_1.MP3'; // Using alternative success for milestones
          break;
        case 'click':
          assetPath = 'audio/click.MP3';
          break;
      }
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("Error playing SFX: $e");
    }
  }

  Future<void> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig();
        await _recorder.start(config, path: path);
      }
    } catch (e) {
      // In production, log errors properly
      debugPrint("Error starting record: $e");
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      debugPrint("Error stopping record: $e");
      return null;
    }
  }

  Future<void> playRecording(String path) async {
    try {
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> playFromUrl(String url) async {
    try {
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint("Error playing audio from URL: $e");
      throw Exception('Failed to play audio. Check your connection.');
    }
  }

  Future<void> preCacheAudio(List<String> urls) async {
    for (var url in urls) {
      if (url.isEmpty) continue;
      try {
        // Just setting the source starts buffering on most platforms, effectively pre-caching it.
        final dummyPlayer = AudioPlayer();
        await dummyPlayer.setSource(UrlSource(url));
        // Dispose after a short delay to allow buffering to begin
        Future.delayed(const Duration(seconds: 1), () => dummyPlayer.dispose());
      } catch (e) {
        debugPrint("Error pre-caching audio URL $url: $e");
      }
    }
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});



