import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/lesson.dart';
import '../models/lesson_task.dart';
import '../widgets/activity_views/mcq_view.dart';
import '../widgets/activity_views/vocabulary_view.dart';
import '../widgets/activity_views/sentence_reordering_view.dart';
import '../widgets/activity_views/matching_view.dart';
import '../widgets/activity_views/pronunciation_view.dart';
import '../widgets/activity_views/scenario_view.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import '../widgets/activity_views/listening_view.dart';

class ValidatorLessonsScreen extends ConsumerStatefulWidget {
  const ValidatorLessonsScreen({super.key});

  @override
  ConsumerState<ValidatorLessonsScreen> createState() =>
      _ValidatorLessonsScreenState();
}

class _ValidatorLessonsScreenState
    extends ConsumerState<ValidatorLessonsScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  String _searchQuery = "";
  String _selectedDialect = "All";

  final List<String> _dialects = [
    "All",
    "Mansaka",
    "Tboli",
    "Hanunuo",
    "Mandaya",
  ];

  @override
  Widget build(BuildContext context) {
    final lessonsStream = ref.watch(pendingLessonsProvider);
    final userAsync = ref.watch(userProfileProvider);
    final userId =
        userAsync.value?['uid'] ??
        userAsync.value?['id'] ??
        'unknown_validator';
    final userRole = userAsync.value?['role'] ?? 'VALIDATOR';

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      floatingActionButton: (_isSelectionMode && _selectedIds.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () => _handleBulkApprove(userId, userRole),
              backgroundColor: AppColors.gold500,
              icon: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.forest900,
              ),
              label: Text(
                'APPROVE ${_selectedIds.length} ITEMS',
                style: AppTypography.label.copyWith(
                  color: AppColors.forest900,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ).animate().scale()
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: lessonsStream.when(
                data: (lessons) {
                  final filtered = _filterLessons(lessons);
                  if (filtered.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildLessonCard(
                              filtered[index],
                              userId,
                              userRole,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 50 * index))
                          .slideX(begin: 0.05);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold500),
                ),
                error: (e, st) => Center(
                  child: Text(
                    'Error loading lessons: $e',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.semanticRed,
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

  List<Lesson> _filterLessons(List<Lesson> lessons) {
    return lessons.where((l) {
      final matchesDialect =
          _selectedDialect == "All" || l.language == _selectedDialect;
      final matchesSearch =
          _searchQuery.isEmpty ||
          l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.language.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDialect && matchesSearch;
    }).toList();
  }

  void _handleBulkApprove(String userId, String userRole) async {
    final service = ref.read(firebaseServiceProvider);
    for (var id in _selectedIds) {
      await service.approveLesson(id, userId, userRole);
    }
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bulk approval complete!'),
          backgroundColor: AppColors.semanticGreen,
        ),
      );
    }
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSelectionMode ? 'Selection Mode' : 'Curriculum',
                style: AppTypography.displayBold.copyWith(
                  fontSize: _isSelectionMode ? 24 : 32,
                  color: AppColors.gold500,
                ),
              ),
              if (_isSelectionMode)
                GestureDetector(
                  onTap: () => setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.semanticRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.semanticRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: AppTypography.label.copyWith(
                        color: AppColors.semanticRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.gold500,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.forest800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.forest700 : AppColors.creamBorder,
              ),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.creamText,
              ),
              decoration: InputDecoration(
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.gold500,
                  size: 20,
                ),
                hintText: 'Search by title, dialect...',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDialectFilter(),
        ],
      ),
    );
  }

  Widget _buildDialectFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _dialects.map((dialect) {
          final isSelected = _selectedDialect == dialect;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDialect = dialect),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold500
                      : (isDark ? AppColors.forest800 : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold500
                        : (isDark
                              ? AppColors.forest700
                              : AppColors.creamBorder),
                  ),
                ),
                child: Text(
                  dialect.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: isSelected ? AppColors.forest900 : AppColors.gold500,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.forest700,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "All caught up!",
            style: AppTypography.h3.copyWith(color: AppColors.forest700),
          ),
          Text(
            "No lessons pending review.",
            style: AppTypography.body.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : AppColors.creamText2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson, String userId, String userRole) {
    final isSelected = _selectedIds.contains(lesson.id);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedIds.add(lesson.id);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(lesson.id);
              if (_selectedIds.isEmpty) _isSelectionMode = false;
            } else {
              _selectedIds.add(lesson.id);
            }
          });
        } else {
          _showLessonPreviewSheet(lesson);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold500.withValues(alpha: 0.1)
              : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.forest800
                    : Colors.white),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? AppColors.gold500
                : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.forest700
                      : AppColors.creamBorder),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EAD7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lesson.language.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: AppColors.forest900,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                if (_isSelectionMode)
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.gold500
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.black26),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              lesson.title,
              style: AppTypography.h2ExtraBold.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.creamBg
                    : AppColors.forest900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${lesson.tasks.length} Activities • Unit ${lesson.unitNumber}',
              style: AppTypography.body.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.creamText3
                    : AppColors.creamText,
                fontSize: 12,
              ),
            ),
            if (!_isSelectionMode) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref
                          .read(firebaseServiceProvider)
                          .approveLesson(lesson.id, userId, userRole),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'APPROVE',
                        style: AppTypography.label.copyWith(
                          color: AppColors.forest900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(
                      Icons.flag_outlined,
                      color: AppColors.terracotta,
                    ),
                    onPressed: () =>
                        _showFlagActionSheet(lesson, userId, userRole),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFlagActionSheet(Lesson lesson, String userId, String userRole) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Request Changes',
              style: AppTypography.h2ExtraBold.copyWith(
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.creamText,
              ),
              decoration: InputDecoration(
                hintText: 'Feedback for the contributor...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white38
                      : AppColors.creamText3,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.forest900
                    : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(firebaseServiceProvider)
                      .flagLesson(lesson.id, userId, userRole, controller.text);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                ),
                child: const Text('SEND FEEDBACK'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLessonPreviewSheet(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _LessonPreviewSheet(lesson: lesson),
    );
  }
}

