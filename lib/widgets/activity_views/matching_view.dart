import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class MatchingView extends StatefulWidget {
  final String question;
  final List<Map<String, String>> pairs;
  final Map<String, String> matchedPairs;
  final String? selectedNative;
  final String? selectedMeaning;
  final Function(String) onNativeTap;
  final Function(String) onMeaningTap;
  final bool isReadOnly;

  const MatchingView({
    super.key,
    required this.question,
    required this.pairs,
    required this.matchedPairs,
    this.selectedNative,
    this.selectedMeaning,
    required this.onNativeTap,
    required this.onMeaningTap,
    this.isReadOnly = false,
  });

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  // Fix #8: Shuffle the meanings column once when the widget is first built,
  // so the order doesn't match the native words and the task is a real challenge.
  late List<String> _shuffledMeanings;

  @override
  void initState() {
    super.initState();
    _shuffledMeanings =
        widget.pairs
            .map((p) => p['meaning'] ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
          ..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> natives = widget.pairs
        .map((p) => p['native'] ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.isEmpty ? 'Match the pairs' : widget.question,
          style: AppTypography.h2.copyWith(
            color: isDark ? Colors.white : AppColors.forest900,
          ),
        ),
        const SizedBox(height: 32),
        ...List.generate(natives.length, (index) {
          final native = natives[index];
          final meaning = index < _shuffledMeanings.length
              ? _shuffledMeanings[index]
              : '';

          final isNativeMatched = widget.matchedPairs.containsKey(native);
          final isMeaningMatched = widget.matchedPairs.containsValue(meaning);

          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: (widget.isReadOnly || isNativeMatched)
                      ? null
                      : () => widget.onNativeTap(native),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isNativeMatched
                          ? AppColors.gold500.withValues(alpha: 0.2)
                          : (widget.selectedNative == native
                                ? AppColors.semanticBlue.withValues(alpha: 0.3)
                                : (isDark ? AppColors.forestDarkCard : Colors.black.withValues(alpha: 0.03))),
                      border: Border.all(
                        color: isNativeMatched
                            ? AppColors.gold500
                            : (widget.selectedNative == native
                                  ? AppColors.semanticBlue
                                  : (isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.1))),
                        width:
                            isNativeMatched || widget.selectedNative == native
                            ? 2
                            : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      native.isEmpty ? 'Native' : native,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.forest900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: (widget.isReadOnly || isMeaningMatched)
                      ? null
                      : () => widget.onMeaningTap(meaning),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isMeaningMatched
                          ? AppColors.gold500.withValues(alpha: 0.2)
                          : (widget.selectedMeaning == meaning
                                ? AppColors.semanticBlue.withValues(alpha: 0.3)
                                : (isDark ? AppColors.forest800 : Colors.black.withValues(alpha: 0.03))),
                      border: Border.all(
                        color: isMeaningMatched
                            ? AppColors.gold500
                            : (widget.selectedMeaning == meaning
                                  ? AppColors.semanticBlue
                                  : (isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.1))),
                        width:
                            isMeaningMatched ||
                                widget.selectedMeaning == meaning
                            ? 2
                            : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      meaning.isEmpty ? 'Meaning' : meaning,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}



