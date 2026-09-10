import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';
import '../widgets/xp_celebration.dart';
import '../models/lesson_task.dart';
import '../models/artifact.dart';
import '../models/app_config.dart';
import '../providers/learning_provider.dart'; 
import 'package:lumad_lingua/widgets/progress_header.dart';
import '../widgets/feedback_panel.dart';
import '../widgets/activity_views/mcq_view.dart';
import '../widgets/activity_views/vocabulary_view.dart';
import '../widgets/activity_views/sentence_reordering_view.dart';
import '../widgets/activity_views/matching_view.dart';
import '../widgets/activity_views/pronunciation_view.dart';
import '../widgets/activity_views/scenario_view.dart';
import '../widgets/activity_views/listening_view.dart';
import '../widgets/activity_views/word_hunt_view.dart';
import '../widgets/activity_views/true_false_view.dart';
import '../widgets/activity_views/fill_blanks_view.dart';
import '../providers/student_provider.dart';
import '../providers/quest_provider.dart';
import '../models/quest.dart';
import '../models/assessment.dart';
import '../services/haptic_service.dart';
import '../widgets/assessment_overlay.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audio_waveforms/audio_waveforms.dart';
import '../widgets/parallax_background.dart';
import '../widgets/elders_wisdom_panel.dart';
import '../utils/icon_utils.dart';
import '../services/task_evaluator.dart';
import '../widgets/lesson_session/session_widgets.dart';
import '../widgets/lesson_session/results_view.dart';
import 'package:confetti/confetti.dart';

class LessonSessionScreen extends ConsumerStatefulWidget {
  const LessonSessionScreen({super.key});

  @override
  ConsumerState<LessonSessionScreen> createState() =>
      _LessonSessionScreenState();
}


class _LessonSessionScreenState extends ConsumerState<LessonSessionScreen> {
  // MCQ
  int? _selectedIndex;

  // Word Hunt
  final Set<String> _foundWords = {};

  // Fill in the Blanks
  final Map<int, String> _selectedBlanks = {};

  // Scrambler
  List<String> _scrambledParts = [];
  List<String> _availableParts = [];

  // Matching
  Map<String, String> _matchedPairs = {};
  String? _selectedNative;
  String? _selectedMeaning;

  bool _isRecording = false;
  bool _hasRecorded = false;

  // Vocabulary Flashcard
  bool _flashcardFlipped = false;

  bool _showFeedback = false;
  bool _lastAnswerCorrect = false;
  String _feedbackSubtitle = "";
  bool _isCelebrating = false;
  int _currentTaskXp = 0;
  int _calculatedSessionXp = 0;

  bool _isContinuing = false;

  int _shakeCounter = 0;
  final Map<String, int> _taskMistakes = {};

  // Speech To Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _lastWords = "";

  // Audio Waveforms
  late final RecorderController _recorderController;

