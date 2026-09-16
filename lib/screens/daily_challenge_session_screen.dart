import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../models/daily_challenge.dart';
import '../models/lesson_task.dart';
import '../providers/learning_provider.dart';
import '../providers/daily_challenge_provider.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/task_evaluator.dart';
import '../widgets/progress_header.dart';
import '../widgets/feedback_panel.dart';
import '../widgets/xp_celebration.dart';
import '../widgets/brand_background.dart';
import '../widgets/elders_wisdom_panel.dart';
import '../widgets/lesson_session/session_widgets.dart';
import '../widgets/activity_views/mcq_view.dart';
import '../widgets/activity_views/vocabulary_view.dart';
import '../widgets/activity_views/sentence_reordering_view.dart';
import '../widgets/activity_views/matching_view.dart';
import '../widgets/activity_views/pronunciation_view.dart';
import '../widgets/activity_views/listening_view.dart';
import '../providers/student_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:confetti/confetti.dart';

class DailyChallengeSessionScreen extends ConsumerStatefulWidget {
  final DailyChallenge challenge;
  const DailyChallengeSessionScreen({super.key, required this.challenge});

  @override
  ConsumerState<DailyChallengeSessionScreen> createState() =>
      _DailyChallengeSessionScreenState();
}

class _DailyChallengeSessionScreenState
    extends ConsumerState<DailyChallengeSessionScreen> {
  // Task States (copied from LessonSessionScreen)
  int? _selectedIndex;
  final Set<String> _foundWords = {};
  final Map<int, String> _selectedBlanks = {};
  List<String> _scrambledParts = [];
  List<String> _availableParts = [];
  Map<String, String> _matchedPairs = {};
  String? _selectedNative;
  String? _selectedMeaning;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _flashcardFlipped = false;
  bool _showFeedback = false;
  bool _lastAnswerCorrect = false;
  String _feedbackSubtitle = "";
  bool _isCelebrating = false;
  int _currentTaskXp = 0;
  int _combo = 0;
  int _shakeCounter = 0;

  final stt.SpeechToText _speech = stt.SpeechToText();
  String _lastWords = "";
  late final RecorderController _recorderController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizSessionProvider.notifier).loadTasks(widget.challenge.tasks);
      _initTaskState();
      ref.read(audioServiceProvider).playAmbientMusic('Daily Challenge');
    });
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _confettiController.dispose();
    _speech.stop();
    ref.read(audioServiceProvider).stopAmbientMusic();
    super.dispose();
  }

  void _initTaskState() {
    final state = ref.read(quizSessionProvider);
    final task = state.currentTask;
    if (task == null) return;

    setState(() {
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
    });
  }

  void _checkAnswer() {
    if (_showFeedback) return;

    final state = ref.read(quizSessionProvider);
    final task = state.currentTask;
    if (task == null) return;

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

    ref.read(quizSessionProvider.notifier).submitAnswer(isCorrect);

    setState(() {
      _lastAnswerCorrect = isCorrect;
      _showFeedback = true;
      if (!isCorrect) {
        _shakeCounter++;
        _combo = 0;
        HapticService.error();
        ref.read(audioServiceProvider).playSFX('error');
      } else {
        _combo++;
        HapticService.success();
        ref.read(audioServiceProvider).playSFX('success');
        _currentTaskXp = 20 + (_combo >= 3 ? 10 : 0);
        if (_combo >= 5) _confettiController.play();
      }
    });
  }

  void _handleContinue() async {
    final state = ref.read(quizSessionProvider);

    if (state.isCompleted) {
      setState(() {
        _showFeedback = false;
        _isCelebrating = true;
      });
      ref.read(audioServiceProvider).playSFX('session_complete');
      
      // Complete in Firebase
      await ref.read(dailyChallengeCompletionProvider.notifier).completeChallenge(widget.challenge);
      
    } else {
      _initTaskState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizSessionProvider);
    final task = state.currentTask;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (task == null && !state.isCompleted) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = state.totalTasks == 0 ? 0.0 : state.completedCount / state.totalTasks;

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: BrandBackground(
        child: Stack(
          children: [
            Column(
              children: [
                ProgressHeader(
                  progress: progress,
                  hearts: ref.watch(studentProvider).hearts,
                  lessonId: 'daily-challenge',
                  icon: Icons.auto_awesome_rounded,
                ),
                Expanded(
                  child: Column(
                    children: [
                      ComboIndicator(combo: _combo),
                      if (task != null)
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.hintMetadata.isNotEmpty)
                                  _buildEldersWisdomButton(context, task),
                                _buildTaskContent(task)
                                    .animate(key: ValueKey(_shakeCounter))
                                    .shakeX(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SessionControlBar(
                  isComplete: task != null && _isTaskComplete(task),
                  onCheck: _checkAnswer,
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
                  title: _lastAnswerCorrect ? "Sacred Accuracy!" : "Spirit Diverged",
                  subtitle: _feedbackSubtitle,
                  onContinue: _handleContinue,
                  xpEarned: _lastAnswerCorrect ? _currentTaskXp : null,
                ),
              ),
            if (_isCelebrating)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.9),
                  child: XPCelebration(
                    xpEarned: widget.challenge.xpReward,
                    stars: 3,
                    onComplete: () {
                      context.go('/');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Daily Challenge Complete! Streak Updated!')),
                      );
                    },
                  ),
                ),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods (Simplified versions from LessonSessionScreen)
  Widget _buildEldersWisdomButton(BuildContext context, LessonTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: () => showEldersWisdom(context, task.hintMetadata),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gold500.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.gold500),
              SizedBox(width: 8),
              Text("ELDERS' WISDOM", style: TextStyle(color: AppColors.gold500, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildTaskContent(LessonTask task) {
    // This could be refactored into a shared widget, but for now we'll duplicate or call the same views
    switch (task.type) {
      case TaskType.multipleChoice:
        return MCQView(
          question: task.questionText,
          options: task.options,
          selectedIndex: _selectedIndex,
          onOptionSelected: (i) => setState(() => _selectedIndex = i),
        );
      case TaskType.listening:
        return ListeningView(
          question: task.questionText,
          options: task.options,
          selectedIndex: _selectedIndex,
          onOptionSelected: (i) => setState(() => _selectedIndex = i),
          audioUrl: task.audioUrl,
        );
      case TaskType.sentenceReordering:
        return SentenceReorderingView(
          question: task.questionText,
          scrambledParts: _scrambledParts,
          availableParts: _availableParts,
          onWordTap: (word) => setState(() {
            _availableParts.remove(word);
            _scrambledParts.add(word);
          }),
          onScrambledWordTap: (word) => setState(() {
            _scrambledParts.remove(word);
            _availableParts.add(word);
          }),
        );
      case TaskType.matching:
        return MatchingView(
          question: task.questionText,
          pairs: task.pairs,
          matchedPairs: _matchedPairs,
          selectedNative: _selectedNative,
          selectedMeaning: _selectedMeaning,
          onNativeTap: (n) => setState(() {
            _selectedNative = n;
            if (_selectedMeaning != null) {
              _matchedPairs[n] = _selectedMeaning!;
              _selectedNative = null;
              _selectedMeaning = null;
            }
          }),
          onMeaningTap: (m) => setState(() {
            _selectedMeaning = m;
            if (_selectedNative != null) {
              _matchedPairs[_selectedNative!] = m;
              _selectedNative = null;
              _selectedMeaning = null;
            }
          }),
        );
      case TaskType.pronunciation:
        return PronunciationView(
          question: task.questionText,
          word: task.nativeWord,
          phonetic: task.phoneticGuide,
          isRecording: _isRecording,
          hasRecorded: _hasRecorded,
          onToggleRecording: () async {
            if (!_isRecording) {
              bool available = await _speech.initialize();
              if (available) {
                setState(() => _isRecording = true);
                await _recorderController.record();
                _speech.listen(onResult: (val) => setState(() => _lastWords = val.recognizedWords));
              }
            } else {
              setState(() => _isRecording = false);
              _speech.stop();
              await _recorderController.stop();
              if (_lastWords.isNotEmpty) setState(() => _hasRecorded = true);
            }
          },
          recorderController: _recorderController,
        );
      case TaskType.vocabulary:
        return VocabularyView(
          nativeWord: task.nativeWord,
          translation: task.options.first,
          definition: task.hintMetadata,
          isFlipped: _flashcardFlipped,
          onFlip: () => setState(() => _flashcardFlipped = !_flashcardFlipped),
        );
      default:
        return const Center(child: Text('Task type not supported in Daily Challenge yet.'));
    }
  }
}
