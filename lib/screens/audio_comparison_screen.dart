import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/brand_card.dart';

class AudioComparisonScreen extends ConsumerStatefulWidget {
  const AudioComparisonScreen({super.key});

  @override
  ConsumerState<AudioComparisonScreen> createState() => _AudioComparisonScreenState();
}

class _AudioComparisonScreenState extends ConsumerState<AudioComparisonScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AUDIO COMPARISON',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: AmbientTopoBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: BrandCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    size: 64,
                    color: AppColors.gold500,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Voice Shadowing',
                    style: AppTypography.h2ExtraBold.copyWith(
                      color: isDark ? Colors.white : AppColors.forest700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Compare your pronunciation with native speakers and master the ancestral tones.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white70 : AppColors.creamText2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: AppColors.gold500),
                  const SizedBox(height: 16),
                  Text(
                    'Shadowing engine calibrating...',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
