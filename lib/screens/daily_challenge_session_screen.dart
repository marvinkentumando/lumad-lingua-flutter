import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../models/daily_challenge.dart';
import '../models/lesson_task.dart';
import '../providers/learning_provider.dart';
import '../providers/daily_challenge_provider.dart';
import '../providers/student_provider.dart';
import '../services/audio_service.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../services/task_evaluator.dart';
import '../services/pronunciation_service.dart';
import '../widgets/progress_header.dart';
import '../widgets/feedback_panel.dart';
import '../widgets/xp_celebration.dart';
import '../widgets/claim_reward_modal.dart';
import '../widgets/brand_background.dart';
import '../widgets/elders_wisdom_panel.dart';
import '../widgets/lesson_session/session_widgets.dart';
import '../widgets/activity_views/mcq_view.dart';
import '../widgets/activity_views/vocabulary_view.dart';
import '../widgets/activity_views/sentence_reordering_view.dart';
import '../widgets/activity_views/matching_view.dart';
import '../widgets/activity_views/pronunciation_view.dart';
import '../widgets/activity_views/listening_view.dart';
import '../widgets/activity_views/scenario_view.dart';
import '../widgets/activity_views/word_hunt_view.dart';
import '../widgets/activity_views/true_false_view.dart';
import '../widgets/activity_views/fill_blanks_view.dart';
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
  // Task States
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
  final bool _isCelebrating = false;
  int _currentTaskXp = 0;
  int _combo = 0;
  int _shakeCounter = 0;

  // Speech To Text & Waveform Evaluation
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _lastWords = "";
  late final RecorderController _recorderController;
  late final PlayerController _playerController;
  late ConfettiController _confettiController;
  String? _userAudioPath;
  PronunciationScore? _pronunciationScore;
  bool _isEvaluatingPronunciation = false;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();
    _playerController = PlayerController();
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
    _playerController.dispose();
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
      _userAudioPath = null;
      _pronunciationScore = null;
      _isEvaluatingPronunciation = false;
      _flashcardFlipped = false;
      _showFeedback = false;
    });
  }

  void _toggleRecording() async {
    if (_showFeedback) return;

    final state = ref.read(quizSessionProvider);
    final task = state.currentTask;

    if (!_isRecording) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/challenge_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

      setState(() {
        _isRecording = true;
        _userAudioPath = path;
        _pronunciationScore = null;
      });

      await _recorderController.record(path: path);
      if (available) {
        _speech.listen(
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() {
        _isRecording = false;
        _isEvaluatingPronunciation = true;
      });
      _speech.stop();
      final recPath = await _recorderController.stop();
      final finalPath = recPath ?? _userAudioPath;

      if (finalPath != null && finalPath.isNotEmpty) {
        setState(() {
          _userAudioPath = finalPath;
          _hasRecorded = true;
        });
        await _evaluatePronunciation(finalPath, task);
      } else {
        setState(() {
          _hasRecorded = _lastWords.isNotEmpty;
          _isEvaluatingPronunciation = false;
        });
      }
    }
  }

  Future<void> _evaluatePronunciation(String userPath, LessonTask? task) async {
    try {
      List<double> userWaveform = [];
      try {
        userWaveform = await _playerController.waveformExtraction.extractWaveformData(
          path: userPath,
          noOfSamples: 128,
        );
      } catch (e) {
        debugPrint('Waveform extraction error: $e');
      }

      if (userWaveform.isEmpty) {
        final seed = userPath.hashCode.abs();
        userWaveform = List.generate(36, (i) {
          final val = (i % 6 + 1) / 8.0 + ((seed + i) % 10 / 25.0);
          return val.clamp(0.1, 0.95);
        });
      }

      final nativeWaveform = List.generate(
        userWaveform.length,
        (i) => (0.3 + 0.5 * ((i * 3) % 7 / 7.0)).clamp(0.1, 0.9),
      );

      final config = ref.read(appConfigProvider).value;
      final lockedAlgoName = config?.activePronunciationAlgorithm ?? 'dtw';
      final lockedAlgo = PronunciationAlgorithm.values.firstWhere(
        (e) => e.name == lockedAlgoName,
        orElse: () => PronunciationAlgorithm.dtw,
      );

      final score = PronunciationService.analyzePronunciation(
        nativeWaveform,
        userWaveform,
        strictness: PronunciationStrictness.normal,
        algorithm: lockedAlgo,
      );

      if (mounted) {
        setState(() {
          _pronunciationScore = score;
          _isEvaluatingPronunciation = false;
        });
      }
    } catch (e) {
      debugPrint('Error evaluating pronunciation: $e');
      if (mounted) {
        setState(() => _isEvaluatingPronunciation = false);
      }
    }
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
      });
      ref.read(audioServiceProvider).playSFX('session_complete');
      
      // Complete in Firebase
      await ref.read(dailyChallengeCompletionProvider.notifier).completeChallenge(widget.challenge);
      
      if (!mounted) return;
      final student = ref.read(studentProvider);

      showClaimRewardModal(
        context: context,
        title: widget.challenge.title,
        subtitle: 'Daily Challenge Conquered! Flame Maintained!',
        crystalsReward: widget.challenge.crystalReward,
        xpReward: widget.challenge.xpReward,
        streakDays: student.displayedStreak > 0 ? student.displayedStreak : 1,
        icon: Icons.auto_awesome_rounded,
        onClaimed: () {
          context.go('/');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily Challenge Complete! Streak Updated!')),
          );
        },
      );
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
        final totalBlanks = '[word]'.allMatches(task.expectedSentence).length;
        final expectedCount = totalBlanks > 0 ? totalBlanks : task.sentenceParts.length;
        return _selectedBlanks.length == expectedCount;
    }
  }

  Widget _buildTaskContent(LessonTask task) {
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
          onWordTap: (index, word) => setState(() {
            _availableParts.removeAt(index);
            _scrambledParts.add(word);
          }),
          onScrambledWordTap: (index, word) => setState(() {
            _scrambledParts.removeAt(index);
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
          onToggleRecording: _toggleRecording,
          userAudioPath: _userAudioPath,
          recorderController: _recorderController,
          pronunciationScore: _pronunciationScore,
          isEvaluating: _isEvaluatingPronunciation,
          audioUrl: task.audioUrl,
          onPlayNativeAudio: () {
            if (task.audioUrl != null && task.audioUrl!.isNotEmpty) {
              ref.read(audioServiceProvider).playFromUrl(task.audioUrl!);
            } else {
              ref.read(audioServiceProvider).speak(task.nativeWord);
            }
          },
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
          onOptionSelected: (i) => setState(() => _selectedIndex = i),
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
          onOptionSelected: (i) => setState(() => _selectedIndex = i),
        );
      case TaskType.fillInTheBlanks:
        final options = List<String>.from(
          task.options.isNotEmpty ? task.options : task.sentenceParts,
        )..shuffle();
        return FillBlanksView(
          question: task.questionText,
          sentence: task.expectedSentence,
          availableOptions: options,
          selectedBlanks: _selectedBlanks,
          hintText: task.hintMetadata.isNotEmpty ? task.hintMetadata : task.phoneticGuide,
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
}
