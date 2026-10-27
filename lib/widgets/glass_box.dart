import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? color;
  final Border? border;
  final Gradient? gradient;
  final bool enableBlur;

  const GlassBox({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.05,
    this.borderRadius = AppRadius.card,
    this.color,
    this.border,
    this.gradient,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Low-power performance optimization: Clamp backdrop blur sigma to 10.0 max
    final effectiveBlur = (blur > 10.0 ? 10.0 : blur).clamp(0.0, 10.0);
    final shouldApplyBlur = enableBlur && effectiveBlur > 0;

    final containerDecoration = BoxDecoration(
      color:
          color ??
          (isDark
              ? Colors.white.withValues(
                  alpha: shouldApplyBlur ? opacity : (opacity * 2.5).clamp(0.1, 0.25),
                )
              : Colors.black.withValues(
                  alpha: shouldApplyBlur ? opacity : (opacity * 1.5).clamp(0.05, 0.15),
                )),
      borderRadius: BorderRadius.circular(borderRadius),
      border:
          border ??
          Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.1,
            ),
            width: 1.5,
          ),
      gradient:
          gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
    );

    if (!shouldApplyBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: containerDecoration,
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          decoration: containerDecoration,
          child: child,
        ),
      ),
    );
  }
}
