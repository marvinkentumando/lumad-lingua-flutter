import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/artifact.dart';
import '../../providers/artifact_provider.dart';
import '../brand_card.dart';
import '../branded_empty_state.dart';
import '../graceful_image.dart';
import 'package:lumad_lingua/widgets/app_shimmer_skeleton.dart';

class ArtifactInventorySection extends ConsumerWidget {
  final String? userId; // If null, shows current user's artifacts

  const ArtifactInventorySection({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final artifactsAsync = userId == null
        ? ref.watch(userArtifactsProvider)
        : ref.watch(otherUserArtifactsProvider(userId!));
    
    // Stats are only for the current user in this implementation, 
    // or we'd need a family for artifactStatsProvider
    final stats = userId == null 
        ? ref.watch(artifactStatsProvider)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recovered Artifacts',
                  style: AppTypography.h3.copyWith(
                    color: isDark ? AppColors.gold500 : AppColors.forest500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (stats != null)
                  Text(
                    '${stats['earned']} of ${stats['total']} recovered',
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white60 : AppColors.creamText2,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/achievements'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.gold500.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'VIEW ALL',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        artifactsAsync.when(
          data: (artifacts) {
            if (artifacts.isEmpty) {
              return const BrandedEmptyState(
                title: 'No Artifacts',
                message: 'No ancestral artifacts have been recovered yet. Continue the journey to discover cultural treasures.',
                icon: Icons.lock_outline,
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: artifacts.length > 5 ? 5 : artifacts.length,
                separatorBuilder: (context, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _ArtifactInventoryCard(artifact: artifacts[index]);
                },
              ),
            );
          },
          loading: () => _buildAppShimmerSkeleton(),
          error: (e, _) => Text(
            'Error loading archives',
            style: TextStyle(color: AppColors.semanticRed.withValues(alpha: 0.5)),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAppShimmerSkeleton() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) => const AppShimmerSkeleton(width: 110, height: 160, borderRadius: 24),
      ),
    );
  }
}

class _ArtifactInventoryCard extends StatelessWidget {
  final Artifact artifact;

  const _ArtifactInventoryCard({required this.artifact});

  @override
  Widget build(BuildContext context) {
    final isEarned = artifact.isEarned;
    final tierColor = _getTierColor(artifact.tier);

    return GestureDetector(
      onTap: () => context.push('/artifact-detail', extra: artifact),
      child: Hero(
        tag: 'artifact_${artifact.id}',
        child: BrandCard(
          theme: isEarned ? BrandCardTheme.cream : BrandCardTheme.vibrant,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          borderRadius: 24,
          child: SizedBox(
            width: 110,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEarned
                        ? tierColor.withValues(alpha: 0.1)
                        : Colors.black26,
                    border: Border.all(
                      color: isEarned
                          ? tierColor.withValues(alpha: 0.5)
                          : Colors.white10,
                      width: 2,
                    ),
                    boxShadow: isEarned
                        ? [
                            BoxShadow(
                              color: tierColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: isEarned ? 1.0 : 0.3,
                    child: artifact.imageUrl.isNotEmpty
                        ? GracefulImage(
                            imageUrl: artifact.imageUrl,
                            width: 52,
                            height: 52,
                            borderRadius: 26,
                          )
                        : Text(
                            artifact.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  artifact.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: isEarned ? Colors.white : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isEarned) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: artifact.progress,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tierColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${artifact.currentProgress}/${artifact.targetValue}',
                    style: AppTypography.label.copyWith(
                      fontSize: 8,
                      color: Colors.white24,
                    ),
                  ),
                ] else
                  Text(
                    artifact.tier.name.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      fontSize: 8,
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTierColor(ArtifactTier tier) {
    switch (tier) {
      case ArtifactTier.ancient:
        return AppColors.gold500;
      case ArtifactTier.sacred:
        return Colors.purpleAccent;
      case ArtifactTier.legendary:
        return Colors.orangeAccent;
      case ArtifactTier.epic:
        return Colors.deepPurpleAccent;
      case ArtifactTier.rare:
        return Colors.blueAccent;
      case ArtifactTier.common:
        return Colors.greenAccent;
    }
  }
}
