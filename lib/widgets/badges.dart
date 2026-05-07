import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BrandBadgeStyle { gold, green, blue, dark, outline, danger }

class BrandBadge extends StatelessWidget {
  final String text;
  final BrandBadgeStyle style;

  const BrandBadge({
    super.key,
    required this.text,
    this.style = BrandBadgeStyle.gold,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BoxBorder? border;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (style) {
      case BrandBadgeStyle.gold:
        bgColor = AppColors.gold500.withValues(alpha: isDark ? 0.18 : 0.25);
        textColor = isDark ? const Color(0xFF9A7200) : const Color(0xFF7A5A00);
        break;
      case BrandBadgeStyle.green:
        bgColor = AppColors.semanticGreen.withValues(alpha: isDark ? 0.16 : 0.2,
        );
        textColor = isDark ? const Color(0xFF1F6E33) : const Color(0xFF144D23);
        break;
      case BrandBadgeStyle.blue:
        bgColor = AppColors.semanticBlue.withValues(alpha: isDark ? 0.14 : 0.18,
        );
        textColor = isDark ? const Color(0xFF1556A8) : const Color(0xFF0D3A73);
        break;
      case BrandBadgeStyle.danger:
        bgColor = AppColors.semanticRed.withValues(alpha: isDark ? 0.14 : 0.18);
        textColor = isDark ? const Color(0xFF981C1C) : const Color(0xFF6A1414);
        break;
      case BrandBadgeStyle.dark:
        bgColor = isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.07);
        textColor = isDark
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.6);
        break;
      case BrandBadgeStyle.outline:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.creamText2 : AppColors.forest700;
        border = Border.all(
          color: isDark ? AppColors.creamBorder : AppColors.forest200,
          width: 1.5,
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label.copyWith(
          color: textColor,
          letterSpacing: 0.6,
          fontSize: 10.5,
        ),
      ),
    );
  }
}



