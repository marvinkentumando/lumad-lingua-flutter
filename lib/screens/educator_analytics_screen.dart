import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../services/firebase_service.dart';
import '../models/admin_models.dart';
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
  String _timeRange = 'Weekly';
  int? _tappedBarIndex;

  @override
  Widget build(BuildContext context) {
    final allUsersAsync = ref.watch(allUsersProvider);
    final dialectDistAsync = ref.watch(dialectDistributionProvider);
    final topLearnersAsync = ref.watch(topLearnersProvider);
    final analyticsAsync = ref.watch(educatorAnalyticsProvider);
    final totalWordsAsync = ref.watch(totalWordsCountProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allUsersProvider);
            ref.invalidate(dialectDistributionProvider);
            ref.invalidate(topLearnersProvider);
          },
          color: AppColors.gold500,
          backgroundColor: isDark ? AppColors.forest800 : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                _buildHeader(
                  allUsersAsync.value ?? [],
                  dialectDistAsync.value ?? {},
                  analyticsAsync.value ?? {},
                  totalWordsAsync.value ?? 0,
                  topLearnersAsync.value ?? [],
                ),
                const SizedBox(height: 24),
                _buildTimeRangeSelector(),
                const SizedBox(height: 24),

                allUsersAsync.when(
                  data: (users) => _buildActivityChart(users),
                  loading: () => _buildLoadingCard(220),
                  error: (e, _) => _buildErrorCard(e),
                ),

                const SizedBox(height: 32),

                dialectDistAsync.when(
                  data: (dist) => _buildDialectDistributionChart(dist),
                  loading: () => _buildLoadingCard(150),
                  error: (e, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),

                allUsersAsync.when(
                  data: (users) => _buildStudentGrowth(users),
                  loading: () => _buildLoadingCard(120),
                  error: (e, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),
                _buildRetentionCard(allUsersAsync),
                const SizedBox(height: 16),
                _buildWordsStatsCard(totalWordsAsync),

                const SizedBox(height: 32),
                analyticsAsync.when(
                  data: (analytics) {
                    final quizPerformance = List<Map<String, dynamic>>.from(analytics['quizPerformance'] ?? []);
                    final commonHurdles = List<Map<String, dynamic>>.from(analytics['commonHurdles'] ?? []);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Quiz Performance'),
                        const SizedBox(height: 16),
                        if (quizPerformance.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Text(
                              'No quiz data recorded yet.',
                              style: AppTypography.body.copyWith(color: isDark ? Colors.white24 : AppColors.creamText3),
                            ),
                          )
                        else
                          ...quizPerformance.map((q) => _buildQuizItem(q)),

                        const SizedBox(height: 32),
                        _buildSectionTitle('Common Hurdles'),
                        const SizedBox(height: 16),
                        if (commonHurdles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Text(
                              'No significant hurdles identified yet.',
                              style: AppTypography.body.copyWith(color: isDark ? Colors.white24 : AppColors.creamText3),
                            ),
                          )
                        else
                          ...commonHurdles.map((h) => _buildHurdleItem(
                                h['topic'] ?? 'Unknown Topic',
                                h['stat'] ?? 'No stats',
                                h['lessonName'] ?? 'Unknown Lesson',
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
                _buildSectionTitle('Top Learners'),
                const SizedBox(height: 16),
                topLearnersAsync.when(
                  data: (learners) => Column(
                    children: learners.asMap().entries.map((e) {
                      final i = e.key;
                      final l = e.value;
                      return _buildLeaderboardItem(
                        '${i + 1}',
                        l['username'] ?? 'Learner',
                        l['role'] ?? 'Student',
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
                    'Error: $e',
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
    );
  }

  Widget _buildHeader(
    List<AdminUser> users,
    Map<String, double> dialectDist,
    Map<String, dynamic> analytics,
    int totalWords,
    List<Map<String, dynamic>> topLearners,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Analytics',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.gold500,
            ),
          ),
        ),
        Row(
          children: [
            _buildExportButton(
              users,
              dialectDist,
              analytics,
              totalWords,
              topLearners,
            ),
            const SizedBox(width: 8),
            _buildFeedbackBell(),
          ],
        ),
      ],
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

  Widget _buildActivityChart(List<AdminUser> users) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> bars = [];

    if (_timeRange == 'Weekly') {
      // Last 7 days of Daily Active Users (DAU)
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dateKey = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        
        final count = users.where((u) => u.activityMap[dateKey] == true).length;
        
        bars.add({
          'label': DateFormat('E').format(day)[0],
          'value': count,
        });
      }
    } else {
      // Monthly Engagement: Last 6 months
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthPrefix = "${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}";
        
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

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _timeRange == 'Weekly' ? 'Daily Active Learners' : 'Monthly Active Learners',
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white : AppColors.creamText,
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
                final h = maxVal > 0
                    ? ((b['value'] as int) / maxVal) * 120
                    : 0.0;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _tappedBarIndex = isTapped ? null : i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isTapped)
                        Text(
                          '${b['value']}',
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (isTapped) const SizedBox(height: 4),
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
                              : (isDark ? Colors.white38 : AppColors.creamText3),
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

  Widget _buildDialectDistributionChart(Map<String, double> dist) {
    if (dist.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sorted = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final main = sorted.first;
    final other = sorted.length > 1 ? sorted[1] : null;

    return BrandCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dictionary Dialect Mix',
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white : AppColors.creamText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: (main.value * 100).toInt(),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.gold500,
                    borderRadius: BorderRadius.horizontal(
                      left: const Radius.circular(10),
                      right: other == null
                          ? const Radius.circular(10)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
              if (other != null)
                Expanded(
                  flex: (other.value * 100).toInt(),
                  child: Container(
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.semanticBlue,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, color: AppColors.gold500),
                  const SizedBox(width: 8),
                  Text(
                    '${main.key} (${(main.value * 100).toInt()}%)',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.creamText2,
                    ),
                  ),
                ],
              ),
              if (other != null)
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: AppColors.semanticBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${other.key} (${(other.value * 100).toInt()}%)',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.creamText2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGrowth(List<AdminUser> users) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentCount = users
        .where((u) => u.joinedAt.isAfter(thirtyDaysAgo))
        .length;

    // Calculate growth points: cumulative count for each of the last 30 days
    final List<double> growthPoints = [];
    final int totalUsersBefore = users.where((u) => u.joinedAt.isBefore(thirtyDaysAgo)).length;
    
    int cumulative = totalUsersBefore;
    for (int i = 29; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final joinedThatDay = users.where((u) => 
        u.joinedAt.year == day.year && 
        u.joinedAt.month == day.month && 
        u.joinedAt.day == day.day).length;
      
      cumulative += joinedThatDay;
      growthPoints.add(cumulative.toDouble());
    }

    // Normalize points to 0.0 - 1.0 range for the painter
    final maxGrowth = growthPoints.isEmpty ? 1.0 : growthPoints.last;
    final normalizedPoints = growthPoints.map((p) => maxGrowth > 0 ? p / maxGrowth : 0.0).toList();

    return BrandCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Growth',
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white : AppColors.creamText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+$recentCount new learners this month',
            style: AppTypography.body.copyWith(
              color: AppColors.semanticGreen,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: CustomPaint(
              painter: _GrowthPainter(points: normalizedPoints), 
              size: Size.infinite
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionCard(AsyncValue<List<AdminUser>> usersAsync) {
    return usersAsync.when(
      data: (users) {
        final active = users.where((u) => u.xp > 0).length;
        final retention = users.isEmpty
            ? 0
            : (active / users.length * 100).toInt();
        return _buildAnalyticsCard(
          'Overall Retention',
          '$retention% of users have started learning.',
          Icons.trending_up_rounded,
        );
      },
      loading: () => _buildLoadingCard(80),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildWordsStatsCard(AsyncValue<int> countAsync) {
    return countAsync.when(
      data: (count) => _buildAnalyticsCard(
        'Preservation Status',
        '$count cultural terms recorded in the dictionary.',
        Icons.menu_book_rounded,
      ),
      loading: () => _buildLoadingCard(80),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // --- Static/Helper UI Components ---

  Widget _buildExportButton(
    List<AdminUser> users,
    Map<String, double> dialectDist,
    Map<String, dynamic> analytics,
    int totalWords,
    List<Map<String, dynamic>> topLearners,
  ) {
    return PopupMenuButton<String>(
      onSelected: (val) => _exportData(
        val,
        users,
        dialectDist,
        analytics,
        totalWords,
        topLearners,
      ),
      color: isDark ? AppColors.forest800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.creamBorder,
          ),
        ),
        child: const Icon(
          Icons.file_download_outlined,
          color: AppColors.gold500,
          size: 20,
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'CSV',
          child: Text(
            'Export CSV',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.creamText2,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'PDF',
          child: Text(
            'Export PDF',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.creamText2,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportData(
    String format,
    List<AdminUser> users,
    Map<String, double> dialectDist,
    Map<String, dynamic> analytics,
    int totalWords,
    List<Map<String, dynamic>> topLearners,
  ) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(now);
      final filename = 'LumadLingua_Report_$dateStr';

      if (format == 'CSV') {
        final List<List<dynamic>> rows = [];
        // Header
        rows.add(['Section', 'Metric', 'Value']);
        // Overview
        rows.add(['Overview', 'Total Users', users.length]);
        rows.add(['Overview', 'Total Words', totalWords]);
        
        // Retention
        final activeCount = users.where((u) => u.xp > 0).length;
        final retention = users.isEmpty ? 0 : (activeCount / users.length * 100).toInt();
        rows.add(['Retention', 'Overall Retention %', '$retention%']);

        // Dialects
        dialectDist.forEach((k, v) {
          rows.add(['Dialect Mix', k, '${(v * 100).toInt()}%']);
        });

        // Top Learners
        rows.add(['Top Learners', 'Rank', 'Username', 'XP']);
        for (int i = 0; i < topLearners.length; i++) {
          rows.add(['Top Learners', i + 1, topLearners[i]['username'], topLearners[i]['xp']]);
        }

        final csvData = ListToCsvConverter().convert(rows);
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$filename.csv');
        await file.writeAsString(csvData);

        await Share.shareXFiles([XFile(file.path)], text: 'Educator Analytics Report (CSV)');
      } else {
        // PDF Implementation
        final pdf = pw.Document();
        
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Header(level: 0, child: pw.Text('Lumad Lingua - Educator Analytics Report')),
              pw.Paragraph(text: 'Generated on: ${DateFormat('MMMM dd, yyyy HH:mm').format(now)}'),
              
              pw.Header(level: 1, child: pw.Text('System Overview')),
              pw.Bullet(text: 'Total Registered Users: ${users.length}'),
              pw.Bullet(text: 'Total Dictionary Words: $totalWords'),
              pw.Bullet(text: 'Active Learners (XP > 0): ${users.where((u) => u.xp > 0).length}'),
              
              pw.Header(level: 1, child: pw.Text('Dialect Distribution')),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['Dialect', 'Percentage'],
                  ...dialectDist.entries.map((e) => [e.key, '${(e.value * 100).toInt()}%']),
                ],
              ),

              pw.Header(level: 1, child: pw.Text('Quiz Performance')),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['Lesson Name', 'Pass Rate', 'Fail Rate'],
                  ...List<Map<String, dynamic>>.from(analytics['quizPerformance'] ?? []).map((q) => [
                    q['name'], '${q['pass']}%', '${q['fail']}%'
                  ]),
                ],
              ),

              pw.Header(level: 1, child: pw.Text('Top Learners')),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['Rank', 'Username', 'Village', 'XP'],
                  ...topLearners.asMap().entries.map((e) => [
                    e.key + 1, e.value['username'], e.value['indigenousGroup'] ?? 'Unknown', e.value['xp']
                  ]),
                ],
              ),
            ],
          ),
        );

        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$filename.pdf');
        await file.writeAsBytes(await pdf.save());

        await Share.shareXFiles([XFile(file.path)], text: 'Educator Analytics Report (PDF)');
      }
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e'), backgroundColor: AppColors.semanticRed),
        );
      }
    }
  }

  Widget _buildFeedbackBell() {
    final unreadCountAsync = ref.watch(unreadFeedbackCountProvider);
    final count = unreadCountAsync.value ?? 0;

    return GestureDetector(
      onTap: () => context.push('/educator/feedback'),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.forestDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.creamBorder,
              ),
            ),
            child: const Icon(
              Icons.mark_email_unread_rounded,
              color: AppColors.gold500,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.semanticRed,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().scale().shake(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      children: ['Weekly', 'Monthly'].map((range) {
        final isSelected = _timeRange == range;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() {
              _timeRange = range;
              _tappedBarIndex = null;
            }),
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
                range.toUpperCase(),
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

  Widget _buildQuizItem(Map<String, dynamic> quiz) {
    final pass = quiz['pass'] as int;
    final fail = quiz['fail'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : AppColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz['name'] as String,
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white : AppColors.creamText,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: pass,
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
                '$pass% passed',
                style: AppTypography.label.copyWith(
                  color: AppColors.semanticGreen,
                  fontSize: 10,
                ),
              ),
              Text(
                '$fail% failed',
                style: AppTypography.label.copyWith(
                  color: AppColors.semanticRed,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHurdleItem(String topic, String stat, String lessonName) {
    return Container(
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
                    color: isDark ? Colors.white : AppColors.creamText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stat,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white24 : AppColors.creamText3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'FIX',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String data, IconData icon) {
    return BrandCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.gold500, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.creamText,
                    fontSize: 16,
                  ),
                ),
                Text(
                  data,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white24 : AppColors.creamText3,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    String village,
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
              : AppColors.creamBorder,
        ),
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
                    color: isDark ? Colors.white : AppColors.creamText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  village,
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white38 : AppColors.creamText3,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$score XP',
            style: AppTypography.mono.copyWith(
              color: AppColors.gold500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthPainter extends CustomPainter {
  final List<double> points;
  _GrowthPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    
    final paint = Paint()
      ..color = AppColors.semanticGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.semanticGreen.withValues(alpha: 0.3),
          AppColors.semanticGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length == 1 ? 1 : points.length - 1)) * size.width;
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GrowthPainter oldDelegate) => 
      oldDelegate.points != points;
}



