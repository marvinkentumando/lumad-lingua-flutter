import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/lesson.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/unit_header_card.dart';
import '../widgets/lesson_step_card.dart';
import '../widgets/skeleton.dart';
import '../utils/icon_utils.dart';
import '../providers/student_provider.dart';
import '../widgets/ambient_topo_background.dart';

class LearningPathScreen extends ConsumerStatefulWidget {
  const LearningPathScreen({super.key});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen>
    with TickerProviderStateMixin {
  bool _isClassic = false; // Default to Mountain for the "path" experience
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  bool _hasScrolledToActive = false;
  final GlobalKey _activeNodeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToActiveLesson() {
    if (_hasScrolledToActive) return;

    // Add a slight delay to ensure rendering is complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final keyContext = _activeNodeKey.currentContext;
      if (keyContext != null && keyContext.mounted) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
          alignment: 0.5,
        );
        _hasScrolledToActive = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsStreamProvider);
    final uri = GoRouterState.of(context).uri;
    final lessonId = uri.queryParameters['lessonId'];

    // Resolve language name from data for the header
    final resolvedLanguage =
        lessonsAsync.whenOrNull(
          data: (allLessons) {
            if (allLessons.isEmpty) return null;
            if (lessonId != null) {
              final match = allLessons.where((l) => l.id == lessonId).firstOrNull;
              if (match != null) return match.language;
            }
            return allLessons.first.language;
          },
        ) ??
        'Language';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientTopoBackground(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Padding for the sticky header
                const SliverToBoxAdapter(child: SizedBox(height: 140)),

                _buildStatsSliver(),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                SliverToBoxAdapter(
                  child: Center(child: _buildToggle()),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 48)),

