import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/pronunciation_service.dart';
import '../brand_card.dart';
import '../pronunciation_analysis_widget.dart';

class SpeakingPracticeView extends StatefulWidget {
  final String question;
  final String word;
  final String phonetic;
  final bool isRecording;
  final bool hasRecorded;
  final VoidCallback? onToggleRecording;
  final bool isReadOnly;
  final String? audioUrl;
  final String? userAudioPath;
  final RecorderController? recorderController;
  final PronunciationScore? pronunciationScore;
  final bool isEvaluating;
  final VoidCallback? onPlayNativeAudio;

  const SpeakingPracticeView({
    super.key,
    required this.question,
    required this.word,
    required this.phonetic,
    this.isRecording = false,
    this.hasRecorded = false,
    this.onToggleRecording,
    this.isReadOnly = false,
    this.audioUrl,
    this.userAudioPath,
    this.recorderController,
    this.pronunciationScore,
    this.isEvaluating = false,
    this.onPlayNativeAudio,
  });

  @override
  State<SpeakingPracticeView> createState() => _SpeakingPracticeViewState();
}

class _SpeakingPracticeViewState extends State<SpeakingPracticeView> {
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  bool _isPlayingUserAudio = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingUserAudio = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playUserRecording() async {
    if (widget.userAudioPath == null || widget.userAudioPath!.isEmpty) return;

    try {
      if (_isPlayingUserAudio) {
        await _audioPlayer.stop();
        setState(() => _isPlayingUserAudio = false);
      } else {
        setState(() => _isPlayingUserAudio = true);
        await _audioPlayer.play(ap.DeviceFileSource(widget.userAudioPath!));
      }
    } catch (e) {
      debugPrint('Error playing user recording: $e');
      if (mounted) setState(() => _isPlayingUserAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.question.isEmpty ? 'Tap and Speak' : widget.question,
            style: AppTypography.h2.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Target Word & Native Preview Card
          BrandCard(
            theme: BrandCardTheme.gold,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            borderRadius: 24,
            child: Column(
              children: [
                Text(
                  widget.word.isEmpty ? 'Word' : widget.word,
                  style: AppTypography.h1ExtraBold.copyWith(
                    color: AppColors.gold500,
                    fontSize: 42,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.phonetic.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.phonetic,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (widget.onPlayNativeAudio != null || (widget.audioUrl != null && widget.audioUrl!.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: widget.onPlayNativeAudio,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold500),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded, color: AppColors.gold500, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Listen Native Speaker 🔊',
                            style: TextStyle(color: AppColors.gold500, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 32),

          // Live Waveform Visualizer & Record Button
          GestureDetector(
            onTap: widget.isReadOnly ? null : widget.onToggleRecording,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isRecording && widget.recorderController != null)
                  Container(
                    width: double.infinity,
                    height: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.forest800.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.gold500, width: 2),
                    ),
                    child: AudioWaveforms(
                      size: const Size(double.infinity, 90),
                      recorderController: widget.recorderController!,
                      enableGesture: false,
                      waveStyle: const WaveStyle(
                        waveColor: AppColors.gold500,
                        spacing: 4.0,
                        extendWaveform: true,
                        showMiddleLine: false,
                      ),
                    ),
                  ),
                if (!widget.isRecording)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: widget.isReadOnly
                          ? (isDark ? Colors.white12 : Colors.black12)
                          : (widget.hasRecorded ? AppColors.gold500 : AppColors.forestDarkCard),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isReadOnly
                            ? Colors.white24
                            : AppColors.gold500,
                        width: 3,
                      ),
                      boxShadow: widget.hasRecorded
                          ? [
                              BoxShadow(
                                color: AppColors.gold500.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 4,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      widget.hasRecorded ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 48,
                      color: widget.hasRecorded ? Colors.black : AppColors.gold500,
                    ),
                  ),
                if (widget.isRecording)
                  const Icon(
                    Icons.stop_rounded,
                    size: 56,
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

          const SizedBox(height: 16),
          Text(
            widget.isReadOnly
                ? "Educator Preview Mode"
                : (widget.isRecording
                    ? "Listening live waveform... Tap to stop 🎙️"
                    : (widget.hasRecorded ? "Audio recorded! Review your score below 🎯" : "Tap mic to speak")),
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
            ),
          ),

          // Action buttons after recording (Listen back / Re-record)
          if (widget.hasRecorded && !widget.isRecording && widget.userAudioPath != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold500,
                    side: const BorderSide(color: AppColors.gold500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _playUserRecording,
                  icon: Icon(
                    _isPlayingUserAudio ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(_isPlayingUserAudio ? 'Stop Recording' : 'Play My Echo 🎧'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: widget.onToggleRecording,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Re-record'),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.1),
          ],

          const SizedBox(height: 24),

          // Pronunciation Evaluation Results Card
          if (widget.isEvaluating) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.gold500),
                  SizedBox(height: 12),
                  Text('Analyzing waveform & pitch accuracy...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ] else if (widget.pronunciationScore != null) ...[
            PronunciationAnalysisWidget(score: widget.pronunciationScore!)
                .animate()
                .fadeIn()
                .slideY(begin: 0.1),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
