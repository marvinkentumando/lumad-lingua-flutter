import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

enum BrandCardTheme { cream, vibrant, gold }

class BrandCard extends StatelessWidget {
  final Widget child;
  final BrandCardTheme theme;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool withAnimation;
  final int delayMs;

  const BrandCard({
    super.key,
    required this.child,
    this.theme = BrandCardTheme.cream,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.margin,
    this.borderRadius = 32,
    this.withAnimation = false,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card;

    if (theme == BrandCardTheme.cream) {
      card = Container(
        margin: margin,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : AppColors.creamBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : AppColors.creamBorder,
            width: 1.5,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 10),
                    blurRadius: 30,
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.creamShadow.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 15),
                    blurRadius: 35,
                  ),
                ],
        ),
        child: Stack(
          children: [
            if (!isDark)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    'assets/images/paper_texture.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      );
    } else if (theme == BrandCardTheme.vibrant) {
      card = Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: isDark ? AppColors.forest500 : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark
                ? AppColors.forest200.withOpacity(0.3)
                : AppColors.creamBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : AppColors.creamShadow.withOpacity(0.3),
              offset: const Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: child,
      );
    } else {
      // Gold Theme - Playful & Interactive
      card = Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.gold500,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.gold700, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold700.withOpacity(0.6),
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: child,
      );
    }

    if (withAnimation) {
      return card
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.1, curve: Curves.easeOutQuad);
    }
    return card;
  }
}


