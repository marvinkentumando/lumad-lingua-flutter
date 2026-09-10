import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class FillBlanksView extends StatelessWidget {
  final String question;
  final String sentence; // e.g. "I love [word] and [word]"
  final List<String> availableOptions;
  final Map<int, String> selectedBlanks;
  final Function(int, String) onWordSelected;
  final Function(int) onBlankTap;

  const FillBlanksView({
    super.key,
    required this.question,
    required this.sentence,
    required this.availableOptions,
    required this.selectedBlanks,
    required this.onWordSelected,
    required this.onBlankTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> segments = sentence.split(RegExp(r'(\[word\])'));
    int blankIndex = 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: AppTypography.h3.copyWith(color: AppColors.gold500),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 4,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: segments.map((segment) {
            if (segment == '[word]') {
              final index = blankIndex++;
              final selection = selectedBlanks[index];
              return GestureDetector(
                onTap: () => onBlankTap(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: selection != null ? AppColors.gold500 : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selection != null ? AppColors.gold500 : (isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                  constraints: const BoxConstraints(minWidth: 60),
                  child: Text(
                    selection ?? '_____',
                    style: AppTypography.body.copyWith(
                      color: selection != null
                          ? Colors.black
                          : (isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.2)),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }
            return Text(
              segment,
              style: AppTypography.h2.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                height: 1.5,
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        Text(
          'TAP WORDS TO FILL BLANKS',
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: availableOptions.map((opt) {
            final isUsed = selectedBlanks.values.contains(opt);
            return GestureDetector(
              onTap: isUsed ? null : () {
                // Find first empty blank
                int? target;
                int totalBlanks = '[word]'.allMatches(sentence).length;
                for(int i=0; i<totalBlanks; i++) {
                  if (!selectedBlanks.containsKey(i)) {
                    target = i;
                    break;
                  }
                }
                if (target != null) onWordSelected(target, opt);
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isUsed ? 0.2 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    opt,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
