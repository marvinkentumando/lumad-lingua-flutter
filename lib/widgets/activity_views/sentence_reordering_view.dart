import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/haptic_service.dart';

class SentenceReorderingView extends StatelessWidget {
  final String question;
  final List<String> scrambledParts;
  final List<String> availableParts;
  final void Function(int index, String word) onWordTap;
  final void Function(int index, String word) onScrambledWordTap;
  final bool isReadOnly;

  const SentenceReorderingView({
    super.key,
    required this.question,
    required this.scrambledParts,
    required this.availableParts,
    required this.onWordTap,
    required this.onScrambledWordTap,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.isEmpty ? 'Reorder the words' : question,
          style: AppTypography.h2.copyWith(
            color: isDark ? Colors.white : AppColors.forest900,
          ),
        ),
        const SizedBox(height: 32),
        // Drop Zone Container (Accepts items dragged from available)
        DragTarget<Map<String, dynamic>>(
          onWillAcceptWithDetails: (details) =>
              !isReadOnly && details.data['source'] == 'available',
          onAcceptWithDetails: (details) {
            HapticService.light();
            final fromIndex = details.data['fromIndex'] as int;
            final word = details.data['word'] as String;
            onWordTap(fromIndex, word);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHovered
                    ? AppColors.gold500.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.black12
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHovered
                      ? AppColors.gold500
                      : (isDark
                          ? Colors.white24
                          : Colors.black.withValues(alpha: 0.1)),
                  width: isHovered ? 2.5 : 2.0,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: AppColors.gold500.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: scrambledParts.isEmpty
                  ? Center(
                      child: Text(
                        "DRAG OR TAP WORDS HERE",
                        style: AppTypography.label.copyWith(
                          color: isDark
                              ? Colors.white30
                              : AppColors.forest900.withValues(alpha: 0.3),
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: scrambledParts.asMap().entries.map((entry) {
                        final chipWidget = Material(
                          color: Colors.transparent,
                          child: Chip(
                            label: Text(
                              entry.value,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppColors.semanticBlue,
                            elevation: 2,
                          ),
                        );

                        if (isReadOnly) {
                          return chipWidget;
                        }

                        return Draggable<Map<String, dynamic>>(
                          data: {
                            'word': entry.value,
                            'fromIndex': entry.key,
                            'source': 'scrambled',
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            child: Transform.scale(
                              scale: 1.1,
                              child: Chip(
                                label: Text(
                                  entry.value,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: AppColors.gold500,
                                elevation: 6,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: chipWidget,
                          ),
                          child: GestureDetector(
                            onTap: () =>
                                onScrambledWordTap(entry.key, entry.value),
                            child: chipWidget,
                          ),
                        );
                      }).toList(),
                    ),
            );
          },
        ),
        const SizedBox(height: 32),
        // Available Parts Section (Accepts items dragged back from drop zone)
        DragTarget<Map<String, dynamic>>(
          onWillAcceptWithDetails: (details) =>
              !isReadOnly && details.data['source'] == 'scrambled',
          onAcceptWithDetails: (details) {
            HapticService.light();
            final fromIndex = details.data['fromIndex'] as int;
            final word = details.data['word'] as String;
            onScrambledWordTap(fromIndex, word);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHovered
                      ? AppColors.gold500
                      : Colors.transparent,
                  width: 2.0,
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableParts.asMap().entries.map((entry) {
                  final chipWidget = Chip(
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: isDark
                        ? AppColors.forest700
                        : AppColors.creamShadow.withValues(alpha: 0.15),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white12
                          : AppColors.creamShadow.withValues(alpha: 0.3),
                    ),
                  );

                  if (isReadOnly) {
                    return chipWidget;
                  }

                  return Draggable<Map<String, dynamic>>(
                    data: {
                      'word': entry.value,
                      'fromIndex': entry.key,
                      'source': 'available',
                    },
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.1,
                        child: Chip(
                          label: Text(
                            entry.value,
                            style: const TextStyle(
                              color: AppColors.forest900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.gold500,
                          elevation: 6,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.25,
                      child: chipWidget,
                    ),
                    child: GestureDetector(
                      onTap: () => onWordTap(entry.key, entry.value),
                      child: chipWidget,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        if (isReadOnly && availableParts.isEmpty && scrambledParts.isEmpty)
          Center(
            child: Text(
              "No words added yet.",
              style: AppTypography.label.copyWith(
                color: isDark
                    ? Colors.white54
                    : AppColors.forest900.withValues(alpha: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}
