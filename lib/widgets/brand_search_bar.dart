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

    // Standardized tokens from AdminUsersScreen
    final bgColor = isDark
        ? AppColors.forest800.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.5);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.forest900.withValues(alpha: 0.05);
    final textColor = isDark ? Colors.white : AppColors.forest900;
    final hintColor = isDark
        ? Colors.white24
        : AppColors.forest900.withValues(alpha: 0.3);

    return Container(
      margin: widget.isMinimal ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 8),
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
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.gold500,
            size: 20,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
                    size: 18,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                )
              : (widget.showFilter
                  ? IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppColors.gold500, size: 20),
                      onPressed: widget.onFilterTap,
                    )
                  : null),
          filled: true,
          fillColor: bgColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.gold500, width: 1.5),
          ),
        ),
      ),
    );
  }
}

