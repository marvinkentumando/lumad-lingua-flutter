import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/haptic_service.dart';
import '../services/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'spirit_particle_overlay.dart';


class LevelUpModal extends StatelessWidget {
  final int newLevel;
  final String newTitle;

  const LevelUpModal({super.key, required this.newLevel, required this.newTitle});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.forest900,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold500.withValues(alpha: 0.3),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
          border: Border.all(color: AppColors.gold500, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.gold500, size: 80)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1.seconds, color: Colors.white)
                .scaleXY(end: 1.1, duration: 800.ms, curve: Curves.easeInOutSine),
            const SizedBox(height: 24),
            Text(
              'RANK UP!',
              style: AppTypography.h1ExtraBold.copyWith(
                color: AppColors.gold500,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are now Level $newLevel',
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.5)),
              ),
              child: Text(
                newTitle.toUpperCase(),
                style: AppTypography.h3.copyWith(
                  color: AppColors.gold500,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold500,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CLAIM POWER',
                style: AppTypography.label.copyWith(color: Colors.black, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    ).animate(onInit: (c) {
      HapticService.levelUp();
    }).scale(curve: Curves.easeOutBack, duration: 600.ms).fadeIn();


  }
}

void showLevelUpModal(BuildContext context, WidgetRef ref, int newLevel, String newTitle) {
  ref.read(audioServiceProvider).playSFX('level_up');
  showSpiritParticles(context, duration: const Duration(seconds: 3));
  showDialog(
    context: context,
    builder: (context) => LevelUpModal(newLevel: newLevel, newTitle: newTitle),
  );
}





