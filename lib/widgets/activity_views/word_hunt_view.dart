import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/haptic_service.dart';

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
  late int _gridSize;
  final List<Offset> _selection = [];
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _gridSize = _calculateGridSize();
    _generateGrid();
  }

  @override
  void didUpdateWidget(WordHuntView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wordsToFind != widget.wordsToFind) {
      setState(() {
        _gridSize = _calculateGridSize();
        _generateGrid();
      });
    }
  }

  int _calculateGridSize() {
    int maxLen = 0;
    for (String w in widget.wordsToFind) {
      final normalized = w.replaceAll(' ', '');
      if (normalized.length > maxLen) {
        maxLen = normalized.length;
      }
    }
    // Dynamic grid size: adapt between 7 and 10 based on words
    int size = maxLen + 1;
    if (size < 7) size = 7;
    if (size > 10) size = 10;
    return size;
  }

  void _generateGrid() {
    _grid = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize, (_) => ''),
    );

    final random = Random();
    for (String word in widget.wordsToFind) {
      final normalized = word.toUpperCase().replaceAll(' ', '');
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 120) {
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

    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_grid[r][c].isEmpty) {
          _grid[r][c] = _randomLetter();
        }
      }
    }
  }

  bool _canPlace(String word, int r, int c, int dx, int dy) {
    final endR = r + (word.length - 1) * dy;
    final endC = c + (word.length - 1) * dx;
    if (endR < 0 || endR >= _gridSize) return false;
    if (endC < 0 || endC >= _gridSize) return false;

    for (int i = 0; i < word.length; i++) {
      final existingChar = _grid[r + i * dy][c + i * dx];
      if (existingChar != '' && existingChar != word[i]) {
        return false;
      }
    }
    return true;
  }

  String _randomLetter() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[Random().nextInt(letters.length)];
  }

  void _handlePanStart(DragStartDetails details, double cellSize) {
    setState(() {
      _isSelecting = true;
      _selection.clear();
      _updateSelection(details.localPosition, cellSize);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, double cellSize) {
    if (_isSelecting) {
      _updateSelection(details.localPosition, cellSize);
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

  void _updateSelection(Offset localPosition, double cellSize) {
    int col = (localPosition.dx / cellSize).floor().clamp(0, _gridSize - 1);
    int row = (localPosition.dy / cellSize).floor().clamp(0, _gridSize - 1);

    final start = _selection.isNotEmpty ? _selection.first : Offset(col.toDouble(), row.toDouble());
    int dr = (row - start.dy).toInt();
    int dc = (col - start.dx).toInt();

    // Enforce straight orthogonal or diagonal lines
    if (dr == 0 || dc == 0 || dr.abs() == dc.abs()) {
      final int steps = max(dr.abs(), dc.abs());
      final int stepR = dr == 0 ? 0 : dr.sign;
      final int stepC = dc == 0 ? 0 : dc.sign;

      final List<Offset> newPath = [];
      for (int i = 0; i <= steps; i++) {
        newPath.add(Offset((start.dx + i * stepC), (start.dy + i * stepR)));
      }

      final prevCount = _selection.length;
      final prevLast = _selection.isNotEmpty ? _selection.last : null;

      if (newPath.length != prevCount || (newPath.isNotEmpty && newPath.last != prevLast)) {
        setState(() {
          _selection.clear();
          _selection.addAll(newPath);
        });
        HapticService.light();
      }
    }
  }

  String _getSelectedWord() {
    if (_selection.isEmpty) return '';
    String result = '';
    for (var pos in _selection) {
      result += _grid[pos.dy.toInt()][pos.dx.toInt()];
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
          runSpacing: 8,
          children: widget.wordsToFind.map((w) {
            final isFound = widget.foundWords.contains(w);
            return Opacity(
              opacity: isFound ? 0.3 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFound
                      ? AppColors.semanticGreen
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxGridWidth = min(constraints.maxWidth, 380.0);
              final double cellSize = (maxGridWidth / _gridSize).clamp(28.0, 48.0);
              final double gridDimension = cellSize * _gridSize;

              return GestureDetector(
                onPanStart: (d) => _handlePanStart(d, cellSize),
                onPanUpdate: (d) => _handlePanUpdate(d, cellSize),
                onPanEnd: _handlePanEnd,
                child: Container(
                  width: gridDimension + 8,
                  height: gridDimension + 8,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Selection Line/Pill Canvas Painter
                      if (_selection.isNotEmpty)
                        CustomPaint(
                          size: Size(gridDimension, gridDimension),
                          painter: _WordHuntSelectionPainter(
                            selection: _selection,
                            cellSize: cellSize,
                          ),
                        ),
                      // Grid Letters
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_gridSize, (r) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_gridSize, (c) {
                              final isSelected = _selection.any((p) => p.dx == c && p.dy == r);
                              return Container(
                                width: cellSize,
                                height: cellSize,
                                alignment: Alignment.center,
                                child: Text(
                                  _grid[r][c],
                                  style: AppTypography.mono.copyWith(
                                    color: isSelected
                                        ? AppColors.forest900
                                        : (isDark ? Colors.white : AppColors.forest900),
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                    fontSize: cellSize * 0.45,
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WordHuntSelectionPainter extends CustomPainter {
  final List<Offset> selection;
  final double cellSize;

  _WordHuntSelectionPainter({
    required this.selection,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selection.isEmpty) return;

    final fillPaint = Paint()
      ..color = AppColors.gold500.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.gold500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final linePaint = Paint()
      ..color = AppColors.gold500.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * 0.75
      ..strokeCap = StrokeCap.round;

    final startCenter = Offset(
      (selection.first.dx + 0.5) * cellSize,
      (selection.first.dy + 0.5) * cellSize,
    );

    if (selection.length == 1) {
      canvas.drawCircle(startCenter, cellSize * 0.38, fillPaint);
      canvas.drawCircle(startCenter, cellSize * 0.38, strokePaint);
    } else {
      final endCenter = Offset(
        (selection.last.dx + 0.5) * cellSize,
        (selection.last.dy + 0.5) * cellSize,
      );
      canvas.drawLine(startCenter, endCenter, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WordHuntSelectionPainter oldDelegate) {
    return oldDelegate.selection != selection || oldDelegate.cellSize != cellSize;
  }
}
