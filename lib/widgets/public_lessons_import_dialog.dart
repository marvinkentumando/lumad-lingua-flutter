import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson.dart';
import '../providers/educator_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PublicLessonsImportDialog extends ConsumerStatefulWidget {
  const PublicLessonsImportDialog({super.key});

  @override
  ConsumerState<PublicLessonsImportDialog> createState() =>
      _PublicLessonsImportDialogState();
}

class _PublicLessonsImportDialogState
    extends ConsumerState<PublicLessonsImportDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLanguage = 'All';
  final Set<String> _importingLessonIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicLessonsAsync = ref.watch(publicLessonsProvider);
    final user = ref.watch(authStateProvider).value;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.library_add_rounded,
                    color: AppColors.gold500,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Public Lessons',
                        style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Copy master lessons into your village library to edit independently.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search public curriculum...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: publicLessonsAsync.when(
                data: (publicLessons) {
                  final filtered = publicLessons.where((l) {
                    final query = _searchController.text.toLowerCase();
                    final matchesQuery = l.title.toLowerCase().contains(query) ||
                        l.category.toLowerCase().contains(query) ||
                        l.language.toLowerCase().contains(query);
                    final matchesLang = _selectedLanguage == 'All' || l.language == _selectedLanguage;
                    return matchesQuery && matchesLang;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.style_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No public lessons available to import.',
                            style: AppTypography.body.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lesson = filtered[index];
                      final isImporting = _importingLessonIds.contains(lesson.id);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.gold500.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${lesson.unitNumber}',
                                style: AppTypography.h3.copyWith(color: AppColors.gold500),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${lesson.language} • ${lesson.category} • ${lesson.tasks.length} tasks',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: isImporting || user == null
                                  ? null
                                  : () => _importLesson(lesson, user.uid),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold500,
                                foregroundColor: AppColors.forest900,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: isImporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.download_rounded, size: 18),
                              label: Text(isImporting ? 'Importing...' : 'Import'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading public lessons: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importLesson(Lesson lesson, String userId) async {
    setState(() {
      _importingLessonIds.add(lesson.id);
    });

    try {
      final newLessonId = await ref
          .read(firebaseServiceProvider)
          .importPublicLessonToVillage(
            publicLessonId: lesson.id,
            educatorId: userId,
          );

      if (mounted && newLessonId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${lesson.title}" into your Village Lessons!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not import lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _importingLessonIds.remove(lesson.id);
        });
      }
    }
  }
}
