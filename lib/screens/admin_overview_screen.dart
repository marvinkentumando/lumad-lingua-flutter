import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../services/database_seeder.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import 'package:go_router/go_router.dart';
import '../providers/contributor_request_provider.dart';
import '../widgets/wotd_widget.dart';
import '../services/auth_service.dart';

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

  final List<Map<String, dynamic>> _systemHealth = [
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
            child: Column(
              children: [
                _buildHeroBanner(context),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
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
                          _sectionLabel('VILLAGE PULSE'),
                          const SizedBox(height: 16),
                          const WotdWidget(),
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
                                            .watch(pendingWordsCountProvider)
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
                          const SizedBox(height: 32),
                          _sectionLabel('SYSTEM HEALTH'),
                          const SizedBox(height: 16),
                          _buildSystemHealthGrid(),
                          const SizedBox(height: 32),
                          _sectionLabel('USER GROWTH (last 7 days)'),
                          const SizedBox(height: 16),
                          BrandCard(
                            theme: BrandCardTheme.vibrant,
                            child: _buildInteractiveBarChart(
                              values: [22, 35, 18, 47, 31, 58, 63],
                              labels: [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ],
                              color: AppColors.semanticBlue,
                              tappedIndex: _tappedGrowthBar,
                              onTap: (i) => setState(
                                () => _tappedGrowthBar = _tappedGrowthBar == i
                                    ? null
                                    : i,
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                          const SizedBox(height: 24),
                          _sectionLabel('CONTRIBUTIONS (last 7 days)'),
                          const SizedBox(height: 16),
                          BrandCard(
                            theme: BrandCardTheme.vibrant,
                            child: _buildInteractiveBarChart(
                              values: [8, 12, 5, 19, 14, 22, 17],
                              labels: [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ],
                              color: AppColors.semanticGreen,
                              tappedIndex: _tappedContribBar,
                              onTap: (i) => setState(
                                () => _tappedContribBar = _tappedContribBar == i
                                    ? null
                                    : i,
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms),
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
                          _sectionLabel('DATABASE MAINTENANCE'),
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
                                        Icons.storage_rounded,
                                        color: AppColors.gold500,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'INITIALIZE DATA',
                                              style: AppTypography.h3.copyWith(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Seed Firestore with sample words and map data.',
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
                                      onPressed: () async {
                                        try {
                                          await DatabaseSeeder.seedAll();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Database seeded successfully!',
                                              ),
                                              backgroundColor:
                                                  AppColors.semanticGreen,
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error seeding: $e',
                                              ),
                                              backgroundColor:
                                                  AppColors.semanticRed,
                                            ),
                                          );
                                        }
                                      },
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
                                        'SEED DATABASE',
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
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                      color: isDark ? AppColors.gold500 : Colors.black,
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
                        color: isDark ? Colors.white70 : Colors.black87,
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

  Widget _buildSystemHealthGrid() {
    return Row(
      children: _systemHealth.map((h) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: h == _systemHealth.last ? 0 : 10),
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
                  h['value'] as String,
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


