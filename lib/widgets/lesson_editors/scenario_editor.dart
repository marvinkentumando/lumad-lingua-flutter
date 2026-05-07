import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'editor_utils.dart';

class ScenarioEditor extends StatelessWidget {
  final LessonStep step;
  final VoidCallback onUpdated;

  const ScenarioEditor({
    super.key,
    required this.step,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final options = step.data['options'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorUtils.buildImageAttachment(
          context: context,
          currentImageUrl: step.data['imageUrl'],
          onUploadComplete: (url) {
            step.data['imageUrl'] = url;
            onUpdated();
          },
        ),
        const SizedBox(height: 24),
        EditorUtils.buildDataTextField(
          label: 'Situation Context',
          initialValue: step.data['scenarioText'] ?? '',
          maxLength: 400,
          onChanged: (val) {
            step.data['scenarioText'] = val;
            onUpdated();
          },
          hint: 'Describe the scene...',
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Question/Prompt',
          initialValue: step.data['question'] ?? '',
          maxLength: 150,
          onChanged: (val) {
            step.data['question'] = val;
            onUpdated();
          },
          hint: 'What should the student do?',
        ),
        const SizedBox(height: 24),
        Text(
          'Responses',
          style: AppTypography.label.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (int i = 0; i < options.length; i++) ...[
              Row(
                key: ValueKey('scenario_opt_row_${step.id}_$i'),
                children: [
                  RadioMenuButton<int>(
                    value: i,
                    groupValue: step.data['correctIndex'],
                    onChanged: (val) {
                      step.data['correctIndex'] = val!;
                      onUpdated();
                    },
                    child: const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('scenario_opt_input_${step.id}_$i'),
                      initialValue: options[i],
                      style: const TextStyle(color: Colors.white),
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'Response ${i + 1}',
                        filled: true,
                        fillColor: AppColors.forestDarkCard,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        options[i] = val;
                        onUpdated();
                      },
                    ),
                  ),
                  if (options.length > 2)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.white24,
                        size: 20,
                      ),
                      onPressed: () {
                        options.removeAt(i);
                        if (step.data['correctIndex'] >= options.length) {
                          step.data['correctIndex'] = options.length - 1;
                        }
                        onUpdated();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
        TextButton.icon(
          icon: const Icon(Icons.add_rounded, color: AppColors.gold500),
          label: const Text(
            'Add Response',
            style: TextStyle(color: AppColors.gold500),
          ),
          onPressed: () {
            options.add('');
            onUpdated();
          },
        ),
      ],
    );
  }
}



