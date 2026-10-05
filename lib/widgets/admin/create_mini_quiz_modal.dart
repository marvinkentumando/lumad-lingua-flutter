import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/educator_models.dart';
import '../../models/lesson_task.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../brand_button.dart';
import '../brand_text_field.dart';

class CreateMiniQuizModal extends ConsumerStatefulWidget {
  const CreateMiniQuizModal({super.key});

  @override
  ConsumerState<CreateMiniQuizModal> createState() => _CreateMiniQuizModalState();
}

class _CreateMiniQuizModalState extends ConsumerState<CreateMiniQuizModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _dialect = 'Mansaka';
  bool _assignImmediately = true;
  bool _isSaving = false;

  final List<LessonTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    // Default task
    _tasks.add(
      LessonTask(
        id: 'task_1',
        type: TaskType.multipleChoice,
        questionText: 'What is the Mansaka term for "Good Morning"?',
        options: const ['Madyaw na dumaw', 'Madyaw na mahalluk', 'Madayaw'],
        correctAnswerIndex: 0,
        hintMetadata: '',
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addTask(TaskType type) {
    setState(() {
      final newId = 'task_${DateTime.now().millisecondsSinceEpoch}';
      if (type == TaskType.multipleChoice) {
        _tasks.add(
          LessonTask(
            id: newId,
            type: TaskType.multipleChoice,
            questionText: 'Question ${_tasks.length + 1}',
            options: ['Option A', 'Option B', 'Option C'],
            correctAnswerIndex: 0,
            hintMetadata: '',
          ),
        );
      } else if (type == TaskType.trueOrFalse) {
        _tasks.add(
          LessonTask(
            id: newId,
            type: TaskType.trueOrFalse,
            questionText: 'Statement ${_tasks.length + 1}',
            correctAnswerIndex: 0,
            hintMetadata: '',
          ),
        );
      } else if (type == TaskType.fillInTheBlanks) {
        _tasks.add(
          LessonTask(
            id: newId,
            type: TaskType.fillInTheBlanks,
            questionText: 'Fill in the blank',
            expectedSentence: 'Sentence with [word]',
            sentenceParts: ['word'],
            hintMetadata: '',
          ),
        );
      } else {
        _tasks.add(
          LessonTask(
            id: newId,
            type: TaskType.matching,
            questionText: 'Match the terms',
            pairs: const [
              {'native': 'Madyaw', 'meaning': 'Good'},
              {'native': 'Kanatong', 'meaning': 'Our'},
            ],
            hintMetadata: '',
          ),
        );
      }
    });
  }

  Future<void> _saveQuiz() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question to the mini-quiz.'),
          backgroundColor: AppColors.semanticRed,
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    final educatorId = user?.uid ?? '';

    setState(() => _isSaving = true);
    try {
      final quiz = VillageMiniQuiz(
        id: '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        educatorId: educatorId,
        dialect: _dialect,
        tasks: _tasks,
        createdAt: DateTime.now(),
        isAssigned: _assignImmediately,
      );

      await ref.read(firebaseServiceProvider).createVillageMiniQuiz(quiz);

      if (mounted) {
        HapticService.success();
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mini-Quiz "${quiz.title}" created & assigned!'),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create mini-quiz: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialectsAsync = ref.watch(dialectsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest800 : AppColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : AppColors.creamBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Mini-Quiz',
                        style: AppTypography.h2.copyWith(
                          color: isDark ? Colors.white : AppColors.forest900,
                        ),
                      ),
                      Text(
                        'Build a custom assessment for village learners',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white54 : AppColors.forest700.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandTextField(
                      controller: _titleCtrl,
                      labelText: 'Quiz Title',
                      prefixIcon: Icons.quiz_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter quiz title' : null,
                    ),
                    const SizedBox(height: 16),
                    BrandTextField(
                      controller: _descCtrl,
                      labelText: 'Instructions / Description',
                      prefixIcon: Icons.description_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Language / Dialect', isDark),
                    dialectsAsync.when(
                      data: (list) => DropdownButtonFormField<String>(
                        initialValue: list.contains(_dialect) ? _dialect : list.firstWhere((e) => e != 'All', orElse: () => 'Mansaka'),
                        dropdownColor: isDark ? AppColors.forest800 : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: _inputDecoration(isDark),
                        items: list.where((d) => d != 'All').map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _dialect = v!),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      value: _assignImmediately,
                      activeTrackColor: AppColors.gold500,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Assign Immediately to Village',
                        style: AppTypography.body.copyWith(
                          color: isDark ? Colors.white : AppColors.forest900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Learners in your village will see this assessment on their Sanctuary screen.',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white54 : AppColors.forest700.withValues(alpha: 0.6),
                        ),
                      ),
                      onChanged: (val) => setState(() => _assignImmediately = val),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'QUESTIONS (${_tasks.length})',
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        PopupMenuButton<TaskType>(
                          onSelected: _addTask,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.gold500.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add, color: AppColors.gold500, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'ADD QUESTION',
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.gold500,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: TaskType.multipleChoice, child: Text('Multiple Choice')),
                            PopupMenuItem(value: TaskType.trueOrFalse, child: Text('True or False')),
                            PopupMenuItem(value: TaskType.fillInTheBlanks, child: Text('Fill in the Blanks')),
                            PopupMenuItem(value: TaskType.matching, child: Text('Matching Game')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._tasks.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final task = entry.value;
                      return _buildTaskEditorCard(idx, task, isDark);
                    }),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: BrandButton(
                        text: _isSaving ? 'SAVING...' : 'CREATE & ASSIGN',
                        type: BrandButtonType.primary,
                        onTap: _isSaving ? null : _saveQuiz,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskEditorCard(int index, LessonTask task, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Q${index + 1} • ${task.type.name.toUpperCase()}',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.semanticRed, size: 18),
                onPressed: () => setState(() => _tasks.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: task.questionText,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: _inputDecoration(isDark, hint: 'Question text'),
            onChanged: (val) {
              _tasks[index] = task.copyWith(questionText: val);
            },
          ),
          if (task.type == TaskType.multipleChoice) ...[
            const SizedBox(height: 12),
            ...List.generate(task.options.length, (optIdx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    // ignore: deprecated_member_use
                    Radio<int>(
                      value: optIdx,
                      // ignore: deprecated_member_use
                      groupValue: task.correctAnswerIndex,
                      fillColor: WidgetStateProperty.all(AppColors.gold500),
                      // ignore: deprecated_member_use
                      onChanged: (v) {
                        setState(() {
                          _tasks[index] = task.copyWith(correctAnswerIndex: v ?? 0);
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: task.options[optIdx],
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: _inputDecoration(isDark, hint: 'Option ${optIdx + 1}'),
                        onChanged: (val) {
                          final newOpts = List<String>.from(task.options);
                          newOpts[optIdx] = val;
                          _tasks[index] = task.copyWith(options: newOpts);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label.copyWith(
          color: isDark ? Colors.white38 : AppColors.creamText3,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}
