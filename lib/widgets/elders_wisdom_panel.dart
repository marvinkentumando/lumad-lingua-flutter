import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class EldersWisdomPanel extends StatelessWidget {
  final String content;
  final VoidCallback? onClose;

  const EldersWisdomPanel({
    super.key,
    required this.content,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest800 : AppColors.creamBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.gold500.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold500.withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.gold500,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ELDERS' WISDOM",
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Lore & Cultural Context",
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white38 : AppColors.forest300,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: isDark ? Colors.white24 : AppColors.forest200,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            content,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white70 : AppColors.forest900,
              fontStyle: FontStyle.italic,
              height: 1.6,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "— The Ancestors",
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

void showEldersWisdom(BuildContext context, String content) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => EldersWisdomPanel(
      content: content,
      onClose: () => Navigator.pop(context),
    ),
  );
}



