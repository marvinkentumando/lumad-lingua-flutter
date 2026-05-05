import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';

class LinguaDuelScreen extends StatefulWidget {
  const LinguaDuelScreen({super.key});

  @override
  State<LinguaDuelScreen> createState() => _LinguaDuelScreenState();
}

class _LinguaDuelScreenState extends State<LinguaDuelScreen> {
  bool _searching = false;

  void _startSearch() {
    setState(() => _searching = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _searching = false);
        _showMatchFound();
      }
    });
  }

  void _showMatchFound() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'MATCH FOUND!',
              style: AppTypography.h1ExtraBold.copyWith(
                color: AppColors.gold500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Opponent: Datu Matu',
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            BrandButton(
              text: 'BATTLE START',
              onTap: () => Navigator.pop(context),
              type: BrandButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BrandBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          _buildMainGraphic(),
                          const SizedBox(height: 40),
                          Text(
                            'Lingua Duel',
                            style: AppTypography.displayBold.copyWith(
                              color: AppColors.gold500,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Challenge friends or random warriors to a real-time language duel.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 48),
                          if (!_searching) ...[
                            _buildDuelModeCard(
                              title: 'Quick Match',
                              subtitle: 'Battle a random learner',
                              icon: Icons.bolt_rounded,
                              onTap: _startSearch,
                            ),
                            const SizedBox(height: 16),
                            _buildDuelModeCard(
                              title: 'Challenge Friend',
                              subtitle: 'Send a duel invite',
                              icon: Icons.people_rounded,
                              onTap: () => context.push('/warriors-circle'),
                            ),
                          ] else
                            _buildSearchingState(),
                        ],
                      ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const Spacer(),
          Text(
            'BATTLE HUB',
            style: AppTypography.label.copyWith(
              color: Colors.white38,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainGraphic() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.gold500.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold500.withOpacity(0.1),
                  width: 2,
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              duration: 2.seconds,
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              curve: Curves.easeInOut,
            ),
        const Icon(Icons.flash_on_rounded, size: 80, color: AppColors.gold500),
      ],
    );
  }

  Widget _buildDuelModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold500.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.gold500),
        ),
        title: Text(
          title,
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.body.copyWith(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white24,
          size: 16,
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSearchingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.gold500),
        const SizedBox(height: 24),
        Text(
          'Searching for Opponents...',
          style: AppTypography.h3.copyWith(color: AppColors.gold500),
        ),
        const SizedBox(height: 8),
        Text(
          'Warriors from across the archipelago are being summoned.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 32),
        BrandButton(
          text: 'CANCEL',
          onTap: () => setState(() => _searching = false),
          type: BrandButtonType.text,
        ),
      ],
    ).animate().fadeIn();
  }
}


