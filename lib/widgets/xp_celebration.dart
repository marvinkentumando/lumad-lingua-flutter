import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/haptic_service.dart';
import '../services/audio_service.dart';
import 'lottie_feedback.dart';

class XPCelebration extends ConsumerStatefulWidget {
  final int xpEarned;
  final int stars;
  final VoidCallback onComplete;

  const XPCelebration({
    super.key,
    required this.xpEarned,
    required this.stars,
    required this.onComplete,
  });

  @override
  ConsumerState<XPCelebration> createState() => _XPCelebrationState();
}

class _XPCelebrationState extends ConsumerState<XPCelebration> {
  late ConfettiController _confettiController;
  int _lastTickSound = -1;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticService.celebration();
      ref.read(audioServiceProvider).playSFX('session_complete');
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti Burst Overlay
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              maxBlastForce: 25,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 35,
              gravity: 0.08,
              colors: const [
                AppColors.gold500,
                Colors.cyanAccent,
                Colors.purpleAccent,
                Colors.amber,
                Colors.white,
              ],
            ),
          ),
        ),

        // Base Lottie Celebration
        const CelebrationLottie(),

        // EXTRA EXPLOSION for 3 Stars
        if (widget.stars == 3) ...[
          const CelebrationLottie(),
          Positioned(
            top: -100,
            child: Lottie.network(
              'https://lottie.host/791c8907-5503-4674-8740-109437298642/hZ4y9Y8j7T.json',
              width: 500,
              height: 500,
            ),
          ),
        ],

        // Main Text Column
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold500.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.gold500, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold500.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.gold500,
                    size: 80,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: 1.seconds,
                )
                .then()
                .shimmer(duration: 1.seconds, color: Colors.white),
            const SizedBox(height: 32),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: widget.xpEarned),
              duration: const Duration(milliseconds: 1800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                if (value > 0 && (value % ((widget.xpEarned / 5).clamp(1, 20).toInt()) == 0) && value != _lastTickSound) {
                  _lastTickSound = value;
                  HapticService.selection();
                }
                return Text(
                  "+$value XP",
                  style: AppTypography.display.copyWith(
                    fontSize: 56,
                    color: AppColors.gold500,
                    shadows: [
                      const Shadow(
                        blurRadius: 16,
                        color: AppColors.gold700,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                );
              },
            ).animate().slideY(begin: 0.5, curve: Curves.easeOutCubic),
            const SizedBox(height: 12),
            Text(
              "Lumad Wisdom Gained!",
              style: AppTypography.h3.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.forest700,
                letterSpacing: 1.5,
              ),
            ).animate().fade(delay: 800.ms).slideY(begin: 0.5),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology_rounded, color: AppColors.gold500, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "LEITNER SRS MASTERY EXPANDED",
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 1100.ms).scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ],
    );
  }
}
