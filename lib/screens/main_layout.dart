import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
import '../widgets/profile_avatar.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final navItems = getNavItemsForRole(currentRole);

    final String location = GoRouterState.of(context).uri.path;
    final bool hideBottomNav = location.startsWith('/scenario-session') ||
        location == '/lingua-duel' ||
        location == '/saka-game' ||
        location == '/scenario-hub' ||
        location == '/audio-comparison';

    // Find matching route. Special handling for '/' to avoid matching everything
    int currentIndex = navItems.indexWhere((item) {
      if (item.route == '/') return location == '/';
      return location.startsWith(item.route);
    });

    if (currentIndex == -1) currentIndex = 0; // Fallback

    final userAsync = ref.watch(authStateProvider);
    final culturalTheme = ref.watch(culturalThemeProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: hideBottomNav
          ? null
          : AppBar(
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
      bottomNavigationBar: hideBottomNav
          ? null
          : Container(
              padding: EdgeInsets.only(
                bottom: bottomPadding > 0 ? bottomPadding : 12,
                left: 30,
                right: 30,
                top: 0,
              ),
              color: Colors.transparent,
              child: DynamicGlassBox(
                borderRadius: 20,
                blur: 20,
                opacity: 0.12,
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedFontSize: 8,
                  unselectedFontSize: 8,
                  currentIndex: currentIndex,
                  selectedItemColor: isDark ? culturalTheme.accentColor : AppColors.forest700,
                  unselectedItemColor: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppColors.forest900.withValues(alpha: 0.4),
                  selectedLabelStyle: AppTypography.label.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isDark ? culturalTheme.accentColor : AppColors.forest700,
                  ),
                  unselectedLabelStyle: AppTypography.label.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppColors.forest900.withValues(alpha: 0.4),
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
      icon: Icon(icon, size: 24),
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
    final profile = ref.watch(userProfileProvider).value;
    String label = '';
    IconData icon = Icons.flash_on;
    final userId = ref.watch(authStateProvider).value?.uid ?? '';
    final notificationsAsync = userId.isNotEmpty
        ? ref.watch(userNotificationsStreamProvider(userId))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);
    final unreadCount =
        notificationsAsync.value?.where((n) => n['isRead'] == false).length ?? 0;

    if (role == UserRole.learner) {
      final student = ref.watch(studentProvider);
      label = '${student.xp} XP';
      icon = Icons.flash_on_rounded;
    } else if (role == UserRole.staff) {
      label = 'STAFF';
      icon = Icons.admin_panel_settings_rounded;
    } else if (role == UserRole.educator) {
      final count = ref.watch(totalUsersCountProvider).value ?? 0;
      label = '$count STUDENTS';
      icon = Icons.people_rounded;
    } else if (role == UserRole.admin) {
      label = 'SYSTEM OVERSEER';
      icon = Icons.admin_panel_settings_rounded;
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
            if (role == UserRole.learner) ...[
              _buildStreakStat(context, ref),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: () {
                HapticService.selection();
                if (role == UserRole.learner) {
                  context.push('/mastery-dashboard');
                } else {
                  context.push('/profile');
                }
              },
              child: Container(
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
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.semanticRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                HapticService.selection();
                context.push('/profile');
              },
              child: authState.when(
                data: (user) => ProfileAvatar(
                  radius: 18,
                  photoUrl: profile?['photoURL'] ?? (user as dynamic)?.photoURL,
                  iconSize: 20,
                  backgroundColor: culturalTheme.accentColor,
                ),
                loading: () => const CircleAvatar(
                  radius: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => ProfileAvatar(
                  radius: 18,
                  iconSize: 20,
                  backgroundColor: culturalTheme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakStat(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/streak');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: AppColors.gold500,
            ),
            const SizedBox(width: 4),
            Text(
              '${student.displayedStreak}',
              style: AppTypography.mono.copyWith(
                color: AppColors.gold500,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }
}

