import 'package:flutter/material.dart';
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

class LearningPathScreen extends ConsumerStatefulWidget {
  const LearningPathScreen({super.key});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen>
    with TickerProviderStateMixin {
  bool _isClassic = true;
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  double _scrollOffset = 0.0;
  bool _hasScrolledToActive = false;
  final GlobalKey _activeNodeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });

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
    _hasScrolledToActive = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _activeNodeKey.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.4,
        );
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
              final match = allLessons
                  .where((l) => l.id == lessonId)
                  .firstOrNull;
              if (match != null) return match.language;
            }
            return allLessons.first.language;
          },
        ) ??
        'Language';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Parallax Topo Background for Mountain mode
          if (!_isClassic)
            Positioned(
              top: -(_scrollOffset * 0.4),
              left: -(_scrollOffset * 0.1),
              right: 0,
              bottom: -(_scrollOffset * 0.4),
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/topo_map.png',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(context, resolvedLanguage),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  _buildToggle(),
                  const SizedBox(height: 48),
                  _buildPathContent(context),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final studentState = ref.watch(studentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statItem('â¤ï¸', '${studentState.hearts}', AppColors.semanticRed),
          const SizedBox(width: 24),
          _statItem('✨', '${studentState.mistCrystals}', AppColors.gold500),
          const SizedBox(width: 24),
          _statItem('🔥', '${studentState.xp}', AppColors.terracotta),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppTypography.label.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String language) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white70 : AppColors.forest700,
            size: 20,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 4,
          child: Text(
            '$language\nLearning Path',
            textAlign: TextAlign.center,
            style: AppTypography.h1ExtraBold.copyWith(
              color: AppColors.gold500,
              fontSize: 28,
              height: 1.1,
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF14241A)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
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
      onTap: () => setState(() => _isClassic = label == 'CLASSIC'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.gold500 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: active
                ? Colors.black
                : (isDark ? Colors.white24 : Colors.black26),
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildPathContent(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsStreamProvider);
    final studentState = ref.watch(studentProvider);

    // Get lessonId from URL
    final uri = GoRouterState.of(context).uri;
    final lessonId = uri.queryParameters['lessonId'];

    return lessonsAsync.when(
      data: (allLessons) {
        if (allLessons.isEmpty) {
          return const Center(child: Text('No lessons found.'));
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

        // Trigger auto-scroll after the first build
        _scrollToActiveLesson();

        return _isClassic
            ? _buildClassicPath(context, grouped, studentState)
            : _buildMountainPath(context, grouped, studentState);
      },
      loading: () => _buildPathSkeleton(),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildPathSkeleton() {
    return Column(
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
    );
  }

  Widget _buildClassicPath(
    BuildContext context,
    Map<int, List<Lesson>> grouped,
    StudentState studentState,
  ) {
    final List<Widget> children = [];
    final sortedUnits = grouped.keys.toList()..sort();

    for (var unitNum in sortedUnits) {
      final unitLessons = grouped[unitNum]!;
      final completedCount = unitLessons
          .where((l) => studentState.lessonProgress[l.id]?['completed'] == true)
          .length;
      final isUnitCompleted = completedCount == unitLessons.length;
      final totalStars = unitLessons.fold<int>(
        0,
        (sum, l) =>
            sum + (studentState.lessonProgress[l.id]?['stars'] as int? ?? 0),
      );

      children.add(
        UnitHeaderCard(
          unitNumber: 'Unit $unitNum',
          title: unitLessons.first.category,
          isCompleted: isUnitCompleted,
          completedCount: completedCount,
          totalCount: unitLessons.length,
          icon: IconUtils.getIconData(unitLessons.first.icon),
          stars: totalStars,
        ),
      );
      children.add(const SizedBox(height: 40));

      for (var lesson in unitLessons) {
        final progressData = studentState.lessonProgress[lesson.id];
        final isCompleted = progressData?['completed'] == true;
        final stars = (progressData?['stars'] as num? ?? 0).toInt();
        final bestScore = (progressData?['bestScore'] as num?)?.toInt();

        LessonStepStatus status = LessonStepStatus.locked;
        bool isLocked = false;
        if (lesson.prerequisiteId != null &&
            lesson.prerequisiteId!.isNotEmpty) {
          isLocked =
              studentState.lessonProgress[lesson
                  .prerequisiteId]?['completed'] !=
              true;
        }

        if (isCompleted) {
          status = LessonStepStatus.completed;
        } else if (!isLocked) {
          status = LessonStepStatus.active;
        }

        // Estimate time from task count (approx 2 min per task)
        final estimatedMin = (lesson.tasks.length * 2).clamp(2, 60);

        final isFirstActive = status == LessonStepStatus.active;

        children.add(
          GestureDetector(
            key: isFirstActive && _activeNodeKey.currentContext == null
                ? _activeNodeKey
                : null,
            onTap: isLocked
                ? null
                : () => context.push('/lesson_session?lessonId=${lesson.id}'),
            child: Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: LessonStepCard(
                title: lesson.title,
                type: lesson.category.toUpperCase(),
                time: '$estimatedMin min',
                status: status,
                stars: stars,
                icon: isLocked ? Icons.lock : IconUtils.getIconData(lesson.icon),
                bestScore: bestScore,
                lessonId: lesson.id,
              ),
            ),
          ),
        );
        children.add(const SizedBox(height: 40));
      }
      children.add(const SizedBox(height: 20));
    }

    return Stack(
      children: [
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: AppColors.gold500.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Column(children: children),
      ],
    );
  }

  Widget _buildMountainPath(
    BuildContext context,
    Map<int, List<Lesson>> grouped,
    StudentState studentState,
  ) {
    final List<Widget> children = [];
    final sortedUnits = grouped.keys.toList()..sort();

    for (var unitNum in sortedUnits) {
      final unitLessons = grouped[unitNum]!;

      for (var i = 0; i < unitLessons.length; i++) {
        final lesson = unitLessons[i];
        final progressData = studentState.lessonProgress[lesson.id];
        final isCompleted = progressData?['completed'] == true;
        bool isLocked = false;
        if (lesson.prerequisiteId != null &&
            lesson.prerequisiteId!.isNotEmpty) {
          isLocked =
              studentState.lessonProgress[lesson
                  .prerequisiteId]?['completed'] !=
              true;
        }
        final isActive = !isCompleted && !isLocked;

        children.add(
          _buildMountainNode(
            context,
            icon: isLocked
                ? Icons.lock
                : (isCompleted ? Icons.check_rounded : IconUtils.getIconData(lesson.icon)),
            isCompleted: isCompleted,
            isActive: isActive,
            label: lesson.title,
            onTap: isLocked
                ? null
                : () => context.push('/lesson_session?lessonId=${lesson.id}'),
          ),
        );

        if (i < unitLessons.length - 1) {
          children.add(
            _buildMountainLine(
              context,
              isCompleted: isCompleted,
              isTransition: isCompleted && !isActive,
            ),
          );
        }
      }

      // Add a transition line between units
      if (unitNum != sortedUnits.last) {
        children.add(
          _buildMountainLine(context, isCompleted: false, isTransition: true),
        );
      }
    }

    return Column(children: children).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMountainNode(
    BuildContext context, {
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
    bool isExam = false,
    String? label,
    String? subLabel,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isExam ? AppColors.semanticRed : AppColors.gold500;

    return GestureDetector(
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
                      width: 120 + (10 * _pulseController.value),
                      height: 120 + (10 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1 + (0.3 * (1 - _pulseController.value)),
                            ),
                            blurRadius: 40 + (20 * _pulseController.value),
                            spreadRadius: 5 + (15 * _pulseController.value),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              Container(
                width: isActive ? 90 : (isExam ? 80 : 70),
                height: isActive ? 90 : (isExam ? 80 : 70),
                decoration: BoxDecoration(
                  color: isCompleted || isActive || isExam
                      ? primaryColor
                      : (isDark
                            ? const Color(0xFF1B1B1B)
                            : Colors.black.withOpacity(0.05)),
                  shape: isExam ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isExam ? BorderRadius.circular(20) : null,
                  border: Border.all(
                    color: isActive || isExam
                        ? Colors.white.withOpacity(0.3)
                        : Colors.transparent,
                    width: 4,
                  ),
                  boxShadow: isActive || isExam
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isCompleted || isActive || isExam
                      ? Colors.black
                      : (isDark ? Colors.white24 : Colors.black26),
                  size: isActive || isExam ? 36 : 28,
                ),
              ),
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          if (subLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              subLabel,
              style: AppTypography.label.copyWith(
                color: isExam
                    ? AppColors.semanticRed
                    : (isDark ? Colors.white24 : Colors.black38),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMountainLine(
    BuildContext context, {
    required bool isCompleted,
    bool isTransition = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 4,
      height: 60,
      decoration: BoxDecoration(
        gradient: isTransition
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gold500,
                  isDark ? Colors.white10 : Colors.black12,
                ],
              )
            : null,
        color: isTransition
            ? null
            : (isCompleted
                  ? AppColors.gold500
                  : (isDark ? Colors.white10 : Colors.black12)),
      ),
    );
  }
}


