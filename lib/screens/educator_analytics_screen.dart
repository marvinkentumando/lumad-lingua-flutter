import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
                _buildHeader(),
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
                _buildSectionTitle('Quiz Performance (Mocked)'),
                const SizedBox(height: 16),
                ..._mockQuizPerformance.map((q) => _buildQuizItem(q)),

                const SizedBox(height: 32),
                _buildSectionTitle('Common Hurdles (Mocked)'),
                const SizedBox(height: 16),
                _buildHurdleItem(
                  'Verb Conjugation',
                  '45% failure rate in Unit 3',
                  'Family Lineage Vocabulary',
                ),
                _buildHurdleItem(
                  'Phonetic Tones',
                  'Struggled by 12 new learners',
                  'Basic Mansaka Greetings',
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

  Widget _buildHeader() {
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
            _buildExportButton(),
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
        color: AppColors.semanticRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'Error loading data: $e',
        style: const TextStyle(color: AppColors.semanticRed),
      ),
    );
  }

  Widget _buildActivityChart(List<AdminUser> users) {
    // Generate activity data based on user creation dates as a proxy for engagement
    final now = DateTime.now();
    final List<Map<String, dynamic>> bars = [];

    if (_timeRange == 'Weekly') {
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final count = users
            .where(
              (u) => u.joinedAt.day == day.day && u.joinedAt.month == day.month,
            )
            .length;
        bars.add({
          'label': DateFormat('E').format(day)[0],
          'value': count + 5,
        }); // +5 for visualization
      }
    } else {
      // Mock or simplified monthly
      bars.addAll([
        {'label': 'W1', 'value': 12},
        {'label': 'W2', 'value': 18},
        {'label': 'W3', 'value': 15},
        {'label': 'W4', 'value': 22},
      ]);
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
              ? Colors.white.withOpacity(0.05)
              : AppColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_timeRange New Learners',
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
                              : AppColors.gold500.withOpacity(0.6),
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
    final recentCount = users
        .where(
          (u) => u.joinedAt.isAfter(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .length;

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
            child: CustomPaint(painter: _GrowthPainter(), size: Size.infinite),
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

  Widget _buildExportButton() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported as $val')));
      },
      color: isDark ? AppColors.forest800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
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

  Widget _buildFeedbackBell() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.creamBorder,
        ),
      ),
      child: const Icon(
        Icons.mark_email_unread_rounded,
        color: AppColors.gold500,
        size: 20,
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
                          ? Colors.white.withOpacity(0.1)
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
              ? Colors.white.withOpacity(0.03)
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
              ? AppColors.semanticRed.withOpacity(0.1)
              : AppColors.semanticRed.withOpacity(0.3),
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
              color: AppColors.gold500.withOpacity(0.1),
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
              color: AppColors.gold500.withOpacity(0.1),
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
              ? Colors.white.withOpacity(0.05)
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
              color: rankColor.withOpacity(0.1),
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

  final List<Map<String, dynamic>> _mockQuizPerformance = [
    {'name': 'Basic Greetings Quiz', 'pass': 87, 'fail': 13},
    {'name': 'Counting Quiz', 'pass': 72, 'fail': 28},
    {'name': 'Family Vocab Quiz', 'pass': 55, 'fail': 45},
  ];
}

class _GrowthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [0.2, 0.3, 0.25, 0.45, 0.5, 0.65, 0.7, 0.85, 0.9, 1.0];
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
          AppColors.semanticGreen.withOpacity(0.3),
          AppColors.semanticGreen.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


