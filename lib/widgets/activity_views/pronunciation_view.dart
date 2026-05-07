import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../preview_audio_player.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class PronunciationView extends StatelessWidget {
  final String question;
  final String word;
  final String phonetic;
  final bool isRecording;
  final bool hasRecorded;
  final VoidCallback? onToggleRecording;
  final bool isReadOnly;
  final String? audioUrl;
  final RecorderController? recorderController;

  const PronunciationView({
    super.key,
    required this.question,
    required this.word,
    required this.phonetic,
    this.isRecording = false,
    this.hasRecorded = false,
    this.onToggleRecording,
    this.isReadOnly = false,
    this.audioUrl,
    this.recorderController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          question.isEmpty ? 'Tap and Speak' : question,
          style: AppTypography.h2.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Text(
          word.isEmpty ? 'Word' : word,
          style: AppTypography.h1ExtraBold.copyWith(
            color: AppColors.gold500,
            fontSize: 48,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          phonetic.isEmpty ? '/phonetic/' : phonetic,
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.white54,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 64),
        if (isReadOnly && audioUrl != null && audioUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: PreviewAudioPlayer(audioUrl: audioUrl!),
          ),
        GestureDetector(
          onTap: isReadOnly ? null : onToggleRecording,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isRecording && recorderController != null)
                AudioWaveforms(
                  size: const Size(250, 100),
                  recorderController: recorderController!,
                  enableGesture: false,
                  waveStyle: WaveStyle(
                    waveColor: Colors.white.withValues(alpha: 0.5),
                    spacing: 4.0,
                    extendWaveform: true,
                    showMiddleLine: false,
                  ),
                ),
              if (!isRecording)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isReadOnly
                        ? Colors.white12
                        : AppColors.forestDarkCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isReadOnly ? Colors.white24 : AppColors.gold500,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 48,
                    color: isReadOnly ? Colors.white24 : AppColors.gold500,
                  ),
                ),
              if (isRecording)
                const Icon(
                      Icons.stop_rounded,
                      size: 64,
                      color: AppColors.semanticRed,
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isReadOnly
              ? "Educator Preview Mode"
              : (isRecording
                    ? "Listening..."
                    : (hasRecorded ? "Audio recorded!" : "Tap to record")),
          style: AppTypography.label.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}


