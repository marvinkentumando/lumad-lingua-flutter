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
import '../services/audio_service.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/profile_avatar.dart';
import '../utils/app_localization.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final navItems = getNavItemsForRole(currentRole);
    final l10n = ref.watch(localizationProvider);

    final String location = GoRouterState.of(context).uri.path;
    final bool hideBottomNav = location.startsWith('/scenario-session') ||
        location.startsWith('/lesson_session') ||
        location.startsWith('/daily-challenge') ||
        location == '/learning/quiz' ||
        location == '/lingua-duel' ||
        location == '/saka-game' ||
        location == '/scenario-hub' ||
        location == '/audio-comparison' ||
        location == '/achievements' ||
        location == '/village-dashboard' ||
        location == '/ancestral-vault-shop' ||
        location == '/streak' ||
        location == '/wisdom-progression' ||
        location == '/offline-wisdom' ||
        location == '/mansaka-history' ||
        location == '/data-privacy' ||
        (location == '/sentiment' && currentRole == UserRole.learner) ||
        location == '/mastery-dashboard' ||
        location == '/warriors-circle';

    // Find matching route. Special handling for '/' to avoid matching everything
    int currentIndex = navItems.indexWhere((item) {
      if (item.route == '/') return location == '/';
      return location.startsWith(item.route);
    });

    if (currentIndex == -1) currentIndex = 0; // Fallback

    final userAsync = ref.watch(authStateProvider);
    final culturalTheme = ref.watch(culturalThemeProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final audioService = ref.read(audioServiceProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAudioComparisonScreen =
          location == '/audio-comparison' || location == '/educator/audio-comparison';

      if (currentRole == UserRole.learner && prefs.backgroundMusicEnabled) {
        if (isAudioComparisonScreen) {
          audioService.pauseAmbientMusic();
        } else {
          audioService.ensureAmbientMusicPlaying();
        }
      } else {
        audioService.pauseAmbientMusic();
      }
    });

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: hideBottomNav
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 16,
              automaticallyImplyLeading: false,
              title: _buildTopBar(
                context,
                ref,
                userAsync,
                culturalTheme,
                currentRole,
                l10n,
              ),
            ),
      body: BrandBackground(child: child),
      bottomNavigationBar: hideBottomNav
          ? null
          : Container(
              padding: EdgeInsets.only(
                bottom: bottomPadding > 0 ? bottomPadding : 8,
                left: 30,
                right: 30,
                top: 0,
              ),
              color: Colors.transparent,
              child: DynamicGlassBox(
                borderRadius: 20,
                blur: 20,
                opacity: 0.12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedFontSize: 10,
                    unselectedFontSize: 10,
                    currentIndex: currentIndex,
                    selectedItemColor: isDark ? culturalTheme.accentColor : AppColors.forest700,
                    unselectedItemColor: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppColors.forest900.withValues(alpha: 0.4),
                    selectedLabelStyle: AppTypography.label.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isDark ? culturalTheme.accentColor : AppColors.forest700,
                    ),
                    unselectedLabelStyle: AppTypography.label.copyWith(
                      fontSize: 10,
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
                      return _buildNavItem(item.icon, item.label, isSelected, l10n);
                    }).toList(),
                  ),
                ),
              ),
            ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    AppLocalization l10n,
  ) {
    // Localize label if possible. Labels from role_nav_config are keys.
    final String localizedLabel = l10n.translate(label.toLowerCase());
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
        child: Icon(icon, size: 24),
      ),
      label: localizedLabel != label.toLowerCase() ? localizedLabel : label,
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue authState,
    CulturalTheme culturalTheme,
    UserRole role,
    AppLocalization l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      label = l10n.translate('researcher_staff');
      icon = Icons.admin_panel_settings_rounded;
    } else if (role == UserRole.educator) {
      final count = ref.watch(educatorLearnersProvider(userId)).value?.length ?? 0;
      label = '$count ${l10n.translate('students')}';
      icon = Icons.people_rounded;
    } else if (role == UserRole.admin) {
      label = l10n.translate('system_overseer');
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
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role == UserRole.learner) ...[
                  _buildStreakStat(context, ref),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      final isEnabled = ref.read(userPreferencesProvider).backgroundMusicEnabled;
                      ref.read(userPreferencesProvider.notifier).setBackgroundMusicEnabled(!isEnabled);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ref.watch(userPreferencesProvider).backgroundMusicEnabled
                            ? Icons.music_note_rounded
                            : Icons.music_off_rounded,
                        color: ref.watch(userPreferencesProvider).backgroundMusicEnabled
                            ? culturalTheme.accentColor
                            : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    if (role == UserRole.learner) {
                      context.go('/mastery-dashboard');
                    } else {
                      context.go('/profile');
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
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    _showSystemGuide(context, l10n);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: isDark ? Colors.white70 : AppColors.forest900,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    context.push('/notifications');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: isDark ? Colors.white70 : AppColors.forest900,
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
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    context.go('/profile');
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
          ),
        ),
      ],
    );
  }

  Widget _buildStreakStat(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/streak');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
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

  void _showSystemGuide(BuildContext context, AppLocalization l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InteractiveSystemGuideModal(l10n: l10n),
    );
  }
}

