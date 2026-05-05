import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lumad_lingua/theme/app_colors.dart';
import 'package:lumad_lingua/theme/app_typography.dart';
import 'package:lumad_lingua/widgets/brand_button.dart';
import 'package:lumad_lingua/widgets/brand_card.dart';
import 'package:lumad_lingua/models/artifact.dart';

class ArtifactDetailScreen extends StatelessWidget {
  final Artifact artifact;

  const ArtifactDetailScreen({super.key, required this.artifact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest900,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Parallax Header
          SliverAppBar(
            expandedHeight: 400.0,
            stretch: true,
            backgroundColor: AppColors.forest900,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: BackButton(color: AppColors.gold500),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image with Gradient Overlay
                  artifact.imageUrl.isNotEmpty
                      ? Hero(
                          tag: 'artifact_${artifact.id}',
                          child: (artifact.imageUrl.startsWith('http')
                              ? Image.network(
                                  artifact.imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(artifact.imageUrl, fit: BoxFit.cover)),
                        )
                      : Container(
                          color: AppColors.forest800,
                          child: Center(
                            child: Icon(
                              _getIcon(artifact.type),
                              size: 100,
                              color: AppColors.gold500.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.forest900],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      artifact.type.toUpperCase(),
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTierColor(
                            artifact.tier,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
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
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(width: 12),
                      Row(
                        children: List.generate(
                          artifact.rarity,
                          (index) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold500,
                            size: 16,
                          ),
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    artifact.title,
                    style: AppTypography.display.copyWith(
                      fontSize: 36,
                      color: AppColors.gold500,
                      height: 1.1,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    artifact.description,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.creamText2,
                      height: 1.6,
                      fontSize: 18,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),

                  // Legend Section
                  _buildSectionHeader(
                    context,
                    "Lore & Legend",
                    Icons.auto_stories_outlined,
                  ),
                  const SizedBox(height: 16),
                  BrandCard(
                    theme: BrandCardTheme.vibrant,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artifact.legend ?? "No legend yet. Uncover more rituals to reveal the full story of this sacred object.",
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.7,
                            fontStyle: artifact.legend != null ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        if (artifact.culturalNote != null) ...[
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),
                          Text(
                            "ELDERS' NOTE",
                            style: AppTypography.label.copyWith(
                              color: AppColors.gold500,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artifact.culturalNote!,
                            style: AppTypography.body.copyWith(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 32),

                  // Material & Origin Section
                  _buildSectionHeader(
                    context,
                    "Origin & Craft",
                    Icons.token_outlined,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildOriginChip(
                        "Mountain Region",
                        Icons.terrain_outlined,
                      ),
                      const SizedBox(width: 12),
                      _buildOriginChip("Abaca Fiber", Icons.grass_outlined),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 48),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: BrandButton(
                          text: "SHARE HERITAGE",
                          type: BrandButtonType.primary,
                          icon: Icons.share_outlined,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Sharing lineage story..."),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.forest800,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.forest700),
                        ),
                        child: const Icon(
                          Icons.bookmark_border,
                          color: AppColors.gold500,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1.seconds).slideY(begin: 0.1),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold500, size: 20),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: Colors.white38,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.forest800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold500, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: AppColors.creamText3,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'tool':
        return Icons.construction;
      case 'clothing':
        return Icons.checkroom_rounded;
      case 'instrument':
        return Icons.music_note;
      default:
        return Icons.category;
    }
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
