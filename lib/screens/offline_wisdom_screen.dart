import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/brand_button.dart';

class OfflineWisdomScreen extends ConsumerWidget {
  const OfflineWisdomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientTopoBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStorageOverview(context),
                      const SizedBox(height: 32),
                      _sectionLabel('OFFLINE MODULES'),
                      const SizedBox(height: 16),
                      _buildSyncTile(
                        context,
                        'Dictionary Core',
                        'All approved words and translations',
                        '4.2 MB',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildSyncTile(
                        context,
                        'Audio Pronunciations',
                        'Recorded fragments for offline listening',
                        '128.5 MB',
                        false,
                      ),
                      const SizedBox(height: 12),
                      _buildSyncTile(
                        context,
                        'Lesson Archive',
                        'Interactive lessons and quiz assets',
                        '15.8 MB',
                        true,
                      ),
                      const SizedBox(height: 32),
                      _sectionLabel('MANAGEMENT'),
                      const SizedBox(height: 16),
                      _buildActionCard(
                        context,
                        Icons.sync_rounded,
                        'Sync All Wisdom',
                        'Update all offline data to the latest versions',
                        onTap: () => _showComingSoon(context, 'Global Sync'),
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        context,
                        Icons.delete_sweep_rounded,
                        'Clear Cache',
                        'Remove all downloaded assets to free up space',
                        isDanger: true,
                        onTap: () => _showComingSoon(context, 'Cache Clear'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.gold500,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Offline Wisdom',
            style: AppTypography.h2ExtraBold.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.forest900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: AppTypography.label.copyWith(
          color: AppColors.gold500,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      );

  Widget _buildStorageOverview(BuildContext context) {
    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OFFLINE STORAGE',
                style: AppTypography.label.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '148.5 MB USED',
                style: AppTypography.mono.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.15,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Approximately 1.2 GB available on device',
            style: AppTypography.body.copyWith(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncTile(
    BuildContext context,
    String title,
    String sub,
    String size,
    bool isSynced,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isSynced ? AppColors.semanticGreen : AppColors.gold500).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSynced ? Icons.cloud_done_rounded : Icons.cloud_download_rounded,
              color: isSynced ? AppColors.semanticGreen : AppColors.gold500,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$sub • $size',
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white38 : AppColors.creamText3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showComingSoon(context, 'Module Sync'),
            icon: Icon(
              Icons.sync_rounded,
              color: isSynced ? Colors.white24 : AppColors.gold500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String sub, {
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    return BrandCard(
      onTap: onTap,
      theme: isDanger ? BrandCardTheme.vibrant : BrandCardTheme.cream,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(
        children: [
          Icon(
            icon,
            color: isDanger ? AppColors.semanticRed : AppColors.gold500,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  sub,
                  style: AppTypography.body.copyWith(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is being prepared by the village elders.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
