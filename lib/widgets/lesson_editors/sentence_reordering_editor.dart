import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'editor_utils.dart';

class SentenceReorderingEditor extends StatefulWidget {
  final LessonStep step;
  final VoidCallback onUpdated;

  const SentenceReorderingEditor({
    super.key,
    required this.step,
    required this.onUpdated,
  });

  @override
  State<SentenceReorderingEditor> createState() =>
      _SentenceReorderingEditorState();
}

class _SentenceReorderingEditorState extends State<SentenceReorderingEditor> {
  // Stable IDs for each word chip to prevent state corruption when deleting/reordering
  final List<String> _chipIds = [];

  @override
  void initState() {
    super.initState();
    final List<String> parts = List<String>.from(
      widget.step.data['parts'] ?? [],
    );
    for (int i = 0; i < parts.length; i++) {
      _chipIds.add(
        DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
      );
    }
  }

  void _addWord() {
    final List<String> parts = List<String>.from(
      widget.step.data['parts'] ?? [],
    );
    setState(() {
      parts.add('new');
      _chipIds.add(DateTime.now().microsecondsSinceEpoch.toString());
      widget.step.data['parts'] = parts;
    });
    widget.onUpdated();
  }

  void _removeWord(int index) {
    final List<String> parts = List<String>.from(
      widget.step.data['parts'] ?? [],
    );
    setState(() {
      parts.removeAt(index);
      _chipIds.removeAt(index);
      widget.step.data['parts'] = parts;
    });
    widget.onUpdated();
  }

  void _autoSplit() {
    final sentence = widget.step.data['sentence'] as String? ?? '';
    final newParts = sentence
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .toList();
    setState(() {
      widget.step.data['parts'] = newParts;
      _chipIds.clear();
      for (int i = 0; i < newParts.length; i++) {
        _chipIds.add(
          DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
        );
      }
    });
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> parts = List<String>.from(
      widget.step.data['parts'] ?? [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorUtils.buildDataTextField(
          label: 'Instruction',
          initialValue: widget.step.data['question'] ?? '',
          maxLength: 100,
          onChanged: (val) {
            widget.step.data['question'] = val;
            widget.onUpdated();
          },
          hint: 'e.g. Reconstruct the morning greeting',
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Expected Full Sentence',
          initialValue: widget.step.data['sentence'] ?? '',
          maxLength: 200,
          onChanged: (val) {
            widget.step.data['sentence'] = val;
            widget.onUpdated();
          },
          hint: 'The correct final order.',
        ),
        const SizedBox(height: 24),
        Text(
          'Sentence Chips',
          style: AppTypography.label.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < parts.length; i++)
              _EditableChip(
                key: ValueKey('chip_${_chipIds[i]}'),
                initialValue: parts[i],
                onChanged: (val) {
                  parts[i] = val;
                  widget.step.data['parts'] = parts;
                  widget.onUpdated();
                },
                onDeleted: () => _removeWord(i),
              ),
            ActionChip(
              label: const Text(
                '+ Add Word',
                style: TextStyle(color: AppColors.gold500, fontSize: 12),
              ),
              backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
              onPressed: _addWord,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(
            Icons.auto_fix_high,
            color: AppColors.gold500,
            size: 16,
          ),
          label: const Text(
            'Auto-split from sentence',
            style: TextStyle(color: AppColors.gold500, fontSize: 12),
          ),
          onPressed: _autoSplit,
        ),
      ],
    );
  }
}

class _EditableChip extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onDeleted;

  const _EditableChip({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  State<_EditableChip> createState() => _EditableChipState();
}

class _EditableChipState extends State<_EditableChip> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_EditableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !_isEditing) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 100,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 30,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            counterText: '',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            setState(() => _isEditing = false);
            widget.onChanged(val);
          },
        ),
      );
    }

    return Chip(
      label: InkWell(
        onTap: () => setState(() => _isEditing = true),
        child: Text(
          widget.initialValue,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      backgroundColor: AppColors.forestDarkCard,
      onDeleted: widget.onDeleted,
      deleteIcon: const Icon(Icons.cancel, size: 14, color: Colors.white54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
