import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import 'summary_widgets.dart';

class SessionResultsView extends ConsumerStatefulWidget {
  final int xpEarned;
  final int stars;
  final int totalTasks;
  final int distinctMistakeTasks;
  final int bonusXp;
  final VoidCallback onFinish;

  const SessionResultsView({
    super.key,
    required this.xpEarned,
    required this.stars,
    required this.totalTasks,
    required this.distinctMistakeTasks,
    required this.bonusXp,
    required this.onFinish,
  });

  @override
  ConsumerState<SessionResultsView> createState() => _SessionResultsViewState();
}

class _SessionResultsViewState extends ConsumerState<SessionResultsView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticService.celebration();
      ref.read(audioServiceProvider).playSFX('session_complete');
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.totalTasks == 0
        ? 100
        : (((widget.totalTasks - widget.distinctMistakeTasks) / widget.totalTasks) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.forest900,
      body: Stack(
        children: [
          // Top Center Confetti Explosion
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              maxBlastForce: 25,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                AppColors.gold500,
                Colors.cyanAccent,
                Colors.purpleAccent,
                Colors.amber,
                Colors.white,
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildStarRating(),
                const SizedBox(height: 20),
                Text(
                  'SESSION COMPLETE',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn().slideY(begin: -0.3),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        AnimatedSummaryStatRow(
                          icon: Icons.bolt_rounded,
                          iconColor: AppColors.gold500,
                          label: 'XP Earned',
                          endValue: widget.xpEarned,
                          prefix: '+',
                          suffix: ' XP',
                          delay: 200.ms,
                        ),
                        const SizedBox(height: 12),
                        AnimatedSummaryStatRow(
                          icon: Icons.check_circle_rounded,
                          iconColor: AppColors.semanticGreen,
                          label: 'Accuracy',
                          endValue: accuracy,
                          prefix: '',
                          suffix: '%',
                          delay: 350.ms,
                        ),
                        const SizedBox(height: 12),
                        AnimatedSummaryStatRow(
                          icon: Icons.task_alt_rounded,
                          iconColor: AppColors.semanticBlue,
                          label: 'Tasks Completed',
                          endValue: widget.totalTasks,
                          prefix: '',
                          suffix: ' tasks',
                          delay: 500.ms,
                        ),
                        if (widget.bonusXp > 0) ...[
                          const SizedBox(height: 12),
                          AnimatedSummaryStatRow(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: Colors.orangeAccent,
                            label: 'Bonus XP',
                            endValue: widget.bonusXp,
                            prefix: '+',
                            suffix: ' XP',
                            delay: 650.ms,
                          ),
                        ],
                        const SizedBox(height: 20),
                        SrsMasteryBadgeWidget(
                          stars: widget.stars,
                          accuracy: accuracy,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.medium();
                        widget.onFinish();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.gold500.withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'FINISH',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index < widget.stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            isActive ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isActive ? AppColors.gold500 : Colors.white10,
            size: index == 1 ? 84 : 54,
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.3, 0.3),
                duration: 600.ms,
                curve: Curves.elasticOut,
                delay: Duration(milliseconds: 300 + (index * 200)),
              )
              .shimmer(delay: 1200.ms, duration: 2.seconds),
        );
      }),
    );
  }
}
