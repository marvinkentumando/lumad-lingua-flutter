import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/haptic_service.dart';

enum BrandButtonType { primary, secondary, small, text, success, danger }

class BrandButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final BrandButtonType type;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const BrandButton({
    super.key,
    required this.text,
    this.onTap,
    this.type = BrandButtonType.primary,
    this.icon,
    this.padding,
  });

  @override
  State<BrandButton> createState() => _BrandButtonState();
}

class _BrandButtonState extends State<BrandButton> {
  bool _isPressed = false;
  bool _isDebouncing = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null || _isDebouncing) {
      return;
    }
    setState(() => _isPressed = true);
    HapticService.light();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null || _isDebouncing) {
      return;
    }
    setState(() {
      _isPressed = false;
      _isDebouncing = true;
    });

    widget.onTap!();

    // Reset debounce after a short cooldown
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isDebouncing = false);
      }
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isDisabled = widget.onTap == null;
    Color bgColor;
    Color textColor;
    Color shadowColor;
    double verticalPadding;
    double horizontalPadding;
    double borderRadius;
    TextStyle textStyle;
    BoxBorder? border;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (widget.type) {
      case BrandButtonType.primary:
        bgColor = isDisabled
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
            : (isDark ? AppColors.gold500 : AppColors.forest500);
        textColor = isDisabled
            ? (isDark ? Colors.white30 : Colors.black26)
            : (isDark ? AppColors.forest900 : Colors.white);
        shadowColor = isDisabled
            ? Colors.transparent
            : (isDark ? AppColors.gold700 : AppColors.forest700);
        verticalPadding = 14;
        horizontalPadding = 28;
        borderRadius = 15;
        textStyle = AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 15,
        );
        break;
      case BrandButtonType.secondary:
        bgColor = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04);
        textColor = isDisabled
            ? (isDark ? Colors.white24 : Colors.black26)
            : (isDark ? Colors.white : AppColors.forest700);
        shadowColor = Colors.transparent;
        border = Border.all(
          color: isDisabled
              ? (isDark ? Colors.white12 : Colors.black12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.forest200),
          width: 2.5,
        );
        verticalPadding = 14;
        horizontalPadding = 28;
        borderRadius = 15;
        textStyle = AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 15,
        );
        break;
      case BrandButtonType.small:
      case BrandButtonType.success:
      case BrandButtonType.danger:
      case BrandButtonType.text:
        bgColor = isDark ? AppColors.gold500 : AppColors.forest500;
        textColor = isDark ? AppColors.forest900 : Colors.white;

        if (widget.type == BrandButtonType.success) {
          bgColor = AppColors.semanticGreen;
          textColor = Colors.white;
        }
        if (widget.type == BrandButtonType.danger) {
          bgColor = AppColors.semanticRed;
          textColor = Colors.white;
        }
        if (widget.type == BrandButtonType.text) {
          bgColor = Colors.transparent;
          textColor = isDark ? AppColors.gold500 : AppColors.forest500;
        }

        if (isDisabled) {
          bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
          textColor = isDark ? Colors.white24 : Colors.black26;
        }

        shadowColor = Colors.transparent;
        verticalPadding = 8;
        horizontalPadding = 16;
        borderRadius = 11;
        textStyle = AppTypography.body.copyWith(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 13,
        );
        break;
    }

    final hasShadow =
        widget.type != BrandButtonType.secondary &&
        widget.type != BrandButtonType.text &&
        !isDisabled;
    final shadowHeight = widget.type == BrandButtonType.primary ? 5.0 : 3.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          margin: EdgeInsets.only(
            top: _isPressed && hasShadow ? shadowHeight : 0,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: shadowColor,
                      offset: Offset(0, _isPressed ? 0 : shadowHeight),
                      blurRadius: 0,
                    ),
                  ]
                : [],
          ),
          padding:
              widget.padding ??
              EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: textColor, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

