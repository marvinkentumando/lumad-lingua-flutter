import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../models/educator_models.dart';
import '../models/lesson.dart';
import '../services/firebase_service.dart';
import '../providers/educator_provider.dart';

enum LessonSort { newest, oldest, name, views }

class EducatorLessonsScreen extends ConsumerStatefulWidget {
  const EducatorLessonsScreen({super.key});

  @override
  ConsumerState<EducatorLessonsScreen> createState() =>
      _EducatorLessonsScreenState();
}

class _EducatorLessonsScreenState extends ConsumerState<EducatorLessonsScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  String _selectedTab = 'All';
  LessonSort _currentSort = LessonSort.newest;
  bool _isGridView = true;
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EducatorLesson> _filterAndSortLessons(List<EducatorLesson> allEducatorLessons) {
    var list = allEducatorLessons.where((lesson) {
      bool matchesTab = false;
      if (_selectedTab == 'All') {
        matchesTab = true;
      } else if (_selectedTab == 'Published' ||
          _selectedTab == 'Draft' ||
          _selectedTab == 'Pending') {
        final statusMap = {
          'Published': 'PUBLISHED',
          'Draft': 'DRAFT',
          'Pending': 'PENDING_REVIEW',
        };
        matchesTab = lesson.status.toUpperCase() == statusMap[_selectedTab];
      } else if (_selectedTab == 'Novice' ||
          _selectedTab == 'Intermediate' ||
          _selectedTab == 'Expert') {
        matchesTab = lesson.level == _selectedTab;
      } else {
        matchesTab = lesson.category == _selectedTab;
      }
      final matchesSearch =
          lesson.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lesson.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();

    switch (_currentSort) {
      case LessonSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case LessonSort.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case LessonSort.name:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case LessonSort.views:
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final educatorLessonsAsync = ref.watch(educatorLessonsProvider);
    final rawLessonsAsync = ref.watch(allLessonsStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: SafeArea(
        child: educatorLessonsAsync.when(
          data: (allEduLessons) {
            final lessons = _filterAndSortLessons(allEduLessons);
            final rawLessons = rawLessonsAsync.value ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lessons Library',
                                style: AppTypography.displayBold.copyWith(
                                  color: AppColors.gold500,
                                  fontSize: 32,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${allEduLessons.length} lessons • ${allEduLessons.where((l) => l.status == 'PUBLISHED').length} published',
                                style: AppTypography.body.copyWith(
                                  color: isDark ? Colors.white24 : AppColors.creamText3,
                                ),
                              ),
                            ],
                          ),
                          // View Toggles
                          Row(
                            children: [
                              _buildViewToggleBtn(
                                Icons.grid_view_rounded,
                                _isGridView && !_isMapView,
                                () => setState(() {
                                  _isGridView = true;
                                  _isMapView = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _buildViewToggleBtn(
                                Icons.view_list_rounded,
                                !_isGridView && !_isMapView,
                                () => setState(() {
                                  _isGridView = false;
                                  _isMapView = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _buildViewToggleBtn(
                                Icons.account_tree_rounded,
                                _isMapView,
                                () => setState(() {
                                  _isMapView = true;
                                }),
                                tooltip: 'Curriculum Map',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(child: _buildTabs()),
                      const SizedBox(width: 8),
                      _buildSortDropdown(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: lessons.isEmpty
                      ? _buildEmptyState()
                      : _isMapView
                      ? _CurriculumMapView(lessons: rawLessons)
                      : _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: lessons.length,
                          itemBuilder: (context, index) =>
                              _buildLibraryCard(lessons[index]),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: lessons.length,
                          itemBuilder: (context, index) =>
                              _buildListItem(lessons[index]),
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold500),
          ),
          error: (e, s) => Center(
            child: Text(
              'Error: $e',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.creamText,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/lesson-editor'),
        backgroundColor: AppColors.gold500,
        child: const Icon(Icons.add_rounded, color: AppColors.forest900),
      ),
    );
  }

  Widget _buildViewToggleBtn(
    IconData icon,
    bool isActive,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold500
                : (isDark ? AppColors.forestDarkCard : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.gold500
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.creamBorder),
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.forest900 : AppColors.gold500,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.history_edu_rounded,
              color: Colors.white10,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching lessons found.'
                  : 'Your library is empty.',
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white24 : AppColors.creamText3,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Start by creating your first lesson.',
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white12 : AppColors.creamBorder,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<LessonSort>(
      onSelected: (sort) => setState(() => _currentSort = sort),
      color: AppColors.forest800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.creamBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, color: AppColors.gold500, size: 16),
            const SizedBox(width: 6),
            Text(
              'SORT',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _sortMenuItem(LessonSort.newest, 'Newest First'),
        _sortMenuItem(LessonSort.oldest, 'Oldest First'),
        _sortMenuItem(LessonSort.name, 'By Name'),
        _sortMenuItem(LessonSort.views, 'By Views'),
      ],
    );
  }

  PopupMenuItem<LessonSort> _sortMenuItem(LessonSort sort, String label) {
    final isActive = _currentSort == sort;
    return PopupMenuItem(
      value: sort,
      child: Row(
        children: [
          if (isActive)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check_rounded, color: AppColors.gold500, size: 16),
            ),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? AppColors.gold500
                  : (isDark ? Colors.white70 : AppColors.creamText),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.creamBorder,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
        decoration: InputDecoration(
          icon: const Icon(Icons.search_rounded, color: AppColors.gold500, size: 20),
          hintText: 'Search lessons...',
          hintStyle: AppTypography.body.copyWith(
            color: isDark ? Colors.white24 : AppColors.creamText3,
            fontSize: 14,
          ),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white38 : AppColors.creamText3,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      'All',
      'Published',
      'Pending',
      'Draft',
      'Novice',
      'Intermediate',
      'Expert',
      'Vocabulary',
      'Oral History',
      'Rituals',
      'Phrases',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold500
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.creamBorder),
                  ),
                ),
                child: Text(
                  tab.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: isSelected
                        ? AppColors.forest900
                        : (isDark ? Colors.white60 : AppColors.creamText2),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLessonActions(EducatorLesson lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest800 : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDraft = lesson.status == 'DRAFT';
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: AppTypography.h2ExtraBold.copyWith(
                  color: AppColors.gold500,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lesson.subtitle,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white38 : AppColors.creamText3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              // Edit
              _buildActionTile(
                Icons.edit_rounded,
                'Edit Lesson',
                'Open in the lesson editor',
                () {
                  Navigator.pop(ctx);
                  context.push('/lesson-editor', extra: lesson.id);
                },
              ),
              // View Students
              _buildActionTile(
                Icons.group_rounded,
                'View Students',
                'See who has started or completed this lesson',
                () {
                  Navigator.pop(ctx);
                  _showStudentCompletionSheet(lesson);
                },
              ),
              // Publish / Unpublish toggle
              _buildActionTile(
                isDraft ? Icons.publish_rounded : Icons.unpublished_rounded,
                isDraft ? 'Publish Lesson' : 'Unpublish Lesson',
                isDraft
                    ? 'Make this lesson live for students'
                    : 'Move back to drafts',
                () async {
                  final newStatus = isDraft ? 'PUBLISHED' : 'DRAFT';
                  try {
                    final fullLesson = await ref
                        .read(firebaseServiceProvider)
                        .getLessonById(lesson.id);
                    if (fullLesson != null) {
                      await ref
                          .read(firebaseServiceProvider)
                          .saveLesson(fullLesson, status: newStatus);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isDraft
                                  ? '"${lesson.title}" published!'
                                  : '"${lesson.title}" moved to drafts.',
                            ),
                            backgroundColor: isDraft
                                ? AppColors.semanticGreen
                                : (isDark ? Colors.white24 : AppColors.creamText3),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating status: $e'),
                          backgroundColor: AppColors.semanticRed,
                        ),
                      );
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              // Shift Units
              _buildActionTile(
                Icons.swap_vert_rounded,
                'Shift Units',
                'Shift all subsequent units by +1',
                () async {
                  try {
                    await ref
                        .read(firebaseServiceProvider)
                        .shiftUnitNumbers(
                          language: lesson.language,
                          startUnit: lesson.unitNumber,
                          offset: 1,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Units shifted successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error shifting units: $e'),
                          backgroundColor: AppColors.semanticRed,
                        ),
                      );
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              // Duplicate
              _buildActionTile(
                Icons.copy_rounded,
                'Duplicate Lesson',
                'Create a copy as a new draft',
                () async {
                  try {
                    final fullLesson = await ref
                        .read(firebaseServiceProvider)
                        .getLessonById(lesson.id);
                    if (fullLesson != null) {
                      final copy = Lesson(
                        id: '', // New ID
                        title: '${fullLesson.title} (Copy)',
                        description: fullLesson.description,
                        category: fullLesson.category,
                        language: fullLesson.language,
                        level: fullLesson.level,
                        unitNumber: fullLesson.unitNumber,
                        tasks: fullLesson.tasks,
                        status: 'DRAFT',
                      );
                      await ref
                          .read(firebaseServiceProvider)
                          .saveLesson(copy, status: 'DRAFT');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Duplicated "${lesson.title}"'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error duplicating: $e'),
                          backgroundColor: AppColors.semanticRed,
                        ),
                      );
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              // Delete
              _buildActionTile(
                Icons.delete_outline_rounded,
                'Delete Lesson',
                'Permanently remove this lesson',
                () async {
                  try {
                    await ref
                        .read(firebaseServiceProvider)
                        .deleteLesson(lesson.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${lesson.title}"'),
                          backgroundColor: AppColors.semanticRed,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting: $e'),
                          backgroundColor: AppColors.semanticRed,
                        ),
                      );
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                isDestructive: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStudentCompletionSheet(EducatorLesson lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => _StudentCompletionSheet(lesson: lesson),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    (isDestructive ? AppColors.semanticRed : AppColors.gold500)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? AppColors.semanticRed
                    : AppColors.gold500,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                      style: AppTypography.body.copyWith(
                        color: isDestructive
                            ? AppColors.semanticRed
                            : (isDark ? Colors.white : AppColors.creamText),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white24 : AppColors.creamText3,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.creamText3.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatViewCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Widget _buildLibraryCard(EducatorLesson lesson) {
    final isDraft = lesson.status == 'DRAFT';
    return GestureDetector(
      onTap: () => context.push('/lesson-editor', extra: lesson.id),
      onLongPress: () => _showLessonActions(lesson),
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDraft ? Colors.white : AppColors.gold500)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDraft ? Icons.edit_note_rounded : Icons.menu_book_rounded,
                    color: isDraft
                        ? (isDark ? Colors.white38 : AppColors.creamText3)
                        : AppColors.gold500,
                    size: 20,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showLessonActions(lesson),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.creamText3.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              lesson.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.creamText,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lesson.subtitle,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white24 : AppColors.creamText3,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 10),
            // Stats row
            if (!isDraft)
              Row(
                children: [
                  const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white24,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatViewCount(lesson.viewCount),
                    style: AppTypography.label.copyWith(
                      color: Colors.white24,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.people_rounded, color: Colors.white24, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    lesson.studentCount.toString(),
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white24 : AppColors.creamText3,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            if (isDraft) const SizedBox(height: 14),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDraft
                        ? (isDark ? Colors.white24 : AppColors.creamBorder)
                        : AppColors.semanticGreen,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isDraft ? 'DRAFT • v${lesson.version}' : lesson.status,
                  style: AppTypography.label.copyWith(
                    color: isDraft
                        ? (isDark ? Colors.white24 : AppColors.creamText3)
                        : AppColors.semanticGreen,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(EducatorLesson lesson) {
    final isDraft = lesson.status == 'DRAFT';
    return Dismissible(
      key: Key(lesson.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.semanticRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.semanticRed,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.forest800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Delete Lesson?',
              style: TextStyle(color: AppColors.gold500),
            ),
            content: Text(
              'Are you sure you want to delete "${lesson.title}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.semanticRed),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        try {
          await ref.read(firebaseServiceProvider).deleteLesson(lesson.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted "${lesson.title}"')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting: $e'),
                backgroundColor: AppColors.semanticRed,
              ),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => context.push('/lesson-editor', extra: lesson.id),
        onLongPress: () => _showLessonActions(lesson),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.forestDarkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDraft ? Colors.white : AppColors.gold500)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDraft ? Icons.edit_note_rounded : Icons.menu_book_rounded,
                  color: isDraft ? Colors.white38 : AppColors.gold500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          lesson.subtitle,
                          style: AppTypography.body.copyWith(
                            color: Colors.white24,
                            fontSize: 11,
                          ),
                        ),
                        if (!isDraft) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.visibility_rounded,
                            color: Colors.white24,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatViewCount(lesson.viewCount),
                            style: AppTypography.label.copyWith(
                              color: Colors.white24,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDraft
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.semanticGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lesson.status,
                  style: AppTypography.label.copyWith(
                    color: isDraft ? Colors.white24 : AppColors.semanticGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurriculumMapView extends StatefulWidget {
  final List<Lesson> lessons;
  const _CurriculumMapView({required this.lessons});

  @override
  State<_CurriculumMapView> createState() => _CurriculumMapViewState();
}

class _CurriculumMapViewState extends State<_CurriculumMapView> {
  final Map<String, GlobalKey> _nodeKeys = {};
  
  @override
  void initState() {
    super.initState();
    _refreshKeys();
  }

  void _refreshKeys() {
    for (var l in widget.lessons) {
      _nodeKeys[l.id] = GlobalKey();
    }
  }

  @override
  void didUpdateWidget(_CurriculumMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessons.length != widget.lessons.length) {
      _refreshKeys();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Group lessons by language, then by unit
    final languages = <String, Map<int, List<Lesson>>>{};
    for (var l in widget.lessons) {
      final langMap = languages.putIfAbsent(l.language, () => {});
      langMap.putIfAbsent(l.unitNumber, () => []).add(l);
    }
    final sortedLanguages = languages.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedLanguages.map((lang) {
          final units = languages[lang]!;
          final sortedUnits = units.keys.toList()..sort();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 16),
                child: Text(
                  lang.toUpperCase(),
                  style: AppTypography.h3.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Lines Layer
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CurriculumLinePainter(
                          lessons: widget.lessons.where((l) => l.language == lang).toList(),
                          nodeKeys: _nodeKeys,
                          context: context,
                        ),
                      ),
                    ),
                    // Nodes Layer
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedUnits.map((uNum) {
                        final unitLessons = units[uNum]!;
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 80),
                          child: Column(
                            children: [
                              // Unit Indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'UNIT $uNum',
                                  style: AppTypography.label.copyWith(
                                    color: isDark ? Colors.white24 : AppColors.creamText3,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Lessons
                              ...unitLessons.map((l) => _buildNode(l, isDark)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, indent: 32, endIndent: 32),
              const SizedBox(height: 32),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNode(Lesson lesson, bool isDark) {
    return Padding(
      key: _nodeKeys[lesson.id],
      padding: const EdgeInsets.only(bottom: 32),
      child: GestureDetector(
        onTap: () => context.push('/lesson-editor', extra: lesson.id),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forestDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: lesson.status == 'PUBLISHED'
                  ? AppColors.gold500.withValues(alpha: 0.3)
                  : (isDark ? Colors.white10 : AppColors.creamBorder),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LVL ${lesson.level}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (lesson.prerequisiteId != null && lesson.prerequisiteId!.isNotEmpty)
                    const Icon(Icons.link_rounded, size: 12, color: AppColors.gold500),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurriculumLinePainter extends CustomPainter {
  final List<Lesson> lessons;
  final Map<String, GlobalKey> nodeKeys;
  final BuildContext context;

  _CurriculumLinePainter({
    required this.lessons,
    required this.nodeKeys,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold500.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowPaint = Paint()
      ..color = AppColors.gold500.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (var l in lessons) {
      if (l.prerequisiteId != null && l.prerequisiteId!.isNotEmpty) {
        final startKey = nodeKeys[l.prerequisiteId];
        final endKey = nodeKeys[l.id];

        if (startKey != null && endKey != null) {
          final startBox = startKey.currentContext?.findRenderObject() as RenderBox?;
          final endBox = endKey.currentContext?.findRenderObject() as RenderBox?;

          if (startBox != null && endBox != null) {
            final startPos = startBox.localToGlobal(
              Offset(startBox.size.width, startBox.size.height / 2),
            );
            final endPos = endBox.localToGlobal(
              Offset(0, endBox.size.height / 2),
            );

            final renderBox = context.findRenderObject() as RenderBox;
            final localStart = renderBox.globalToLocal(startPos);
            final localEnd = renderBox.globalToLocal(endPos);

            final path = Path();
            path.moveTo(localStart.dx, localStart.dy);
            
            final double midX = localStart.dx + (localEnd.dx - localStart.dx) / 2;
            
            path.cubicTo(
              midX, localStart.dy,
              midX, localEnd.dy,
              localEnd.dx, localEnd.dy,
            );

            canvas.drawPath(path, paint);
            
            final arrowPath = Path();
            arrowPath.moveTo(localEnd.dx, localEnd.dy);
            arrowPath.lineTo(localEnd.dx - 6, localEnd.dy - 4);
            arrowPath.lineTo(localEnd.dx - 6, localEnd.dy + 4);
            arrowPath.close();
            canvas.drawPath(arrowPath, arrowPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurriculumLinePainter oldDelegate) => true;
}

class _StudentCompletionSheet extends ConsumerWidget {
  final EducatorLesson lesson;
  const _StudentCompletionSheet({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(educatorStudentsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : AppColors.creamBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Progress',
                      style: AppTypography.h2ExtraBold.copyWith(
                        color: AppColors.gold500,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      lesson.title,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white38 : AppColors.creamText3,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white38 : AppColors.creamText3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: studentsAsync.when(
              data: (allStudents) {
                // Filter students who have interacted with this lesson
                final activeStudents = allStudents.where((s) {
                  return s.lessonBreakdown.any((lb) => lb.lessonTitle == lesson.title);
                }).toList();

                if (activeStudents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off_rounded,
                          size: 48,
                          color: isDark ? Colors.white10 : AppColors.creamBorder,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students have started this yet.',
                          style: TextStyle(
                            color: isDark ? Colors.white24 : AppColors.creamText3,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: activeStudents.length,
                  padding: const EdgeInsets.only(bottom: 40),
                  itemBuilder: (context, index) {
                    final student = activeStudents[index];
                    final progress = student.lessonBreakdown.firstWhere(
                      (lb) => lb.lessonTitle == lesson.title,
                    );

                    return _buildStudentItem(student, progress, isDark);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold500),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(
    EducatorStudent student,
    StudentLessonProgress progress,
    bool isDark,
  ) {
    Color statusColor;
    IconData statusIcon;
    switch (progress.status) {
      case 'Completed':
        statusColor = AppColors.semanticGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'In Progress':
        statusColor = AppColors.gold500;
        statusIcon = Icons.pending_rounded;
        break;
      default:
        statusColor = isDark ? Colors.white24 : AppColors.creamText3;
        statusIcon = Icons.not_started_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: student.avatar.startsWith('http')
                ? NetworkImage(student.avatar) as ImageProvider
                : AssetImage(student.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Accuracy: ${(progress.accuracy * 100).toInt()}%',
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white24 : AppColors.creamText3,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    progress.status.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress.progress * 100).toInt()}% SCORE',
                style: AppTypography.mono.copyWith(
                  color: isDark ? Colors.white38 : AppColors.creamText3,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



