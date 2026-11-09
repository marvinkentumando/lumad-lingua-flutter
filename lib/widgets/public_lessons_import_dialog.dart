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
  bool _isImportingAll = false;
  int _importProgress = 0;
  int _importTotal = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicLessonsAsync = ref.watch(publicLessonsProvider);
    final educatorLessonsAsync = ref.watch(educatorLessonsProvider);
    final user = ref.watch(authStateProvider).value;

    // Collect set of titles already imported into this village
    final alreadyImportedTitles = <String>{};
    educatorLessonsAsync.whenData((eduLessons) {
      for (var l in eduLessons) {
        alreadyImportedTitles.add(l.title.toLowerCase());
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.88,
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 750),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
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

            // Search Bar & Import All Action Header
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search curriculum by title, category, language...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Content Area
            Expanded(
              child: publicLessonsAsync.when(
                data: (publicLessons) {
                  // Extract available languages for filter chips
                  final languages = <String>{'All'};
                  for (var l in publicLessons) {
                    if (l.language.isNotEmpty) languages.add(l.language);
                  }

                  // Filter lessons
                  final filtered = publicLessons.where((l) {
                    final query = _searchController.text.toLowerCase();
                    final matchesQuery = l.title.toLowerCase().contains(query) ||
                        l.category.toLowerCase().contains(query) ||
                        l.language.toLowerCase().contains(query);
                    final matchesLang = _selectedLanguage == 'All' || l.language == _selectedLanguage;
                    return matchesQuery && matchesLang;
                  }).toList();

                  // Sort by unit number ascending for intuitive learning path ordering
                  filtered.sort((a, b) {
                    final langCompare = a.language.compareTo(b.language);
                    if (langCompare != 0) return langCompare;
                    return a.unitNumber.compareTo(b.unitNumber);
                  });

                  final unimportedFiltered = filtered.where((l) {
                    return !alreadyImportedTitles.contains(l.title.toLowerCase());
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language Filters & Import All Row
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: languages.map((lang) {
                                  final isSelected = _selectedLanguage == lang;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      selected: isSelected,
                                      label: Text(lang),
                                      selectedColor: AppColors.gold500,
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      labelStyle: TextStyle(
                                        color: isSelected ? AppColors.forest900 : null,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      onSelected: (_) {
                                        setState(() => _selectedLanguage = lang);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          if (unimportedFiltered.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isImportingAll || user == null
                                  ? null
                                  : () => _importAllLessons(unimportedFiltered, user.uid),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold500,
                                foregroundColor: AppColors.forest900,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isImportingAll
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(AppColors.forest900),
                                      ),
                                    )
                                  : const Icon(Icons.download_for_offline_rounded, size: 18),
                              label: Text(
                                _isImportingAll
                                    ? '$_importProgress/$_importTotal'
                                    : 'Import All (${unimportedFiltered.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_isImportingAll) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _importTotal > 0 ? _importProgress / _importTotal : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(AppColors.gold500),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Lessons List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.style_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No public lessons found matching your filters.',
                                      style: AppTypography.body.copyWith(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final lesson = filtered[index];
                                  final isAlreadyImported = alreadyImportedTitles
                                      .contains(lesson.title.toLowerCase());
                                  final isImporting = _importingLessonIds.contains(lesson.id);

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isAlreadyImported
                                            ? Colors.green.withValues(alpha: 0.3)
                                            : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Unit Badge Container
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isAlreadyImported
                                                ? Colors.green.withValues(alpha: 0.12)
                                                : AppColors.gold500.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'UNIT',
                                                style: AppTypography.caption.copyWith(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAlreadyImported
                                                      ? Colors.green.shade700
                                                      : AppColors.gold500,
                                                ),
                                              ),
                                              Text(
                                                '${lesson.unitNumber}',
                                                style: AppTypography.h3.copyWith(
                                                  height: 1.1,
                                                  color: isAlreadyImported
                                                      ? Colors.green.shade700
                                                      : AppColors.gold500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Title & Specs
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lesson.title,
                                                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      lesson.language,
                                                      style: AppTypography.caption.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${lesson.category} • ${lesson.tasks.length} tasks',
                                                    style: AppTypography.caption,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Action Button / Status Badge
                                        if (isAlreadyImported)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Imported',
                                                  style: AppTypography.caption.copyWith(
                                                    color: Colors.green.shade800,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          ElevatedButton.icon(
                                            onPressed: isImporting || _isImportingAll || user == null
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
                                                      valueColor: AlwaysStoppedAnimation(AppColors.forest900),
                                                    ),
                                                  )
                                                : const Icon(Icons.download_rounded, size: 18),
                                            label: Text(isImporting ? 'Importing...' : 'Import'),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
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

  Future<void> _importAllLessons(List<Lesson> lessonsToImport, String userId) async {
    if (lessonsToImport.isEmpty) return;

    setState(() {
      _isImportingAll = true;
      _importProgress = 0;
      _importTotal = lessonsToImport.length;
    });

    int successCount = 0;
    for (var lesson in lessonsToImport) {
      if (!mounted) break;
      try {
        final result = await ref
            .read(firebaseServiceProvider)
            .importPublicLessonToVillage(
              publicLessonId: lesson.id,
              educatorId: userId,
            );
        if (result != null) successCount++;
      } catch (e) {
        debugPrint('Failed batch importing lesson ${lesson.title}: $e');
      }
      setState(() {
        _importProgress++;
      });
    }

    if (mounted) {
      setState(() {
        _isImportingAll = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $successCount lessons into your Village!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
