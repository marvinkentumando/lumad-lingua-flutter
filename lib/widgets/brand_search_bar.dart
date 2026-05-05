import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_box.dart';

class BrandSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isMinimal;
  final TextInputAction textInputAction;
  final bool showFilter;
  final VoidCallback? onFilterTap;
  final bool showMic;
  final VoidCallback? onMicTap;

  const BrandSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
    this.isMinimal = false,
    this.showFilter = false,
    this.onFilterTap,
    this.showMic = false,
    this.onMicTap,
  });

  @override
  State<BrandSearchBar> createState() => _BrandSearchBarState();
}

class _BrandSearchBarState extends State<BrandSearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  void _onTextChanged() {
    if (mounted) {
      final textNotEmpty = _controller.text.isNotEmpty;
      if (_hasText != textNotEmpty) {
        setState(() {
          _hasText = textNotEmpty;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme tokens
    final bgColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.8);
    final borderColor = isDark
        ? AppColors.gold500.withValues(alpha: 0.2)
        : AppColors.forest500.withValues(alpha: 0.1);
    final iconColor = isDark ? AppColors.gold500 : AppColors.forest700;
    final textColor = isDark ? Colors.white : AppColors.forest900;
    final hintColor = isDark ? Colors.white38 : AppColors.creamText2;
    final cursorColor = isDark ? AppColors.gold500 : AppColors.forest500;

    final searchBarContent = Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.isMinimal ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(24),
        border: widget.isMinimal
            ? null
            : Border.all(color: borderColor, width: 1.5),
        boxShadow: widget.isMinimal || isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.creamShadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: (val) {
                HapticFeedback.mediumImpact();
                widget.onSubmitted?.call(val);
              },
              style: AppTypography.body.copyWith(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: cursorColor,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.body.copyWith(
                  color: hintColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Suffix Actions with Animated Transitions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: _hasText
                    ? GestureDetector(
                        key: const ValueKey('clear'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _controller.clear();
                          widget.onChanged?.call('');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: textColor.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: textColor,
                          ),
                        ),
                      )
                    : widget.showMic
                    ? GestureDetector(
                        key: const ValueKey('mic'),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onMicTap?.call();
                        },
                        child: Icon(
                          Icons.mic_none_rounded,
                          color: iconColor,
                          size: 22,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('none')),
              ),

              // Persistent Filter Section
              if (widget.showFilter) ...[
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 20,
                  color: borderColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onFilterTap?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, color: iconColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'FILTERS',
                          style: AppTypography.label.copyWith(
                            color: iconColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (widget.isMinimal) return searchBarContent;

    return GlassBox(
      borderRadius: 24,
      blur: 15,
      opacity: isDark ? 0.15 : 0.05,
      child: searchBarContent,
    );
  }
}
