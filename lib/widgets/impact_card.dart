import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_card.dart';
import '../services/impact_service.dart';

class ImpactCard extends StatelessWidget {
  final ContributionImpact impact;

  const ImpactCard({
    super.key,
    required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR IMPACT',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const Icon(
                Icons.insights_rounded,
                color: AppColors.gold500,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPrimaryMetric(),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),
          Row(
            children: impact.stats.map((stat) => Expanded(
              child: _buildSecondaryMetric(
                label: stat.label,
                value: stat.value,
                icon: stat.icon,
                color: stat.color,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetric() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold500.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.gold500,
            size: 32,
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              impact.primaryMetric.toString(),
              style: AppTypography.displayBold.copyWith(
                color: Colors.white,
                fontSize: 36,
                height: 1,
              ),
            ),
            Text(
              impact.primaryLabel,
              style: AppTypography.label.copyWith(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildSecondaryMetric({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white24, size: 20),
        const SizedBox(height: 12),
        Text(
          value,
          style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: Colors.white24,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}



