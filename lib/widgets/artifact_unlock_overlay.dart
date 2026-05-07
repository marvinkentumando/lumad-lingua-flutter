import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/artifact.dart';
import '../services/haptic_service.dart';
import '../services/audio_service.dart';
import 'spirit_particle_overlay.dart';

class ArtifactUnlockOverlay extends ConsumerStatefulWidget {
  final Artifact artifact;

  const ArtifactUnlockOverlay({super.key, required this.artifact});

  @override
  ConsumerState<ArtifactUnlockOverlay> createState() => _ArtifactUnlockOverlayState();
}

class _ArtifactUnlockOverlayState extends ConsumerState<ArtifactUnlockOverlay> {
  @override
  void initState() {
    super.initState();
    // Fire sensory feedback on artifact reveal
    HapticService.artifactUnlock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).playSFX('milestone');
    });
  }

  Color _getTierColor() {
    switch (widget.artifact.tier) {
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

  List<Color> _getTierParticleColors() {
    final tierColor = _getTierColor();
    return [
      tierColor,
      tierColor.withValues(alpha: 0.7),
      Colors.white,
      AppColors.gold500,
      Colors.cyanAccent,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor();

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      body: Stack(
        children: [
          // Spirit particle celebration layer
          SpiritParticleOverlay(
            duration: const Duration(seconds: 4),
            colors: _getTierParticleColors(),
            particleCount: 50,
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NEW ARTIFACT DISCOVERED',
                  style: AppTypography.label.copyWith(
                    color: tierColor,
                    letterSpacing: 4,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5),
                const SizedBox(height: 40),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tierColor.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.4),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                    border: Border.all(color: tierColor, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: widget.artifact.imageUrl.isNotEmpty
                      ? Image.asset(widget.artifact.imageUrl, width: 100, height: 100, fit: BoxFit.contain)
                      : Text(widget.artifact.emoji, style: const TextStyle(fontSize: 80)),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds, curve: Curves.easeInOut)
                .shimmer(duration: 2.seconds, color: Colors.white),
                const SizedBox(height: 40),
                Text(
                  widget.artifact.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.h1ExtraBold.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    widget.artifact.tier.name.toUpperCase(),
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).scale(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.artifact.description,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
                const SizedBox(height: 60),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tierColor,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    HapticService.buttonPress();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'COLLECT',
                    style: AppTypography.label.copyWith(color: Colors.black, fontWeight: FontWeight.w900),
                  ),
                ).animate().fadeIn(delay: 1000.ms).scale(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showArtifactUnlockOverlay(BuildContext context, Artifact artifact) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) => ArtifactUnlockOverlay(artifact: artifact),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}



