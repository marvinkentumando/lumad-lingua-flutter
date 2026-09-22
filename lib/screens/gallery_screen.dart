import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumad_lingua/theme/app_colors.dart';
import 'package:lumad_lingua/theme/app_typography.dart';
import 'package:lumad_lingua/widgets/brand_card.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'package:lumad_lingua/models/artifact.dart';
import 'package:lumad_lingua/models/gallery_models.dart';
import 'package:lumad_lingua/utils/gallery_utils.dart';
import 'package:animations/animations.dart';
import 'artifact_detail_screen.dart';
import '../services/haptic_service.dart';
import 'package:lumad_lingua/widgets/app_shimmer_skeleton.dart';
import '../widgets/branded_empty_state.dart';
import '../widgets/graceful_image.dart';
import '../utils/app_localization.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String _selectedTier = 'All';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final badgesAsync = user != null
        ? ref.watch(userBadgesStreamProvider(user.uid))
        : const AsyncValue<List<GalleryBadge>>.data([]);
    final artifactsAsync = ref.watch(artifactsStreamProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: AppColors.forest800,
      appBar: AppBar(
        title: Text(l10n.translate('ancestral_gallery')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Badge Collection",
              style: AppTypography.display.copyWith(
                fontSize: 28,
                color: AppColors.gold500,
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
            const SizedBox(height: 16),
            badgesAsync.when(
              data: (badges) => _buildBadgeGrid(badges),
              loading: () => _buildBadgeAppShimmerSkeleton(),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                      "Sacred Artifacts",
                      style: AppTypography.display.copyWith(
                        fontSize: 28,
                        color: AppColors.gold500,
                      ),
                    )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.2),
                _buildTierFilter(),
              ],
            ),
            const SizedBox(height: 16),
            artifactsAsync.when(
              data: (artifacts) {
                final filtered = _selectedTier == 'All' 
                    ? artifacts 
                    : artifacts.where((a) => a.tier.name.toLowerCase() == _selectedTier.toLowerCase()).toList();
                return _buildArtifactScroll(filtered);
              },
              loading: () => _buildArtifactAppShimmerSkeleton(),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 40),

            Text(
              "Oral Histories",
              style: AppTypography.display.copyWith(
                fontSize: 28,
                color: AppColors.gold500,
              ),
            ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.2),
            const SizedBox(height: 16),
            ..._buildLegendList(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTierFilter() {
    final tiers = ['All', 'Common', 'Rare', 'Epic', 'Legendary'];
    return PopupMenuButton<String>(
      onSelected: (tier) => setState(() => _selectedTier = tier),
      icon: const Icon(Icons.filter_list_rounded, color: AppColors.gold500),
      color: AppColors.forest900,
      itemBuilder: (context) => tiers
          .map(
            (tier) => PopupMenuItem(
              value: tier,
              child: Text(
                tier,
                style: TextStyle(
                  color: _selectedTier == tier
                      ? AppColors.gold500
                      : Colors.white70,
                  fontWeight: _selectedTier == tier
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildArtifactScroll(List<Artifact> artifacts) {
    if (artifacts.isEmpty) {
      return const BrandedEmptyState(
        title: "Vault Empty",
        message: "Searching the ancestral archives... Continue your journey to discover sacred artifacts.",
        icon: Icons.search_off_rounded,
      );
    }

    return SizedBox(
      height: 360,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: artifacts.length,
        itemBuilder: (context, index) {
          final artifact = artifacts[index];
          return OpenContainer(
                closedColor: Colors.transparent,
                closedElevation: 0,
                openElevation: 0,
                transitionDuration: const Duration(milliseconds: 600),
                openBuilder: (context, _) =>
                    ArtifactDetailScreen(artifact: artifact),
                closedBuilder: (context, openContainer) => GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    openContainer();
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 20),
                    child: BrandCard(
                      theme: BrandCardTheme.cream,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GracefulImage(
                              imageUrl: artifact.imageUrl,
                              width: double.infinity,
                              borderRadius: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            artifact.title,
                            style: AppTypography.h2.copyWith(
                              color: AppColors.creamText,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            artifact.description,
                            style: AppTypography.body.copyWith(
                              color: AppColors.creamText2,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTierColor(
                                    artifact.tier,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _getTierColor(
                                      artifact.tier,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  artifact.tier.name.toUpperCase(),
                                  style: AppTypography.label.copyWith(
                                    color: _getTierColor(artifact.tier),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(
                                  artifact.rarity,
                                  (index) => const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.gold500,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate(delay: (200 * index).ms)
              .fadeIn(duration: 500.ms)
              .slideX(begin: 0.1);
        },
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

  List<Widget> _buildLegendList(BuildContext context) {
    return _staticLegends.asMap().entries.map((entry) {
      final index = entry.key;
      final legend = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: BrandCard(
          theme: BrandCardTheme.vibrant,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              legend['title']!,
              style: AppTypography.h3.copyWith(color: Colors.white),
            ),
            subtitle: Text(
              legend['excerpt']!,
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gold500,
              size: 16,
            ),
            onTap: () {
              final artifactFromLegend = Artifact(
                id: 'legend_$index',
                title: legend['title']!,
                description: legend['excerpt']!,
                imageUrl: "",
                type: "legend",
              );
              context.push('/artifact-detail', extra: artifactFromLegend);
            },
          ),
        ),
      ).animate(delay: (400 + (100 * index)).ms).fadeIn().slideY(begin: 0.2);
    }).toList();
  }

  Widget _buildBadgeGrid(List<GalleryBadge> badges) {
    if (badges.isEmpty) {
      return const BrandedEmptyState(
        title: "No Spirit Tokens",
        message: "Earn badges by participating in the community and completing ancestral lessons.",
        icon: Icons.workspace_premium_outlined,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final badgeColor = GalleryUtils.getColorFromHex(badge.colorHex);

        return Column(
          children: [
            Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: badge.isEarned
                        ? badgeColor.withValues(alpha: 0.2)
                        : Colors.white10,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: badge.isEarned ? badgeColor : Colors.white24,
                      width: 2,
                    ),
                    boxShadow: badge.isEarned
                        ? [
                            BoxShadow(
                              color: badgeColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    GalleryUtils.getIconData(badge.iconName),
                    color: badge.isEarned ? badgeColor : Colors.white24,
                    size: 32,
                  ),
                )
                .animate(onPlay: (c) => badge.isEarned ? c.repeat() : null)
                .shimmer(delay: 2.seconds, duration: 2.seconds),
            const SizedBox(height: 8),
            Text(
              badge.title,
              style: AppTypography.label.copyWith(
                color: badge.isEarned ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBadgeAppShimmerSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 3,
      itemBuilder: (context, index) => const Column(
        children: [
          AppShimmerSkeleton(width: 70, height: 70, isCircle: true),
          SizedBox(height: 8),
          AppShimmerSkeleton(width: 50, height: 10),
        ],
      ),
    );
  }

  Widget _buildArtifactAppShimmerSkeleton() {
    return SizedBox(
      height: 360,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 280,
          margin: const EdgeInsets.only(right: 20),
          child: const BrandCard(
            theme: BrandCardTheme.cream,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: AppShimmerSkeleton(borderRadius: 12)),
                SizedBox(height: 16),
                AppShimmerSkeleton(width: 150, height: 20),
                SizedBox(height: 8),
                AppShimmerSkeleton(width: 200, height: 12),
                SizedBox(height: 4),
                AppShimmerSkeleton(width: 180, height: 12),
                SizedBox(height: 16),
                Row(
                  children: [
                    AppShimmerSkeleton(width: 60, height: 20),
                    Spacer(),
                    AppShimmerSkeleton(width: 40, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<Map<String, String>> _staticLegends = [
    {
      "title": "Creation of the First People",
      "excerpt":
          "A timeless Mansaka tale of how the world was carved from a giant bird's wing...",
    },
    {
      "title": "The Golden Spirit",
      "excerpt":
          "A Mansaka legend about the spirit of the mountains who guided the first tribe to the valley...",
    },
    {
      "title": "Mt. Hamiguitan's Guardian",
      "excerpt":
          "The story of the ancient spirit protecting the pygmy forests of the east...",
    },
  ];
}
