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
import '../utils/app_localization.dart';
import '../providers/student_provider.dart';

class AncestralVaultShopScreen extends ConsumerStatefulWidget {
  const AncestralVaultShopScreen({super.key});

  @override
  ConsumerState<AncestralVaultShopScreen> createState() =>
      _AncestralVaultShopScreenState();
}

class _AncestralVaultShopScreenState
    extends ConsumerState<AncestralVaultShopScreen> {
  String _selectedCategory = 'ALL';

  static final List<Artifact> _defaultVaultCatalog = [
    // Titles
    Artifact(
      id: 'title_mansaka_elder',
      title: 'Mansaka Elder',
      description: 'A respected keeper of tribal ancestral stories.',
      emoji: '📜',
      type: 'title',
      tier: ArtifactTier.epic,
      crystalCost: 150,
      passiveBonus: '+5% XP from sessions',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'title_tribal_guardian',
      title: 'Tribal Guardian',
      description: 'Sworn protector of indigenous heritage and language.',
      emoji: '🛡️',
      type: 'title',
      tier: ArtifactTier.sacred,
      crystalCost: 200,
      passiveBonus: '+10% XP from quizzes',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'title_sacred_weaver',
      title: 'Sacred Weaver',
      description: 'Master artisan of traditional indigenous patterns.',
      emoji: '🧵',
      type: 'title',
      tier: ArtifactTier.legendary,
      crystalCost: 250,
      passiveBonus: '+15% Mist Crystals from quests',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'title_spirit_chanter',
      title: 'Spirit Chanter',
      description: 'Voice of the ancient oral chants and ancestral echoes.',
      emoji: '🎙️',
      type: 'title',
      tier: ArtifactTier.ancient,
      crystalCost: 300,
      passiveBonus: '+20% XP on speaking practice',
      isAvailableInShop: true,
    ),

    // Avatar Frames
    Artifact(
      id: 'frame_sunburst_gold',
      title: 'Golden Sunburst Frame',
      description: 'Radiant golden sunray halo around your avatar.',
      emoji: '☀️',
      type: 'frame',
      tier: ArtifactTier.rare,
      crystalCost: 100,
      passiveBonus: 'Cultural Sun Aura',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'frame_forest_vine',
      title: 'Forest Vine Frame',
      description: 'Sacred Kagulangan forest vines woven around your avatar.',
      emoji: '🌿',
      type: 'frame',
      tier: ArtifactTier.rare,
      crystalCost: 120,
      passiveBonus: 'Ancestral Forest Halo',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'frame_tribal_flame',
      title: 'Tribal Flame Frame',
      description: 'Sacred spark fire that ignites your warrior presence.',
      emoji: '🔥',
      type: 'frame',
      tier: ArtifactTier.epic,
      crystalCost: 220,
      passiveBonus: 'Sacred Fire Glow',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'frame_ancestral_crown',
      title: 'Ancestral Gold Halo',
      description: 'Glowing golden spirit crown reserved for tribal legends.',
      emoji: '👑',
      type: 'frame',
      tier: ArtifactTier.legendary,
      crystalCost: 350,
      passiveBonus: 'Golden Spirit Crown',
      isAvailableInShop: true,
    ),

    // Badges & Artifacts
    Artifact(
      id: 'badge_waling_waling',
      title: 'Waling-Waling Spark',
      description: 'Sacred orchid emblem representing rare beauty and honor.',
      emoji: '🌸',
      type: 'badge',
      tier: ArtifactTier.common,
      crystalCost: 80,
      passiveBonus: 'Royal Orchid Badge',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'artifact_golden_agung',
      title: 'Golden Agung',
      description: 'Resonant brass gong that summons the spirits of the tribe.',
      emoji: '🔔',
      type: 'artifact',
      tier: ArtifactTier.epic,
      crystalCost: 180,
      passiveBonus: 'Gong of Resonance',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'artifact_kulintang_pearl',
      title: 'Kulintang Pearl',
      description: 'Harmonic pearl instrument used in traditional celebrations.',
      emoji: '💎',
      type: 'badge',
      tier: ArtifactTier.sacred,
      crystalCost: 250,
      passiveBonus: 'Tribe Harmony Gem',
      isAvailableInShop: true,
    ),
    Artifact(
      id: 'badge_agila_emblem',
      title: 'Agila Spirit Emblem',
      description: 'Emblem of the Philippine Eagle, guardian of mountain skies.',
      emoji: '🦅',
      type: 'badge',
      tier: ArtifactTier.ancient,
      crystalCost: 400,
      passiveBonus: 'Great Eagle Badge',
      isAvailableInShop: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final artifactsAsync = ref.watch(artifactsStreamProvider);
    final studentState = ref.watch(studentProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final crystals = studentState.mistCrystals > 0
        ? studentState.mistCrystals
        : (userProfile?['mistCrystals'] ?? 0);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.translate('ancestral_vault_caps'),
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
          ),
        ),
        actions: [_buildCrystalBalance(crystals)],
      ),
      body: Column(
        children: [
          _buildFilterChips(isDark),
          Expanded(
            child: artifactsAsync.when(
              data: (artifacts) {
                final List<Artifact> combinedCatalog = [];
                final Map<String, Artifact> map = {};

                for (var a in artifacts) {
                  if (a.isAvailableInShop) {
                    map[a.id] = a;
                  }
                }

                for (var def in _defaultVaultCatalog) {
                  if (!map.containsKey(def.id)) {
                    map[def.id] = def;
                  }
                }

                combinedCatalog.addAll(map.values);

                final filtered = combinedCatalog.where((a) {
                  if (_selectedCategory == 'TITLES') return a.isTitle;
                  if (_selectedCategory == 'FRAMES') return a.isFrame;
                  if (_selectedCategory == 'BADGES') {
                    return a.isBadge || a.type == 'artifact';
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.translate('vault_sealed'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildShopCard(
                    context,
                    ref,
                    filtered[index],
                    crystals,
                    l10n,
                    isDark,
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold500),
              ),
              error: (_, __) {
                final filtered = _defaultVaultCatalog.where((a) {
                  if (_selectedCategory == 'TITLES') return a.isTitle;
                  if (_selectedCategory == 'FRAMES') return a.isFrame;
                  if (_selectedCategory == 'BADGES') {
                    return a.isBadge || a.type == 'artifact';
                  }
                  return true;
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildShopCard(
                    context,
                    ref,
                    filtered[index],
                    crystals,
                    l10n,
                    isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final categories = [
      {'key': 'ALL', 'label': 'ALL'},
      {'key': 'TITLES', 'label': 'TITLES 📜'},
      {'key': 'FRAMES', 'label': 'FRAMES 🌿'},
      {'key': 'BADGES', 'label': 'BADGES 🏺'},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];

          return ChoiceChip(
            selected: isSelected,
            label: Text(cat['label']!),
            selectedColor: AppColors.gold500,
            backgroundColor: isDark
                ? AppColors.forest800
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            labelStyle: AppTypography.mono.copyWith(
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.white70 : AppColors.creamText2),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppColors.gold500
                    : (isDark
                          ? AppColors.gold500.withValues(alpha: 0.2)
                          : AppColors.creamBorder),
              ),
            ),
            onSelected: (_) {
              HapticService.selection();
              setState(() => _selectedCategory = cat['key']!);
            },
          );
        },
      ),
    );
  }

  Widget _buildCrystalBalance(int balance) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
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
    AppLocalization l10n,
    bool isDark,
  ) {
    final canAfford = userCrystals >= artifact.crystalCost;
    final tierColor = _getTierColor(artifact.tier);

    final isHighTier =
        artifact.tier == ArtifactTier.legendary ||
        artifact.tier == ArtifactTier.ancient;

    final studentState = ref.watch(studentProvider);
    final userProfile = ref.watch(userProfileProvider).value;

    final currentTitle =
        studentState.equippedTitle ?? userProfile?['equippedTitle'];
    final currentBadge =
        studentState.equippedBadge ?? userProfile?['equippedBadge'];
    final currentFrame =
        studentState.equippedFrame ?? userProfile?['equippedFrame'];

    bool isEquipped = false;
    if (artifact.isEarned) {
      if (artifact.isTitle && currentTitle == artifact.title) isEquipped = true;
      if (artifact.isBadge && currentBadge == artifact.emoji) isEquipped = true;
      if (artifact.isFrame && currentFrame == artifact.title) isEquipped = true;
      if (!artifact.isCustomization && currentTitle == artifact.title) {
        isEquipped = true;
      }
    }

    final cardTheme = isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold;
    final cardTextColor = isDark ? Colors.white : AppColors.forest900;
    final costTextColor = isDark ? Colors.white : AppColors.forest900;
    final dividerColor = isDark ? Colors.white10 : AppColors.creamBorder;

    Widget content = BrandCard(
      theme: cardTheme,
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
                    color: tierColor.withValues(alpha: 0.5),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            artifact.title,
            style: AppTypography.h3.copyWith(
              color: isHighTier ? tierColor : cardTextColor,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artifact.passiveBonus ?? l10n.translate('ancestral_blessing'),
            style: AppTypography.label.copyWith(
              color: isDark ? AppColors.semanticGreen : AppColors.forest700,
              fontSize: 10,
              fontWeight: isDark ? null : FontWeight.bold,
            ),
          ),
          Divider(color: dividerColor, height: 20),
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
                      color: costTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticService.selection();
                  if (artifact.isEarned) {
                    if (!isEquipped) {
                      ref.read(studentProvider.notifier).equipCustomization(
                            title: artifact.isTitle || !artifact.isCustomization
                                ? artifact.title
                                : null,
                            emoji: artifact.isBadge ? artifact.emoji : null,
                            frame: artifact.isFrame ? artifact.title : null,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Equipped: "${artifact.title}"!'),
                          backgroundColor: AppColors.semanticGreen,
                        ),
                      );
                    }
                  } else {
                    _showExchangeDialog(
                        context, ref, artifact, canAfford, l10n);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isEquipped
                        ? AppColors.semanticGreen
                        : (artifact.isEarned
                            ? AppColors.gold500
                            : (canAfford
                                ? AppColors.gold500
                                : (isDark ? Colors.white10 : AppColors.creamBorder))),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isEquipped
                        ? 'EQUIPPED ✓'
                        : (artifact.isEarned
                            ? 'EQUIP'
                            : l10n.translate('unlock_caps')),
                    style: AppTypography.mono.copyWith(
                      color: isEquipped
                          ? Colors.black
                          : (artifact.isEarned
                              ? Colors.black
                              : (canAfford
                                  ? Colors.black
                                  : (isDark ? Colors.white24 : AppColors.creamText3))),
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
              color: tierColor.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: tierColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: content,
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .boxShadow(
            begin: BoxShadow(
              color: tierColor.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
            end: BoxShadow(
              color: tierColor.withValues(alpha: 0.4),
              blurRadius: 30,
            ),
            duration: 2.seconds,
          );
    } else if (artifact.tier == ArtifactTier.epic ||
        artifact.tier == ArtifactTier.sacred) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 1),
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
    AppLocalization l10n,
  ) {
    if (!canAfford) {
      HapticService.warning();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('not_enough_crystals_exchange')),
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
                    Text(l10n.translate('sacred_exchange'),
                        style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('exchange_confirm', params: {
                        'cost': artifact.crystalCost.toString(),
                        'item': artifact.title
                      }),
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
                            text: l10n.translate('cancel'),
                            type: BrandButtonType.secondary,
                            onTap: isPurchasing
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BrandButton(
                            text: isPurchasing
                                ? l10n.translate('processing')
                                : l10n
                                    .translate('unlock_caps')
                                    .toLowerCase()
                                    .capitalize(),
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
                                        ref
                                            .read(studentProvider.notifier)
                                            .spendMistCrystals(
                                                artifact.crystalCost);

                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        HapticService.artifactUnlock();
                                        ref
                                            .read(audioServiceProvider)
                                            .playSFX('milestone');
                                        _showSuccessOverlay(
                                            context, artifact, l10n);
                                      } catch (e) {
                                        setDialogState(
                                          () => isPurchasing = false,
                                        );
                                        HapticService.error();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                              content: Text(e.toString())),
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

  void _showSuccessOverlay(
      BuildContext context, Artifact artifact, AppLocalization l10n) {
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
                  l10n.translate('legacy_unlocked'),
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
                  l10n.translate('tap_return_vault'),
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
