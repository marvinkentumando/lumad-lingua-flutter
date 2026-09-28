import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/haptic_service.dart';
import '../services/audio_service.dart';
import '../utils/app_localization.dart';
import 'spirit_particle_overlay.dart';
import 'crystal_burst_animation.dart';

/// Modal dialog for claiming Tribal Quest & Daily Challenge rewards.
/// Features high-impact cultural visuals, spirit particles, count-up animations,
/// and interactive claim feedback.
class ClaimRewardModal extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final int crystalsReward;
  final int xpReward;
  final int? streakDays;
  final IconData icon;
  final VoidCallback? onClaimed;

  const ClaimRewardModal({
    super.key,
    required this.title,
    required this.subtitle,
    this.crystalsReward = 0,
    this.xpReward = 0,
    this.streakDays,
    this.icon = Icons.auto_awesome_rounded,
    this.onClaimed,
  });

  @override
  ConsumerState<ClaimRewardModal> createState() => _ClaimRewardModalState();
}

class _ClaimRewardModalState extends ConsumerState<ClaimRewardModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _showBurst = true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Trigger haptic and audio feedback on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticService.celebration();
      ref.read(audioServiceProvider).playSFX('session_complete');
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleClaim() {
    HapticService.success();
    ref.read(audioServiceProvider).playSFX('success');
    widget.onClaimed?.call();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ethereal Spirit Particle Overlay in Background
          Positioned.fill(
            child: SpiritParticleOverlay(
              duration: const Duration(seconds: 4),
              particleCount: 35,
              colors: const [
                AppColors.gold500,
                AppColors.gold700,
                Colors.amber,
                Colors.orangeAccent,
                Colors.white,
              ],
            ),
          ),

          // Main Card Container
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.forest900 : AppColors.creamBg,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: AppColors.gold500,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold500.withValues(alpha: 0.35),
                  blurRadius: 50,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),

                // Rotating Sun Ray Badge Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Rotating Sun Rays Effect
                    RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.gold500.withValues(alpha: 0.0),
                              AppColors.gold500.withValues(alpha: 0.3),
                              AppColors.gold500.withValues(alpha: 0.0),
                              AppColors.gold500.withValues(alpha: 0.3),
                              AppColors.gold500.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Glowing Pulse Circle
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold500.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.gold500.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.08, 1.08),
                          duration: 1200.ms,
                          curve: Curves.easeInOut,
                        ),

                    // Inner Icon Badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.gold500,
                            AppColors.gold700,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold500.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.black,
                        size: 42,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 24),

                // Claim Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'HARVEST OF WISDOM',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                const SizedBox(height: 12),

                // Main Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.h1ExtraBold.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 24,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

                const SizedBox(height: 6),

                // Subtitle / Quest Description
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white70 : AppColors.forest700,
                    fontSize: 13,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),

                // Rewards Row / Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.crystalsReward > 0) ...[
                      _buildRewardChip(
                        context: context,
                        icon: '✨',
                        label: l10n.translate('mist_crystals'),
                        amount: widget.crystalsReward,
                        color: AppColors.gold500,
                        delayMs: 500,
                      ),
                    ],
                    if (widget.crystalsReward > 0 && widget.xpReward > 0)
                      const SizedBox(width: 12),
                    if (widget.xpReward > 0) ...[
                      _buildRewardChip(
                        context: context,
                        icon: '🔥',
                        label: l10n.translate('archive_xp'),
                        amount: widget.xpReward,
                        color: Colors.deepOrangeAccent,
                        delayMs: 650,
                      ),
                    ],
                    if (widget.streakDays != null && widget.streakDays! > 0) ...[
                      if (widget.crystalsReward > 0 || widget.xpReward > 0)
                        const SizedBox(width: 12),
                      _buildRewardChip(
                        context: context,
                        icon: '☀️',
                        label: 'STREAK',
                        amount: widget.streakDays!,
                        unit: 'DAYS',
                        color: Colors.amber,
                        delayMs: 800,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                // Claim Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold500,
                      foregroundColor: Colors.black,
                      elevation: 8,
                      shadowColor: AppColors.gold500.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _handleClaim,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.translate('claim_caps'),
                          style: AppTypography.label.copyWith(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 850.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
              ],
            ),
          ).animate().scale(
                curve: Curves.easeOutBack,
                duration: 500.ms,
              ).fadeIn(),

          // Center Crystal Burst Effect
          if (_showBurst)
            Positioned.fill(
              child: CrystalBurstAnimation(
                onComplete: () {
                  if (mounted) setState(() => _showBurst = false);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRewardChip({
    required BuildContext context,
    required String icon,
    required String label,
    required int amount,
    String? unit,
    required Color color,
    required int delayMs,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: amount),
              duration: Duration(milliseconds: 1200 + delayMs),
              builder: (context, value, child) {
                return Text(
                  '+$value ${unit ?? ''}'.trim(),
                  style: AppTypography.h2.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: AppTypography.label.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delayMs.ms).slideY(begin: 0.4, curve: Curves.easeOutBack);
  }
}

/// Helper function to display the expanded claim reward modal.
void showClaimRewardModal({
  required BuildContext context,
  required String title,
  required String subtitle,
  int crystalsReward = 0,
  int xpReward = 0,
  int? streakDays,
  IconData icon = Icons.card_giftcard_rounded,
  VoidCallback? onClaimed,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => ClaimRewardModal(
      title: title,
      subtitle: subtitle,
      crystalsReward: crystalsReward,
      xpReward: xpReward,
      streakDays: streakDays,
      icon: icon,
      onClaimed: onClaimed,
    ),
  );
}
