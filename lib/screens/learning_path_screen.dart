import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/lesson.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/unit_header_card.dart';
import '../widgets/lesson_step_card.dart';
import '../widgets/branded_empty_state.dart';
import '../widgets/wisdom_portal.dart';
import 'package:lumad_lingua/widgets/app_shimmer_skeleton.dart';
import '../utils/icon_utils.dart';
import '../providers/student_provider.dart';
import '../providers/learning_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/brand_background.dart';
import '../widgets/assessment_overlay.dart';
import '../models/assessment.dart';
import '../services/auth_service.dart';
import '../services/certificate_service.dart';
import '../services/haptic_service.dart';

class LearningPathScreen extends ConsumerStatefulWidget {
  const LearningPathScreen({super.key});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  late ConfettiController _confettiController;
  bool _hasScrolledToActive = false;
  bool _showCelebration = false;
  bool _showPostTest = false;
  bool _isGeneratingCertificate = false;
  final GlobalKey _activeNodeKey = GlobalKey();

  void _triggerSummitCelebration() {
    HapticFeedback.heavyImpact();
    setState(() => _showCelebration = true);
    _confettiController.play();
  }

  Future<void> _handleClaimCertificate(String language) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _showPostTest = true);
  }

  Future<void> _generateAndShareCertificate(String language) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isGeneratingCertificate = true);

    try {
      final certificateService = CertificateService();
      final file = await certificateService.generateCertificate(
        userName: user.displayName ?? 'Lumad Learner',
        language: language,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'My Lumad Lingua Certificate - $language',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate certificate: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingCertificate = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _scrollToActiveLesson() {
    if (_hasScrolledToActive) return;
    _hasScrolledToActive = true; // Guard immediately to prevent duplicate calls

    // Use post-frame callback to ensure the widget tree is fully laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptScrollToActive(retries: 5);
    });
  }

  void _attemptScrollToActive({required int retries}) {
    if (!mounted || retries <= 0) return;

    final keyContext = _activeNodeKey.currentContext;
    if (keyContext != null && keyContext.mounted) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutQuart,
        alignment: 0.4, // Position slightly above center for better visibility
      );
    } else {
      // Widget tree may still be settling — retry after a short delay
      Future.delayed(const Duration(milliseconds: 200), () {
        _attemptScrollToActive(retries: retries - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsStreamProvider);
    final uri = GoRouterState.of(context).uri;
    final lessonId = uri.queryParameters['lessonId'];
    final prefs = ref.watch(userPreferencesProvider);
    final isClassic = prefs.learningPathView == 'CLASSIC';

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
      body: BrandBackground(
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
                  child: Center(child: _buildToggle(isClassic)),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 48)),

                _buildSliverPathContent(context, isClassic),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // Glassmorphic Header
            _buildGlassHeader(context, resolvedLanguage),

            if (_showCelebration) _buildCelebrationOverlay(resolvedLanguage),

            if (_showPostTest)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.center,
                  child: AssessmentOverlay(
                    type: AssessmentType.postTest,
                    questions: [
                      AssessmentQuestion(
                        id: 'peak_mastery',
                        text: 'How would you rate your overall mastery of $resolvedLanguage after completing this path?',
                        options: ['Mastered', 'Proficient', 'Developing', 'Beginner'],
                      ),
                      AssessmentQuestion(
                        id: 'cultural_connection',
                        text: 'Do you feel more connected to the Lumad culture after these lessons?',
                        options: ['Strongly Connected', 'Somewhat Connected', 'A little', 'Not at all'],
                      ),
                      AssessmentQuestion(
                        id: 'app_satisfaction',
                        text: 'How helpful was Lumad Lingua in your learning journey?',
                        options: ['Extremely Helpful', 'Helpful', 'Neutral', 'Unhelpful'],
                      ),
                    ],
                    onComplete: (answers) async {
                      final user = ref.read(authServiceProvider).currentUser;
                      if (user != null) {
                        final result = AssessmentResult(
                          userId: user.uid,
                          type: AssessmentType.postTest,
                          answers: answers,
                          timestamp: DateTime.now(),
                          lessonId: 'summit_$resolvedLanguage',
                        );
                        await ref.read(firebaseServiceProvider).saveAssessmentResult(result);
                      }
                      setState(() {
                        _showPostTest = false;
                      });
                      await _generateAndShareCertificate(resolvedLanguage);
                    },
                  ),
                ).animate().fadeIn(),
              ),

            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.gold500,
                  AppColors.terracotta,
                  AppColors.forest500,
                  Colors.white,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationOverlay(String language) {
    return GestureDetector(
      onTap: () => setState(() => _showCelebration = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        width: double.infinity,
        height: double.infinity,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.gold500,
                size: 120,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).shimmer(delay: 600.ms),
              const SizedBox(height: 24),
              Text(
                'SUMMIT REACHED!',
                style: AppTypography.displayBold.copyWith(
                  color: AppColors.gold500,
                  fontSize: 32,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'You have reached the Peak of Wisdom. Your journey through this ancestral language is complete!',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () => _handleClaimCertificate(language),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.gold500, AppColors.terracotta]),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: _isGeneratingCertificate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.gold500,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'CLAIM CERTIFICATE',
                            style: AppTypography.label.copyWith(
                              color: AppColors.gold500,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ).animate().scale(delay: 800.ms, curve: Curves.easeOutBack).shimmer(delay: 2.seconds),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showCelebration = false),
                child: Text(
                  'RETURN TO PATH',
                  style: AppTypography.label.copyWith(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassHeader(BuildContext context, String language) {
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
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.onSurface,
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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

  Widget _buildToggle(bool isClassic) {
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
          _toggleBtn('CLASSIC', isClassic),
          _toggleBtn('MOUNTAIN', !isClassic),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(userPreferencesProvider.notifier).setLearningPathView(label);
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
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverPathContent(BuildContext context, bool isClassic) {
    final lessonsAsync = ref.watch(lessonsStreamProvider);
    final studentState = ref.watch(studentProvider);
    final cachedLessonIds = ref.watch(cachedLessonIdsProvider).value ?? {};

    // Get lessonId from URL
    final uri = GoRouterState.of(context).uri;
    final lessonId = uri.queryParameters['lessonId'];

    return lessonsAsync.when(
      data: (allLessons) {
        if (allLessons.isEmpty) {
          return const SliverFillRemaining(
            child: BrandedEmptyState(
              title: 'Trail Unmarked',
              message: 'No lessons found for this language yet.',
              icon: Icons.map_outlined,
            ),
          );
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

        final isSummitUnlocked = lessons.isNotEmpty &&
            lessons.every((l) => studentState.lessonProgress[l.id]?['completed'] == true);

        // Trigger auto-scroll
        _scrollToActiveLesson();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: isClassic
              ? _buildSliverClassicPath(context, grouped, studentState, cachedLessonIds, isSummitUnlocked)
              : _buildSliverMountainPath(context, grouped, studentState, cachedLessonIds, isSummitUnlocked),
        );
      },
      loading: () => SliverToBoxAdapter(child: _buildPathAppShimmerSkeleton()),
      error: (err, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildPathAppShimmerSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (i) => Column(
          children: [
            const AppShimmerSkeleton(height: 100, borderRadius: 24),
            const SizedBox(height: 40),
            ...List.generate(2, (j) => const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: AppShimmerSkeleton(height: 120, borderRadius: 32),
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
    Set<String> cachedLessonIds,
    bool isSummitUnlocked,
  ) {
    final List<Widget> children = [];
    final sortedUnits = grouped.keys.toList()..sort(); // Unit 1, 2, 3...
    bool activeNodeKeyAssigned = false;

    for (var unitNum in sortedUnits) {
      final unitLessons = grouped[unitNum]!;
      final lessons = unitLessons; // Lesson 1, 2, 3...

      final completedCount = unitLessons
          .where((l) => studentState.lessonProgress[l.id]?['completed'] == true)
          .length;
      final isUnitCompleted = completedCount == unitLessons.length;
      final totalStars = unitLessons.fold<int>(
        0,
        (sum, l) => sum + (studentState.lessonProgress[l.id]?['stars'] as int? ?? 0),
      );

      final List<Widget> lessonWidgets = [];

      for (var i = 0; i < lessons.length; i++) {
        final lesson = lessons[i];
        final progressData = studentState.lessonProgress[lesson.id];
        final isCompleted = progressData?['completed'] == true;
        final bestScore = (progressData?['bestScore'] as num?)?.toInt();
        final isCached = cachedLessonIds.contains(lesson.id);

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

        final isLast = i == lessons.length - 1;

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
                isCached: isCached,
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

    // Add Summit at the bottom for top-to-bottom classic path
    children.add(const SizedBox(height: 20));
    children.add(_buildSummitVisual(isSummitUnlocked));

    return SliverList(delegate: SliverChildListDelegate(children));
  }

  Widget _buildSummitVisual(bool isUnlocked) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        // Calculate parallax offset
        double scrollOffset = 0.0;
        if (_scrollController.hasClients) {
          scrollOffset = _scrollController.offset;
        }

        // Only start parallaxing when we're near the summit (usually top of list)
        // Adjust the multiplier to control "depth"
        final parallaxY = scrollOffset * 0.15;

        return Transform.translate(
          offset: Offset(0, parallaxY),
          child: GestureDetector(
            onTap: isUnlocked ? _triggerSummitCelebration : null,
            child: Column(
              children: [
                WisdomPortal(isUnlocked: isUnlocked, size: 200),
                const SizedBox(height: 24),
                Text(
                  'THE PEAK OF WISDOM',
                  style: AppTypography.label.copyWith(
                    color: isUnlocked ? AppColors.gold500 : Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ).animate(onPlay: (c) => isUnlocked ? c.repeat() : null).shimmer(duration: 3.seconds),
                Text(
                  isUnlocked ? 'Tap to enter the Peak' : 'Complete all lessons to reach the summit',
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverMountainPath(
    BuildContext context,
    Map<int, List<Lesson>> grouped,
    StudentState studentState,
    Set<String> cachedLessonIds,
    bool isSummitUnlocked,
  ) {
    final List<Widget> children = [];
    final sortedUnits = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    bool activeNodeKeyAssigned = false;

    // Add Summit to the Mountain Path
    children.add(_buildSummitVisual(isSummitUnlocked));
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
        final isCached = cachedLessonIds.contains(lesson.id);
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
              isCached: isCached,
              label: lesson.title,
              onTap: isLocked
                  ? null
                  : () {
                      HapticService.light();
                      context.push('/lesson_session?lessonId=${lesson.id}');
                    },
              index: totalLessons - globalIndex,
            ),
          ),
        );

        // Add line leading TO this node from the PREVIOUS one (which is lower in the list, so globalIndex + 1)
        if (globalIndex < (totalLessons - 1)) {
          double nextShift = 0;
          int nextIdx = globalIndex + 1;
          if (nextIdx % 4 == 1) nextShift = -60;
          if (nextIdx % 4 == 3) nextShift = 60;

          children.add(
            _buildMountainLine(
              context,
              isCompleted: isCompleted,
              isActive: isActive,
              startShift: horizontalShift,
              endShift: nextShift,
              index: totalLessons - globalIndex - 1,
            ),
          );
        } else {
          // This is the very first lesson (bottom of the mountain)
          // Add a starting line coming from below
          children.add(
            _buildMountainLine(
              context,
              isCompleted: isCompleted,
              isActive: isActive,
              startShift: horizontalShift,
              endShift: horizontalShift, // Vertical line
              index: totalLessons - globalIndex - 1,
            ),
          );
        }

        // Special case: If this is the highest lesson (globalIndex == 0), 
        // add a line connecting it TO the Summit above it.
        if (globalIndex == 0) {
          children.insert(
            2, // After Summit visual and its spacing
            _buildMountainLine(
              context,
              isCompleted: isSummitUnlocked,
              isActive: !isSummitUnlocked && isCompleted,
              startShift: 0, // Summit is centered
              endShift: horizontalShift,
              index: totalLessons,
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
    bool isCached = false,
    String? label,
    VoidCallback? onTap,
    int index = 0,
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
              clipBehavior: Clip.none,
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
                Animate(
                  delay: (index * 200 + 500).ms,
                ).fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ).custom(
                  builder: (context, value, child) => Container(
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
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: isActive ? 34 : 28,
                  ),
                )),
                if (isCached)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.semanticGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.offline_pin_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ).animate(delay: (index * 200 + 1000).ms).scale(duration: 400.ms, curve: Curves.elasticOut),
                  ),
              ],
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              Animate(
                delay: (index * 200 + 800).ms,
              ).fadeIn(duration: 400.ms).slideY(begin: 0.2),
              Container(
                constraints: const BoxConstraints(maxWidth: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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
    bool isActive = false,
    double startShift = 0,
    double endShift = 0,
    int index = 0,
  }) {
    return Animate().custom(
      duration: 1000.ms,
      delay: (index * 200).ms,
      builder: (context, value, child) => Center(
        child: CustomPaint(
          size: const Size(double.infinity, 80),
          painter: PathLinePainter(
            startShift: startShift,
            endShift: endShift,
            color: isCompleted 
                ? AppColors.gold500 
                : (isActive 
                    ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            isDashed: !isCompleted && !isActive,
            isCompleted: isCompleted,
            growth: value,
            isActive: isActive,
          ),
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
  final bool isCompleted;
  final double growth; // 0.0 to 1.0
  final bool isActive;

  PathLinePainter({
    required this.startShift,
    required this.endShift,
    required this.color,
    this.isDashed = false,
    this.isCompleted = false,
    this.growth = 1.0,
    this.isActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isDashed ? 0.3 : 1.0)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startX = size.width / 2 + startShift;
    final endX = size.width / 2 + endShift;

    // Use Quadratic Bezier for a winding feel
    final path = Path();
    path.moveTo(startX, 0);
    
    // Calculate an organic control point for the curve
    // The "wiggle" factor is based on the shift difference to keep curves consistent
    final wiggle = (startX - endX).abs() > 10 ? (startX - endX) * 0.3 : 30.0;
    final controlPoint = Offset((startX + endX) / 2 + wiggle, size.height * 0.5);
    final endPoint = Offset(endX, size.height);

    path.quadraticBezierTo(
      controlPoint.dx, controlPoint.dy,
      endPoint.dx, endPoint.dy,
    );

    // Extract and draw growth path
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0, metric.length * growth);
      
      if (isDashed) {
        _drawDashedWovenPath(canvas, metric, paint, growth);
      } else {
        // Main Vine Body
        canvas.drawPath(extractPath, paint);
        
        // Texture Layer: "Woven Vine" Detail
        if (growth > 0) {
          _drawWovenTexture(canvas, extractPath, color);
        }
      }

      // Procedural Leaves
      if (growth > 0.1 && !isDashed) {
        _drawProceduralLeaves(canvas, metric, growth);
      }
    }

    if (isCompleted && growth >= 1.0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, glowPaint);
    }
  }

  void _drawWovenTexture(Canvas canvas, Path path, Color baseColor) {
    // Secondary "fiber" lines to give a woven feel
    final texturePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      const dashWidth = 10.0;
      const dashSpace = 15.0;
      double distance = 5.0; // Offset from start

      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + dashWidth, metric.length)),
          texturePaint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawDashedWovenPath(Canvas canvas, PathMetric metric, Paint paint, double g) {
    const dashWidth = 8.0;
    const dashSpace = 8.0;
    double distance = 0.0;
    while (distance < metric.length * g) {
      canvas.drawPath(
        metric.extractPath(distance, math.min(distance + dashWidth, metric.length * g)),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  void _drawProceduralLeaves(Canvas canvas, PathMetric metric, double g) {
    final rand = math.Random(startShift.hashCode + endShift.hashCode);
    const int leafCount = 3;
    final leafPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < leafCount; i++) {
      final double t = (i + 1) / (leafCount + 1);
      if (t > g) continue;

      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent != null) {
        final pos = tangent.position;
        final angle = tangent.vector.direction;

        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(angle + (i % 2 == 0 ? 1.0 : -1.0));
        
        final leafScale = math.min(1.0, (g - t) / 0.1) * (0.7 + rand.nextDouble() * 0.5);
        canvas.scale(leafScale);

        final leafPath = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(6, -10, 14, 0)
          ..quadraticBezierTo(6, 10, 0, 0)
          ..close();
        
        canvas.drawPath(leafPath, leafPaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant PathLinePainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.isDashed != isDashed || 
           oldDelegate.isCompleted != isCompleted ||
           oldDelegate.startShift != startShift ||
           oldDelegate.endShift != endShift ||
           oldDelegate.growth != growth;
  }
}