class _InteractiveSystemGuideModal extends StatefulWidget {
  final AppLocalization l10n;

  const _InteractiveSystemGuideModal({
    required this.l10n,
  });

  @override
  State<_InteractiveSystemGuideModal> createState() =>
      __InteractiveSystemGuideModalState();
}

class __InteractiveSystemGuideModalState
    extends State<_InteractiveSystemGuideModal> {
  late final PageController _pageController;
  int _currentPage = 0;
  int _selectedCategoryIndex = 0; // 0: ALL, 1: CULTURE, 2: LEARNING, 3: COMMUNITY
  bool _isPlayingSample = false;
  final Set<int> _expandedCards = {};

  final List<String> _categories = [
    'ALL',
    'CULTURE',
    'LEARNING',
    'COMMUNITY',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAllGuideItems(AppLocalization l10n) {
    return [
      {
        'id': 1,
        'category': 'CULTURE',
        'icon': Icons.auto_stories_rounded,
        'title': l10n.translate('guide_title_1'),
        'description': l10n.translate('guide_desc_1'),
        'tip': 'Explore oral history, ancestral traditions, and cultural heritage exhibits.',
        'actionLabel': 'EXPLORE HERITAGE 🌿',
        'route': '/mansaka-history',
      },
      {
        'id': 2,
        'category': 'LEARNING',
        'icon': Icons.map_rounded,
        'title': l10n.translate('guide_title_2'),
        'description': l10n.translate('guide_desc_2'),
        'tip': 'Complete path nodes, earn XP, and level up your mastery streak.',
        'actionLabel': 'GO TO LEARNING PATH 🗺️',
        'route': '/',
      },
      {
        'id': 3,
        'category': 'LEARNING',
        'icon': Icons.mic_external_on_rounded,
        'title': l10n.translate('guide_title_3'),
        'description': l10n.translate('guide_desc_3'),
        'tip': 'Speak into the microphone to analyze pronunciation accuracy & pitch.',
        'actionLabel': 'TEST AUDIO SAMPLE 🎧',
        'isAudioSample': true,
      },
      {
        'id': 4,
        'category': 'LEARNING',
        'icon': Icons.translate_rounded,
        'title': l10n.translate('guide_title_4'),
        'description': l10n.translate('guide_desc_4'),
        'tip': 'Search indigenous words, bookmark favorites, and filter by parts of speech.',
        'actionLabel': 'OPEN DICTIONARY 📖',
        'route': '/dictionary',
      },
      {
        'id': 5,
        'category': 'COMMUNITY',
        'icon': Icons.workspace_premium_rounded,
        'title': l10n.translate('guide_title_5'),
        'description': l10n.translate('guide_desc_5'),
        'tip': 'Climb rankings, send "Salute!" cheers to friends, and earn merit badges.',
        'actionLabel': 'VIEW LEADERBOARD 🏆',
        'route': '/leaderboard',
      },
      {
        'id': 6,
        'category': 'COMMUNITY',
        'icon': Icons.gavel_rounded,
        'title': l10n.translate('guide_title_6'),
        'description': l10n.translate('guide_desc_6'),
        'tip': 'All community audio contributions are verified by elder council members.',
        'actionLabel': 'COMMUNITY FEED 💬',
        'route': '/community-feed',
      },
    ];
  }

  List<Map<String, dynamic>> _filteredItems(List<Map<String, dynamic>> allItems) {
    if (_selectedCategoryIndex == 0) return allItems;
    final cat = _categories[_selectedCategoryIndex];
    return allItems.where((item) => item['category'] == cat).toList();
  }

  void _onCategorySelected(int index) {
    HapticService.selection();
    setState(() {
      _selectedCategoryIndex = index;
      _currentPage = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _playAudioSample() async {
    HapticService.medium();
    setState(() => _isPlayingSample = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _isPlayingSample = false);
      HapticService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.volume_up_rounded, color: AppColors.gold500, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Audio Sample: "Madyaw na madyaw!" (100% Clarity)'),
              ),
            ],
          ),
          backgroundColor: AppColors.forest900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = _getAllGuideItems(widget.l10n);
    final items = _filteredItems(allItems);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest800 : AppColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n.translate('system_nav_guide'),
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.l10n.translate('welcome_lumad_lingua'),
                        style: AppTypography.h2.copyWith(
                          color: isDark ? Colors.white : AppColors.forest900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: isDark ? Colors.white70 : AppColors.forest900,
                ),
              ],
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(_categories.length, (index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _onCategorySelected(index),
                    selectedColor: AppColors.gold500,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.forest900
                          : (isDark ? Colors.white70 : AppColors.forest900),
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      fontSize: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.gold500
                            : (isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 12),

          // Step Indicator Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'STEP ${_currentPage + 1} OF ${items.length}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  _categories[_selectedCategoryIndex],
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Interactive PageView Carousel
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No items in this category',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      HapticService.selection();
                      setState(() => _currentPage = page);
                    },
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final int itemId = item['id'];
                      final bool isExpanded = _expandedCards.contains(itemId);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : AppColors.creamBorder,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.forest900.withValues(alpha: 0.04),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold500.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: AppColors.gold500,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.gold500.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item['category'],
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.gold500,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['title'],
                                          style: AppTypography.h3.copyWith(
                                            color: isDark ? Colors.white : AppColors.forest900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Text(
                                item['description'],
                                style: AppTypography.body.copyWith(
                                  color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Expandable Tip
                              GestureDetector(
                                onTap: () {
                                  HapticService.light();
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedCards.remove(itemId);
                                    } else {
                                      _expandedCards.add(itemId);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold500.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.gold500.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.lightbulb_outline_rounded,
                                                size: 16,
                                                color: AppColors.gold500,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'KEY TAKEAWAY',
                                                style: AppTypography.label.copyWith(
                                                  color: AppColors.gold500,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            color: AppColors.gold500,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      if (isExpanded) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          item['tip'],
                                          style: AppTypography.body.copyWith(
                                            color: isDark
                                                ? Colors.white60
                                                : AppColors.forest900.withValues(alpha: 0.7),
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Interactive Action Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (item['isAudioSample'] == true) {
                                      _playAudioSample();
                                    } else {
                                      HapticService.selection();
                                      context.pop();
                                      if (item['route'] != null) {
                                        context.go(item['route']);
                                      }
                                    }
                                  },
                                  icon: _isPlayingSample && item['isAudioSample'] == true
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.forest900,
                                          ),
                                        )
                                      : Icon(
                                          item['isAudioSample'] == true
                                              ? Icons.volume_up_rounded
                                              : Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                  label: Text(item['actionLabel']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold500,
                                    foregroundColor: AppColors.forest900,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Slide Controls & Indicators
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () {
                          HapticService.selection();
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : AppColors.forest900,
                  ),
                  child: const Text('PREVIOUS'),
                ),

                // Dot Page Indicators
                Row(
                  children: List.generate(items.length, (idx) {
                    final isCurrent = idx == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isCurrent ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.gold500
                            : (isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),

                ElevatedButton(
                  onPressed: () {
                    HapticService.selection();
                    if (_currentPage < items.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      HapticService.success();
                      context.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold500,
                    foregroundColor: AppColors.forest900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage < items.length - 1 ? 'NEXT ➔' : 'GOT IT! 🚀',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
