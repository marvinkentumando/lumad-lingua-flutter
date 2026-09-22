import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/upload_queue_service.dart';
import '../utils/app_localization.dart';
import 'brand_button.dart';

class SyncConflictResolver extends ConsumerWidget {
  final AppLocalization l10n;

  const SyncConflictResolver({super.key, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadQueueProvider);
    final conflicts = uploadState.conflicts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest900 : AppColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('resolve_conflicts').toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('conflict_detected_desc'),
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white70 : AppColors.forest700,
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: conflicts.length,
              itemBuilder: (context, index) {
                final conflict = conflicts[index];
                return _buildConflictItem(context, ref, conflict, isDark, l10n);
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: BrandButton(
              text: l10n.translate('done'),
              onTap: () => context.pop(),
              type: BrandButtonType.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictItem(
    BuildContext context,
    WidgetRef ref,
    SyncConflict conflict,
    bool isDark,
    AppLocalization l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conflict.lessonTitle,
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVersionColumn(
                  l10n.translate('local_device'),
                  conflict.localData['stars'],
                  conflict.localData['score'],
                  AppColors.gold500,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white12,
              ),
              Expanded(
                child: _buildVersionColumn(
                  l10n.translate('cloud_server'),
                  conflict.serverData['stars'],
                  conflict.serverData['bestScore'],
                  Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: BrandButton(
                  text: l10n.translate('keep_cloud'),
                  onTap: () => ref.read(uploadQueueProvider.notifier).resolveConflict(conflict.lessonId, false),
                  type: BrandButtonType.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BrandButton(
                  text: l10n.translate('use_local'),
                  onTap: () => ref.read(uploadQueueProvider.notifier).resolveConflict(conflict.lessonId, true),
                  type: BrandButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionColumn(String label, int stars, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: color, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Icon(
              Icons.star_rounded,
              size: 14,
              color: i < stars ? AppColors.gold500 : Colors.white10,
            ),
          ),
        ),
        Text(
          '$score XP',
          style: AppTypography.mono.copyWith(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