  // Gamification Mechanics
  int _combo = 0;
  int _bonusXp = 0;
  DateTime _taskStartTime = DateTime.now();
  late ConfettiController _confettiController;
  bool _isSuddenDeath = false;
  LessonTask? _suddenDeathTask;
  LessonTask? _lastTask;
  bool _showLeaderboardSnippet = false;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadLesson();
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _confettiController.dispose();
    _speech.stop();
    ref.read(audioServiceProvider).stopAmbientMusic();
    super.dispose();
  }


  void _loadLesson() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lessonId = GoRouterState.of(
        context,
      ).uri.queryParameters['lessonId'];
      if (lessonId != null) {
        ref.read(currentLessonProvider(lessonId).future).then((lesson) {
          if (lesson != null && mounted) {
            ref.read(quizSessionProvider.notifier).loadTasks(lesson.tasks);
            _initTaskState();

            final audioUrls = lesson.tasks
                .map((t) => t.audioUrl)
                .where((url) => url != null && url.isNotEmpty)
                .cast<String>()
                .toList();
            if (audioUrls.isNotEmpty) {
              ref.read(audioServiceProvider).preCacheAudio(audioUrls);
            }

            ref.read(audioServiceProvider).playAmbientMusic(lesson.title);
          }
        });
      }
    });
  }

  void _initTaskState() {
    final state = ref.read(quizSessionProvider);
    final task = state.currentTask;
    if (task == null) return;

    _selectedIndex = null;
    _foundWords.clear();
    _selectedBlanks.clear();
    _scrambledParts = [];
    _availableParts = List.from(task.sentenceParts)..shuffle();
    _matchedPairs = {};
    _selectedNative = null;
    _selectedMeaning = null;
    _isRecording = false;
    _hasRecorded = false;
    _flashcardFlipped = false;
    _showFeedback = false;
    _taskStartTime = DateTime.now();
  }

  void _onOptionSelected(int index) {
    if (_showFeedback) return;
    HapticService.selection();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleRecording() async {
    if (_showFeedback) return;

    if (!_isRecording) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isRecording = true);
        await _recorderController.record();
        _speech.listen(
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isRecording = false);
      _speech.stop();
      await _recorderController.stop();
      if (_lastWords.isNotEmpty) {
        setState(() => _hasRecorded = true);
      }
    }
  }

  bool _isTaskComplete(LessonTask task) {
    switch (task.type) {
      case TaskType.multipleChoice:
      case TaskType.listening:
      case TaskType.trueOrFalse:
      case TaskType.scenario:
        return _selectedIndex != null;
      case TaskType.sentenceReordering:
        return _scrambledParts.length == task.sentenceParts.length;
      case TaskType.matching:
        return _matchedPairs.length == task.pairs.length;
      case TaskType.pronunciation:
        return _hasRecorded;
      case TaskType.vocabulary:
        return _flashcardFlipped;
      case TaskType.wordHunt:
        return _foundWords.length == task.options.length;
      case TaskType.fillInTheBlanks:
        return _selectedBlanks.length == task.sentenceParts.length;
    }
  }

  void _checkAnswer() {
    if (_showFeedback) return; // Prevent double submission

    final state = ref.read(quizSessionProvider);
    final baseTask = state.currentTask;
    final task = (_isSuddenDeath && _suddenDeathTask != null)
        ? _suddenDeathTask!
        : baseTask;
    if (task == null) return;
    if (!_isTaskComplete(task)) return;

    final evaluation = TaskEvaluator.evaluate(
      task: task,
      selectedIndex: _selectedIndex,
      scrambledParts: _scrambledParts,
      matchedPairs: _matchedPairs,
      selectedBlanks: _selectedBlanks,
      hasRecorded: _hasRecorded,
      lastWords: _lastWords,
    );

    bool isCorrect = evaluation.isCorrect;
    _feedbackSubtitle = evaluation.feedbackSubtitle;

    if (task.type == TaskType.vocabulary && isCorrect) {
      ref.read(questActionProvider.notifier).updateProgress(QuestType.flashcard, 1);
    } else if (task.type == TaskType.pronunciation && isCorrect) {
      ref.read(questActionProvider.notifier).updateProgress(QuestType.pronunciation, 1);
    }

    final savedIsCorrect = ref
        .read(quizSessionProvider.notifier)
        .submitAnswer(
          isCorrect,
          isFirstTry: (_taskMistakes[task.id] ?? 0) == 0,
          logicalTaskId: task.id, 
        );

    if (mounted) {
      setState(() {
        _lastAnswerCorrect = savedIsCorrect;
        _showFeedback = true;
        if (!savedIsCorrect) {
          ref.read(studentProvider.notifier).decrementHeart();
          _shakeCounter++;
          _taskMistakes[task.id] = (_taskMistakes[task.id] ?? 0) + 1;
          _combo = 0;
          HapticService.error();
          ref.read(audioServiceProvider).playSFX('error');
        } else {
          final prevCombo = _combo;
          _combo++;
          HapticService.success();
          ref.read(audioServiceProvider).playSFX('success');

          int taskXp = 20;
          final timeTaken = DateTime.now().difference(_taskStartTime);
          if (timeTaken.inSeconds <= 5) {
            _bonusXp += 5;
            taskXp += 5;
          }

          if (_combo >= 5) {
            _bonusXp += 15;
            taskXp += 15;
            HapticService.heavy();
          } else if (_combo >= 3) {
            _bonusXp += 5;
            taskXp += 5;
            HapticService.medium();
          } else if (prevCombo == 2 && _combo == 3) {
            HapticService.light();
          }

          _currentTaskXp = taskXp;

          if (_combo >= 10) {
            _confettiController.play();
            HapticService.celebration();
            ref.read(audioServiceProvider).playSFX('success');
            _checkLeaderboardRank();
          } else if (_combo >= 5) {
            _confettiController.play();
            HapticService.celebration();
            ref.read(audioServiceProvider).playSFX('success');
          } else if (_combo >= 3) {
            HapticService.combo();
            ref.read(audioServiceProvider).playSFX('success');
          }
        }
      });
    }

    if (_isSuddenDeath && mounted) {
      _handleSuddenDeathResult(savedIsCorrect);
    }
  }

  void _checkLeaderboardRank() {
    final topLearners = ref.read(topLearnersProvider).value;
    final user = ref.read(authServiceProvider).currentUser;
    if (topLearners != null && user != null) {
      final userIndex = topLearners.indexWhere(
        (l) => (l['uid'] ?? l['id']) == user.uid,
      );
      if (userIndex >= 0 && userIndex < 3) {
        setState(() => _showLeaderboardSnippet = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showLeaderboardSnippet = false);
        });
      }
    }
  }

  void _handleContinue() {
    if (_isContinuing) return;
    _isContinuing = true;

    final state = ref.read(quizSessionProvider);

    final uri = GoRouterState.of(context).uri;
    final lessonId = uri.queryParameters['lessonId'] ?? '';
    final user = ref.read(authServiceProvider).currentUser;
    final hearts = ref.read(studentProvider).hearts;

    if (state.isCompleted) {
      if (lessonId.isNotEmpty && user != null) {
        int stars = 3;
        if (hearts <= 2) {
          stars = 1;
        } else if (hearts <= 4) {
          stars = 2;
        }

        final config = ref.read(appConfigProvider).value ?? AppConfig.fromFirestore({});
        final totalTasks = state.totalTasks;
        final distinctMistakeTasks = _taskMistakes.keys.length;
        final accurateCount = totalTasks - distinctMistakeTasks;
        final sessionXp =
            (accurateCount * config.lessonTaskPerfectXp) + 
            (distinctMistakeTasks * config.lessonTaskRetryXp) + 
            config.lessonCompletionBaseXp + _bonusXp;

        setState(() {
          _showFeedback = false;
          _isCelebrating = true;
          _calculatedSessionXp = sessionXp;
        });
        ref.read(audioServiceProvider).playSFX('session_complete');

        ref
            .read(firebaseServiceProvider)
            .completeLesson(
              user.uid,
              lessonId,
              state.completedCount * 10,
              stars,
              taskPerformance: _taskMistakes,
              bonusXp: _bonusXp,
            )
            .then((result) {
              if (!mounted) return;
              final bool unlockedBadge = result['unlockedBadge'] ?? false;
              final Artifact? droppedArtifact =
                  result['droppedArtifact'] as Artifact?;

              if (droppedArtifact != null) {
                _showArtifactDropDialog(droppedArtifact, unlockedBadge);
              } else if (unlockedBadge) {
                _showBadgeUnlockedDialog();
              }
              
              // Increment daily streak on lesson completion
              ref.read(studentProvider.notifier).incrementStreak();
              
              // Update Tribal Challenges progress
              ref.read(questActionProvider.notifier).updateProgress(QuestType.lesson, 1);

              // 20% chance to show a post-test assessment for data gathering
              final bool shouldShowPostTest = stars == 3 && (DateTime.now().millisecond % 5 == 0);
              
              if (shouldShowPostTest) {
                _showPostTestAssessment(onFinish: () {
                  if (droppedArtifact != null) {
                    _showArtifactDropDialog(droppedArtifact, unlockedBadge);
                  } else if (unlockedBadge) {
                    _showBadgeUnlockedDialog();
                  }
                });
              } else {
                if (droppedArtifact != null) {
                  _showArtifactDropDialog(droppedArtifact, unlockedBadge);
                } else if (unlockedBadge) {
                  _showBadgeUnlockedDialog();
                }
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sync error: ${error.toString()}'),
                    backgroundColor: AppColors.semanticRed,
                  ),
                );
              }
            })
            .whenComplete(() {
              if (mounted) {
                setState(() => _isContinuing = false);
              }
            });
      } else {
        _isContinuing = false;
      }
    } else if (hearts == 0) {
      _showSuddenDeathChallenge();
      _isContinuing = false;
    } else {
      setState(() {
        _initTaskState();
      });
      _isContinuing = false;
    }
  }

  void _showPostTestAssessment({required VoidCallback onFinish}) {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      onFinish();
      return;
    }

    final List<AssessmentQuestion> postTestQuestions = [
      AssessmentQuestion(
        id: 'confidence',
        text: 'How confident do you feel about the words you just learned?',
        options: ['Very confident', 'Somewhat confident', 'A bit confused', 'I need more practice'],
      ),
      AssessmentQuestion(
        id: 'difficulty',
        text: 'Was the difficulty of this lesson appropriate?',
        options: ['Too easy', 'Just right', 'Too hard', 'Very challenging'],
      ),
      AssessmentQuestion(
        id: 'utility',
        text: 'How likely are you to use these words in a conversation?',
        options: ['Very likely', 'Possibly', 'Not sure', 'Unlikely'],
      ),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AssessmentOverlay(
            type: AssessmentType.postTest,
            questions: postTestQuestions,
            onComplete: (answers) async {
              final result = AssessmentResult(
                userId: user.uid,
                type: AssessmentType.postTest,
                lessonId: GoRouterState.of(context).uri.queryParameters['lessonId'],
                answers: answers,
                timestamp: DateTime.now(),
              );
              await ref.read(firebaseServiceProvider).saveAssessmentResult(result);
              if (ctx.mounted) Navigator.pop(ctx);
              onFinish();
            },
          ),
        ),
      ),
    );
  }

  void _showQuitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '\ud83c\udfc3 Leave Session?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Your progress in this session will be lost. Are you sure you want to quit?',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep Going',
              style: TextStyle(color: AppColors.gold500),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text(
              'Quit',
              style: TextStyle(color: AppColors.semanticRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionSummary({
    required int xpEarned,
    required int stars,
    required int totalTasks,
    required int distinctMistakeTasks,
    required int bonusXp,
  }) {
    if (!mounted) return;

    // Trigger extra confetti if 3 stars
    if (stars == 3) {
      _confettiController.play();
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, anim1, anim2) => SessionResultsView(
        xpEarned: xpEarned,
        stars: stars,
        totalTasks: totalTasks,
        distinctMistakeTasks: distinctMistakeTasks,
        bonusXp: bonusXp,
        onFinish: () => context.go('/'),
      ),
    );
  }

  void _showHeartRecoveryDialog() {
    final studentState = ref.read(studentProvider);
    const crystalCost = 50;
    final canAfford = studentState.mistCrystals >= crystalCost;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Out of Hearts! \ud83d\udc94",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Your journey has grown difficult. Would you like to restore your strength?",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Cost: ", style: TextStyle(color: Colors.white54)),
                  Text(
                    "$crystalCost ",
                    style: TextStyle(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.gold500,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (!canAfford)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  "Not enough crystals!",
                  style: TextStyle(color: AppColors.semanticRed, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(); 
            },
            child: const Text(
              "End Session",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: canAfford
                ? () async {
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user != null) {
                      await ref
                          .read(firebaseServiceProvider)
                          .spendMistCrystals(user.uid, crystalCost);
                      ref.read(studentProvider.notifier).refillHearts();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold500,
              foregroundColor: AppColors.forest900,
              disabledBackgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Restore Hearts",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuddenDeathChallenge() {
    final state = ref.read(quizSessionProvider);
    final tasks = state.totalTasks > 0
        ? state.currentTask != null
              ? [state.currentTask!]
              : []
        : [];
    if (tasks.isEmpty) {
      _showHeartRecoveryDialog();
      return;
    }

    setState(() {
      _isSuddenDeath = true;
      _suddenDeathTask = tasks[0]; 
      _initTaskState();
    });
  }

  void _handleSuddenDeathResult(bool isCorrect) {
    if (isCorrect) {
      ref.read(studentProvider.notifier).gainHeart(1); 
      setState(() {
        _isSuddenDeath = false;
        _suddenDeathTask = null;
        _showFeedback = false;
        _initTaskState();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SUDDEN DEATH SURVIVED! +1 Heart'),
          backgroundColor: AppColors.semanticGreen,
        ),
      );
    } else {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SUDDEN DEATH FAILED... Session Ended'),
          backgroundColor: AppColors.semanticRed,
        ),
      );
    }
  }

  void _showBadgeUnlockedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(
              Icons.military_tech_rounded,
              size: 64,
              color: AppColors.gold500,
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text(
              'Badge Unlocked!',
              style: TextStyle(
                color: AppColors.gold500,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: const Text(
          'You earned the Perfect Scholar badge for your flawless performance!',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Awesome!',
                style: TextStyle(color: AppColors.gold500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showArtifactDropDialog(Artifact artifact, bool alsoUnlockedBadge) {
    if (!mounted) return;

    HapticService.celebration();
    ref.read(audioServiceProvider).playSFX('session_complete');
    _confettiController.play();


    Color tierColor = Colors.white54;
    switch (artifact.tier) {
      case ArtifactTier.common:
        tierColor = Colors.white54;
        break;
      case ArtifactTier.rare:
        tierColor = Colors.blueAccent;
        break;
      case ArtifactTier.epic:
        tierColor = Colors.purpleAccent;
        break;
      case ArtifactTier.sacred:
        tierColor = Colors.cyanAccent;
        break;
      case ArtifactTier.ancient:
        tierColor = AppColors.gold500;
        break;
      case ArtifactTier.legendary:
        tierColor = Colors.orangeAccent;
        break;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tierColor.withValues(alpha: 0.5), width: 2),
        ),
        title: Column(
          children: [
            const Text(
              'Loot Drop!',
              style: TextStyle(
                color: AppColors.gold500,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ).animate().slideY(begin: -0.5).fadeIn(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: tierColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Text(artifact.emoji, style: const TextStyle(fontSize: 64))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.1, duration: 800.ms),
            ),
            const SizedBox(height: 16),
            Text(
              artifact.title,
              style: TextStyle(
                color: tierColor,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                artifact.tier.name.toUpperCase(),
                style: TextStyle(
                  color: tierColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          artifact.description,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (alsoUnlockedBadge) {
                  _showBadgeUnlockedDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tierColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add to Vault',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskContent(LessonTask task) {
    switch (task.type) {
      case TaskType.multipleChoice:
        return MCQView(
          question: task.questionText,
          options: task.options,
          selectedIndex: _selectedIndex,
          onOptionSelected: _onOptionSelected,
        );
      case TaskType.listening:
        return ListeningView(
          question: task.questionText,
          options: task.options,
          selectedIndex: _selectedIndex,
          onOptionSelected: _onOptionSelected,
          audioUrl: task.audioUrl,
        );
      case TaskType.sentenceReordering:
        return SentenceReorderingView(
          question: task.questionText,
          scrambledParts: _scrambledParts,
          availableParts: _availableParts,
          onWordTap: (word) {
            HapticService.light();
            setState(() {
              _availableParts.remove(word);
              _scrambledParts.add(word);
            });
          },
          onScrambledWordTap: (word) {
            HapticService.light();
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
            HapticService.selection();
            setState(() {
              if (_matchedPairs.containsKey(native)) {
                _matchedPairs.remove(native);
                return;
              }

              if (_selectedNative == native) {
                _selectedNative = null;
              } else {
                _selectedNative = native;
                if (_selectedMeaning != null) {
                  _matchedPairs[native] = _selectedMeaning!;
                  _selectedNative = null;
                  _selectedMeaning = null;
                  HapticService.success();
                }
              }
            });
          },
          onMeaningTap: (meaning) {
            HapticService.selection();
            setState(() {
              String? matchedNative;
              _matchedPairs.forEach((key, value) {
                if (value == meaning) matchedNative = key;
              });

              if (matchedNative != null) {
                _matchedPairs.remove(matchedNative);
                return;
              }

              if (_selectedMeaning == meaning) {
                _selectedMeaning = null;
              } else {
                _selectedMeaning = meaning;
                if (_selectedNative != null) {
                  _matchedPairs[_selectedNative!] = meaning;
                  _selectedNative = null;
                  _selectedMeaning = null;
                  HapticService.success();
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
          onToggleRecording: _toggleRecording,
          recorderController: _recorderController,
        );
      case TaskType.vocabulary:
        return VocabularyView(
          nativeWord: task.nativeWord,
          translation: task.options.isNotEmpty ? task.options.first : '',
          definition: task.hintMetadata,
          imageUrl: task.imageUrl,
          audioUrl: task.audioUrl,
          isFlipped: _flashcardFlipped,
          onFlip: () {
            HapticService.light();
            setState(() => _flashcardFlipped = !_flashcardFlipped);
          },
        );
      case TaskType.scenario:
        return ScenarioView(
          question: task.questionText,
          scenarioText: task.hintMetadata,
          options: task.options,
          selectedIndex: _selectedIndex,
          onOptionSelected: _onOptionSelected,
        );
      case TaskType.wordHunt:
        return WordHuntView(
          question: task.questionText,
          wordsToFind: task.options,
          foundWords: _foundWords,
          onWordFound: (word) {
            setState(() {
              _foundWords.add(word);
            });
            if (_foundWords.length == task.options.length) {
              HapticService.heavy();
            } else {
              HapticService.medium();
            }
          },
        );
      case TaskType.trueOrFalse:
        return TrueFalseView(
          question: task.questionText,
          selectedIndex: _selectedIndex,
          onOptionSelected: _onOptionSelected,
        );
      case TaskType.fillInTheBlanks:
        // Ensure we have shuffled options including the correct ones
        // In a real app, you might add some distractors
        final options = List<String>.from(task.sentenceParts)..shuffle();
        return FillBlanksView(
          question: task.questionText,
          sentence: task.expectedSentence,
          availableOptions: options,
          selectedBlanks: _selectedBlanks,
          onWordSelected: (index, word) {
            setState(() {
              _selectedBlanks[index] = word;
            });
            HapticService.light();
          },
          onBlankTap: (index) {
            HapticService.light();
            setState(() {
              _selectedBlanks.remove(index);
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizSessionProvider);
    final baseTask = state.currentTask;
    final task = (_isSuddenDeath && _suddenDeathTask != null)
        ? _suddenDeathTask!
        : baseTask;

    if (task != null) {
      _lastTask = task;
    }

    final effectiveTask = task ?? _lastTask;

    if (effectiveTask == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = state.totalTasks == 0
        ? 0.0
        : state.completedCount / state.totalTasks;
    final hearts = ref.watch(studentProvider).hearts;
    final sessionStars = hearts <= 2 ? 1 : (hearts <= 4 ? 2 : 3);
    final distinctMistakeTasks = _taskMistakes.keys.length;

    final lessonId = GoRouterState.of(context).uri.queryParameters['lessonId'];
    final lessonAsync = lessonId != null ? ref.watch(currentLessonProvider(lessonId)) : const AsyncValue.data(null);
    final lessonObj = lessonAsync.value;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showQuitConfirmationDialog();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
        body: ParallaxBackground(
          backgroundImage: 'assets/images/onboarding_bg.png',
          intensity: 15,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  maxBlastForce: 20,
                  minBlastForce: 5,
                  emissionFrequency: 0.05,
                  numberOfParticles: 25,
                  gravity: 0.05,
                  colors: const [
                    AppColors.gold500,
                    Colors.cyanAccent,
                    Colors.purpleAccent,
                    Colors.white,
                  ],
                  createParticlePath: _drawSpiritSoul,
                ),

              ),
              if (_combo >= 10)
                Positioned.fill(
                  child: IgnorePointer(
                    child:
                        Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.4),
                                  width: 8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(
                              color: Colors.red.withValues(alpha: 0.1),
                              duration: 2.seconds,
                            ),
                  ),
                ),

              Column( 

                children: [
                  ProgressHeader(
                    progress: progress,
                    hearts: hearts,
                    lessonId: lessonId,
                    icon: lessonObj != null ? IconUtils.getIconData(lessonObj.icon) : null,
                  ),
                  if (_showLeaderboardSnippet)
                    _buildLeaderboardSnippet(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.forest900 : AppColors.creamBg,
                        boxShadow: _combo >= 5
                            ? [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  blurRadius: 60,
                                  spreadRadius: -10,
                                ),
                              ]
                            : (_combo >= 3
                                  ? [
                                      BoxShadow(
                                        color: AppColors.gold500.withValues(alpha: 0.1),
                                        blurRadius: 40,
                                        spreadRadius: -10,
                                      ),
                                    ]
                                  : []),
                      ),
                      child: Column(
                        children: [
                          ComboIndicator(combo: _combo),
                          if (effectiveTask.grammarTitle != null)
                            GrammarButton(
                              title: effectiveTask.grammarTitle!,
                              description: effectiveTask.grammarDescription ?? '',
                              examples: effectiveTask.grammarExamples ?? [],
                            ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: _isSuddenDeath && _suddenDeathTask != null
                                  ? Column(
                                      children: [
                                        const SuddenDeathBanner(),
                                        const SizedBox(height: 24),
                                        _buildTaskContent(effectiveTask),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (effectiveTask.hintMetadata.isNotEmpty)
                                          _buildEldersWisdomButton(context, effectiveTask),
                                        _buildTaskContent(effectiveTask)
                                            .animate(key: ValueKey(_shakeCounter))
                                            .shakeX(
                                              hz: 6,
                                              curve: Curves.easeInOut,
                                              amount: 5,
                                            ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SessionControlBar(
                    isComplete: _isTaskComplete(effectiveTask),
                    onCheck: () {
                      HapticService.medium();
                      _checkAnswer();
                    },
                  ),
                ],
              ),

              if (_showFeedback)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FeedbackPanel(
                    isCorrect: _lastAnswerCorrect,
                    title: _lastAnswerCorrect ? "Correct!" : "Slipped!",
                    subtitle: _feedbackSubtitle,
                    onContinue: _handleContinue,
                    xpEarned: _lastAnswerCorrect ? _currentTaskXp : null,
                  ),
                ),

              if (_isCelebrating)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: XPCelebration(
                      xpEarned: _calculatedSessionXp,
                      stars: sessionStars,
                      onComplete: () => _showSessionSummary(
                        xpEarned: _calculatedSessionXp,
                        stars: sessionStars,
                        totalTasks: state.totalTasks,
                        distinctMistakeTasks: distinctMistakeTasks,
                        bonusXp: _bonusXp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Path _drawSpiritSoul(Size size) {
    var path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.5,
      size.width * 0.5, size.height * 0.9,
    );
    path.quadraticBezierTo(
      size.width * 0.2, size.height * 0.5,
      size.width * 0.5, size.height * 0.2,
    );
    path.close();
    return path;
  }

  Widget _buildLeaderboardSnippet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold500,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.forest900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "YOU'RE IN THE TOP 3! 🔥",
              style: AppTypography.label.copyWith(
                color: AppColors.forest900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -1.0).fadeIn();
  }

  Widget _buildEldersWisdomButton(BuildContext context, LessonTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          showEldersWisdom(context, task.hintMetadata);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gold500.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.gold500),
              const SizedBox(width: 8),
              Text(
                "ELDERS' WISDOM",
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white12),
      ),
    );
  }
}

