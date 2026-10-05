import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/haptic_service.dart';

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
        const SizedBox(height: 8),
        Text(
          'TAP OR DRAG NATIVE WORDS TO THEIR MEANINGS',
          style: AppTypography.label.copyWith(
            color: isDark
                ? Colors.white30
                : AppColors.forest900.withValues(alpha: 0.3),
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(natives.length, (index) {
          final native = natives[index];
          final meaning = index < _shuffledMeanings.length
              ? _shuffledMeanings[index]
              : '';

          final isNativeMatched = widget.matchedPairs.containsKey(native);
          final isMeaningMatched = widget.matchedPairs.containsValue(meaning);

          Widget nativeCard = GestureDetector(
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
                        : (isDark
                            ? AppColors.forestDarkCard
                            : Colors.black.withValues(alpha: 0.03))),
                border: Border.all(
                  color: isNativeMatched
                      ? AppColors.gold500
                      : (widget.selectedNative == native
                          ? AppColors.semanticBlue
                          : (isDark
                              ? Colors.white24
                              : Colors.black.withValues(alpha: 0.1))),
                  width:
                      isNativeMatched || widget.selectedNative == native ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                native.isEmpty ? 'Native' : native,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontWeight: widget.selectedNative == native || isNativeMatched
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );

          if (!widget.isReadOnly && !isNativeMatched) {
            nativeCard = Draggable<String>(
              data: native,
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold500,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    native,
                    style: const TextStyle(
                      color: AppColors.forest900,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: nativeCard,
              ),
              child: nativeCard,
            );
          }

          return Row(
            children: [
              Expanded(child: nativeCard),
              const SizedBox(width: 16),
              Expanded(
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) =>
                      !widget.isReadOnly && !isMeaningMatched,
                  onAcceptWithDetails: (details) {
                    HapticService.success();
                    widget.onNativeTap(details.data);
                    widget.onMeaningTap(meaning);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;

                    return GestureDetector(
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
                              : (isHovered
                                  ? AppColors.gold500.withValues(alpha: 0.25)
                                  : (widget.selectedMeaning == meaning
                                      ? AppColors.semanticBlue
                                          .withValues(alpha: 0.3)
                                      : (isDark
                                          ? AppColors.forest800
                                          : Colors.black
                                              .withValues(alpha: 0.03)))),
                          border: Border.all(
                            color: isMeaningMatched || isHovered
                                ? AppColors.gold500
                                : (widget.selectedMeaning == meaning
                                    ? AppColors.semanticBlue
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.black
                                            .withValues(alpha: 0.1))),
                            width: isMeaningMatched ||
                                    widget.selectedMeaning == meaning ||
                                    isHovered
                                ? 2
                                : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.gold500.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          meaning.isEmpty ? 'Meaning' : meaning,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.forest900.withValues(alpha: 0.7),
                            fontWeight: isMeaningMatched ||
                                    widget.selectedMeaning == meaning ||
                                    isHovered
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
