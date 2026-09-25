import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/lesson.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';

class EducatorUnitManagementScreen extends ConsumerStatefulWidget {
  const EducatorUnitManagementScreen({super.key});

  @override
  ConsumerState<EducatorUnitManagementScreen> createState() =>
      _EducatorUnitManagementScreenState();
}

class _EducatorUnitManagementScreenState
    extends ConsumerState<EducatorUnitManagementScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  String _selectedLanguage = 'Mansaka';

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(allLessonsStreamProvider);
    final dialectsAsync = ref.watch(dialectsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Unit Management',
          style: AppTypography.h2ExtraBold.copyWith(color: AppColors.gold500),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gold500),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildLanguageSelector(dialectsAsync),
          Expanded(
            child: lessonsAsync.when(
              data: (lessons) {
                final filteredLessons = lessons
                    .where((l) => l.language == _selectedLanguage)
                    .toList();

                // Sort by unit number
                filteredLessons.sort(
                  (a, b) => a.unitNumber.compareTo(b.unitNumber),
                );

                if (filteredLessons.isEmpty) {
                  return _buildEmptyState();
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLessons.length,
                  onReorderStart: (index) {
                    HapticService.selection();
                  },
                  onReorderItem: (int oldIndex, int newIndex) {
                    _onReorderUnits(oldIndex, newIndex, filteredLessons);
                  },
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];
                    return _buildLessonTile(lesson, index);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold500),
              ),
              error: (e, s) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(AsyncValue<List<String>> dialectsAsync) {
    return dialectsAsync.when(
      data: (dialects) {
        final filteredDialects = dialects.where((d) => d != 'All').toList();
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredDialects.length,
            itemBuilder: (context, index) {
              final dialect = filteredDialects[index];
              final isSelected = _selectedLanguage == dialect;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(dialect),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedLanguage = dialect);
                  },
                  selectedColor: AppColors.gold500,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.forest900
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox(height: 60),
    );
  }

  Widget _buildLessonTile(Lesson lesson, int index) {
    return Container(
      key: ValueKey(lesson.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.creamBorder,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gold500.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: AppTypography.h3.copyWith(
                color: AppColors.gold500,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          lesson.title,
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white : AppColors.creamText,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Unit ${lesson.unitNumber} • Level ${lesson.level}',
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.drag_handle_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_rounded,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No lessons found for $_selectedLanguage',
            style: AppTypography.h3.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onReorderUnits(int oldIndex, int newIndex, List<Lesson> filteredLessons) async {
    HapticService.medium();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final movedLesson = filteredLessons.removeAt(oldIndex);
    filteredLessons.insert(newIndex, movedLesson);

    try {
      final batch = ref.read(firebaseServiceProvider).db.batch();
      for (int i = 0; i < filteredLessons.length; i++) {
        final lesson = filteredLessons[i];
        if (lesson.unitNumber != i + 1) {
          batch.update(
            ref.read(firebaseServiceProvider).db.collection('lessons').doc(lesson.id),
            {'unitNumber': i + 1},
          );
        }
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Units reordered successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reordering units: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }
}



