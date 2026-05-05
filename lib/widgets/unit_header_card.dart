import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class UnitHeaderCard extends StatelessWidget {
  final String unitNumber;
  final String title;
  final bool isCompleted;
  final int completedCount;
  final int totalCount;
  final IconData? icon;
  final int stars;

  const UnitHeaderCard({
    super.key,
    required this.unitNumber,
    required this.title,
    this.isCompleted = false,
    this.completedCount = 0,
    this.totalCount = 0,
    this.icon,
    this.stars = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242C26) : AppColors.creamBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            width: 1.5,
          ),
          image: !isDark
              ? const DecorationImage(
                  image: AssetImage('assets/images/paper_texture.png'),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        unitNumber.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'LEVEL COMPLETE',
                            style: AppTypography.label.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: AppColors.gold500, size: 32),
                        ),
                      if (icon != null) const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.h1ExtraBold.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.forest700,
                                fontSize: 24,
                                height: 1.1,
                              ),
                            ),
                            if (stars > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(
                                  3,
                                  (i) => Icon(
                                    Icons.star_rounded,
                                    color:
                                        i <
                                            (stars /
                                                    (totalCount > 0
                                                        ? totalCount
                                                        : 1))
                                                .round()
                                        ? AppColors.gold500
                                        : Colors.grey.withValues(alpha: 0.3),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (totalCount > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '$completedCount/$totalCount LESSONS',
                          style: AppTypography.label.copyWith(
                            color: isDark ? Colors.white30 : Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${totalCount > 0 ? (completedCount * 100 ~/ totalCount) : 0}%',
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? completedCount / totalCount : 0,
                        minHeight: 4,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.06),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.gold500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.gold500 : AppColors.forest500,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
