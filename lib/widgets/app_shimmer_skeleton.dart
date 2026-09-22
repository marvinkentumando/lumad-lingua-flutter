import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class AppShimmerSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;

  const AppShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.forest700.withValues(alpha: 0.5),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.1),
        );
  }
}

class TribalLoadingBones extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;

  const TribalLoadingBones({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.forest800.withValues(alpha: 0.7),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.gold500.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 2000.ms,
          color: AppColors.gold500.withValues(alpha: 0.05),
        );
  }
}
