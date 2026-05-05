import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_typography.dart';

import '../widgets/brand_background.dart';
import '../widgets/dynamic_glass_box.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../providers/learning_provider.dart';
import '../providers/student_provider.dart';
import '../providers/role_provider.dart';
import '../services/firebase_service.dart';
import '../config/role_nav_config.dart';
import '../services/cultural_theme_service.dart';
import '../services/haptic_service.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final navItems = getNavItemsForRole(currentRole);

    final String location = GoRouterState.of(context).uri.toString();

    // Find matching route. Special handling for '/' to avoid matching everything
    int currentIndex = navItems.indexWhere((item) {
      if (item.route == '/') return location == '/';
      return location.startsWith(item.route);
    });

    if (currentIndex == -1) currentIndex = 0; // Fallback

    final userAsync = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final culturalTheme = ref.watch(culturalThemeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: _buildTopBar(
          context,
          ref,
          userAsync,
          culturalTheme,
          currentRole,
        ),
      ),
      body: BrandBackground(child: child),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(
          bottom: 24,
          left: 20,
          right: 20,
          top: 10,
        ),
        color: Colors.transparent,
        child: DynamicGlassBox(
          borderRadius: 32,
          blur: 20,
          opacity: isDark ? 0.12 : 0.6,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            selectedItemColor: isDark
                ? culturalTheme.accentColor
                : culturalTheme.primaryColor,
            unselectedItemColor: (isDark ? Colors.white : Colors.black)
                .withOpacity(0.3),
            selectedLabelStyle: AppTypography.label.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? culturalTheme.accentColor
                  : culturalTheme.primaryColor,
            ),
            unselectedLabelStyle: AppTypography.label.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
            onTap: (index) {
              if (index >= 0 && index < navItems.length) {
                HapticService.light();
                context.go(navItems[index].route);
              }
            },
            items: navItems.map((item) {
              final isSelected = navItems.indexOf(item) == currentIndex;
              return _buildNavItem(item.icon, item.label, isSelected);
            }).toList(),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(icon, size: 24),
      ),
      label: label,
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue authState,
    CulturalTheme culturalTheme,
    UserRole role,
  ) {
    String label = '';
    IconData icon = Icons.flash_on;
    final userId = ref.watch(authStateProvider).value?.uid ?? '';

    if (role == UserRole.learner) {
      final student = ref.watch(studentProvider);
      label = '${student.mistCrystals} CRYSTALS';
      icon = Icons.auto_awesome;
    } else if (role == UserRole.validator) {
      final count = ref.watch(validatorActivityCountProvider(userId)).value ?? 0;
      label = '$count VALIDATIONS';
      icon = Icons.verified_user_rounded;
    } else if (role == UserRole.educator) {
      final count = ref.watch(totalUsersCountProvider).value ?? 0;
      label = '$count STUDENTS';
      icon = Icons.people_rounded;
    } else if (role == UserRole.contributor) {
      final count = ref.watch(contributorWordCountProvider(userId)).value ?? 0;
      label = '$count CONTRIBUTIONS';
      icon = Icons.menu_book_rounded;
    } else {
      final xp = ref.watch(xpProvider);
      label = '$xp XP';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '“',
          style: GoogleFonts.fredoka(
            color: culturalTheme.accentColor,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: culturalTheme.accentColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTypography.mono.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                HapticService.selection();
                context.push('/notifications');
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                HapticService.selection();
                context.push('/profile');
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: culturalTheme.accentColor,
                child: ClipOval(
                  child: authState.when(
                    data: (user) => (user as dynamic)?.photoURL != null
                        ? Image.network((user as dynamic).photoURL!)
                        : const Icon(Icons.person_rounded, color: Colors.black),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) =>
                        const Icon(Icons.person_rounded, color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
