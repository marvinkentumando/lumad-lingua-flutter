import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../services/offline_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'dart:async';

class OfflineWisdomScreen extends ConsumerStatefulWidget {
  const OfflineWisdomScreen({super.key});

  @override
  ConsumerState<OfflineWisdomScreen> createState() => _OfflineWisdomScreenState();
}

class _OfflineWisdomScreenState extends ConsumerState<OfflineWisdomScreen> {
  bool _isSyncing = false;
  double _syncProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final lessonCountAsync = ref.watch(offlineLessonCountProvider);
    final dictionaryCountAsync = ref.watch(offlineDictionaryCountProvider);
    final artifactCountAsync = ref.watch(offlineArtifactCountProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              if (_isSyncing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _syncProgress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Syncing Ancestral Knowledge... ${(_syncProgress * 100).toInt()}%',
                        style: AppTypography.label.copyWith(color: AppColors.gold500, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStorageOverview(
                        context,
                        lessonCountAsync.value ?? 0,
                        dictionaryCountAsync.value ?? 0,
                        artifactCountAsync.value ?? 0,
                      ),
                      const SizedBox(height: 32),
                      _sectionLabel('OFFLINE MODULES'),
                      const SizedBox(height: 16),
                      _buildSyncTile(
                        context,
                        'Dictionary Core',
                        '${dictionaryCountAsync.value ?? 0} approved words cached',
                        '${((dictionaryCountAsync.value ?? 0) * 0.01).toStringAsFixed(1)} MB',
                        (dictionaryCountAsync.value ?? 0) > 0,
                      ),
                      const SizedBox(height: 12),
                      _buildSyncTile(
                        context,
                        'Lesson Archive',
                        '${lessonCountAsync.value ?? 0} modules available offline',
                        '${((lessonCountAsync.value ?? 0) * 0.5).toStringAsFixed(1)} MB',
                        (lessonCountAsync.value ?? 0) > 0,
                      ),
                      const SizedBox(height: 12),
                      _buildSyncTile(
                        context,
                        'Artifact Archive',
                        '${artifactCountAsync.value ?? 0} sacred items archived',
                        '${((artifactCountAsync.value ?? 0) * 0.05).toStringAsFixed(1)} MB',
                        (artifactCountAsync.value ?? 0) > 0,
                      ),
                      const SizedBox(height: 32),
                      _sectionLabel('MANAGEMENT'),
                      const SizedBox(height: 16),
                      _buildActionCard(
                        context,
                        Icons.sync_rounded,
                        'Sync All Wisdom',
                        'Update all offline data to the latest versions',
                        onTap: _isSyncing ? null : () => _handleSyncAll(),
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        context,
                        Icons.delete_sweep_rounded,
                        'Clear Cache',
                        'Remove all downloaded assets to free up space',
                        isDanger: true,
                        onTap: _isSyncing ? null : () => _showClearConfirmation(),
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
            onPressed: () => context.pop(),
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

  Widget _buildStorageOverview(BuildContext context, int lessons, int words, int artifacts) {
    // Estimating 10KB per word, 500KB per lesson, 50KB per artifact
    double mbUsed = (words * 0.01) + (lessons * 0.5) + (artifacts * 0.05);
    double pct = (mbUsed / 200).clamp(0.05, 1.0); // 200MB as a theoretical "full" cache limit

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
                '${mbUsed.toStringAsFixed(1)} MB USED',
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
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capacity managed by village protocols.',
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
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
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
                    color: isDark ? Colors.white60 : AppColors.creamText3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!isSynced)
            IconButton(
              onPressed: _handleSyncAll,
              icon: const Icon(
                Icons.download_rounded,
                color: AppColors.gold500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon, String title, String sub, {
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
                    color: isDanger ? Colors.white : AppColors.forest900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  sub,
                  style: AppTypography.body.copyWith(
                    color: isDanger ? Colors.white60 : AppColors.forest700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: isDanger ? Colors.white24 : AppColors.forest200),
        ],
      ),
    );
  }

  Future<void> _handleSyncAll() async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.1;
    });

    try {
      // 1. Sync Dictionary
      setState(() => _syncProgress = 0.2);
      final words = await ref.read(firebaseServiceProvider).getAllDictionaryWords().first;
      await ref.read(offlineServiceProvider).saveDictionaryEntries(words);
      
      setState(() => _syncProgress = 0.6);
      
      // 2. Sync Lessons
      final lessons = await ref.read(firebaseServiceProvider).getPublishedLessons().first;
      await ref.read(offlineServiceProvider).saveLessons(lessons);

      setState(() => _syncProgress = 0.8);

      // 3. Sync Artifacts
      final user = ref.read(authStateProvider).value;
      final artifacts = await ref.read(firebaseServiceProvider).getArtifacts(userId: user?.uid).first;
      await ref.read(offlineServiceProvider).saveArtifacts(artifacts);

      setState(() => _syncProgress = 1.0);
      
      // Refresh providers
      ref.invalidate(offlineLessonCountProvider);
      ref.invalidate(offlineDictionaryCountProvider);
      ref.invalidate(offlineArtifactCountProvider);
      ref.invalidate(cachedArtifactsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ancestral knowledge successfully cached!'), backgroundColor: AppColors.semanticGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: AppColors.semanticRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: const Text('Clear Wisdom Cache?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'All offline lessons and dictionary terms will be removed from this device. You will need a connection to access them again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(offlineServiceProvider).clearCache();
              ref.invalidate(offlineLessonCountProvider);
              ref.invalidate(offlineDictionaryCountProvider);
              ref.invalidate(offlineArtifactCountProvider);
              ref.invalidate(cachedArtifactsProvider);
              if (context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }
}