                _buildSliverPathContent(context),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // Glassmorphic Header
            _buildGlassHeader(context, resolvedLanguage),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassHeader(BuildContext context, String language) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.only(top: topPadding + 10, bottom: 20),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF0F1711) : Colors.white)
                  .withValues(alpha: 0.7),
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.pop();
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white70 : AppColors.forest700,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        language.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'Learning Path',
                        style: AppTypography.h2.copyWith(
                          color: isDark ? Colors.white : AppColors.forest700,
                          fontSize: 22,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Balance for back button
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildStatsSliver() {
    final studentState = ref.watch(studentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statItem('❤️', '${studentState.hearts}', AppColors.semanticRed),
              const SizedBox(width: 32),
              _statItem('✨', '${studentState.mistCrystals}', AppColors.gold500),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/streak');
                },
                child: _statItem('🔥', '${studentState.displayedStreak}', AppColors.terracotta),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _statItem(String emoji, String value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.label.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF14241A)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('CLASSIC', _isClassic),
          _toggleBtn('MOUNTAIN', !_isClassic),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isClassic = label == 'CLASSIC');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.gold500 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active
            ? [BoxShadow(color: AppColors.gold500.withValues(alpha: 0.2), blurRadius: 10)]
            : null,
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: active
                ? Colors.black
                : (isDark ? Colors.white24 : Colors.black26),
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverPathContent(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsStreamProvider);
    final studentState = ref.watch(studentProvider);

    // Get lessonId from URL
    final uri = GoRouterState.of(context).uri;
    final lessonId = uri.queryParameters['lessonId'];

    return lessonsAsync.when(
      data: (allLessons) {
        if (allLessons.isEmpty) {
          return const SliverFillRemaining(child: Center(child: Text('No lessons found.')));
        }

        // Find the language for the selected lessonId, or default to first
        String? targetLanguage;
        if (lessonId != null) {
          targetLanguage = allLessons
              .where((l) => l.id == lessonId)
              .firstOrNull
              ?.language;
        }
        targetLanguage ??= allLessons.first.language;

        final lessons = allLessons
            .where((l) => l.language == targetLanguage)
            .toList();
        lessons.sort((a, b) => a.unitNumber.compareTo(b.unitNumber));

        // Group by unit
        final grouped = <int, List<Lesson>>{};
        for (var l in lessons) {
          grouped.putIfAbsent(l.unitNumber, () => []).add(l);
        }

        // Trigger auto-scroll
        _scrollToActiveLesson();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: _isClassic
              ? _buildSliverClassicPath(context, grouped, studentState)
              : _buildSliverMountainPath(context, grouped, studentState),
        );
      },
      loading: () => SliverToBoxAdapter(child: _buildPathSkeleton()),
      error: (err, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildPathSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (i) => Column(
          children: [
            const Skeleton(height: 100, borderRadius: 24),
            const SizedBox(height: 40),
            ...List.generate(2, (j) => const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Skeleton(height: 120, borderRadius: 32),
            )),
          ],
        )),
      ),
    );
  }

  Widget _buildSliverClassicPath(
    BuildContext context,
    Map<int, List<Lesson>> grouped,
    StudentState studentState,
  ) {
    final List<Widget> children = [];
    final sortedUnits = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    bool activeNodeKeyAssigned = false;

    // We add the Summit at the very top
    children.add(_buildSummitVisual());
    children.add(const SizedBox(height: 60));

    for (var unitNum in sortedUnits) {
      final unitLessons = grouped[unitNum]!;
      final reversedLessons = unitLessons.reversed.toList();

      final completedCount = unitLessons
          .where((l) => studentState.lessonProgress[l.id]?['completed'] == true)
          .length;
      final isUnitCompleted = completedCount == unitLessons.length;
      final totalStars = unitLessons.fold<int>(
        0,
        (sum, l) => sum + (studentState.lessonProgress[l.id]?['stars'] as int? ?? 0),
      );

      final List<Widget> lessonWidgets = [];

      for (var i = 0; i < reversedLessons.length; i++) {
        final lesson = reversedLessons[i];
        final progressData = studentState.lessonProgress[lesson.id];
        final isCompleted = progressData?['completed'] == true;
        final bestScore = (progressData?['bestScore'] as num?)?.toInt();

        LessonStepStatus status = LessonStepStatus.locked;
        bool isLocked = false;
        if (lesson.prerequisiteId != null && lesson.prerequisiteId!.isNotEmpty) {
          isLocked = studentState.lessonProgress[lesson.prerequisiteId]?['completed'] != true;
        }

        if (isCompleted) {
          status = LessonStepStatus.completed;
        } else if (!isLocked) {
          status = LessonStepStatus.active;
        }

        final estimatedMin = (lesson.tasks.length * 2).clamp(2, 60);

        final isFirstActive = status == LessonStepStatus.active;
        bool assignKey = false;
        if (isFirstActive && !activeNodeKeyAssigned) {
          assignKey = true;
          activeNodeKeyAssigned = true;
        }

        final isLast = i == reversedLessons.length - 1;

        lessonWidgets.add(
          GestureDetector(
            key: assignKey ? _activeNodeKey : null,
            onTap: isLocked
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    context.push('/lesson_session?lessonId=${lesson.id}');
                  },
            child: Opacity(
              opacity: isLocked ? 0.4 : 1.0,
              child: LessonStepCard(
                title: lesson.title,
                time: '$estimatedMin min',
                status: status,
                bestScore: bestScore,
                lessonId: lesson.id,
                isLast: isLast,
              ),
            ),
          ),
        );
      }

      final showChildren = !(isUnitCompleted && unitLessons.length == 1);

      children.add(
        UnitHeaderCard(
          unitNumber: 'Unit $unitNum',
          title: unitLessons.first.title,
          isCompleted: isUnitCompleted,
          completedCount: completedCount,
          totalCount: unitLessons.length,
          icon: IconUtils.getIconData(unitLessons.first.icon),
          stars: totalStars,
          onTap: !showChildren
              ? () => context.push('/lesson_session?lessonId=${unitLessons.first.id}')
              : null,
          children: showChildren ? lessonWidgets : const [],
        ),
      );
      children.add(const SizedBox(height: 40));
    }

    return SliverList(delegate: SliverChildListDelegate(children));
  }

  Widget _buildSummitVisual() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold500.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold500.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.wb_sunny_rounded, // Ancestral Sun
            color: AppColors.gold500,
            size: 64,
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 3.seconds, curve: Curves.easeInOut)
         .shimmer(delay: 2.seconds, duration: 2.seconds),
        const SizedBox(height: 16),
        Text(
          'THE PEAK OF WISDOM',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 4,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        Text(
          'Complete all lessons to reach the summit',
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white24 : Colors.black26,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSliverMountainPath(
    BuildContext context,
    Map<int, List<Lesson>> grouped,
    StudentState studentState,
  ) {
    final List<Widget> children = [];
    final sortedUnits = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    bool activeNodeKeyAssigned = false;

    // Add Summit to the Mountain Path
    children.add(_buildSummitVisual());
    children.add(const SizedBox(height: 80));

    int globalIndex = 0;
    int totalLessons = lessonsCount(grouped);

    for (var unitNum in sortedUnits) {
      final unitLessons = grouped[unitNum]!;
      final reversedLessons = unitLessons.reversed.toList();

      for (var i = 0; i < reversedLessons.length; i++) {
        final lesson = reversedLessons[i];
        final progressData = studentState.lessonProgress[lesson.id];
        final isCompleted = progressData?['completed'] == true;
        bool isLocked = false;
        if (lesson.prerequisiteId != null && lesson.prerequisiteId!.isNotEmpty) {
          isLocked = studentState.lessonProgress[lesson.prerequisiteId]?['completed'] != true;
        }
        final isActive = !isCompleted && !isLocked;

        bool assignKey = false;
        if (isActive && !activeNodeKeyAssigned) {
          assignKey = true;
          activeNodeKeyAssigned = true;
        }

        double horizontalShift = 0;
        if (globalIndex % 4 == 1) horizontalShift = -60;
        if (globalIndex % 4 == 3) horizontalShift = 60;

        children.add(
          Transform.translate(
            offset: Offset(horizontalShift, 0),
            child: _buildMountainNode(
              context,
              key: assignKey ? _activeNodeKey : null,
              icon: isLocked
                  ? Icons.lock
                  : (isCompleted ? Icons.check_rounded : IconUtils.getIconData(lesson.icon)),
              isCompleted: isCompleted,
              isActive: isActive,
              label: lesson.title,
              onTap: isLocked
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      context.push('/lesson_session?lessonId=${lesson.id}');
                    },
            ),
          ),
        );

        if (globalIndex < (totalLessons - 1)) {
          double nextShift = 0;
          int nextIdx = globalIndex + 1;
          if (nextIdx % 4 == 1) nextShift = -60;
          if (nextIdx % 4 == 3) nextShift = 60;

          children.add(
            _buildMountainLine(
              context,
              isCompleted: isCompleted,
              isTransition: isCompleted && !isActive,
              startShift: horizontalShift,
              endShift: nextShift,
            ),
          );
        }

        globalIndex++;
      }

      if (unitNum != sortedUnits.last) {
        children.add(const SizedBox(height: 40));
      }
    }

    return SliverList(
      delegate: SliverChildListDelegate(children),
    );
  }

  int lessonsCount(Map<int, List<Lesson>> grouped) {
    return grouped.values.fold(0, (sum, list) => sum + list.length);
  }

  Widget _buildMountainNode(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
    bool isExam = false,
    String? label,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isExam ? AppColors.semanticRed : AppColors.gold500;

    return Center(
      key: key,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 100 + (25 * _pulseController.value),
                        height: 100 + (25 * _pulseController.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15 + (0.2 * (1 - _pulseController.value))),
                              blurRadius: 30 + (30 * _pulseController.value),
                              spreadRadius: 2 + (15 * _pulseController.value),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                Container(
                  width: isActive ? 84 : 70,
                  height: isActive ? 84 : 70,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive || isExam
                        ? primaryColor
                        : (isDark
                              ? const Color(0xFF1B1B1B)
                              : Colors.black.withValues(alpha: 0.05)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.4)
                          : (isCompleted ? Colors.white.withValues(alpha: 0.2) : Colors.transparent),
                      width: isActive ? 5 : 2,
                    ),
                    boxShadow: [
                      if (isActive || isCompleted)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      if (isActive)
                         BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isCompleted || isActive || isExam
                        ? Colors.black
                        : (isDark ? Colors.white24 : Colors.black26),
                    size: isActive ? 34 : 28,
                  ),
                ),
              ],
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxWidth: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMountainLine(
    BuildContext context, {
    required bool isCompleted,
    bool isTransition = false,
    double startShift = 0,
    double endShift = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: CustomPaint(
        size: const Size(double.infinity, 70),
        painter: PathLinePainter(
          startShift: startShift,
          endShift: endShift,
          color: isCompleted ? AppColors.gold500 : (isDark ? Colors.white10 : Colors.black12),
          isDashed: !isCompleted,
        ),
      ),
    );
  }
}

class PathLinePainter extends CustomPainter {
  final double startShift;
  final double endShift;
  final Color color;
  final bool isDashed;

  PathLinePainter({
    required this.startShift,
    required this.endShift,
    required this.color,
    this.isDashed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startX = size.width / 2 + startShift;
    final endX = size.width / 2 + endShift;

    final path = Path();
    path.moveTo(startX, 5);
    path.lineTo(endX, size.height - 5);

    if (isDashed) {
      const dashWidth = 8.0;
      const dashSpace = 8.0;
      double distance = 0.0;
      for (final PathMetric measurePath in path.computeMetrics()) {
        while (distance < measurePath.length) {
          canvas.drawPath(
            measurePath.extractPath(distance, distance + dashWidth),
            paint,
          );
          distance += dashWidth + dashSpace;
        }
      }
    } else {
      canvas.drawPath(path, paint);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
