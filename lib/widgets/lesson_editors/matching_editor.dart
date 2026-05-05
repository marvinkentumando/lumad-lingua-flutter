import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'editor_utils.dart';

class MatchingEditor extends StatefulWidget {
  final LessonStep step;
  final VoidCallback onUpdated;

  const MatchingEditor({
    super.key,
    required this.step,
    required this.onUpdated,
  });

  @override
  State<MatchingEditor> createState() => _MatchingEditorState();
}

class _MatchingEditorState extends State<MatchingEditor> {
  // We use a local ID for each pair to ensure stable keys when items are removed
  final List<String> _pairIds = [];

  @override
  void initState() {
    super.initState();
    final pairs = widget.step.data['pairs'] as List;
    for (int i = 0; i < pairs.length; i++) {
      _pairIds.add(
        DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
      );
    }
  }

  void _addPair() {
    final pairs = widget.step.data['pairs'] as List;
    setState(() {
      pairs.add({'native': '', 'meaning': ''});
      _pairIds.add(DateTime.now().microsecondsSinceEpoch.toString());
    });
    widget.onUpdated();
  }

  void _removePair(int index) {
    final pairs = widget.step.data['pairs'] as List;
    setState(() {
      pairs.removeAt(index);
      _pairIds.removeAt(index);
    });
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.step.data['pairs'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorUtils.buildDataTextField(
          label: 'Instruction',
          initialValue: widget.step.data['question'] ?? '',
          maxLength: 150,
          onChanged: (val) {
            widget.step.data['question'] = val;
            widget.onUpdated();
          },
          hint: 'e.g. Match the animals to their meanings',
        ),
        const SizedBox(height: 24),
        Text(
          'Matching Pairs',
          style: AppTypography.label.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < pairs.length; i++) ...[
          Row(
            key: ValueKey('pair_row_${_pairIds[i]}'),
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: pairs[i]['native'],
                  style: const TextStyle(color: Colors.white),
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: 'Native',
                    filled: true,
                    fillColor: AppColors.forestDarkCard,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    pairs[i]['native'] = val;
                    widget.onUpdated();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: pairs[i]['meaning'],
                  style: const TextStyle(color: Colors.white),
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: 'Meaning',
                    filled: true,
                    fillColor: AppColors.forestDarkCard,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    pairs[i]['meaning'] = val;
                    widget.onUpdated();
                  },
                ),
              ),
              if (pairs.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Colors.white24,
                    size: 20,
                  ),
                  onPressed: () => _removePair(i),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextButton.icon(
          icon: const Icon(Icons.add_rounded, color: AppColors.gold500),
          label: const Text(
            'Add Pair',
            style: TextStyle(color: AppColors.gold500),
          ),
          onPressed: _addPair,
        ),
      ],
    );
  }
}


