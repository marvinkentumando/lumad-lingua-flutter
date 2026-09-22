import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import 'package:lumad_lingua/widgets/app_shimmer_skeleton.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import 'package:go_router/go_router.dart';
import '../widgets/wotd_widget.dart';
import '../services/auth_service.dart';
import '../services/word_of_day_service.dart';
import '../models/dictionary_entry.dart';
import '../widgets/branded_empty_state.dart';
import '../utils/app_localization.dart';

class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});
  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  int? _tappedGrowthBar;

  final List<Map<String, dynamic>> _defaultHealth = [
    {
      'label': 'API Status',
      'value': 'Online',
      'color': AppColors.semanticGreen,
      'icon': Icons.cloud_done_rounded,
    },
    {
      'label': 'Storage',
      'value': '75%',
      'color': AppColors.gold500,
      'icon': Icons.storage_rounded,
    },
    {
      'label': 'Database',
      'value': 'Healthy',
      'color': AppColors.semanticGreen,
      'icon': Icons.dns_rounded,
    },
    {
      'label': 'Uptime',
      'value': '99.8%',
      'color': AppColors.semanticBlue,
      'icon': Icons.timer_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(systemHealthProvider);
    final activityAsync = ref.watch(platformActivityProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(systemHealthProvider);
              ref.invalidate(platformActivityProvider);
              await Future.delayed(const Duration(seconds: 1));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.translate('stats_refreshed')),
                ),
              );
            },
            color: AppColors.gold500,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(context, l10n),
                  const SizedBox(height: 24),
                  _sectionLabel(l10n.translate('village_pulse')),
                  const SizedBox(height: 16),
                  const WotdWidget(),
                  const SizedBox(height: 12),
                  _buildWotdAdminControls(l10n),
                  const SizedBox(height: 32),
                  _sectionLabel(l10n.translate('platform_stats')),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ref.watch(totalUsersCountProvider).when(
                            data: (count) => _statCard(
                              count.toString(),
                              l10n.translate('total_users'),
                              Icons.people_outline,
                              AppColors.semanticBlue,
                            ),
                            loading: () => _statCard(
                              '',
                              l10n.translate('total_users'),
                              Icons.people_outline,
                              AppColors.semanticBlue,
                              isLoading: true,
                            ),
                            error: (_, __) => _statCard(
                              '!',
                              l10n.translate('total_users'),
                              Icons.people_outline,
                              AppColors.semanticBlue,
                            ),
                          ),
                      ref.watch(totalWordsCountProvider).when(
                            data: (count) => _statCard(
                              count.toString(),
                              l10n.translate('words_added'),
                              Icons.library_books_outlined,
                              AppColors.semanticGreen,
                            ),
                            loading: () => _statCard(
                              '',
                              l10n.translate('words_added'),
                              Icons.library_books_outlined,
                              AppColors.semanticGreen,
                              isLoading: true,
                            ),
                            error: (_, __) => _statCard(
                              '!',
                              l10n.translate('words_added'),
                              Icons.library_books_outlined,
                              AppColors.semanticGreen,
                            ),
                          ),
                      ref.watch(totalAudioClipsCountProvider).when(
                            data: (count) => _statCard(
                              count.toString(),
                              l10n.translate('audio_clips'),
                              Icons.mic_outlined,
                              AppColors.semanticRed,
                            ),
                            loading: () => _statCard(
                              '',
                              l10n.translate('audio_clips'),
                              Icons.mic_outlined,
                              AppColors.semanticRed,
                              isLoading: true,
                            ),
                            error: (_, __) => _statCard(
                              '!',
                              l10n.translate('audio_clips'),
                              Icons.mic_outlined,
                              AppColors.semanticRed,
                            ),
                          ),
                      GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          context.push('/admin/dictionary');
                        },
                        child: _statCard(
                          l10n.translate('manage_label'),
                          l10n.translate('dictionary_label'),
                          Icons.book_rounded,
                          AppColors.gold500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          context.push('/admin/algorithm-selection');
                        },
                        child: _statCard(
                          'AI MODELS',
                          'DEPLOYMENT',
                          Icons.psychology_rounded,
                          AppColors.semanticBlue,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          context.push('/admin/lessons');
                        },
                        child: _statCard(
                          l10n.translate('manage_label'),
                          l10n.translate('lessons_label'),
                          Icons.library_books_rounded,
                          AppColors.gold500,
                        ),
                      ),
                    ]
                        .animate(interval: 80.ms)
                        .fadeIn(delay: 100.ms)
                        .scale(begin: const Offset(0.92, 0.92)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        BrandButton(
                          text: l10n.translate('advanced_analytics'),
                          type: BrandButtonType.primary,
                          icon: Icons.analytics_rounded,
                          onTap: () => context.push('/admin/analytics'),
                        ),
                        const SizedBox(height: 12),
                        BrandButton(
                          text: 'VIEW TEST ASSESSMENTS',
                          type: BrandButtonType.secondary,
                          icon: Icons.assignment_turned_in_rounded,
                          onTap: () => context.push('/admin/assessments'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),
                  _sectionLabel(l10n.translate('system_health_label')),
                  const SizedBox(height: 16),
                  healthAsync.when(
                    data: (health) => _buildSystemHealthGrid(health),
                    loading: () => _buildSystemHealthGrid(null),
                    error: (_, __) => _buildSystemHealthGrid(null),
                  ),
                  const SizedBox(height: 32),
                  _sectionLabel(l10n.translate('user_growth_label')),
                  const SizedBox(height: 16),
                  activityAsync.when(
                    data: (data) => BrandCard(
                      theme: BrandCardTheme.vibrant,
                      child: _buildInteractiveBarChart(
                        values: data['growth'] ?? [0, 0, 0, 0, 0, 0, 0],
                        labels: [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ],
                        color: AppColors.semanticBlue,
                        tappedIndex: _tappedGrowthBar,
                        onTap: (i) => setState(() => _tappedGrowthBar =
                            _tappedGrowthBar == i ? null : i),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    loading: () => _buildChartAppShimmerSkeleton(),
                    error: (_, __) => const Text('Error loading growth data'),
                  ),
                  const SizedBox(height: 32),
                  _sectionLabel(l10n.translate('gamification_economics')),
                  const SizedBox(height: 16),
                  BrandCard(
                    theme: BrandCardTheme.gold,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.forest900,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.translate('warrior_circle_ops'),
                                      style: AppTypography.h3.copyWith(
                                        color: AppColors.forest900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      l10n.translate('manage_seasons_desc'),
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.forest700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: BrandButton(
                              text: l10n.translate('go_economics_hub'),
                              onTap: () => context.push('/admin/gamification'),
                              type: BrandButtonType.primary,
                              icon: Icons.auto_awesome_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWotdAdminControls(AppLocalization l10n) {
    final metadataAsync = ref.watch(wotdMetadataProvider);

    return metadataAsync.when(
      data: (data) {
        final isManual = data?['isManual'] as bool? ?? false;
        return Row(
          children: [
            Expanded(
              child: BrandButton(
                text: l10n.translate('force_rotation'),
                type: BrandButtonType.secondary,
                icon: Icons.refresh_rounded,
                onTap: () => _forceWotdRotation(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BrandButton(
                text: isManual
                    ? l10n.translate('resume_auto')
                    : l10n.translate('pick_manually'),
                type: isManual
                    ? BrandButtonType.primary
                    : BrandButtonType.secondary,
                icon: isManual
                    ? Icons.auto_mode_rounded
                    : Icons.edit_calendar_rounded,
                onTap: () {
                  if (isManual) {
                    _resumeAutoRotation();
                  } else {
                    _showWordPickerDialog();
                  }
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _forceWotdRotation() async {
    final l10n = ref.read(localizationProvider);
    try {
      await ref.read(wordOfDayServiceProvider).forceNewWord();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('wotd_rotated'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rotation failed: $e')),
      );
    }
  }

  Future<void> _resumeAutoRotation() async {
    try {
      await ref.read(wordOfDayServiceProvider).resumeAutomaticRotation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Automatic rotation resumed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resume: $e')),
      );
    }
  }

  void _showWordPickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _WordPickerSheet(),
    );
  }

  Widget _buildHeroBanner(BuildContext context, AppLocalization l10n) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    final name = profile?['username'] ?? 'Admin';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: BrandCard(
        theme: BrandCardTheme.gold,
        padding: const EdgeInsets.all(24),
        borderRadius: 32,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('good_morning_name', params: {'name': name}),
                    style: AppTypography.displayBold.copyWith(
                      color: Colors.black,
                      fontSize: 32,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${l10n.translate('system_overseer')}  •  COMMANDER',
                      style: AppTypography.label.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.forest900,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealthGrid(Map<String, dynamic>? data) {
    return Row(
      children: _defaultHealth.map((h) {
        String value = h['value'];
        if (data != null) {
          switch (h['label']) {
            case 'API Status':
              value = data['apiStatus'] ?? value;
              break;
            case 'Storage':
              value = data['storage'] ?? value;
              break;
            case 'Database':
              value = data['database'] ?? value;
              break;
            case 'Uptime':
              value = data['uptime'] ?? value;
              break;
          }
        }

        final isPulsing = value == 'Online' || value == 'Healthy';

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: h == _defaultHealth.last ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? (h['color'] as Color).withValues(alpha: 0.15)
                    : AppColors.creamBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  h['icon'] as IconData,
                  color: h['color'] as Color,
                  size: 20,
                )
                    .animate(
                      onPlay: (c) =>
                          isPulsing ? c.repeat(reverse: true) : c.stop(),
                    )
                    .tint(
                      color: (h['color'] as Color).withValues(alpha: 0.4),
                      duration: 2.seconds,
                    ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTypography.h3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                )
                    .animate(
                      onPlay: (c) =>
                          isPulsing ? c.repeat(reverse: true) : c.stop(),
                    )
                    .custom(
                      duration: 2.seconds,
                      builder: (context, val, child) => Opacity(
                        opacity: 0.6 + (val * 0.4),
                        child: child,
                      ),
                    ),
                Text(
                  (h['label'] as String).toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartAppShimmerSkeleton() {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
              7,
              (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppShimmerSkeleton(
                            height: 30 + (i * 12.0) % 60.0,
                            borderRadius: 6,
                          ),
                          const SizedBox(height: 10),
                          const AppShimmerSkeleton(
                              height: 8, width: 24, borderRadius: 2),
                        ],
                      ),
                    ),
                  )),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: AppTypography.mono.copyWith(
          color: isDark ? Colors.white24 : AppColors.creamText3,
          fontSize: 9,
          letterSpacing: 2,
        ),
      );

  Widget _statCard(String value, String label, IconData icon, Color color,
      {bool isLoading = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.forest700.withValues(alpha: 0.5)
            : AppColors.gold500,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? color.withValues(alpha: 0.05)
                : AppColors.gold700.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isDark ? color : AppColors.forest900, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                const AppShimmerSkeleton(width: 60, height: 28, borderRadius: 8)
              else
                Text(
                  value,
                  style: AppTypography.display.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              Text(
                label.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white24 : AppColors.forest700,
                  fontSize: 8,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveBarChart({
    required List<int> values,
    required List<String> labels,
    required Color color,
    int? tappedIndex,
    required void Function(int) onTap,
  }) {
    final max = values.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final pct = values[i] / (max == 0 ? 1 : max);
          final isTapped = tappedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticService.light();
                onTap(i);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Text(
                      '${values[i]}',
                      style: AppTypography.mono.copyWith(
                        color: isTapped ? color : color.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 800 + i * 100),
                      curve: Curves.elasticOut,
                      height: (pct * 100).clamp(10.0, 100.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color,
                            color.withValues(alpha: isTapped ? 0.8 : 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isTapped
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      labels[i],
                      style: AppTypography.mono.copyWith(
                        color: isTapped ? color : Colors.white60,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WordPickerSheet extends ConsumerStatefulWidget {
  const _WordPickerSheet();

  @override
  ConsumerState<_WordPickerSheet> createState() => _WordPickerSheetState();
}

class _WordPickerSheetState extends ConsumerState<_WordPickerSheet> {
  String _search = '';
  String _dialect = 'All';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _search = query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialectsAsync = ref.watch(dialectsProvider);
    final wordsAsync = ref.watch(
      globalDictionaryStreamProvider(
        ValidatorQuery('', 20, search: _search, dialect: _dialect),
      ),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select WOTD',
                        style: AppTypography.h2.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Force a word to be the Word of the Day',
                        style: AppTypography.body.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search for a word...',
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          dialectsAsync.when(
            data: (dialects) => SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: dialects.length,
                itemBuilder: (context, i) {
                  final d = dialects[i];
                  final isSelected = _dialect == d;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(d),
                      selected: isSelected,
                      onSelected: (s) => setState(() => _dialect = d),
                      selectedColor: AppColors.gold500,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: wordsAsync.when(
              data: (words) {
                // Filter to only show approved words for WOTD
                final approvedWords = words
                    .where((w) => w.status == ValidationStatus.approved)
                    .toList();

                if (approvedWords.isEmpty) {
                  return BrandedEmptyState(
                    title: _search.isNotEmpty
                        ? 'Word Not Found'
                        : 'No Sacred Words',
                    message: _search.isNotEmpty
                        ? 'Try a different search term.'
                        : 'No approved words available for rotation.',
                    icon: Icons.search_off_rounded,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: approvedWords.length,
                  itemBuilder: (context, i) {
                    final w = approvedWords[i];
                    return Card(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        onTap: () => _confirmSelection(w),
                        title: Text(
                          w.indigenousWord,
                          style: AppTypography.h3.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          '${w.language} \u2022 ${w.translation}',
                          style: AppTypography.body.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection(DictionaryEntry word) {
    final l10n = ref.read(localizationProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_wotd')),
        content: Text(
            'Set "${word.indigenousWord}" as the Word of the Day? This will override automatic rotation.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.translate('cancel').toUpperCase()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
              _setWord(word);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
            child: Text(l10n.translate('save').toUpperCase(),
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _setWord(DictionaryEntry word) async {
    try {
      await ref.read(wordOfDayServiceProvider).setManualWord(word.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('"${word.indigenousWord}" is now the Word of the Day.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set word: $e')),
      );
    }
  }
}
