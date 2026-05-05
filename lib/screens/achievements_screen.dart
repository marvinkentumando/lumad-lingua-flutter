import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lumad_lingua/theme/app_colors.dart';
import 'package:lumad_lingua/theme/app_typography.dart';
import 'package:lumad_lingua/widgets/brand_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumad_lingua/providers/artifact_provider.dart';
import 'package:lumad_lingua/models/artifact.dart';
import 'package:lumad_lingua/models/gallery_models.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import 'package:lumad_lingua/utils/gallery_utils.dart';
import 'package:go_router/go_router.dart';
import '../services/haptic_service.dart';

import '../widgets/skeleton.dart';
import '../widgets/graceful_image.dart';
import '../widgets/branded_empty_state.dart';

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final double progress;

  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0.0,
  });
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateProvider).value;
    final artifactsAsync = ref.watch(userArtifactsProvider);
    final badgesAsync = user != null
        ? ref.watch(userBadgesStreamProvider(user.uid))
        : const AsyncValue<List<GalleryBadge>>.data([]);
    final stats = ref.watch(artifactStatsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ancestral Honors'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Stats Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Legacy",
                    style: AppTypography.display.copyWith(
                      color: isDark ? AppColors.gold500 : AppColors.forest500,
                      fontSize: 32,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                    "Tracing your journey through the ancestral wisdom.",
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white54 : AppColors.creamText2,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),
                  _buildStatsRow(stats),
                ],
              ),
            ),
          ),

          // Badges Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Spirit Tokens"),
                  const SizedBox(height: 16),
                  badgesAsync.when(
                    data: (badges) => _buildBadgeList(badges),
                    loading: () => _buildBadgeSkeleton(),
                    error: (err, _) => Text("Error loading tokens: $err"),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Artifacts Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader("Ancestral Vault"),
                      TextButton.icon(
                        onPressed: () {
                          HapticService.selection();
                          context.push('/ancestral-vault-shop');
                        },

                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.gold500,
                          size: 16,
                        ),
                        label: Text(
                          "VISIT SHOP",
                          style: AppTypography.mono.copyWith(
                            color: AppColors.gold500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          artifactsAsync.when(
            data: (artifacts) {
              if (artifacts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: BrandedEmptyState(
                    title: "Vault Locked",
                    message: "You haven't earned any ancestral artifacts yet. Complete lessons to unlock cultural treasures.",
                    icon: Icons.lock_outline,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildArtifactCard(context, artifacts[index]),
                    childCount: artifacts.length,
                  ),
                ),
              );
            },
            loading: () => _buildArtifactSkeleton(),
            error: (err, _) => SliverToBoxAdapter(child: Text("Error: $err")),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
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
          child: Divider(color: AppColors.gold500.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildStatItem(
          "Collected",
          "${stats['earned'] ?? 0}",
          Icons.auto_awesome,
        ),
        const SizedBox(width: 16),
        _buildStatItem("Total", "${stats['total'] ?? 0}", Icons.temple_hindu),
        const SizedBox(width: 16),
        _buildStatItem(
          "Rank",
          (stats['earned'] ?? 0) >= 10 ? "Elder" : ((stats['earned'] ?? 0) >= 5 ? "Warrior" : "Novice"),
          Icons.workspace_premium,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold500, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: Colors.white38,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeList(List<GalleryBadge> badges) {
    if (badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "No spirit tokens earned yet.",
            style: TextStyle(color: Colors.white24),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          final color = GalleryUtils.getColorFromHex(badge.colorHex);
          final tierLabel = _getRomanNumeral(badge.tier);

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: badge.isEarned
                          ? color.withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                      child: Icon(
                        GalleryUtils.getIconData(badge.iconName),
                        color: badge.isEarned ? color : Colors.white10,
                      ),
                    ),
                    if (badge.isEarned && badge.tier > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          tierLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  badge.title,
                  style: AppTypography.label.copyWith(
                    color: badge.isEarned ? Colors.white70 : Colors.white10,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().fadeIn(delay: (100 * index).ms).scale();
        },
      ),
    );
  }

  String _getRomanNumeral(int tier) {
    switch (tier) {
      case 1:
        return "I";
      case 2:
        return "II";
      case 3:
        return "III";
      default:
        return "";
    }
  }

  Widget _buildArtifactCard(BuildContext context, Artifact artifact) {
    final tierColor = _getTierColor(artifact.tier);

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/artifact-detail', extra: artifact);
      },

      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GracefulImage(
                imageUrl: artifact.imageUrl,
                width: double.infinity,
                borderRadius: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              artifact.title,
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: tierColor.withOpacity(0.3)),
              ),
              child: Text(
                artifact.tier.name.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: tierColor,
                  fontSize: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeSkeleton() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) => Container(

          width: 80,
          margin: const EdgeInsets.only(right: 16),
          child: const Column(
            children: [
              Skeleton(width: 60, height: 60, isCircle: true),
              SizedBox(height: 8),
              Skeleton(width: 50, height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtifactSkeleton() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const BrandCard(
            theme: BrandCardTheme.vibrant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Skeleton(borderRadius: 8)),
                SizedBox(height: 12),
                Skeleton(width: 100, height: 14),
                SizedBox(height: 4),
                Skeleton(width: 60, height: 10),
              ],
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  Color _getTierColor(ArtifactTier tier) {
    switch (tier) {
      case ArtifactTier.rare:
        return Colors.blueAccent;
      case ArtifactTier.sacred:
        return Colors.purpleAccent;
      case ArtifactTier.ancient:
        return AppColors.gold500;
      case ArtifactTier.epic:
        return Colors.deepPurpleAccent;
      case ArtifactTier.legendary:
        return Colors.orangeAccent;
      case ArtifactTier.common:
        return Colors.greenAccent;
    }
  }
}


