import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../models/admin_models.dart';
import '../providers/educator_provider.dart';
import '../utils/app_localization.dart';
import 'package:intl/intl.dart';

class EducatorAnalyticsScreen extends ConsumerStatefulWidget {
  const EducatorAnalyticsScreen({super.key});
  @override
  ConsumerState<EducatorAnalyticsScreen> createState() =>
      _EducatorAnalyticsScreenState();
}

class _EducatorAnalyticsScreenState
    extends ConsumerState<EducatorAnalyticsScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  String _timeRange = 'Daily';
  int? _tappedBarIndex;
  int? _selectedUnit;

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final userAuth = ref.watch(authStateProvider).value;
    final educatorId = userAuth?.uid ?? '';

    final selectedYear = ref.watch(selectedAcademicYearProvider);
    final allUsersAsync = ref.watch(educatorLearnersProvider(educatorId));
    final usersAsync = allUsersAsync.whenData((users) {
      if (selectedYear == 'All') return users;
      return users.where((u) => (u.academicYear ?? '2026-2027') == selectedYear).toList();
    });

    final dialectDistAsync = ref.watch(dialectDistributionProvider);
    final topLearnersAsync = ref.watch(villageTopLearnersProvider(educatorId));
    final analyticsAsync = ref.watch(educatorAnalyticsProvider((educatorId: educatorId, academicYear: selectedYear)));
    final totalWordsAsync = ref.watch(totalWordsCountProvider);

    final eduLessonsAsync = ref.watch(educatorLessonsProvider);
    final availableUnits = eduLessonsAsync.when(
      data: (lessons) {
        final units = lessons.map((l) => l.unitNumber).toSet().toList()..sort();
        return units.isEmpty ? [1] : units;
      },
      loading: () => [1],
      error: (_, __) => [1],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(educatorLearnersProvider(educatorId));
              ref.invalidate(villageTopLearnersProvider(educatorId));
              ref.invalidate(educatorAnalyticsProvider((educatorId: educatorId, academicYear: selectedYear)));
            },
            color: AppColors.gold500,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(
                    usersAsync.value ?? [],
                    dialectDistAsync.value ?? {},
                    analyticsAsync.value ?? {},
                    totalWordsAsync.value ?? 0,
                    topLearnersAsync.value ?? [],
                    availableUnits,
                    l10n,
                  ),
                  const SizedBox(height: 24),
                  
                  usersAsync.when(
                    data: (users) => _buildActiveLearnersStats(users, l10n),
                    loading: () => _buildLoadingCard(100),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  analyticsAsync.when(
                    data: (analytics) => Row(
                      children: [
                        _buildStatCard(
                          l10n.translate('total_xp'),
                          '${analytics['totalXP'] ?? 0}',
                          l10n.translate('across_village'),
                          AppColors.gold500,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          l10n.translate('progress'),
                          (analytics['avgLessonsCompleted'] as double? ?? 0).toStringAsFixed(1),
                          l10n.translate('avg_lessons'),
                          AppColors.semanticBlue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          l10n.translate('accuracy'),
                          '${((analytics['pronunciationAccuracy'] as double? ?? 0) * 100).toInt()}%',
                          l10n.translate('pronunciation'),
                          AppColors.semanticGreen,
                        ),
                      ],
                    ),
                    loading: () => _buildLoadingCard(80),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  _buildTimeRangeSelector(l10n),
                  const SizedBox(height: 24),

                  usersAsync.when(
                    data: (users) => _buildActivityChart(users, l10n),
                    loading: () => _buildLoadingCard(220),
                    error: (e, _) => _buildErrorCard(e),
                  ),

                  const SizedBox(height: 32),

                  usersAsync.when(
                    data: (users) => _buildStudentGrowth(users, l10n),
                    loading: () => _buildLoadingCard(120),
                    error: (e, _) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  usersAsync.when(
                    data: (users) => _buildXpDistributionCard(users, l10n),
                    loading: () => _buildLoadingCard(120),
                    error: (e, _) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),
                  analyticsAsync.when(
                    data: (analytics) {
                      final quizPerformance = List<Map<String, dynamic>>.from(analytics['quizPerformance'] ?? []);
                      final commonHurdles = List<Map<String, dynamic>>.from(analytics['commonHurdles'] ?? []);
                      final weeklyTrend = List<Map<String, dynamic>>.from(analytics['weeklyTrend'] ?? []);
                      final users = usersAsync.value ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTemporalTrendChart(weeklyTrend, l10n),
                          const SizedBox(height: 32),
                          _buildSectionTitle(l10n.translate('quiz_performance')),
                          const SizedBox(height: 16),
                          if (quizPerformance.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: Text(
                                l10n.translate('no_quiz_data_yet'),
                                style: AppTypography.body.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                              ),
                            )
                          else
                            ...quizPerformance.map((q) => _buildQuizItem(q, users, l10n)),

                          const SizedBox(height: 32),
                          _buildSectionTitle(l10n.translate('common_hurdles')),
                          const SizedBox(height: 16),
                          if (commonHurdles.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: Text(
                                l10n.translate('no_hurdles_yet'),
                                style: AppTypography.body.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                              ),
                            )
                          else
                            ...commonHurdles.map((h) => _buildHurdleItem(
                                  h['topic'] ?? l10n.translate('unknown_topic'),
                                  h['stat'] ?? l10n.translate('no_stats'),
                                  h['lessonName'] ?? l10n.translate('unknown_lesson'),
                                  l10n,
                                )),
                        ],
                      );
                    },
                    loading: () => Column(
                      children: [
                        _buildLoadingCard(150),
                        const SizedBox(height: 32),
                        _buildLoadingCard(150),
                      ],
                    ),
                    error: (e, _) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle(l10n.translate('top_learners')),
                  const SizedBox(height: 16),
                  topLearnersAsync.when(
                    data: (learners) => Column(
                      children: learners.asMap().entries.map((e) {
                        final i = e.key;
                        final l = e.value;
                        return _buildLeaderboardItem(
                          '${i + 1}',
                          l['username'] ?? l10n.translate('learner_default'),
                          l['municipality'] ?? l['indigenousGroup'] ?? l10n.translate('unknown'),
                          l['xp'] ?? 0,
                          i == 0
                              ? AppColors.gold500
                              : i == 1
                              ? Colors.grey.shade400
                              : i == 2
                              ? Colors.orange.shade300
                              : (isDark ? Colors.white24 : AppColors.creamBorder),
                        );
                      }).toList(),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.gold500),
                    ),
                    error: (e, _) => Text(
                      l10n.translate('error_prefix', params: {'error': '$e'}),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppColors.creamText3,
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

  Widget _buildHeader(
    List<AdminUser> users,
    Map<String, double> dialectDist,
    Map<String, dynamic> analytics,
    int totalWords,
    List<Map<String, dynamic>> topLearners,
    List<int> availableUnits,
    AppLocalization l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.translate('advanced_analytics'),
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold500,
                ),
              ),
            ),
            Row(
              children: [
                _buildAcademicYearFilter(),
                const SizedBox(width: 8),
                _buildUnitFilter(availableUnits),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${users.length} learners tracked',
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitFilter(List<int> availableUnits) {
    return PopupMenuButton<int?>(
      onSelected: (unit) {
        HapticService.selection();
        setState(() => _selectedUnit = unit);
      },
      color: isDark ? AppColors.forest800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded, color: AppColors.gold500, size: 16),
            const SizedBox(width: 6),
            Text(
              _selectedUnit == null ? 'All Units' : 'Unit $_selectedUnit',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('All Units'),
        ),
        ...availableUnits.map((uNum) => PopupMenuItem(
          value: uNum,
          child: Text('Unit $uNum'),
        )),
      ],
    );
  }

  Widget _buildAcademicYearFilter() {
    final selectedYear = ref.watch(selectedAcademicYearProvider);
    final availableYears = ref.watch(availableAcademicYearsProvider);

    return PopupMenuButton<String>(
      onSelected: (year) {
        HapticService.selection();
        ref.read(selectedAcademicYearProvider.notifier).state = year;
      },
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.gold500.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.gold500, size: 14),
            const SizedBox(width: 4),
            Text(
              selectedYear == 'All' ? 'ALL YEARS' : 'SY $selectedYear',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.gold500, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => availableYears.map((year) {
        final isActive = selectedYear == year;
        return PopupMenuItem<String>(
          value: year,
          child: Row(
            children: [
              if (isActive)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_rounded, color: AppColors.gold500, size: 16),
                ),
              Text(
                year == 'All' ? 'All Academic Years' : 'SY $year',
                style: TextStyle(
                  color: isActive ? AppColors.gold500 : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingCard(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.gold500),
      ),
    );
  }

  Widget _buildErrorCard(dynamic e) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.semanticRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'Error loading data: $e',
        style: const TextStyle(color: AppColors.semanticRed),
      ),
    );
  }

  Widget _buildActivityChart(List<AdminUser> users, AppLocalization l10n) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> bars = [];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_timeRange == 'Daily') {
      // Last 7 days of Daily Active Users (DAU)
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dateKey =
            "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

        final count = users.where((u) => u.activityMap[dateKey] == true).length;

        bars.add({
          'label': DateFormat('E').format(day)[0],
          'value': count,
        });
      }
    } else if (_timeRange == 'Weekly') {
      // Weekly Active Users (WAU) - last 4 weeks
      for (int i = 3; i >= 0; i--) {
        final weekEnd = now.subtract(Duration(days: i * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 6));

        final count = users.where((u) {
          return u.activityMap.keys.any((k) {
            final date = DateTime.tryParse(k);
            if (date == null) return false;
            return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                date.isBefore(weekEnd.add(const Duration(seconds: 1)));
          });
        }).length;

        bars.add({
          'label': 'W${4 - i}',
          'value': count,
        });
      }
    } else {
      // Monthly Engagement: Last 6 months
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthPrefix =
            "${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}";

        // Count users active at least once in this month
        final count = users.where((u) {
          return u.activityMap.keys.any((k) => k.startsWith(monthPrefix));
        }).length;

        bars.add({
          'label': DateFormat('MMM').format(monthDate),
          'value': count,
        });
      }
    }

    final maxVal = bars.fold<int>(
      0,
      (m, b) => (b['value'] as int) > m ? (b['value'] as int) : m,
    );

    String chartTitle = l10n.translate('active_learners');
    if (_timeRange == 'Daily') chartTitle = l10n.translate('daily_active_learners_7d');
    if (_timeRange == 'Weekly') chartTitle = l10n.translate('weekly_active_learners_4w');
    if (_timeRange == 'Monthly') chartTitle = l10n.translate('monthly_active_learners_6m');

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.forest900.withValues(alpha: 0.05),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chartTitle,
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.asMap().entries.map((e) {
                final i = e.key;
                final b = e.value;
                final isTapped = _tappedBarIndex == i;
                final val = b['value'] as int;
                final h = maxVal > 0 ? (val / maxVal) * 120 : 0.0;
                
                return GestureDetector(
                  onTap: () {
                    HapticService.light();
                    setState(() => _tappedBarIndex = isTapped ? null : i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$val',
                        style: AppTypography.label.copyWith(
                          color: isTapped ? AppColors.gold500 : (isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.4)),
                          fontSize: 9,
                          fontWeight: isTapped ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 18,
                        height: h,
                        decoration: BoxDecoration(
                          color: isTapped
                              ? AppColors.gold500
                              : AppColors.gold500.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b['label'] as String,
                        style: AppTypography.label.copyWith(
                          color: isTapped
                              ? AppColors.gold500
                              : (isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.4)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGrowth(List<AdminUser> users, AppLocalization l10n) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final recentCount = users
        .where((u) => u.joinedAt.isAfter(thirtyDaysAgo))
        .length;

    // Calculate growth points: cumulative count for each of the last 30 days
    final List<FlSpot> spots = [];
    final int totalUsersBefore = users.where((u) => u.joinedAt.isBefore(thirtyDaysAgo)).length;
    
    int cumulative = totalUsersBefore;
    for (int i = 29; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final joinedThatDay = users.where((u) => 
        u.joinedAt.year == day.year && 
        u.joinedAt.month == day.month && 
        u.joinedAt.day == day.day).length;
      
      cumulative += joinedThatDay;
      spots.add(FlSpot((29 - i).toDouble(), cumulative.toDouble()));
    }

    final maxY = spots.isEmpty ? 10.0 : (spots.last.y * 1.2).ceilToDouble();

    return InkWell(
      onTap: () {
        HapticService.selection();
        _showStudentGrowthDetails(context, users, isDark, l10n);
      },
      borderRadius: BorderRadius.circular(20),
      child: BrandCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('student_growth'),
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.translate('new_learners_this_month', params: {'count': '$recentCount'}),
              style: AppTypography.body.copyWith(
                color: AppColors.semanticGreen,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white10 : Colors.black12,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxY || value == (maxY / 2).roundToDouble()) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          final dayIndex = value.toInt();
                          if (dayIndex == 0 || dayIndex == 15 || dayIndex == 29) {
                            final targetDate = now.subtract(Duration(days: 29 - dayIndex));
                            return Text(
                              DateFormat('MMM d').format(targetDate),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5),
                                fontSize: 9,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 29,
                  minY: 0,
                  maxY: maxY > 0 ? maxY : 10.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.gold500,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.gold500.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final dayIndex = spot.x.toInt();
                          final targetDate = now.subtract(Duration(days: 29 - dayIndex));
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(targetDate)}\n${spot.y.toInt()} learners',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentGrowthDetails(BuildContext context, List<AdminUser> users, bool isDark, AppLocalization l10n) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentUsers = users.where((u) => u.joinedAt.isAfter(thirtyDaysAgo)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest800 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('student_growth'),
                        style: AppTypography.h3.copyWith(
                          color: isDark ? Colors.white : AppColors.forest900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Enrolled: ${users.length} learners',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          'Recently Joined (${recentUsers.length} this month)',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.semanticGreen,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (recentUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No new signups in the last 30 days.',
                              style: AppTypography.body.copyWith(
                                color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        else
                          ...recentUsers.map((user) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.forest900 : Colors.black.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.gold500.withValues(alpha: 0.2),
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                        style: const TextStyle(color: AppColors.gold500, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name.isNotEmpty ? user.name : 'Learner',
                                            style: AppTypography.body.copyWith(
                                              color: isDark ? Colors.white : AppColors.forest900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Joined: ${DateFormat('MMM d, yyyy').format(user.joinedAt)} • XP: ${user.xp}',
                                            style: AppTypography.label.copyWith(
                                              color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.6),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeRangeSelector(AppLocalization l10n) {
    return Row(
      children: ['Daily', 'Weekly', 'Monthly'].map((range) {
        final isSelected = _timeRange == range;
        final label = range == 'Daily'
            ? l10n.translate('daily')
            : range == 'Weekly'
                ? l10n.translate('weekly')
                : l10n.translate('monthly');

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              HapticService.selection();
              setState(() {
                _timeRange = range;
                _tappedBarIndex = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold500 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold500
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.creamBorder),
                ),
              ),
              child: Text(
                label.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: isSelected
                      ? AppColors.forest900
                      : (isDark ? Colors.white60 : AppColors.creamText2),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuizItem(Map<String, dynamic> quiz, List<AdminUser> users, AppLocalization l10n) {
    final pass = quiz['pass'] as int;
    final fail = quiz['fail'] as int;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticService.selection();
        _showQuizStudentBreakdown(context, quiz, users, isDark, l10n);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : AppColors.forest900.withValues(alpha: 0.05),
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quiz['name'] as String,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: pass > 0 ? pass : 1,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.semanticGreen,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(4),
                        right: fail == 0 ? const Radius.circular(4) : Radius.zero,
                      ),
                    ),
                  ),
                ),
                if (fail > 0)
                  Expanded(
                    flex: fail,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.semanticRed,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('percent_passed', params: {'percent': '$pass'}),
                  style: AppTypography.label.copyWith(
                    color: AppColors.semanticGreen,
                    fontSize: 10,
                  ),
                ),
                Text(
                  l10n.translate('percent_failed', params: {'percent': '$fail'}),
                  style: AppTypography.label.copyWith(
                    color: AppColors.semanticRed,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizStudentBreakdown(BuildContext context, Map<String, dynamic> quiz, List<AdminUser> users, bool isDark, AppLocalization l10n) {
    final passRate = quiz['pass'] as int;
    final lessonName = quiz['name'] as String;

    final passedUserIds = List<String>.from(quiz['passedUserIds'] ?? []);
    final attemptedUserIds = List<String>.from(quiz['attemptedUserIds'] ?? []);

    final passedUsers = users.where((u) => passedUserIds.contains(u.id)).toList();
    final strugglingUsers = users.where((u) => attemptedUserIds.contains(u.id)).toList();
    final unattemptedUsers = users.where((u) => !passedUserIds.contains(u.id) && !attemptedUserIds.contains(u.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest800 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lessonName,
                          style: AppTypography.h3.copyWith(
                            color: isDark ? Colors.white : AppColors.forest900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$passRate% Pass Rate',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          'Passed Students (${passedUsers.length})',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.semanticGreen,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (passedUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('No students passed yet.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                          )
                        else
                          ...passedUsers.map((u) => _buildStudentRow(u.name, '${u.xp} XP • ${u.streak}d streak', true, isDark, status: 'passed')),
                        const SizedBox(height: 24),
                        Text(
                          'Needs Review / Failed (${strugglingUsers.length})',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.semanticRed,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (strugglingUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('No students need review.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                          )
                        else
                          ...strugglingUsers.map((u) => _buildStudentRow(u.name, 'Attempted • Needs review', false, isDark, status: 'failed')),
                        const SizedBox(height: 24),
                        Text(
                          "Haven't Taken / Not Taken (${unattemptedUsers.length})",
                          style: AppTypography.h3.copyWith(
                            color: AppColors.gold500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (unattemptedUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('All students have taken this lesson.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                          )
                        else
                          ...unattemptedUsers.map((u) => _buildStudentRow(u.name, 'Not taken yet', false, isDark, status: 'unattempted')),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentRow(String name, String detail, bool passed, bool isDark, {String? status}) {
    final effectiveStatus = status ?? (passed ? 'passed' : 'failed');
    Color color;
    IconData icon;
    if (effectiveStatus == 'passed') {
      color = AppColors.semanticGreen;
      icon = Icons.check;
    } else if (effectiveStatus == 'failed') {
      color = AppColors.semanticRed;
      icon = Icons.priority_high;
    } else {
      color = AppColors.gold500;
      icon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest900 : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.forest900)),
                Text(detail, style: AppTypography.caption.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHurdleItem(
    String topic,
    String stat,
    String lessonName,
    AppLocalization l10n,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticService.selection();
        _showHurdleStudentBreakdown(context, topic, stat, lessonName, isDark, l10n);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.semanticRed.withValues(alpha: 0.1)
                : AppColors.semanticRed.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.semanticRed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showHurdleStudentBreakdown(BuildContext context, String topic, String stat, String lessonName, bool isDark, AppLocalization l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest800 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          topic,
                          style: AppTypography.h3.copyWith(
                            color: isDark ? Colors.white : AppColors.forest900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lessonName,
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stat,
                    style: AppTypography.body.copyWith(
                      color: AppColors.semanticRed,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          'Students Requiring Review',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.semanticRed,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStudentRow('Lumad Apprentice', 'Repeated 3 slips on this concept', false, isDark),
                        _buildStudentRow('Student Learner', 'Struggled with audio tone matching', false, isDark),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gold500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Educator Tip',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.gold500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Assign a targeted review flashcard set for $topic to reinforce understanding.',
                                style: AppTypography.body.copyWith(
                                  color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.label.copyWith(
        color: AppColors.gold500,
        letterSpacing: 2,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildLeaderboardItem(
    String rank,
    String name,
    String municipality,
    int score,
    Color rankColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.forest900.withValues(alpha: 0.05),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              rank,
              style: TextStyle(color: rankColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  municipality,
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$score XP',
            style: AppTypography.mono.copyWith(
              color: isDark ? AppColors.gold500 : AppColors.gold700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLearnersStats(List<AdminUser> users, AppLocalization l10n) {
    final now = DateTime.now();
    
    // DAU (Today)
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final dau = users.where((u) => u.activityMap[todayStr] == true).length;
    
    // WAU (Last 7 days)
    final last7Days = List.generate(7, (i) => DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i))));
    final wau = users.where((u) => last7Days.any((date) => u.activityMap[date] == true)).length;
    
    // MAU (Last 30 days)
    final last30Days = List.generate(30, (i) => DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i))));
    final mau = users.where((u) => last30Days.any((date) => u.activityMap[date] == true)).length;

    return Row(
      children: [
        _buildStatCard('DAU', dau.toString(), l10n.translate('today'), AppColors.gold500),
        const SizedBox(width: 12),
        _buildStatCard('WAU', wau.toString(), l10n.translate('days_count', params: {'count': '7'}), AppColors.semanticBlue),
        const SizedBox(width: 12),
        _buildStatCard('MAU', mau.toString(), l10n.translate('days_count', params: {'count': '30'}), AppColors.semanticGreen),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String sub, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.forest900.withValues(alpha: 0.05),
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              sub,
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.4),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemporalTrendChart(List<Map<String, dynamic>> weeklyTrend, AppLocalization l10n) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (weeklyTrend.isEmpty) return const SizedBox.shrink();

    final passSpots = weeklyTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['passRate'] as num).toDouble());
    }).toList();

    final accSpots = weeklyTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['accuracy'] as num).toDouble());
    }).toList();

    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.cream,
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Performance Trend',
                style: AppTypography.h3.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('Pass Rate (%)', AppColors.semanticGreen),
                  const SizedBox(width: 12),
                  _buildLegendItem('Accuracy (%)', AppColors.gold500),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Week-over-week quiz pass rate and pronunciation accuracy',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < weeklyTrend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              weeklyTrend[index]['label'] as String,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (weeklyTrend.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: passSpots,
                    isCurved: true,
                    color: AppColors.semanticGreen,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.semanticGreen.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: accSpots,
                    isCurved: true,
                    color: AppColors.gold500,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : AppColors.forest900,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildXpDistributionCard(List<AdminUser> users, AppLocalization l10n) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (users.isEmpty) return const SizedBox.shrink();

    final xps = users.map((u) => u.xp).toList()..sort();
    final minXp = xps.first;
    final maxXp = xps.last;
    final sumXp = xps.fold(0, (a, b) => a + b);
    final meanXp = (sumXp / xps.length).round();

    int medianXp = 0;
    if (xps.isNotEmpty) {
      if (xps.length % 2 == 1) {
        medianXp = xps[xps.length ~/ 2];
      } else {
        medianXp = ((xps[xps.length ~/ 2 - 1] + xps[xps.length ~/ 2]) / 2).round();
      }
    }

    int q1 = xps[(xps.length * 0.25).floor()];
    int q3 = xps[(xps.length * 0.75).floor()];
    final range = (maxXp - minXp) <= 0 ? 1 : (maxXp - minXp);

    final double q1Ratio = ((q1 - minXp) / range).clamp(0.0, 1.0);
    final double q3Ratio = ((q3 - minXp) / range).clamp(0.0, 1.0);
    final double medianRatio = ((medianXp - minXp) / range).clamp(0.0, 1.0);

    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.cream,
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP Performance Spectrum',
                style: AppTypography.h3.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Middle 50% Spread: ${q3 - q1} XP',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Visual tier distribution showing student performance bands & class median',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),

          // 3-Zone Performance Spectrum Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double medianLeft = width * medianRatio;

              return Column(
                children: [
                  // Median Pin Label Above Bar
                  SizedBox(
                    height: 28,
                    child: Stack(
                      children: [
                        Positioned(
                          left: (medianLeft - 40).clamp(0.0, width - 80),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold500,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Median: $medianXp XP',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.forest900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Multi-Zone Bar Track
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                        child: Row(
                          children: [
                            // Zone 1: Lower Tier (Needs Support)
                            Expanded(
                              flex: (q1Ratio * 100).round().clamp(1, 100),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                                ),
                              ),
                            ),
                            // Zone 2: Middle Tier (Core Progress)
                            Expanded(
                              flex: (((q3Ratio - q1Ratio) * 100).round()).clamp(1, 100),
                              child: Container(
                                color: AppColors.gold500,
                              ),
                            ),
                            // Zone 3: Top Tier (High Achievers)
                            Expanded(
                              flex: (((1.0 - q3Ratio) * 100).round()).clamp(1, 100),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.semanticGreen,
                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(11)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Vertical Median Indicator Pin
                      Positioned(
                        left: (medianLeft - 2).clamp(0.0, width - 4),
                        child: Container(
                          width: 4,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : AppColors.forest900,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Min, Mean, Max Labels below the bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lowest: $minXp XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black54)),
                      Text('Class Avg: $meanXp XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gold500)),
                      Text('Highest: $maxXp XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black54)),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Simplified Tier Cards
          Row(
            children: [
              _buildSpectrumChip('Lower 25%', '$q1 XP', 'Needs Support', Colors.amber.shade700),
              const SizedBox(width: 8),
              _buildSpectrumChip('Middle 50%', '$medianXp XP', 'Core Progress', AppColors.gold500),
              const SizedBox(width: 8),
              _buildSpectrumChip('Top 25%', '$q3 XP', 'High Achievers', AppColors.semanticGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrumChip(String tier, String val, String subtitle, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(tier, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.forest900)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      ),
    );
  }
}


