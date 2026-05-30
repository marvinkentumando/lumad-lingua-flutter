import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/haptic_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest900,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F2619), AppColors.forest900],
              ),
            ),
          ),

          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              HapticService.selection();
              setState(() => _currentIndex = index);
            },
            children: [
              _buildNarrativePage(
                title: "The Echoes Fade",
                subtitle: "OUR ANCESTRAL VOICES",
                description:
                    "The sacred languages of our tribes are fading like mist at dawn. You have been chosen to gather the remaining echoes.",
                image: 'assets/images/lumad_waves.gif',
                accentColor: AppColors.gold500,
              ),
              _buildNarrativePage(
                title: "The Ancestral Vault",
                subtitle: "SACRED KNOWLEDGE",
                description:
                    "Every word you learn restores a piece of our history. Unlock ancient artifacts and rebuild the legacy of our people.",
                icon: Icons.auto_awesome,
                accentColor: Colors.cyanAccent,
              ),
              _buildNarrativePage(
                title: "Your Tribal Journey",
                subtitle: "WISDOM AWAITS",
                description:
                    "Join the Warriors' Circle and compete in ritual duels. The path to mastery is long, but the elders walk with you.",
                icon: Icons.fort_rounded,
                accentColor: Colors.orangeAccent,
              ),
            ],
          ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                _buildIndicator(),
                const SizedBox(height: 40),
                _buildActionButton(
                  _currentIndex == 2 ? "BEGIN THE RITUAL" : "CONTINUE",
                  () {
                    if (_currentIndex == 2) {
                      context.go('/login');
                    } else {
                      _pageController.nextPage(
                        duration: 600.ms,
                        curve: Curves.easeOutQuart,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativePage({
    required String title,
    required String subtitle,
    required String description,
    String? image,
    IconData? icon,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          if (image != null)
            Image.asset(image, height: 280)
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.8, 0.8))
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: accentColor.withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 10),
                ],
              ),
              child: Icon(icon, size: 100, color: accentColor),
            ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),

          const SizedBox(height: 60),
          Text(
            subtitle,
            style: AppTypography.label.copyWith(
              color: accentColor,
              letterSpacing: 4,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.display.copyWith(
              color: Colors.white,
              fontSize: 38,
              height: 1.1,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 24),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white70,
              fontSize: 18,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: _currentIndex == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index ? AppColors.gold500 : Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticService.buttonPress();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.gold500,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold500.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTypography.label.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5);
  }
}



