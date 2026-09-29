import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class _OptimizedShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final BoxBorder? border;

  const _OptimizedShimmerBox({
    this.width,
    this.height,
    this.borderRadius = 16,
    this.isCircle = false,
    required this.baseColor,
    required this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.border,
  });

  @override
  State<_OptimizedShimmerBox> createState() => _OptimizedShimmerBoxState();
}

class _OptimizedShimmerBoxState extends State<_OptimizedShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle
                  ? null
                  : BorderRadius.circular(widget.borderRadius),
              border: widget.border,
              gradient: LinearGradient(
                begin: Alignment(-1.2 + (progress * 3.2), -0.3),
                end: Alignment(-0.2 + (progress * 3.2), 0.3),
                colors: [
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

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
    return _OptimizedShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      isCircle: isCircle,
      baseColor: AppColors.forest700.withValues(alpha: 0.4),
      highlightColor: AppColors.forest600.withValues(alpha: 0.7),
      duration: const Duration(milliseconds: 1400),
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
    return _OptimizedShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      isCircle: isCircle,
      baseColor: AppColors.forest800.withValues(alpha: 0.6),
      highlightColor: AppColors.gold500.withValues(alpha: 0.15),
      duration: const Duration(milliseconds: 1800),
      border: Border.all(
        color: AppColors.gold500.withValues(alpha: 0.1),
        width: 1,
      ),
    );
  }
}

/// A structured skeleton card matching Dictionary Screen entries for low-overhead loading
class DictionaryCardSkeleton extends StatelessWidget {
  const DictionaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.forest800.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.forest700.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const AppShimmerSkeleton(
                        width: 120,
                        height: 20,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 8),
                      const AppShimmerSkeleton(
                        width: 50,
                        height: 16,
                        borderRadius: 12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const AppShimmerSkeleton(
                    width: 180,
                    height: 14,
                    borderRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const AppShimmerSkeleton(
              width: 36,
              height: 36,
              isCircle: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// A structured skeleton card matching Hub / Dashboard Screen cards
class HubCardSkeleton extends StatelessWidget {
  final double height;
  final double borderRadius;

  const HubCardSkeleton({
    super.key,
    this.height = 100,
    this.borderRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.forest800.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.forest700.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const AppShimmerSkeleton(
              width: 48,
              height: 48,
              isCircle: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  AppShimmerSkeleton(
                    width: 140,
                    height: 18,
                    borderRadius: 8,
                  ),
                  SizedBox(height: 8),
                  AppShimmerSkeleton(
                    width: 200,
                    height: 12,
                    borderRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
