import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/haptic_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../models/lesson.dart';
import '../services/upload_queue_service.dart';
import '../services/offline_service.dart';
import '../models/lesson_task.dart';
import '../models/lesson_step.dart';
import '../services/firebase_service.dart';
import '../widgets/lesson_editors/configuration_editor.dart';
import '../widgets/lesson_editors/vocabulary_editor.dart';
import '../widgets/lesson_editors/mcq_editor.dart';
import '../widgets/lesson_editors/pronunciation_editor.dart';
import '../widgets/lesson_editors/matching_editor.dart';
import '../widgets/lesson_editors/sentence_reordering_editor.dart';
import '../widgets/lesson_editors/listening_editor.dart';
import '../widgets/lesson_editors/scenario_editor.dart';
import '../widgets/lesson_editors/editor_utils.dart';
import '../widgets/lesson_previews/lesson_preview_panel.dart';

class LessonEditorScreen extends ConsumerStatefulWidget {
  final String? lessonId;
  const LessonEditorScreen({super.key, this.lessonId});

  @override
  ConsumerState<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends ConsumerState<LessonEditorScreen>
    with SingleTickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  // Core config state
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _dialect = 'Mansaka';
  String _category = 'Vocabulary';
  String _difficulty = 'Beginner';
  int _unitNumber = 1;
  String? _prerequisiteId;

  // Steps state
  String? _currentLessonId;
  final List<LessonStep> _steps = [];
  LessonStep? _selectedStep;
  bool _isPreviewSessionActive = false;
  int _previewActivityIndex = 0;
  bool _isLoading = false;

  // Mobile Tabs
  late TabController _tabController;

  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentLessonId = widget.lessonId;

    // Initial configuration step
    _steps.add(
      LessonStep(
        id: 'config',
        type: ActivityType.configuration,
        title: 'Core Configuration',
      ),
    );
    _selectedStep = _steps.first;

