import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../services/supabase_storage_service.dart';

class PreviewAudioPlayer extends ConsumerStatefulWidget {
  final String audioUrl;
  final double size;
  final Color? color;
  // Fix #6: When true, audio auto-plays once after the first frame.
  final bool autoPlay;

  const PreviewAudioPlayer({
    super.key,
    required this.audioUrl,
    this.size = 48,
    this.color,
    this.autoPlay = false,
  });

  @override
  ConsumerState<PreviewAudioPlayer> createState() => _PreviewAudioPlayerState();
}

class _PreviewAudioPlayerState extends ConsumerState<PreviewAudioPlayer> {
  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    // Fix #6: Auto-play on first frame if requested.
    if (widget.autoPlay && widget.audioUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _togglePlay();
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else {
        setState(() => _hasError = false);
        // Resolve URL from Supabase if it's just a path
        final resolvedUrl = ref.read(supabaseStorageServiceProvider).getAudioUrl(widget.audioUrl);
        await _player.play(UrlSource(resolvedUrl));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        setState(() => _hasError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load audio. Please check your connection.',
            ),
            backgroundColor: AppColors.semanticRed,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioUrl.isEmpty) return const SizedBox.shrink();

    final isPlaying = _playerState == PlayerState.playing;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        padding: EdgeInsets.all(widget.size * 0.4),
        decoration: BoxDecoration(
          color: (widget.color ?? AppColors.gold500).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _hasError
              ? Icons.error_outline_rounded
              : (isPlaying
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_filled_rounded),
          color: _hasError
              ? AppColors.semanticRed
              : (widget.color ?? AppColors.gold500),
          size: widget.size,
        ),
      ),
    );
  }
}
