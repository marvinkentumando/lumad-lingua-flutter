import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/lesson.dart';
import '../models/school_year.dart';
import '../providers/educator_provider.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../utils/app_localization.dart';

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
    final userAuth = ref.watch(authStateProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    final role = profile?['role']?.toString().toLowerCase();
    final educatorId = userAuth?.uid ?? '';
    final isAdmin = role == 'admin';

    final lessonsAsync = ref.watch(allLessonsStreamProvider);
    final dialectsAsync = ref.watch(dialectsProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.translate('unit_management'),
          style: AppTypography.h2ExtraBold.copyWith(color: AppColors.gold500),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gold500),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: AppColors.gold500),
            tooltip: 'Manage School Years',
            onPressed: () => _showManageSchoolYearsDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLanguageSelector(dialectsAsync),
          Expanded(
            child: lessonsAsync.when(
              data: (lessons) {
                final filteredLessons = lessons.where((l) {
                  if (l.language != _selectedLanguage) return false;
                  if (isAdmin) {
                    return l.educatorId == null || l.educatorId!.isEmpty || l.educatorId == educatorId;
                  }
                  return l.educatorId == educatorId;
                }).toList();

                // Sort by unit number
                filteredLessons.sort(
                  (a, b) => a.unitNumber.compareTo(b.unitNumber),
                );

                if (filteredLessons.isEmpty) {
                  return _buildEmptyState();
                }

                return ReorderableListView(
                  padding: const EdgeInsets.all(16),
                  onReorderStart: (index) {
                    HapticService.selection();
                  },
                  onReorderItem: (int oldIndex, int newIndex) {
                    _onReorderUnits(oldIndex, newIndex, filteredLessons);
                  },
                  children: List.generate(
                    filteredLessons.length,
                    (index) => _buildLessonTile(filteredLessons[index], index),
                  ),
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

  void _showManageSchoolYearsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final schoolYearsAsync = ref.watch(schoolYearsStreamProvider);
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                const Icon(Icons.date_range_rounded, color: AppColors.gold500),
                const SizedBox(width: 8),
                Text('Manage School Years', style: AppTypography.h3.copyWith(color: AppColors.gold500)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: schoolYearsAsync.when(
                data: (years) {
                  if (years.isEmpty) {
                    return const Center(child: Text('No custom school years configured. Using default presets.'));
                  }
                  return ListView.builder(
                    itemCount: years.length,
                    itemBuilder: (context, index) {
                      final sy = years[index];
                      return ListTile(
                        title: Text(sy.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${sy.startDate.toLocal().toString().split(' ')[0]} to ${sy.endDate.toLocal().toString().split(' ')[0]}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                          onPressed: () async {
                            HapticService.medium();
                            await ref.read(firebaseServiceProvider).deleteSchoolYear(sy.id);
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
                icon: const Icon(Icons.add_rounded, color: Colors.black),
                label: const Text('Add School Year', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  Navigator.pop(context);
                  _showAddSchoolYearDialog(context, ref);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSchoolYearDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Add New School Year', style: AppTypography.h3.copyWith(color: AppColors.gold500)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'School Year Name (e.g. 2027-2028)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(startDate.toLocal().toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.gold500),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setStateModal(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(endDate.toLocal().toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.gold500),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setStateModal(() => endDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
              child: const Text('Save', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                HapticService.celebration();
                final sy = SchoolYear(
                  id: '',
                  name: nameController.text.trim(),
                  startDate: startDate,
                  endDate: endDate,
                  isActive: true,
                );
                await ref.read(firebaseServiceProvider).addSchoolYear(sy);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}



