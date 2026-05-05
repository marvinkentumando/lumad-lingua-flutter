import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../services/srs_service.dart';

enum QuizTaskType { mcq, matching, scrambled, audio }

class QuizTask {
  final QuizTaskType type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final List<String> validOrders;
  final Map<String, String> matchingPairs;
  final String? audioUrl;

  const QuizTask({
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.validOrders = const [],
    this.matchingPairs = const {},
    this.audioUrl,
  });
}

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;

  final List<QuizTask> _tasks = [
    const QuizTask(
      type: QuizTaskType.mcq,
      question: "How do you say 'Good Morning' in Mansaka?",
      options: ["Maayong Buntag", "Maayong Hapon", "Maayong Gabi", "Salamat"],
      correctAnswer: "Maayong Buntag",
    ),
    const QuizTask(
      type: QuizTaskType.matching,
      question: "Match the Family Terms",
      options: ["Ina", "Ama", "Opo", "Mother", "Father", "Grandparent"],
      correctAnswer: "",
      matchingPairs: {"Ina": "Mother", "Ama": "Father", "Opo": "Grandparent"},
    ),
    const QuizTask(
      type: QuizTaskType.scrambled,
      question: "Reorder to say: 'Good Morning Friend'",
      options: ["Friend", "Morning", "Good"],
      correctAnswer: "Good Morning Friend",
      validOrders: ["Good Morning Friend", "Good Friend Morning"],
    ),
  ];

  List<String> _scrambledCurrent = [];
  List<String> _matchingLeft = [];
  List<String> _matchingRight = [];
  String? _selectedLeft;
  String? _selectedRight;
  final Set<String> _matchedKeys = {};

  @override
  void initState() {
    super.initState();
    _initializeTaskState();
  }

  void _initializeTaskState() {
    final task = _tasks[_currentIndex];
    if (task.type == QuizTaskType.scrambled) {
      _scrambledCurrent = List.from(task.options)..shuffle();
    } else if (task.type == QuizTaskType.matching) {
      _matchingLeft = task.matchingPairs.keys.toList()..shuffle();
      _matchingRight = task.matchingPairs.values.toList()..shuffle();
    }
    _selectedLeft = null;
    _selectedRight = null;
    _matchedKeys.clear();
  }

  void _handleAnswer(bool correct) {
    if (correct) _score += 10;

    ref
        .read(srsServiceProvider)
        .recordAttempt(_currentIndex.toString(), correct);

    setState(() {
      if (_currentIndex < _tasks.length - 1) {
        _currentIndex++;
        _initializeTaskState();
      } else {
        _isFinished = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildResultScreen();
    final task = _tasks[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.forest800,
      appBar: AppBar(
        title: Text("Quest: ${_currentIndex + 1}/${_tasks.length}"),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _tasks.length,
              backgroundColor: AppColors.forest700,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold500),
            ),
            const SizedBox(height: 40),
            BrandCard(
              theme: BrandCardTheme.cream,
              child: Column(
                children: [
                  Text(
                    _getTaskEmoji(task.type),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    task.question,
                    style: AppTypography.h2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(child: _buildTaskInput(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInput(QuizTask task) {
    switch (task.type) {
      case QuizTaskType.mcq:
        return ListView(
          children: task.options
              .map(
                (opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BrandButton(
                    text: opt,
                    type: BrandButtonType.secondary,
                    onTap: () => _handleAnswer(opt == task.correctAnswer),
                  ),
                ),
              )
              .toList(),
        );
      case QuizTaskType.scrambled:
        return Column(
          children: [
            Wrap(
              spacing: 8,
              children: _scrambledCurrent
                  .map(
                    (word) => ActionChip(
                      label: Text(word),
                      backgroundColor: AppColors.forest700,
                      labelStyle: const TextStyle(color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _scrambledCurrent.remove(word);
                          _scrambledCurrent.add(word);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
            BrandButton(
              text: "Check Translation",
              onTap: () {
                final result = _scrambledCurrent.join(" ");
                _handleAnswer(
                  task.validOrders.contains(result) ||
                      result == task.correctAnswer,
                );
              },
            ),
          ],
        );
      case QuizTaskType.matching:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      children: _matchingLeft
                          .map((opt) => _buildMatchChip(opt, isLeft: true))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ListView(
                      children: _matchingRight
                          .map((opt) => _buildMatchChip(opt, isLeft: false))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return Center(
          child: BrandButton(
            text: "Continue",
            onTap: () => _handleAnswer(true),
          ),
        );
    }
  }

  Widget _buildMatchChip(String text, {required bool isLeft}) {
    bool isSelected = isLeft
        ? (_selectedLeft == text)
        : (_selectedRight == text);
    bool isMatched = isLeft
        ? _matchedKeys.contains(text)
        : _matchedKeys.contains(
            _tasks[_currentIndex].matchingPairs.entries
                .firstWhere((e) => e.value == text)
                .key,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandButton(
        text: text,
        type: isMatched
            ? BrandButtonType.primary
            : (isSelected
                  ? BrandButtonType.primary
                  : BrandButtonType.secondary),
        onTap: isMatched
            ? null
            : () {
                setState(() {
                  if (isLeft) {
                    _selectedLeft = text;
                  } else {
                    _selectedRight = text;
                  }

                  if (_selectedLeft != null && _selectedRight != null) {
                    if (_tasks[_currentIndex].matchingPairs[_selectedLeft] ==
                        _selectedRight) {
                      _matchedKeys.add(_selectedLeft!);
                      _selectedLeft = null;
                      _selectedRight = null;
                      if (_matchedKeys.length ==
                          _tasks[_currentIndex].matchingPairs.length) {
                        _handleAnswer(true);
                      }
                    } else {
                      _selectedLeft = null;
                      _selectedRight = null;
                    }
                  }
                });
              },
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      backgroundColor: AppColors.forest800,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🏆", style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                "Ancestral Mastery",
                style: AppTypography.display.copyWith(
                  color: AppColors.gold500,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your IQ session earned $_score XP!",
                style: AppTypography.h3.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              BrandButton(
                text: "Return to Trail",
                type: BrandButtonType.primary,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTaskEmoji(QuizTaskType type) {
    switch (type) {
      case QuizTaskType.mcq:
        return "❓";
      case QuizTaskType.matching:
        return "🧩";
      case QuizTaskType.scrambled:
        return "🔠";
      case QuizTaskType.audio:
        return "🎧";
    }
  }
}
