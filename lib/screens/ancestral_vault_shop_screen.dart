import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../models/artifact.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../services/audio_service.dart';
import '../widgets/spirit_particle_overlay.dart';


class AncestralVaultShopScreen extends ConsumerWidget {
  const AncestralVaultShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifactsAsync = ref.watch(artifactsStreamProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final crystals = userProfile?['mistCrystals'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.forest900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ANCESTRAL VAULT',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
          ),
        ),
        actions: [_buildCrystalBalance(crystals)],
      ),
      body: artifactsAsync.when(
        data: (artifacts) {
          final shopItems = artifacts
              .where((a) => a.isAvailableInShop)
              .toList();

          if (shopItems.isEmpty) {
            return const Center(
              child: Text(
                "The vault is currently sealed.\nCheck back after your next ritual.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: shopItems.length,
            itemBuilder: (context, index) =>
                _buildShopCard(context, ref, shopItems[index], crystals),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold500),
        ),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildCrystalBalance(int balance) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.gold500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold500.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.diamond_outlined,
            color: AppColors.gold500,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            "$balance",
            style: AppTypography.mono.copyWith(
              color: AppColors.gold500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(ArtifactTier tier) {
    switch (tier) {
      case ArtifactTier.common:
        return Colors.white54;
      case ArtifactTier.rare:
        return Colors.blueAccent;
      case ArtifactTier.epic:
        return Colors.purpleAccent;
      case ArtifactTier.sacred:
        return Colors.cyanAccent;
      case ArtifactTier.ancient:
        return AppColors.gold500;
      case ArtifactTier.legendary:
        return Colors.orangeAccent;
    }
  }

  Widget _buildShopCard(
    BuildContext context,
    WidgetRef ref,
    Artifact artifact,
    int userCrystals,
  ) {
    final canAfford = userCrystals >= artifact.crystalCost;
    final tierColor = _getTierColor(artifact.tier);

    final isHighTier =
        artifact.tier == ArtifactTier.legendary ||
        artifact.tier == ArtifactTier.ancient;

    Widget content = BrandCard(
      theme: BrandCardTheme.vibrant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Text(artifact.emoji, style: const TextStyle(fontSize: 48))
                  .animate(
                    onPlay: (c) =>
                        isHighTier ? c.repeat(reverse: true) : c.repeat(),
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: isHighTier ? 1.15 : 1.0,
                    duration: 1000.ms,
                  )
                  .shimmer(
                    duration: 2.seconds,
                    color: tierColor.withOpacity(0.5),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            artifact.title,
            style: AppTypography.h3.copyWith(
              color: isHighTier ? tierColor : Colors.white,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artifact.passiveBonus ?? "Ancestral blessing",
            style: AppTypography.label.copyWith(
              color: AppColors.semanticGreen,
              fontSize: 10,
            ),
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.diamond_outlined,
                    color: AppColors.gold500,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${artifact.crystalCost}",
                    style: AppTypography.mono.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                    HapticService.selection();
                    _showExchangeDialog(context, ref, artifact, canAfford);
                },

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: canAfford ? AppColors.gold500 : Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "UNLOCK",
                    style: AppTypography.mono.copyWith(
                      color: canAfford ? Colors.black : Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isHighTier) {
      return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: tierColor.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: tierColor.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: content,
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .boxShadow(
            begin: BoxShadow(
              color: tierColor.withOpacity(0.1),
              blurRadius: 10,
            ),
            end: BoxShadow(
              color: tierColor.withOpacity(0.4),
              blurRadius: 30,
            ),
            duration: 2.seconds,
          );
    } else if (artifact.tier == ArtifactTier.epic ||
        artifact.tier == ArtifactTier.sacred) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tierColor.withOpacity(0.3), width: 1),
        ),
        child: content,
      );
    }

    return content;
  }

  void _showExchangeDialog(
    BuildContext context,
    WidgetRef ref,
    Artifact artifact,
    bool canAfford,
  ) {
    if (!canAfford) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You require more Mist Crystals for this exchange."),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isPurchasing = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: BrandCard(
                theme: BrandCardTheme.cream,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(artifact.emoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text("Sacred Exchange", style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Text(
                      "Do you wish to spend ${artifact.crystalCost} Mist Crystals to unlock the ${artifact.title}?",
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.creamText3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: BrandButton(
                            text: "Cancel",
                            type: BrandButtonType.secondary,
                            onTap: isPurchasing
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BrandButton(
                            text: isPurchasing ? "Processing..." : "Unlock",
                            type: BrandButtonType.primary,
                            onTap: isPurchasing
                                ? null
                                : () async {
                                    final userId = ref
                                        .read(authServiceProvider)
                                        .currentUser
                                        ?.uid;
                                    if (userId != null) {
                                      setDialogState(() => isPurchasing = true);
                                      try {
                                        await ref
                                            .read(firebaseServiceProvider)
                                            .purchaseArtifact(
                                              userId,
                                              artifact.id,
                                              artifact.crystalCost,
                                            );
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        HapticService.artifactUnlock();
                                        ref.read(audioServiceProvider).playSFX('milestone');
                                        _showSuccessOverlay(context, artifact);

                                      } catch (e) {
                                        setDialogState(
                                          () => isPurchasing = false,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessOverlay(BuildContext context, Artifact artifact) {
    showSpiritParticles(context, duration: const Duration(seconds: 4));
    showDialog(

      context: context,
      barrierDismissible: false,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Material(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(artifact.emoji, style: const TextStyle(fontSize: 120))
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1.seconds),
                const SizedBox(height: 24),
                Text(
                  "LEGACY UNLOCKED",
                  style: AppTypography.display.copyWith(
                    color: AppColors.gold500,
                    fontSize: 32,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
                const SizedBox(height: 8),
                Text(
                  artifact.title,
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 40),
                Text(
                  "Tap to return to the vault",
                  style: AppTypography.mono.copyWith(
                    color: Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


