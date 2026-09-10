import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../brand_card.dart';

class TrueFalseView extends StatelessWidget {
  final String question;
  final int? selectedIndex; // 0 for True, 1 for False
  final ValueChanged<int> onOptionSelected;

  const TrueFalseView({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrandCard(
          theme: BrandCardTheme.vibrant,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              question,
              style: AppTypography.h2.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: _buildOption(context, 0, 'TRUE', Icons.check_circle_outline, isDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOption(context, 1, 'FALSE', Icons.cancel_outlined, isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, int index, String label, IconData icon, bool isDark) {
    final isSelected = selectedIndex == index;
    final color = index == 0 ? AppColors.semanticGreen : AppColors.semanticRed;

    return GestureDetector(
      onTap: () => onOptionSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTypography.h3.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.5)),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
