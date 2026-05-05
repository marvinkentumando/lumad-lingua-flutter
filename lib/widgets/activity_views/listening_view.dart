import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../preview_audio_player.dart';
import 'mcq_view.dart';

// Fix #6: ListeningView is now stateful so it can:
//  - Auto-play the audio once when the task loads.
//  - Cap replays at 3 and display a remaining-plays counter.
class ListeningView extends StatefulWidget {
  final String question;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int>? onOptionSelected;
  final String? audioUrl;
  final bool isReadOnly;

  const ListeningView({
    super.key,
    required this.question,
    required this.options,
    this.selectedIndex,
    this.onOptionSelected,
    this.audioUrl,
    this.isReadOnly = false,
  });

  @override
  State<ListeningView> createState() => _ListeningViewState();
}

class _ListeningViewState extends State<ListeningView> {
  static const _maxReplays = 3;
  int _playsUsed = 0;

  // The key lets us programmatically restart the PreviewAudioPlayer for auto-play.
  final GlobalKey _playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Auto-play once after the first frame.
    if (!widget.isReadOnly &&
        widget.audioUrl != null &&
        widget.audioUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _playsUsed = 1);
        }
      });
    }
  }

  bool get _canReplay => _playsUsed < _maxReplays;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Audio player section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Center(
                child: PreviewAudioPlayer(
                  key: _playerKey,
                  audioUrl: widget.audioUrl ?? '',
                  size: 64,
                  autoPlay: _playsUsed == 1 && !widget.isReadOnly,
                ),
              ),
              if (!widget.isReadOnly &&
                  widget.audioUrl != null &&
                  widget.audioUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Replay button
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _canReplay ? 1.0 : 0.35,
                      child: TextButton.icon(
                        onPressed: _canReplay
                            ? () => setState(() => _playsUsed++)
                            : null,
                        icon: const Icon(Icons.replay_rounded, size: 16),
                        label: const Text('Replay'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold500,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    // Replay counter chips
                    ...List.generate(_maxReplays, (i) {
                      final used = i < _playsUsed;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: used ? Colors.white24 : AppColors.gold500,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                if (!_canReplay)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'No more replays â€” choose carefully!',
                      style: AppTypography.label.copyWith(
                        color: AppColors.semanticRed,
                        fontSize: 11,
                      ),
                    ).animate().fadeIn(),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        MCQView(
          question: widget.question.isEmpty
              ? 'Listen and choose the correct answer'
              : widget.question,
          options: widget.options,
          selectedIndex: widget.selectedIndex,
          onOptionSelected: widget.onOptionSelected,
          isReadOnly: widget.isReadOnly,
        ),
      ],
    );
  }
}


