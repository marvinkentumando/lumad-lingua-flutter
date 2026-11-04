import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lumad_lingua/theme/app_colors.dart';
import 'package:lumad_lingua/widgets/app_shimmer_skeleton.dart';

class GracefulImage extends StatelessWidget {
  final String imageUrl;
  final String? fallbackEmoji;
  final IconData? fallbackIcon;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const GracefulImage({
    super.key,
    required this.imageUrl,
    this.fallbackEmoji,
    this.fallbackIcon,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildFallback(context);
    }

    if (!imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildFallback(context),
        fadeInDuration: const Duration(milliseconds: 500),
        fadeOutDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (fallbackEmoji != null && fallbackEmoji!.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.forest800,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            fallbackEmoji!,
            style: TextStyle(fontSize: (height != null && height! < 100) ? 32 : 54),
          ),
        ),
      );
    }

    if (fallbackIcon != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.forest800,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(
            fallbackIcon,
            size: (height != null && height! < 100) ? 32 : 54,
            color: AppColors.gold500,
          ),
        ),
      );
    }

    return AppShimmerSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  Widget _buildPlaceholder() {
    return AppShimmerSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
