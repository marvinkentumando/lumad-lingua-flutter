import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/haptic_service.dart';

class FillBlanksView extends StatefulWidget {
  final String question;
  final String sentence; // e.g. "I love [word] and [word]"
  final List<String> availableOptions;
  final Map<int, String> selectedBlanks;
  final Function(int, String) onWordSelected;
  final Function(int) onBlankTap;
  final String? hintText;
  final Function(int)? onRevealClue;

  const FillBlanksView({
    super.key,
    required this.question,
    required this.sentence,
    required this.availableOptions,
    required this.selectedBlanks,
    required this.onWordSelected,
    required this.onBlankTap,
    this.hintText,
    this.onRevealClue,
  });

  @override
  State<FillBlanksView> createState() => _FillBlanksViewState();
}

class _FillBlanksViewState extends State<FillBlanksView>
    with SingleTickerProviderStateMixin {
  int? _focusedBlankIndex;
  bool _isClueRevealed = false;
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  int _calculateActiveFocus(int totalBlanks) {
    if (_focusedBlankIndex != null &&
        _focusedBlankIndex! < totalBlanks &&
        !widget.selectedBlanks.containsKey(_focusedBlankIndex)) {
      return _focusedBlankIndex!;
    }
    for (int i = 0; i < totalBlanks; i++) {
      if (!widget.selectedBlanks.containsKey(i)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> segments = widget.sentence.split(RegExp(r'(\[word\])'));
    final int totalBlanks = '[word]'.allMatches(widget.sentence).length;
    final int activeFocusIndex =
        _calculateActiveFocus(totalBlanks > 0 ? totalBlanks : 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int blankIndexCounter = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.question,
                style: AppTypography.h3.copyWith(color: AppColors.gold500),
              ),
            ),
            if (widget.hintText != null && widget.hintText!.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() {
                    _isClueRevealed = !_isClueRevealed;
                  });
                  if (_isClueRevealed && widget.onRevealClue != null) {
                    widget.onRevealClue!(activeFocusIndex);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isClueRevealed
                        ? AppColors.gold500.withValues(alpha: 0.2)
                        : (isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isClueRevealed
                          ? AppColors.gold500
                          : (isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        size: 14,
                        color: _isClueRevealed
                            ? AppColors.gold500
                            : (isDark
                                ? Colors.white60
                                : AppColors.forest900.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isClueRevealed ? 'Clue Active' : 'Elder Clue',
                        style: AppTypography.label.copyWith(
                          color: _isClueRevealed
                              ? AppColors.gold500
                              : (isDark
                                  ? Colors.white70
                                  : AppColors.forest900
                                      .withValues(alpha: 0.7)),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_isClueRevealed && widget.hintText != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 16, color: AppColors.gold500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ELDER CLUE: ${widget.hintText}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        // Sentence with Blanks
        Wrap(
          spacing: 6,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: segments.map((segment) {
            if (segment == '[word]') {
              final index = blankIndexCounter++;
              final selection = widget.selectedBlanks[index];
              final isFocused = (index == activeFocusIndex) && (selection == null);

              return GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() {
                    _focusedBlankIndex = index;
                  });
                  if (selection != null) {
                    widget.onBlankTap(index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selection != null
                        ? AppColors.gold500
                        : (isFocused
                            ? AppColors.gold500.withValues(alpha: 0.15)
                            : (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05))),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selection != null
                          ? AppColors.gold500
                          : (isFocused
                              ? AppColors.gold500
                              : (isDark
                                  ? Colors.white24
                                  : Colors.black.withValues(alpha: 0.15))),
                      width: isFocused ? 2.0 : 1.0,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: AppColors.gold500.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  constraints: const BoxConstraints(minWidth: 64),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selection ?? '_____',
                        style: AppTypography.body.copyWith(
                          color: selection != null
                              ? Colors.black
                              : (isFocused
                                  ? AppColors.gold500
                                  : (isDark
                                      ? Colors.white24
                                      : AppColors.forest900
                                          .withValues(alpha: 0.3))),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isFocused) ...[
                        const SizedBox(width: 4),
                        FadeTransition(
                          opacity: _cursorController,
                          child: Container(
                            width: 2,
                            height: 16,
                            color: AppColors.gold500,
                          ),
                        ),
                      ],
                    ],
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
            color: isDark
                ? Colors.white24
                : AppColors.forest900.withValues(alpha: 0.3),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.availableOptions.map((opt) {
            final isUsed = widget.selectedBlanks.values.contains(opt);
            return GestureDetector(
              onTap: isUsed
                  ? null
                  : () {
                      HapticService.light();
                      widget.onWordSelected(activeFocusIndex, opt);
                      setState(() {
                        _focusedBlankIndex = null; // Auto advance focus
                      });
                    },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isUsed ? 0.2 : 1.0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.1),
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
