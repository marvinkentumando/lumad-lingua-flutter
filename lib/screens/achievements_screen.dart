import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifactsAsync = ref.watch(userArtifactsProvider);
    final stats = ref.watch(artifactStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ancestral Honors',
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
      ),
      extendBodyBehindAppBar: true,
      body: BrandBackground(
        child: SafeArea(
          child: artifactsAsync.when(
            data: (artifacts) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Legacy",
                      style: AppTypography.display.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tracing your journey through ancestral wisdom.",
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppColors.forest900.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildStatsRow(stats, isDark),
                    const SizedBox(height: 40),
                    _buildSectionHeader("Ancestral Vault"),
                    const SizedBox(height: 16),
                    if (artifacts.isEmpty)
                      const BrandedEmptyState(
                        title: "Vault Locked",
                        message: "Complete lessons to unlock cultural treasures.",
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
                          childAspectRatio: 0.75,
                        ),
                        itemCount: artifacts.length,
                        itemBuilder: (context, index) => 
                            _buildArtifactCard(context, artifacts[index], isDark),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error: $err")),
          ),
        ),
      ),
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

  Widget _buildStatsRow(Map<String, dynamic> stats, bool isDark) {
    return Row(
      children: [
        _buildStatItem("Collected", "${stats['earned'] ?? 0}", Icons.auto_awesome, isDark),
        const SizedBox(width: 16),
        _buildStatItem("Total", "${stats['total'] ?? 0}", Icons.temple_hindu, isDark),
        const SizedBox(width: 16),
        _buildStatItem(
          "Rank",
          (stats['earned'] ?? 0) >= 10 ? "Elder" : ((stats['earned'] ?? 0) >= 5 ? "Warrior" : "Novice"),
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
                color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4),
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
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: artifact.imageUrl.isNotEmpty
                  ? GracefulImage(
                      imageUrl: artifact.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 8,
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(artifact.emoji, style: const TextStyle(fontSize: 32)),
                      ),
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
            const SizedBox(height: 4),
            Text(
              artifact.tier.name.toUpperCase(),
              style: AppTypography.label.copyWith(color: tierColor, fontSize: 8),
            ),
          ],
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

