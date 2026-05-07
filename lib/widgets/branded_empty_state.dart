import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class BrandedEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? emoji;
  final Widget? action;

  const BrandedEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.emoji,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold500.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: emoji != null
                  ? Text(emoji!, style: const TextStyle(fontSize: 64))
                  : Icon(
                      icon ?? Icons.auto_awesome,
                      size: 64,
                      color: AppColors.gold500.withValues(alpha: 0.5),
                    ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 2.seconds,
              curve: Curves.easeInOut,
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: AppTypography.h2.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            if (action != null) ...[
              const SizedBox(height: 32),
              action!.animate().fadeIn(delay: 600.ms).scale(),
            ],
          ],
        ),
      ),
    );
  }
}



