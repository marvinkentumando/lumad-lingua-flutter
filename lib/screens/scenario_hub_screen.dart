import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';

class ScenarioHubScreen extends StatelessWidget {
  const ScenarioHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BrandBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          'Scenario Stories',
                          style: AppTypography.displayBold.copyWith(
                            color: AppColors.gold500,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your path. Every word matters.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildScenarioCard(
                          context,
                          title: 'The Elder\'s Request',
                          description:
                              'Help an elder navigate the forest by following their Mansaka instructions.',
                          difficulty: 'Beginner',
                          reward: '50 XP',
                          id: 'elders_request',
                        ),
                        const SizedBox(height: 16),
                        _buildScenarioCard(
                          context,
                          title: 'Market Negotiations',
                          description:
                              'Trade goods at the local market using traditional counting and naming.',
                          difficulty: 'Intermediate',
                          reward: '100 XP',
                          id: 'market_negotiations',
                        ),
                        const SizedBox(height: 16),
                        _buildScenarioCard(
                          context,
                          title: 'The Sacred Ritual',
                          description:
                              'Participate in a village ceremony and learn the sacred terminology.',
                          difficulty: 'Advanced',
                          reward: '200 XP',
                          id: 'sacred_ritual',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context, {
    required String title,
    required String description,
    required String difficulty,
    required String reward,
    required String id,
  }) {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      child: InkWell(
        onTap: () {
          // Navigate to scenario session
          context.push('/scenario-session/$id');
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      difficulty.toUpperCase(),
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    reward,
                    style: AppTypography.mono.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    color: AppColors.gold500,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'START SCENARIO',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}


