import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/haptic_service.dart';

class AdminScreenHeader extends StatelessWidget {
  final String title;
  final String eyebrow;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const AdminScreenHeader({
    super.key,
    required this.title,
    this.eyebrow = 'ADMINISTRATION PORTAL',
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed ?? () {
              HapticService.light();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin/overview');
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.forest900,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.gold500, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        eyebrow.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.gold500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.h2.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
