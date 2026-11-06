import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lumad_lingua/theme/app_colors.dart';
import 'package:lumad_lingua/theme/app_typography.dart';
import 'package:lumad_lingua/providers/artifact_provider.dart';
import 'package:lumad_lingua/models/artifact.dart';
import 'package:lumad_lingua/services/haptic_service.dart';
import 'package:go_router/go_router.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/branded_empty_state.dart';
import '../widgets/graceful_image.dart';
import '../utils/app_localization.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String _sortBy = 'tier';              // 'tier', 'progress', 'name'

  @override
  Widget build(BuildContext context) {
    final artifactsAsync = ref.watch(userArtifactsProvider);
    final stats = ref.watch(artifactStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('ancestral_honors'),
          style: AppTypography.h3.copyWith(
            color: isDark ? Colors.white : AppColors.forest900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.forest900,
          ),
          onPressed: () {
            if (context.mounted) {
              context.pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.gold500),
            tooltip: l10n.translate('sort'),
            onPressed: () {
              HapticService.selection();
              _showSortBottomSheet(context, isDark, l10n);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: BrandBackground(
        child: SafeArea(
          child: artifactsAsync.when(
            data: (artifacts) {
              List<Artifact> sortedList = List.from(artifacts);

              // Apply sorting
              sortedList.sort((a, b) {
                if (_sortBy == 'progress') {
                  return b.progress.compareTo(a.progress);
                } else if (_sortBy == 'tier') {
                  return b.tier.index.compareTo(a.tier.index);
                } else {
                  return a.title.compareTo(b.title);
                }
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('your_legacy'),
                      style: AppTypography.display.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 32,
                      ),
                    ).animate().fadeIn().slideY(begin: -0.2),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('legacy_desc'),
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.forest900.withValues(alpha: 0.75),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),
                    _buildStatsRow(stats, isDark, l10n).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),
                    _buildSectionHeader(l10n.translate('ancestral_vault')),
                    const SizedBox(height: 16),
                    if (artifacts.isEmpty)
                      BrandedEmptyState(
                        title: l10n.translate('vault_locked'),
                        message: l10n.translate('unlock_treasures'),
                        icon: Icons.lock_outline,
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: sortedList.length,
                        itemBuilder: (context, index) => 
                            _buildArtifactCard(context, sortedList[index], isDark),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
            error: (err, _) => BrandedEmptyState.error(
              error: err.toString(),
              advice: 'Complete lessons and daily challenges to unlock ancestral badges.',
              onRetry: () => ref.invalidate(userArtifactsProvider),
            ),
          ),
        ),
      ),
    );
  }



  void _showSortBottomSheet(BuildContext context, bool isDark, AppLocalization l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest800 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('sort_by'),
                style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.forest900),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.gold500),
                title: Text(l10n.translate('sort_tier'), style: TextStyle(color: isDark ? Colors.white : AppColors.forest900)),
                trailing: _sortBy == 'tier' ? const Icon(Icons.check, color: AppColors.gold500) : null,
                onTap: () {
                  setState(() => _sortBy = 'tier');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up, color: AppColors.gold500),
                title: Text(l10n.translate('sort_progress'), style: TextStyle(color: isDark ? Colors.white : AppColors.forest900)),
                trailing: _sortBy == 'progress' ? const Icon(Icons.check, color: AppColors.gold500) : null,
                onTap: () {
                  setState(() => _sortBy = 'progress');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha, color: AppColors.gold500),
                title: Text(l10n.translate('sort_name'), style: TextStyle(color: isDark ? Colors.white : AppColors.forest900)),
                trailing: _sortBy == 'name' ? const Icon(Icons.check, color: AppColors.gold500) : null,
                onTap: () {
                  setState(() => _sortBy = 'name');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(color: AppColors.gold500.withValues(alpha: 0.2)),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats, bool isDark, AppLocalization l10n) {
    return Row(
      children: [
        _buildStatItem(l10n.translate('collected'), "${stats['earned'] ?? 0}", Icons.auto_awesome, isDark),
        const SizedBox(width: 16),
        _buildStatItem(l10n.translate('total_label'), "${stats['total'] ?? 0}", Icons.temple_hindu, isDark),
        const SizedBox(width: 16),
        _buildStatItem(
          l10n.translate('rank_label'),
          (stats['earned'] ?? 0) >= 10 ? l10n.translate('elder') : ((stats['earned'] ?? 0) >= 5 ? "Warrior" : l10n.translate('novice')),
          Icons.workspace_premium,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: isDark ? AppColors.gold500 : AppColors.gold700, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.4),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtifactCard(BuildContext context, Artifact artifact, bool isDark) {
    final tierColor = _getTierColor(artifact.tier);
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/artifact-detail', extra: artifact);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: artifact.isEarned ? tierColor.withValues(alpha: 0.8) : Colors.transparent,
            width: 2,
          ),
          boxShadow: artifact.isEarned
              ? [
                  BoxShadow(
                    color: tierColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: BrandCard(
          theme: BrandCardTheme.vibrant,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: artifact.imageUrl.isNotEmpty
                          ? GracefulImage(
                              imageUrl: artifact.imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(artifact.emoji, style: const TextStyle(fontSize: 36)),
                              ),
                            ),
                    ),
                    if (!artifact.isEarned)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock_rounded, color: Colors.white70, size: 28),
                        ),
                      ),
                    if (artifact.isEarned)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: tierColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                artifact.title,
                style: AppTypography.h3.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    artifact.tier.name.toUpperCase(),
                    style: AppTypography.label.copyWith(color: tierColor, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${(artifact.progress * 100).toInt()}%",
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: artifact.progress,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(artifact.isEarned ? tierColor : AppColors.gold500),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTierColor(ArtifactTier tier) {
    switch (tier) {
      case ArtifactTier.rare: return Colors.blueAccent;
      case ArtifactTier.sacred: return Colors.purpleAccent;
      case ArtifactTier.ancient: return AppColors.gold500;
      case ArtifactTier.epic: return Colors.deepPurpleAccent;
      case ArtifactTier.legendary: return Colors.orangeAccent;
      case ArtifactTier.common: return Colors.greenAccent;
    }
  }
}