final pendingLessonsProvider = StreamProvider<List<Lesson>>((ref) {
  return ref.watch(firebaseServiceProvider).getPendingLessons();
});

class _LessonPreviewSheet extends StatefulWidget {
  final Lesson lesson;
  const _LessonPreviewSheet({required this.lesson});

  @override
  State<_LessonPreviewSheet> createState() => _LessonPreviewSheetState();
}

class _LessonPreviewSheetState extends State<_LessonPreviewSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Temporary interaction state for previewing
  int? _selectedIndex;
  List<String> _scrambledParts = [];
  List<String> _availableParts = [];
  Map<String, String> _matchedPairs = {};
  String? _selectedNative;
  String? _selectedMeaning;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _flashcardFlipped = false;

  @override
  void initState() {
    super.initState();
    _initTaskState(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initTaskState(int index) {
    if (widget.lesson.tasks.isEmpty) return;
    final task = widget.lesson.tasks[index];

    _selectedIndex = null;
    _scrambledParts = [];
    _availableParts = List.from(task.sentenceParts)..shuffle();
    _matchedPairs = {};
    _selectedNative = null;
    _selectedMeaning = null;
    _isRecording = false;
    _hasRecorded = false;
    _flashcardFlipped = false;
  }

  Widget _buildTaskContent(LessonTask task) {
    switch (task.type) {
      case TaskType.multipleChoice:
        return MCQView(
          question: task.questionText,
          options: task.options,
          selectedIndex: _selectedIndex,
          onOptionSelected: (idx) => setState(() => _selectedIndex = idx),
        );
      case TaskType.listening:
        return ListeningView(
          question: task.questionText,
          options: task.options,
          selectedIndex: _selectedIndex,
          onOptionSelected: (idx) => setState(() => _selectedIndex = idx),
          audioUrl: task.audioUrl,
        );
      case TaskType.sentenceReordering:
        return SentenceReorderingView(
          question: task.questionText,
          scrambledParts: _scrambledParts,
          availableParts: _availableParts,
          onWordTap: (word) {
            setState(() {
              _availableParts.remove(word);
              _scrambledParts.add(word);
            });
          },
          onScrambledWordTap: (word) {
            setState(() {
              _scrambledParts.remove(word);
              _availableParts.add(word);
            });
          },
        );
      case TaskType.matching:
        return MatchingView(
          question: task.questionText,
          pairs: task.pairs,
          matchedPairs: _matchedPairs,
          selectedNative: _selectedNative,
          selectedMeaning: _selectedMeaning,
          onNativeTap: (native) {
            setState(() {
              if (_selectedNative == native) {
                _selectedNative = null;
              } else {
                _selectedNative = native;
                if (_selectedMeaning != null) {
                  _matchedPairs[native] = _selectedMeaning!;
                  _selectedNative = null;
                  _selectedMeaning = null;
                }
              }
            });
          },
          onMeaningTap: (meaning) {
            setState(() {
              if (_selectedMeaning == meaning) {
                _selectedMeaning = null;
              } else {
                _selectedMeaning = meaning;
                if (_selectedNative != null) {
                  _matchedPairs[_selectedNative!] = meaning;
                  _selectedNative = null;
                  _selectedMeaning = null;
                }
              }
            });
          },
        );
      case TaskType.pronunciation:
        return PronunciationView(
          question: task.questionText,
          word: task.nativeWord,
          phonetic: task.phoneticGuide,
          isRecording: _isRecording,
          hasRecorded: _hasRecorded,
          onToggleRecording: () => setState(() {
            _isRecording = !_isRecording;
            if (!_isRecording) _hasRecorded = true;
          }),
        );
      case TaskType.vocabulary:
        return VocabularyView(
          nativeWord: task.nativeWord,
          translation: task.options.isNotEmpty ? task.options.first : '',
          definition: task.hintMetadata,
          imageUrl: task.imageUrl,
          audioUrl: task.audioUrl,
          isFlipped: _flashcardFlipped,
          onFlip: () => setState(() => _flashcardFlipped = !_flashcardFlipped),
        );
      case TaskType.scenario:
        return ScenarioView(
          question: task.questionText,
          scenarioText: task.hintMetadata,
          options: task.options,
          selectedIndex: _selectedIndex,
          onOptionSelected: (idx) => setState(() => _selectedIndex = idx),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lesson.tasks.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Text(
          "No tasks in this lesson.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preview: ${widget.lesson.title}',
                  style: AppTypography.h3.copyWith(color: AppColors.gold500),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Activity ${_currentPage + 1} of ${widget.lesson.tasks.length}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.creamText3,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.lesson.tasks[_currentPage].type
                      .toString()
                      .split('.')
                      .last
                      .toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: AppColors.semanticGreen,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.forest700),
          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.lesson.tasks.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _initTaskState(index);
                });
              },
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: IgnorePointer(
                    ignoring: false, // Allow interaction for a true preview
                    child: _buildTaskContent(widget.lesson.tasks[index]),
                  ),
                );
              },
            ),
          ),
          // Navigation
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.forest900
                  : AppColors.creamBg,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.forest700
                      : AppColors.creamBorder,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                      : null,
                  child: Text(
                    'PREVIOUS',
                    style: TextStyle(
                      color: _currentPage > 0
                          ? AppColors.gold500
                          : Colors.white24,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _currentPage < widget.lesson.tasks.length - 1
                      ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                      : null,
                  child: Text(
                    'NEXT',
                    style: TextStyle(
                      color: _currentPage < widget.lesson.tasks.length - 1
                          ? AppColors.gold500
                          : Colors.white24,
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
}
