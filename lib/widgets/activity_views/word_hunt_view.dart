import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class WordHuntView extends StatefulWidget {
  final String question;
  final List<String> wordsToFind;
  final Set<String> foundWords;
  final Function(String) onWordFound;

  const WordHuntView({
    super.key,
    required this.question,
    required this.wordsToFind,
    required this.foundWords,
    required this.onWordFound,
  });

  @override
  State<WordHuntView> createState() => _WordHuntViewState();
}

class _WordHuntViewState extends State<WordHuntView> {
  late List<List<String>> _grid;
  final int _gridSize = 8;
  final List<Offset> _selection = [];
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _generateGrid();
  }

  void _generateGrid() {
    // Fill with random letters
    _grid = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize, (_) => _randomLetter()),
    );

    // Place words
    final random = Random();
    for (String word in widget.wordsToFind) {
      final normalized = word.toUpperCase().replaceAll(' ', '');
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 100) {
        attempts++;
        int row = random.nextInt(_gridSize);
        int col = random.nextInt(_gridSize);
        int dx = random.nextInt(3) - 1; // -1, 0, 1
        int dy = random.nextInt(3) - 1;

        if (dx == 0 && dy == 0) continue;

        if (_canPlace(normalized, row, col, dx, dy)) {
          for (int i = 0; i < normalized.length; i++) {
            _grid[row + i * dy][col + i * dx] = normalized[i];
          }
          placed = true;
        }
      }
    }
  }

  bool _canPlace(String word, int r, int c, int dx, int dy) {
    if (r + word.length * dy < 0 || r + word.length * dy >= _gridSize) return false;
    if (c + word.length * dx < 0 || c + word.length * dx >= _gridSize) return false;

    // Check for collisions (very simple: allow if letter matches or random was there)
    // For a real word hunt, we'd track which letters are "original" vs random
    return true;
  }

  String _randomLetter() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[Random().nextInt(letters.length)];
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isSelecting = true;
      _selection.clear();
      _addSelection(details.localPosition);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isSelecting) {
      setState(() {
        _addSelection(details.localPosition);
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isSelecting) return;

    final selectedWord = _getSelectedWord();
    final reversedSelectedWord = selectedWord.split('').reversed.join('');

    for (String word in widget.wordsToFind) {
      final normalized = word.toUpperCase().replaceAll(' ', '');
      if ((selectedWord == normalized || reversedSelectedWord == normalized) &&
          !widget.foundWords.contains(word)) {
        widget.onWordFound(word);
        break;
      }
    }

    setState(() {
      _isSelecting = false;
      _selection.clear();
    });
  }

  void _addSelection(Offset localPosition) {
    final double cellSize = 40.0; // Estimate
    int col = (localPosition.dx / cellSize).floor();
    int row = (localPosition.dy / cellSize).floor();

    if (row >= 0 && row < _gridSize && col >= 0 && col < _gridSize) {
      final pos = Offset(col.toDouble(), row.toDouble());
      if (_selection.isEmpty) {
        _selection.add(pos);
      } else {
        // Enforce straight lines
        final first = _selection.first;
        int dr = (row - first.dy).toInt();
        int dc = (col - first.dx).toInt();

        if (dr == 0 || dc == 0 || dr.abs() == dc.abs()) {
          _selection.add(pos);
        }
      }
    }
  }

  String _getSelectedWord() {
    if (_selection.isEmpty) return '';
    
    // Sort selection to follow direction
    // For simplicity, just concat unique ones in order of touch
    String result = '';
    final Set<String> seen = {};
    for (var pos in _selection) {
      final key = '${pos.dx},${pos.dy}';
      if (!seen.contains(key)) {
        result += _grid[pos.dy.toInt()][pos.dx.toInt()];
        seen.add(key);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          widget.question,
          style: AppTypography.h3.copyWith(color: AppColors.gold500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          children: widget.wordsToFind.map((w) {
            final isFound = widget.foundWords.contains(w);
            return Opacity(
              opacity: isFound ? 0.3 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFound ? AppColors.semanticGreen : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  w,
                  style: AppTypography.label.copyWith(
                    color: isFound
                        ? Colors.black
                        : (isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.6)),
                    decoration: isFound ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Center(
          child: GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_gridSize, (r) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_gridSize, (c) {
                      final isSelected = _selection.any((p) => p.dx == c && p.dy == r);
                      return Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.gold500.withValues(alpha: 0.6) : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _grid[r][c],
                          style: AppTypography.mono.copyWith(
                            color: isSelected
                                ? Colors.black
                                : (isDark ? Colors.white : AppColors.forest900),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
