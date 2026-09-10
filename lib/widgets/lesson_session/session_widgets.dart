import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/haptic_service.dart';
import '../grammar_nugget_panel.dart';

class ComboIndicator extends StatelessWidget {
  final int combo;
  const ComboIndicator({super.key, required this.combo});

  @override
  Widget build(BuildContext context) {
    if (combo < 3) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: combo >= 5 ? Colors.orange : (isDark ? AppColors.gold500 : AppColors.gold700),
            size: 24,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.2, duration: 400.ms),
          const SizedBox(width: 8),
          Text(
            '$combo COMBO!',
            style: AppTypography.h3.copyWith(
              color: combo >= 5 ? Colors.orange : (isDark ? AppColors.gold500 : AppColors.gold800),
              fontWeight: FontWeight.w900,
            ),
          ).animate().slideX(begin: -0.2),
          const Spacer(),
          if (combo >= 5)
            Text(
              '+15 XP',
              style: AppTypography.mono.copyWith(
                color: isDark ? Colors.orange : AppColors.gold900,
                fontSize: 12,
              ),
            ).animate().fadeIn().slideY(begin: 0.5),
        ],
      ),
    );
  }
}

class GrammarButton extends StatelessWidget {
  final String title;
  final String description;
  final List<String> examples;

  const GrammarButton({
    super.key,
    required this.title,
    required this.description,
    required this.examples,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 24, 8),
        child: GestureDetector(
          onTap: () {
            HapticService.light();
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => GrammarNuggetPanel(
                title: title,
                description: description,
                examples: examples,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold500,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.forest800, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.black, size: 18),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds),
      ),
    );
  }
}

class SuddenDeathBanner extends StatelessWidget {
  const SuddenDeathBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.semanticRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.semanticRed),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.semanticRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "SUDDEN DEATH: Answer correctly to survive!",
              style: AppTypography.label.copyWith(
                color: AppColors.semanticRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().shake();
  }
}

class SessionControlBar extends StatelessWidget {
  final bool isComplete;
  final VoidCallback onCheck;

  const SessionControlBar({
    super.key,
    required this.isComplete,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest700 : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.creamBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isComplete ? 1.0 : 0.5,
              child: Material(
                color: isComplete
                    ? AppColors.gold500
                    : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isComplete ? onCheck : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isComplete
                          ? [const BoxShadow(color: AppColors.gold700, offset: Offset(0, 5))]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        'CHECK',
                        style: AppTypography.bodyLarge.copyWith(
                          color: isComplete
                              ? AppColors.creamText
                              : (isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.2)),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
