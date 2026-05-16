import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import 'package:go_router/go_router.dart';
import '../providers/contributor_request_provider.dart';
import '../widgets/wotd_widget.dart';
import '../services/auth_service.dart';
import '../services/database_seeder.dart';
import '../services/word_of_day_service.dart';
import '../models/dictionary_entry.dart';

class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});
  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  int? _tappedGrowthBar;
  int? _tappedContribBar;

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

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/topo_map.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(systemHealthProvider);
                ref.invalidate(platformActivityProvider);
                await Future.delayed(const Duration(seconds: 1));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Platform stats refreshed.'),
                  ),
                );
              },
              color: AppColors.gold500,
              backgroundColor: isDark ? AppColors.forest800 : Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(context),
                    const SizedBox(height: 24),
                    _sectionLabel('VILLAGE PULSE'),
                          const SizedBox(height: 16),
                          const WotdWidget(),
                          const SizedBox(height: 12),
                          _buildWotdAdminControls(),
                          const SizedBox(height: 32),
                          _sectionLabel('PLATFORM STATS'),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.45,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children:
                                [
                                      _statCard(
                                        ref
                                            .watch(totalUsersCountProvider)
                                            .when(
                                              data: (count) => count.toString(),
                                              loading: () => '...',
                                              error: (_, __) => '!',
                                            ),
                                        'Total Users',
                                        Icons.people_outline,
                                        AppColors.semanticBlue,
                                      ),
                                      _statCard(
                                        ref
                                            .watch(totalWordsCountProvider)
                                            .when(
                                              data: (count) => count.toString(),
                                              loading: () => '...',
                                              error: (_, __) => '!',
                                            ),
                                        'Words Added',
                                        Icons.library_books_outlined,
                                        AppColors.semanticGreen,
                                      ),
                                      _statCard(
                                        ref
                                            .watch(pendingWordsCountProvider(null))
                                            .when(
                                              data: (count) => count.toString(),
                                              loading: () => '...',
                                              error: (_, __) => '!',
                                            ),
                                        'Pending Review',
                                        Icons.pending_outlined,
                                        AppColors.gold500,
                                      ),
                                      _statCard(
                                        ref
                                            .watch(totalAudioClipsCountProvider)
                                            .when(
                                              data: (count) => count.toString(),
                                              loading: () => '...',
                                              error: (_, __) => '!',
                                            ),
                                        'Audio Clips',
                                        Icons.mic_outlined,
                                        AppColors.semanticRed,
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            context.push('/admin/requests'),
                                        child: _statCard(
                                          ref
                                              .watch(
                                                pendingRequestsCountProvider,
                                              )
                                              .when(
                                                data: (count) =>
                                                    count.toString(),
                                                loading: () => '...',
                                                error: (_, __) => '!',
                                              ),
                                          'Role Requests',
                                          Icons.person_add_rounded,
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
                            child: BrandButton(
                              text: "ADVANCED PEDAGOGICAL ANALYTICS",
                              type: BrandButtonType.primary,
                              icon: Icons.analytics_rounded,
                              onTap: () => context.push('/admin/analytics'),
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 32),
                          _sectionLabel('SYSTEM HEALTH'),
                          const SizedBox(height: 16),
                          healthAsync.when(
                            data: (health) => _buildSystemHealthGrid(health),
                            loading: () => _buildSystemHealthGrid(null),
                            error: (_, __) => _buildSystemHealthGrid(null),
                          ),
                          const SizedBox(height: 32),
                          _sectionLabel('USER GROWTH (last 7 days)'),
                          const SizedBox(height: 16),
                          activityAsync.when(
                            data: (data) => BrandCard(
                              theme: BrandCardTheme.vibrant,
                              child: _buildInteractiveBarChart(
                                values: data['growth'] ?? [0,0,0,0,0,0,0],
                                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                                color: AppColors.semanticBlue,
                                tappedIndex: _tappedGrowthBar,
                                onTap: (i) => setState(() => _tappedGrowthBar = _tappedGrowthBar == i ? null : i),
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('Error loading growth data'),
                          ),
                          const SizedBox(height: 24),
                          _sectionLabel('CONTRIBUTIONS (last 7 days)'),
                          const SizedBox(height: 16),
                          activityAsync.when(
                            data: (data) => BrandCard(
                              theme: BrandCardTheme.vibrant,
                              child: _buildInteractiveBarChart(
                                values: data['contributions'] ?? [0,0,0,0,0,0,0],
                                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                                color: AppColors.semanticGreen,
                                tappedIndex: _tappedContribBar,
                                onTap: (i) => setState(() => _tappedContribBar = _tappedContribBar == i ? null : i),
                              ),
                            ).animate().fadeIn(delay: 500.ms),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('Error loading contribution data'),
                          ),
                          const SizedBox(height: 24),
                          _sectionLabel('DIALECT DISTRIBUTION'),
                          const SizedBox(height: 16),
                          BrandCard(
                            theme: BrandCardTheme.cream,
                            child: ref
                                .watch(dialectDistributionProvider)
                                .when(
                                  data: (distribution) {
                                    if (distribution.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Center(
                                          child: Text(
                                            'No data available',
                                            style: AppTypography.body.copyWith(
                                              color: AppColors.forest900,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return Column(
                                      children: distribution.entries.map((e) {
                                        return _dialectRow(
                                          context,
                                          e.key,
                                          e.value,
                                          _getDialectColor(e.key),
                                        );
                                      }).toList(),
                                    );
                                  },
                                  loading: () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(
                                        color: AppColors.forest900,
                                      ),
                                    ),
                                  ),
                                  error: (err, _) =>
                                      Center(child: Text('Error: $err')),
                                ),
                          ).animate().fadeIn(delay: 600.ms),
                          const SizedBox(height: 32),
                          _sectionLabel('SPATIAL ASSETS'),
                          const SizedBox(height: 16),
                          BrandCard(
                            theme: BrandCardTheme.vibrant,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.map_rounded,
                                        color: AppColors.gold500,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ANCESTRAL MAP ARCHITECT',
                                              style: AppTypography.h3.copyWith(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Manage coordinates for cultural sites and municipalities.',
                                              style: AppTypography.body
                                                  .copyWith(
                                                    color: Colors.white60,
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
                                    child: ElevatedButton(
                                      onPressed: () => context.push('/admin/map-architect'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.gold500,
                                        foregroundColor: AppColors.forest900,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'OPEN MAP EDITOR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _sectionLabel('GAMIFICATION & ECONOMICS'),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'WARRIOR CIRCLE OPS',
                                              style: AppTypography.h3.copyWith(
                                                color: AppColors.forest900,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Manage seasons, shop prices, and duel moderation.',
                                              style: AppTypography.body
                                                  .copyWith(
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
                                    child: ElevatedButton(
                                      onPressed: () => context.push('/admin/gamification'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.forest900,
                                        foregroundColor: AppColors.gold500,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'GO TO ECONOMICS HUB',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _sectionLabel('SYSTEM MAINTENANCE'),
                          const SizedBox(height: 16),
                          BrandCard(
                            theme: BrandCardTheme.vibrant,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_fix_high_rounded,
                                        color: AppColors.semanticRed,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'DATABASE SEEDER',
                                        style: AppTypography.h3.copyWith(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reset or initialize core platform data (Municipalities, Lessons, Dictionary). Use with caution.',
                                    style: AppTypography.body.copyWith(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _showSeedConfirmation(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.semanticRed.withValues(alpha: 0.2),
                                            foregroundColor: AppColors.semanticRed,
                                            side: const BorderSide(color: AppColors.semanticRed),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'SEED DATABASE',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _syncMetadata(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.gold500.withValues(alpha: 0.2),
                                            foregroundColor: AppColors.gold500,
                                            side: const BorderSide(color: AppColors.gold500),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'SYNC METADATA',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
        ],
      ),
    );
  }

  Widget _buildWotdAdminControls() {
    final metadataAsync = ref.watch(wotdMetadataProvider);

    return metadataAsync.when(
      data: (data) {
        final isManual = data?['isManual'] as bool? ?? false;
        return Row(
          children: [
            Expanded(
              child: BrandButton(
                text: "FORCE ROTATION",
                type: BrandButtonType.secondary,
                icon: Icons.refresh_rounded,
                onTap: () => _forceWotdRotation(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BrandButton(
                text: isManual ? "RESUME AUTO" : "PICK MANUALLY",
                type: isManual ? BrandButtonType.primary : BrandButtonType.secondary,
                icon: isManual ? Icons.auto_mode_rounded : Icons.edit_calendar_rounded,
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
    try {
      await ref.read(wordOfDayServiceProvider).forceNewWord();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word of the Day rotated.')),
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

  Future<void> _syncMetadata() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syncing town metadata...')),
      );
      await ref.read(firebaseServiceProvider).syncMunicipalityDialects();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metadata synced! Towns updated with current dialects.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  void _showSeedConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest800 : Colors.white,
        title: const Text('Seed Database?'),
        content: const Text(
          'This will re-initialize core platform data and update municipality IDs. Existing records will be merged or updated. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _runSeeder();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
            child: const Text('PROCEED'),
          ),
        ],
      ),
    );
  }

  Future<void> _runSeeder() async {
    try {
      // Import the seeder service
      // Note: We need to import database_seeder.dart at the top
      await DatabaseSeeder.seedAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database seeded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seeding failed: $e')),
      );
    }
  }

  Widget _buildHeroBanner(BuildContext context) {
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
                    'Maayong\nAdlaw,\n$name!',
                    style: AppTypography.displayBold.copyWith(
                      color: Colors.black,
                      fontSize: 32,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SYSTEM OVERSEER  •  COMMANDER',
                      style: AppTypography.label.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        letterSpacing: 1,
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
            case 'Storage':
              value = data['storage'] ?? value;
            case 'Database':
              value = data['database'] ?? value;
            case 'Uptime':
              value = data['uptime'] ?? value;
          }
        }
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: h == _defaultHealth.last ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.forestDarkCard : Colors.white,
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
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.forest500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  (h['label'] as String).toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white24 : AppColors.creamText3,
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

  Widget _sectionLabel(String label) => Text(
    label,
    style: AppTypography.mono.copyWith(
      color: isDark ? Colors.white24 : AppColors.creamText3,
      fontSize: 9,
      letterSpacing: 2,
    ),
  );

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest700.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? color.withValues(alpha: 0.1)
              : AppColors.creamBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.display.copyWith(
                  color: isDark ? Colors.white : AppColors.forest500,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white24 : AppColors.creamText3,
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
          final pct = values[i] / max;
          final isTapped = tappedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    if (isTapped)
                      Text(
                        '${values[i]}',
                        style: AppTypography.mono.copyWith(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (isTapped) const SizedBox(height: 4),
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
                        color: isTapped ? color : Colors.white24,
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

  Widget _dialectRow(
    BuildContext context,
    String name,
    double pct,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.creamText2,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: AppTypography.mono.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.creamBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                height: 8,
                width: MediaQuery.of(context).size.width * 0.7 * pct,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDialectColor(String dialect) {
    switch (dialect.toLowerCase()) {
      case 'mansaka':
        return AppColors.gold500;
      case 'mandaya':
        return AppColors.semanticBlue;
      case 'manobo':
        return AppColors.semanticGreen;
      case 'bagobo':
        return AppColors.semanticRed;
      case 'kagan':
        return AppColors.gold700;
      default:
        return AppColors.forest700;
    }
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
        color: isDark ? AppColors.forest800 : AppColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                          color: isDark ? Colors.white : AppColors.forest900,
                        ),
                      ),
                      Text(
                        'Force a word to be the Word of the Day',
                        style: AppTypography.body.copyWith(
                          color: isDark ? Colors.white60 : AppColors.forest600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search for a word...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
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
                final approvedWords = words.where((w) => w.status == ValidationStatus.approved).toList();

                if (approvedWords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No approved words found',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: approvedWords.length,
                  itemBuilder: (context, i) {
                    final w = approvedWords[i];
                    return Card(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        onTap: () => _confirmSelection(w),
                        title: Text(
                          w.indigenousWord,
                          style: AppTypography.h3.copyWith(
                            color: isDark ? Colors.white : AppColors.forest900,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          '${w.language} • ${w.translation}',
                          style: AppTypography.body.copyWith(
                            color: isDark ? Colors.white60 : AppColors.forest600,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm WOTD'),
        content: Text('Set "${word.indigenousWord}" as the Word of the Day? This will override automatic rotation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
              _setWord(word);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
            child: const Text('SET AS WOTD', style: TextStyle(color: Colors.black)),
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
        SnackBar(content: Text('"${word.indigenousWord}" is now the Word of the Day.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set word: $e')),
      );
    }
  }
}