    if (widget.lessonId != null) {
      _loadLessonData();
    }

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _isLoading) return;
      _saveLesson(isDraft: true, isAutoSave: true);
    });

    // Listen to upload queue
    ref.listenManual(uploadQueueProvider, (previous, next) {
      if (previous == true && next == false) {
        // Sync finished
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline drafts synced successfully!'),
            ),
          );
        }
      }
    });
  }

  Future<void> _loadLessonData() async {
    if (_currentLessonId == null) return;
    setState(() => _isLoading = true);
    try {
      final lesson = await ref
          .read(firebaseServiceProvider)
          .getLessonById(_currentLessonId!);
      if (lesson != null) {
        setState(() {
          _titleController.text = lesson.title;
          _descController.text = lesson.description;
          _dialect = lesson.language;
          _category = lesson.category;
          _unitNumber = lesson.unitNumber;
          _prerequisiteId = lesson.prerequisiteId;
          // Map tasks back to steps
          _steps.clear();
          _steps.add(
            LessonStep(
              id: 'config',
              type: ActivityType.configuration,
              title: 'Core Configuration',
              data: {
                'tags': [], // Placeholder if not in model
              },
            ),
          );

          for (var task in lesson.tasks) {
            _steps.add(_taskToStep(task));
          }
          _selectedStep = _steps.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lesson: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  LessonStep _taskToStep(LessonTask task) {
    ActivityType type;
    Map<String, dynamic> data = {};

    switch (task.type) {
      case TaskType.multipleChoice:
        type = ActivityType.mcq;
        data = {
          'question': task.questionText,
          'options': task.options,
          'correctIndex': task.correctAnswerIndex,
          'imageUrl': task.imageUrl,
          'audioUrl': task.audioUrl,
        };
        break;
      case TaskType.vocabulary:
        type = ActivityType.vocabulary;
        data = {
          'word': task.nativeWord,
          'translation': task.options.isNotEmpty ? task.options.first : '',
          'definition': task.hintMetadata,
          'imageUrl': task.imageUrl,
          'audioUrl': task.audioUrl,
        };
        break;
      case TaskType.pronunciation:
        type = ActivityType.pronunciation;
        data = {
          'word': task.nativeWord,
          'phonetic': task.phoneticGuide,
          'audioUrl': task.audioUrl,
        };
        break;
      case TaskType.matching:
        type = ActivityType.matching;
        data = {'pairs': task.pairs, 'question': task.questionText};
        break;
      case TaskType.sentenceReordering:
        type = ActivityType.sentenceReordering;
        data = {
          'sentence': task.expectedSentence,
          'parts': task.sentenceParts,
          'question': task.questionText,
        };
        break;
      case TaskType.listening:
        type = ActivityType.listening;
        data = {
          'question': task.questionText,
          'options': task.options,
          'correctIndex': task.correctAnswerIndex,
          'audioUrl': task.audioUrl,
        };
        break;
      case TaskType.scenario:
        type = ActivityType.scenario;
        data = {
          'question': task.questionText,
          'scenarioText': task.hintMetadata,
          'options': task.options,
          'correctIndex': task.correctAnswerIndex,
          'imageUrl': task.imageUrl,
        };
        break;
      case TaskType.wordHunt:
        type = ActivityType.wordHunt;
        data = {
          'question': task.questionText,
          'options': task.options, // Words to find
        };
        break;
      case TaskType.trueOrFalse:
        type = ActivityType.trueOrFalse;
        data = {
          'question': task.questionText,
          'correctIndex': task.correctAnswerIndex, // 0 for True, 1 for False
        };
        break;
      case TaskType.fillInTheBlanks:
        type = ActivityType.fillInTheBlanks;
        data = {
          'question': task.questionText,
          'expectedSentence': task.expectedSentence,
          'parts': task.sentenceParts, // The blanks
        };
        break;
    }

    return LessonStep(
      id: task.id,
      type: type,
      title: task.type.toString().split('.').last,
      data: data,
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _descController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addStep(ActivityType type, String title) {
    setState(() {
      final newStep = LessonStep(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        data: _getDefaultDataForType(type),
      );
      _steps.add(newStep);
      _selectedStep = newStep;
      if (MediaQuery.of(context).size.width < 800) {
        _tabController.animateTo(1); // Go to edit tab on mobile
      }
    });
  }

  Map<String, dynamic> _getDefaultDataForType(ActivityType type) {
    switch (type) {
      case ActivityType.vocabulary:
        return {
          'word': '',
          'translation': '',
          'definition': '',
          'options': <String>[],
        };
      case ActivityType.mcq:
        return {
          'question': '',
          'options': ['', '', ''],
          'correctIndex': 0,
        };
      case ActivityType.pronunciation:
        return {'word': '', 'phonetic': ''};
      case ActivityType.matching:
        return {
          'pairs': [
            {'native': '', 'meaning': ''},
          ],
          'question': 'Match the pairs',
        };
      case ActivityType.sentenceReordering:
        return {
          'sentence': '',
          'parts': <String>[],
          'question': 'Reorder the words',
        };
      case ActivityType.listening:
        return {
          'question': 'Listen and choose the correct answer',
          'audioUrl': '',
          'options': ['', '', ''],
          'correctIndex': 0,
        };
      case ActivityType.scenario:
        return {
          'question': 'What would you say in this situation?',
          'scenarioText': 'You are meeting an elder in the village...',
          'imageUrl': '',
          'options': ['', '', ''],
          'correctIndex': 0,
        };
      case ActivityType.wordHunt:
        return {
          'question': 'Find the hidden words',
          'options': ['', '', ''],
        };
      case ActivityType.trueOrFalse:
        return {
          'question': 'Is this statement correct?',
          'correctIndex': 0,
        };
      case ActivityType.fillInTheBlanks:
        return {
          'question': 'Fill in the missing words',
          'expectedSentence': '',
          'parts': <String>[],
        };
      default:
        return {};
    }
  }

  LessonTask _stepToTask(LessonStep step) {
    TaskType type;
    switch (step.type) {
      case ActivityType.mcq:
        type = TaskType.multipleChoice;
        break;
      case ActivityType.pronunciation:
        type = TaskType.pronunciation;
        break;
      case ActivityType.matching:
        type = TaskType.matching;
        break;
      case ActivityType.sentenceReordering:
        type = TaskType.sentenceReordering;
        break;
      case ActivityType.vocabulary:
        type = TaskType.vocabulary;
        break;
      case ActivityType.listening:
        type = TaskType.listening;
        break;
      case ActivityType.scenario:
        type = TaskType.scenario;
        break;
      case ActivityType.wordHunt:
        type = TaskType.wordHunt;
        break;
      case ActivityType.trueOrFalse:
        type = TaskType.trueOrFalse;
        break;
      case ActivityType.fillInTheBlanks:
        type = TaskType.fillInTheBlanks;
        break;
      default:
        type = TaskType.multipleChoice;
    }

    List<String> options = List<String>.from(step.data['options'] ?? []);
    if (step.type == ActivityType.vocabulary &&
        (step.data['translation'] as String?)?.isNotEmpty == true) {
      options = [step.data['translation']!];
    }

    return LessonTask(
      id: step.id,
      type: type,
      questionText: (step.data['question'] as String?)?.isNotEmpty ?? false
          ? step.data['question']
          : step.title,
      options: options,
      correctAnswerIndex: step.data['correctIndex'] ?? 0,
      pairs:
          (step.data['pairs'] as List?)
              ?.map((p) => Map<String, String>.from(p))
              .toList() ??
          [],
      sentenceParts: List<String>.from(step.data['parts'] ?? []),
      expectedSentence: step.data['sentence'] ?? '',
      nativeWord: step.data['word'] ?? '',
      phoneticGuide: step.data['phonetic'] ?? '',
      hintMetadata: step.data['scenarioText'] ?? step.data['definition'] ?? '',
      imageUrl: step.data['imageUrl'],
      audioUrl: step.data['audioUrl'],
    );
  }

  void _saveLesson({bool isDraft = false, bool isAutoSave = false}) async {
    if (!isDraft) {
      if (_titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Validation Error: Lesson Title is required to publish.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.semanticRed,
          ),
        );
        return;
      }
      if (_steps.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Validation Error: Add at least one activity to submit.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.semanticRed,
          ),
        );
        return;
      }

      final invalidSteps = _steps.where((s) => !s.isValid).toList();
      if (invalidSteps.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please complete all activities before publishing: ${invalidSteps.map((s) => s.title).join(", ")}',
            ),
            backgroundColor: AppColors.terracotta,
          ),
        );
        return;
      }

      // Check for unit uniqueness
      final isUnique = await ref
          .read(firebaseServiceProvider)
          .isUnitUnique(
            _dialect,
            _unitNumber,
            excludeLessonId: _currentLessonId,
          );

      if (!isUnique) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Validation Error: A lesson for $_dialect Unit $_unitNumber already exists.',
              ),
              backgroundColor: AppColors.semanticRed,
            ),
          );
        }
        return;
      }
    }

    if (!isAutoSave) setState(() => _isLoading = true);

    try {
      final lesson = Lesson(
        id: _currentLessonId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descController.text,
        category: _category,
        language: _dialect,
        level: _difficulty == 'Beginner'
            ? 1
            : (_difficulty == 'Intermediate' ? 2 : 3),
        unitNumber: _unitNumber,
        icon: _steps.any((s) => s.type == ActivityType.vocabulary)
            ? 'local_florist'
            : 'psychology',
        status: isDraft ? 'DRAFT' : 'PUBLISHED',
        prerequisiteId: _prerequisiteId,
        tasks: _steps
            .where((s) => s.type != ActivityType.configuration)
            .map((s) => _stepToTask(s))
            .toList(),
      );

      final firebaseService = ref.read(firebaseServiceProvider);
      final offlineService = ref.read(offlineServiceProvider);

      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        // Offline: Save to Hive draft box
        await offlineService.saveDraftLesson(lesson);
        if (!isAutoSave && mounted) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved locally. Will sync when online.'),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Online: Save to Firebase
        final savedId = await firebaseService.saveLesson(
          lesson,
          status: isDraft ? 'DRAFT' : 'PUBLISHED',
        );

        if (mounted) {
          setState(() {
            _currentLessonId = savedId;
          });

          // Remove from local drafts if it was there
          await offlineService.removeDraftLesson(lesson.id);

          if (isAutoSave) {
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Auto-saved at ${TimeOfDay.now().format(context)}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  backgroundColor: AppColors.forest800,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          } else {
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isDraft
                        ? 'Lesson saved to drafts!'
                        : 'Lesson published successfully!',
                  ),
                ),
              );
              Navigator.pop(context, true);
            }
          }
        }
      }
    } catch (e) {
      if (mounted && !isAutoSave) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving lesson: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    } finally {
      if (mounted && !isAutoSave) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            title: Text(
              'Unsaved Changes',
              style: AppTypography.h3.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              'You may have unsaved changes. Are you sure you want to exit?',
              style: AppTypography.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'CANCEL',
                  style: AppTypography.label.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'EXIT',
                  style: AppTypography.label.copyWith(
                    color: AppColors.semanticRed,
                  ),
                ),
              ),
            ],
          ),
        );

        if (shouldPop ?? false) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Lesson Weaver',
                style: GoogleFonts.outfit(
                  color: AppColors.gold500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                TextButton(
                  onPressed: () => _saveLesson(isDraft: true),
                  child: Text(
                    'SAVE DRAFT',
                    style: AppTypography.label.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _saveLesson(isDraft: false),
                  child: Text(
                    'PUBLISH LESSON',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gold500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Pane 1: Steps List
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: _buildStepsList(),
          ),
        ),
        // Pane 2: Content Editor
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: _buildContentEditor(),
          ),
        ),
        // Pane 3: Live Preview
        Expanded(flex: 3, child: _buildLivePreview()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold500,
          labelColor: AppColors.gold500,
          unselectedLabelColor: isDark ? Colors.white54 : AppColors.creamText3,
          tabs: const [
            Tab(text: 'Steps'),
            Tab(text: 'Edit'),
            Tab(text: 'Preview'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildStepsList().animate().fadeIn(duration: 400.ms),
              _buildContentEditor().animate().fadeIn(duration: 400.ms),
              _buildLivePreview().animate().fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ],
    );
  }

  // --- Pane 1: Steps List ---
  Widget _buildStepsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'LESSON STEPS',
            style: AppTypography.label.copyWith(
              color: AppColors.gold500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _steps.length,
            onReorderStart: (index) {
              HapticService.selection();
            },
            onReorder: (oldIndex, newIndex) {
              HapticService.medium();
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final step = _steps.removeAt(oldIndex);
                _steps.insert(newIndex, step);
              });
            },
            itemBuilder: (context, index) {
              final step = _steps[index];
              final isSelected = _selectedStep == step;
              final isStepValid = step.isValid;
              return ListTile(
                key: ValueKey(step.id),
                leading: Icon(
                  _getIconData(step.type),
                  color: isStepValid
                      ? AppColors.gold500
                      : AppColors.semanticRed,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: AppTypography.body.copyWith(
                          color: isStepValid
                              ? (isDark ? Colors.white : AppColors.creamText)
                              : AppColors.semanticRed,
                        ),
                      ),
                    ),
                    if (!isStepValid)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.semanticRed,
                        size: 16,
                      ),
                  ],
                ),
                subtitle: Text(
                  step.type.name,
                  style: AppTypography.label.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                tileColor: isSelected
                    ? (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05))
                    : null,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedStep = step;
                    if (MediaQuery.of(context).size.width < 800) {
                      _tabController.animateTo(1);
                    }
                  });
                },
                trailing: step.type != ActivityType.configuration
                    ? IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _steps.remove(step);
                            if (_selectedStep == step) {
                              _selectedStep = _steps.first;
                            }
                          });
                        },
                      )
                    : null,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: BrandButton(
            text: 'ADD ACTIVITY',
            type: BrandButtonType.secondary,
            onTap: _showAddActivityDialog,
          ),
        ),
      ],
    );
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.forestDarkCard : Colors.white,
        title: Text(
          'Add Activity',
          style: AppTypography.h3.copyWith(
            color: isDark ? Colors.white : AppColors.creamText,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildActivityOption(
                dialogContext,
                ActivityType.vocabulary,
                'Vocabulary Builder',
                Icons.text_fields,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.mcq,
                'Multiple Choice',
                Icons.check_circle_outline,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.pronunciation,
                'Pronunciation Anchor',
                Icons.mic_none,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.matching,
                'Matching Game',
                Icons.compare_arrows,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.sentenceReordering,
                'Sentence Scrambler',
                Icons.wrap_text,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.listening,
                'Listening Challenge',
                Icons.headphones,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.scenario,
                'Cultural Scenario',
                Icons.movie_outlined,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.wordHunt,
                'Word Hunt',
                Icons.grid_on_rounded,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.trueOrFalse,
                'True or False',
                Icons.thumbs_up_down_rounded,
              ),
              _buildActivityOption(
                dialogContext,
                ActivityType.fillInTheBlanks,
                'Fill in the Blanks',
                Icons.space_bar_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityOption(
    BuildContext dialogContext,
    ActivityType type,
    String title,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold500),
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          color: isDark ? Colors.white : AppColors.creamText,
        ),
      ),
      onTap: () {
        Navigator.of(dialogContext).pop();
        _addStep(type, title);
      },
    );
  }

  // --- Pane 2: Content Editor ---
  Widget _buildContentEditor() {
    if (_selectedStep == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
                  'assets/images/lumad_character.png',
                  height: 120,
                  opacity: const AlwaysStoppedAnimation(0.4),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .moveY(
                  begin: -5,
                  end: 5,
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            Text(
              'Select a step to edit',
              style: AppTypography.h3.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your lesson content will appear here.',
              style: AppTypography.body.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
          key: ValueKey('editor_${_selectedStep!.id}'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _selectedStep!.title,
                    style: AppTypography.h2.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _getTooltipMessage(_selectedStep!.type),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSelectedEditor(),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.02, curve: Curves.easeOut);
  }

  Widget _buildSelectedEditor() {
    try {
      switch (_selectedStep!.type) {
        case ActivityType.configuration:
          return ConfigurationEditor(
            titleController: _titleController,
            descController: _descController,
            currentLessonId: _currentLessonId,
            prerequisiteId: _prerequisiteId,
            category: _category,
            dialect: _dialect,
            unitNumber: _unitNumber,
            difficulty: _difficulty,
            step: _selectedStep!,
            onPrerequisiteChanged: (val) =>
                setState(() => _prerequisiteId = val),
            onCategoryChanged: (val) => setState(() => _category = val!),
            onDialectChanged: (val) => setState(() => _dialect = val!),
            onUnitNumberChanged: (val) => setState(() => _unitNumber = val),
            onDifficultyChanged: (val) => setState(() => _difficulty = val!),
            onUpdated: () => setState(() {}),
          );
        case ActivityType.vocabulary:
          return VocabularyEditor(
            step: _selectedStep!,
            onUpdated: () => setState(() {}),
          );
        case ActivityType.mcq:
          return MCQEditor(
            step: _selectedStep!,
            onUpdated: () => setState(() {}),
          );
        case ActivityType.pronunciation:
          return PronunciationEditor(
            step: _selectedStep!,
            onUpdated: () => setState(() {}),
          );
        case ActivityType.matching:
          return MatchingEditor(
            step: _selectedStep!,
            onUpdated: () => setState(() {}),
          );
        case ActivityType.sentenceReordering:
          return SentenceReorderingEditor(
            step: _selectedStep!,
            onUpdated: () => setState(() {}),
          );
        case ActivityType.listening:
          return ListeningEditor(
            step: _selectedStep!,
            onUpdated: () => setState(() {}),
          );
        case ActivityType.scenario:
          return ScenarioEditor(
            step: _selectedStep!,
            onUpdated: () => setState(() {}),
          );
        case ActivityType.wordHunt:
          return _buildWordHuntEditor();
        case ActivityType.trueOrFalse:
          return _buildTrueOrFalseEditor();
        case ActivityType.fillInTheBlanks:
          return _buildFillInTheBlanksEditor();
      }
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.semanticRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.semanticRed),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.semanticRed,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Editor Error',
              style: AppTypography.body.copyWith(
                color: AppColors.semanticRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              e.toString(),
              style: AppTypography.label.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  String _getTooltipMessage(ActivityType type) {
    switch (type) {
      case ActivityType.vocabulary:
        return 'Add a native word, its meaning, and an artifact image.';
      case ActivityType.mcq:
        return 'Test comprehension with multiple choices.';
      case ActivityType.pronunciation:
        return 'Help students learn proper intonation.';
      case ActivityType.matching:
        return 'Pair native words with their translations.';
      case ActivityType.sentenceReordering:
        return 'Students drag words to form a correct sentence.';
      case ActivityType.wordHunt:
        return 'Students find indigenous words in a grid.';
      case ActivityType.trueOrFalse:
        return 'Simple binary choice comprehension check.';
      case ActivityType.fillInTheBlanks:
        return 'Students type or select missing words in a sentence.';
      default:
        return 'Configure this activity.';
    }
  }

    Widget _buildWordHuntEditor() {
    final options = _selectedStep!.data['options'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorUtils.buildDataTextField(
          label: 'Question / Instructions',
          initialValue: _selectedStep!.data['question'] ?? '',
          onChanged: (val) {
            _selectedStep!.data['question'] = val;
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Words to Find',
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(options.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: EditorUtils.buildDataTextField(
                    label: 'Word ${i + 1}',
                    initialValue: options[i],
                    onChanged: (val) {
                      options[i] = val;
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  onPressed: () {
                    setState(() {
                      options.removeAt(i);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add, color: AppColors.gold500),
          label: const Text('Add Word', style: TextStyle(color: AppColors.gold500)),
          onPressed: () {
            setState(() {
              options.add('');
            });
          },
        ),
      ],
    );
  }

  Widget _buildTrueOrFalseEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorUtils.buildDataTextField(
          label: 'Statement',
          initialValue: _selectedStep!.data['question'] ?? '',
          onChanged: (val) {
            _selectedStep!.data['question'] = val;
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Correct Answer',
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('TRUE'),
                selected: _selectedStep!.data['correctIndex'] == 0,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStep!.data['correctIndex'] = 0;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('FALSE'),
                selected: _selectedStep!.data['correctIndex'] == 1,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStep!.data['correctIndex'] = 1;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFillInTheBlanksEditor() {
    final parts = _selectedStep!.data['parts'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorUtils.buildDataTextField(
          label: 'Instruction',
          initialValue: _selectedStep!.data['question'] ?? '',
          onChanged: (val) {
            _selectedStep!.data['question'] = val;
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Full Sentence (use [word] for blanks)',
          initialValue: _selectedStep!.data['expectedSentence'] ?? '',
          onChanged: (val) {
            _selectedStep!.data['expectedSentence'] = val;
            // Auto-extract parts if we wanted to, but let's keep it manual for now or simple
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Answer Keys (Words that go in the blanks)',
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(parts.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: EditorUtils.buildDataTextField(
                    label: 'Blank ${i + 1} Answer',
                    initialValue: parts[i],
                    onChanged: (val) {
                      parts[i] = val;
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  onPressed: () {
                    setState(() {
                      parts.removeAt(i);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add, color: AppColors.gold500),
          label: const Text('Add Blank Answer', style: TextStyle(color: AppColors.gold500)),
          onPressed: () {
            setState(() {
              parts.add('');
            });
          },
        ),
      ],
    );
  }

  // --- Pane 3: Live Preview ---
  List<LessonStep> get _previewActivities =>
      _steps.where((step) => step.type != ActivityType.configuration).toList();

  void _startPreviewSession() {
    final activities = _previewActivities;
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add an activity before starting the lesson preview.'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    setState(() {
      _isPreviewSessionActive = true;
      _previewActivityIndex = 0;
      _selectedStep = activities.first;
    });
  }

  void _showPreviewActivity(int index) {
    final activities = _previewActivities;
    if (index < 0 || index >= activities.length) return;

    setState(() {
      _previewActivityIndex = index;
      _selectedStep = activities[index];
    });
  }

  void _exitPreviewSession() {
    setState(() {
      _isPreviewSessionActive = false;
      _previewActivityIndex = 0;
      _selectedStep = _steps.first;
    });
  }

  Widget _buildLivePreview() {
    final activities = _previewActivities;
    final previewIndex = activities.isEmpty
        ? 0
        : _previewActivityIndex.clamp(0, activities.length - 1) as int;
    final previewStep = _isPreviewSessionActive && activities.isNotEmpty
        ? activities[previewIndex]
        : _selectedStep;

    return LessonPreviewPanel(
      selectedStep: previewStep,
      title: _titleController.text,
      description: _descController.text,
      difficulty: _difficulty,
      dialect: _dialect,
      onStart: _startPreviewSession,
      onExitPreview: _exitPreviewSession,
      onPreviousActivity: _isPreviewSessionActive && previewIndex > 0
          ? () => _showPreviewActivity(previewIndex - 1)
          : null,
      onNextActivity: _isPreviewSessionActive &&
              previewIndex < activities.length - 1
          ? () => _showPreviewActivity(previewIndex + 1)
          : null,
      isPreviewSessionActive: _isPreviewSessionActive,
      currentActivityNumber:
          _isPreviewSessionActive && activities.isNotEmpty
              ? previewIndex + 1
              : 0,
      totalActivities: activities.length,
    );
  }

  IconData _getIconData(ActivityType type) {
    switch (type) {
      case ActivityType.configuration:
        return Icons.settings_rounded;
      case ActivityType.vocabulary:
        return Icons.text_fields;
      case ActivityType.mcq:
        return Icons.check_circle_outline;
      case ActivityType.pronunciation:
        return Icons.mic_none;
      case ActivityType.matching:
        return Icons.compare_arrows;
      case ActivityType.sentenceReordering:
        return Icons.wrap_text;
      case ActivityType.listening:
        return Icons.headphones;
      case ActivityType.scenario:
        return Icons.movie_outlined;
      case ActivityType.wordHunt:
        return Icons.grid_on_rounded;
      case ActivityType.trueOrFalse:
        return Icons.thumbs_up_down_rounded;
      case ActivityType.fillInTheBlanks:
        return Icons.space_bar_rounded;
    }
  }
}



