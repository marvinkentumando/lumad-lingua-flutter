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
  String _selectedCategory = 'ALL';     // 'ALL', 'EARNED', 'LOCKED', 'TITLES', 'FRAMES', 'BADGES'

  @override
  Widget build(BuildContext context) {
    final artifactsAsync = ref.watch(userArtifactsProvider);
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
      ),
      extendBodyBehindAppBar: true,
      body: BrandBackground(
        child: SafeArea(
          child: artifactsAsync.when(
            data: (artifacts) {
              // Apply category filtering
              List<Artifact> filteredList = artifacts.where((a) {
                if (_selectedCategory == 'EARNED') return a.isEarned;
                if (_selectedCategory == 'LOCKED') return !a.isEarned;
                if (_selectedCategory == 'TITLES') return a.isTitle;
                if (_selectedCategory == 'FRAMES') return a.isFrame;
                if (_selectedCategory == 'BADGES') return a.isBadge;
                return true;
              }).toList();

              // Default sorting by tier index descending
              filteredList.sort((a, b) => b.tier.index.compareTo(a.tier.index));

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
                    _buildSectionHeader(l10n.translate('ancestral_vault')),
                    const SizedBox(height: 12),
                    _buildCategoryFilterRow(isDark),
                    const SizedBox(height: 16),
                    if (filteredList.isEmpty)
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
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) => 
                            _buildArtifactCard(context, filteredList[index], isDark),
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

  Widget _buildCategoryFilterRow(bool isDark) {
    final categories = ['ALL', 'EARNED', 'LOCKED', 'TITLES', 'FRAMES', 'BADGES'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticService.selection();
                setState(() => _selectedCategory = cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold500 : Colors.white.withValues(alpha: isDark ? 0.05 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.gold500 : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Text(
                  cat,
                  style: AppTypography.label.copyWith(
                    color: isSelected ? AppColors.forest900 : (isDark ? Colors.white70 : AppColors.forest900),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showArtifactDetailModal(BuildContext context, Artifact artifact, bool isDark) {
    final tierColor = _getTierColor(artifact.tier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.forest800 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(artifact.emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                artifact.tier.name.toUpperCase(),
                                style: TextStyle(color: tierColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (artifact.isEarned)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.semanticGreen.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'UNLOCKED',
                                  style: TextStyle(color: AppColors.semanticGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LOCKED',
                                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          artifact.title,
                          style: AppTypography.h3.copyWith(
                            color: isDark ? Colors.white : AppColors.forest900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                artifact.description,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (artifact.legend != null && artifact.legend!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'LORE & LEGEND',
                  style: AppTypography.label.copyWith(color: AppColors.gold500, fontSize: 10, letterSpacing: 1.5),
                ),
                const SizedBox(height: 6),
                Text(
                  artifact.legend!,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (artifact.passiveBonus != null && artifact.passiveBonus!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.gold500, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Passive Bonus: ${artifact.passiveBonus}',
                        style: const TextStyle(
                          color: AppColors.gold500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.pop();
                        context.push('/artifact-detail', extra: artifact);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold500,
                        side: const BorderSide(color: AppColors.gold500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('VIEW FULL DETAILS'),
                    ),
                  ),
                  if (artifact.isEarned && artifact.isCustomization) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticService.celebration();
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Equipped "${artifact.title}"! 🌿'),
                              backgroundColor: AppColors.semanticGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold500,
                          foregroundColor: AppColors.forest900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('EQUIP', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
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

  Widget _buildArtifactCard(BuildContext context, Artifact artifact, bool isDark) {
    final tierColor = _getTierColor(artifact.tier);
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        _showArtifactDetailModal(context, artifact, isDark);
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
              Text(
                artifact.tier.name.toUpperCase(),
                style: AppTypography.label.copyWith(color: tierColor, fontSize: 8, fontWeight: FontWeight.bold),
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
