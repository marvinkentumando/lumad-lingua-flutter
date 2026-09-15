import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/branded_empty_state.dart';
import '../models/educator_models.dart';
import '../widgets/brand_search_bar.dart';
import '../providers/educator_provider.dart';
import '../services/haptic_service.dart';

enum StudentSort { name, progress, level }

class EducatorStudentsScreen extends ConsumerStatefulWidget {
  const EducatorStudentsScreen({super.key});

  @override
  ConsumerState<EducatorStudentsScreen> createState() =>
      _EducatorStudentsScreenState();
}

class _EducatorStudentsScreenState
    extends ConsumerState<EducatorStudentsScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  StudentSort _currentSort = StudentSort.name;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<EducatorStudent> _getFilteredStudents(List<EducatorStudent> allStudents) {
    var list = allStudents.where((s) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.level.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    switch (_currentSort) {
      case StudentSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case StudentSort.progress:
        list.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case StudentSort.level:
        const order = {'Beginner': 0, 'Intermediate': 1, 'Expert': 2};
        list.sort(
          (a, b) => (order[a.level] ?? 0).compareTo(order[b.level] ?? 0),
        );
        break;
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(educatorStudentsProvider);

    return studentsAsync.when(
      data: (allStudents) {
        final filteredStudents = _getFilteredStudents(allStudents);
        final strugglingCount = allStudents.where((s) => s.isStruggling).length;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Hub',
                        style: AppTypography.displayBold.copyWith(
                          color: AppColors.gold500,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${allStudents.length} learners',
                            style: AppTypography.body.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          if (strugglingCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.semanticRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$strugglingCount STRUGGLING',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.semanticRed,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: BrandSearchBar(
                    controller: _searchController,
                    hintText: 'Search students...',
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(height: 16),
                // Filters + sort row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildSortDropdown(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Result count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '${filteredStudents.length} result${filteredStudents.length == 1 ? '' : 's'}',
                    style: AppTypography.label.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredStudents.length + 1, // +1 for bottom spacing
                          itemBuilder: (context, index) {
                            if (index == filteredStudents.length) {
                              return const SizedBox(height: 100);
                            }
                            return _buildStudentCard(filteredStudents[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.gold500))),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildEmptyState() {
    return BrandedEmptyState(
      title: _searchQuery.isNotEmpty ? 'Member Not Found' : 'Quiet Village',
      message: _searchQuery.isNotEmpty
          ? 'Try adjusting your search or filter.'
          : 'No students have joined your village yet.',
      icon: _searchQuery.isNotEmpty ? Icons.person_search_rounded : Icons.people_outline_rounded,
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<StudentSort>(
      onSelected: (sort) => setState(() => _currentSort = sort),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        _sortMenuItem(StudentSort.name, 'By Name'),
        _sortMenuItem(StudentSort.progress, 'By Progress'),
        _sortMenuItem(StudentSort.level, 'By Level'),
      ],
    );
  }

  PopupMenuItem<StudentSort> _sortMenuItem(StudentSort sort, String label) {
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
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(EducatorStudent student) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          _showStudentDetailSheet(student);
        },
        child: BrandCard(
          theme: BrandCardTheme.vibrant,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
                    backgroundImage: student.avatar.startsWith('http')
                        ? NetworkImage(student.avatar) as ImageProvider
                        : AssetImage(student.avatar),
                  ),
                  if (student.isStruggling)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.semanticRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.priority_high_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          student.name,
                          style: AppTypography.h3.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        if (student.streakDays > 3) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.gold500,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          student.level.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: student.progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: student.isStruggling
                                  ? AppColors.semanticRed
                                  : AppColors.gold500,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(student.progress * 100).toInt()}%',
                style: AppTypography.mono.copyWith(
                  color: student.isStruggling
                      ? AppColors.semanticRed
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: student.isStruggling
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentDetailSheet(EducatorStudent student) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : AppColors.forest900).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Avatar + info
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
                          backgroundImage: student.avatar.startsWith('http')
                              ? NetworkImage(student.avatar) as ImageProvider
                              : AssetImage(student.avatar),
                        ),
                        if (student.isStruggling)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.semanticRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NEEDS HELP',
                                style: AppTypography.label.copyWith(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      student.name,
                      style: AppTypography.h2.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          student.level.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            color: isDark ? AppColors.gold500 : AppColors.gold700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'LESSONS',
                      student.lessonsCompleted.toString(),
                      Icons.menu_book_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'STREAK',
                      '${student.streakDays} Days',
                      Icons.local_fire_department_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'PROGRESS',
                      '${(student.progress * 100).toInt()}%',
                      Icons.trending_up_rounded,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Heatmap
              _buildAttendanceHeatmap(student),
              const SizedBox(height: 24),
              // Lesson breakdown
              Text(
                'LESSON BREAKDOWN',
                style: AppTypography.label.copyWith(
                  color: isDark ? AppColors.gold500 : AppColors.gold700,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ...student.lessonBreakdown.map(
                (lp) => _buildLessonProgressItem(lp, isDark),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonProgressItem(StudentLessonProgress lp, bool isDark) {
    Color statusColor;
    switch (lp.status) {
      case 'Completed':
        statusColor = AppColors.semanticGreen;
        break;
      case 'In Progress':
        statusColor = isDark ? AppColors.gold500 : AppColors.gold700;
        break;
      default:
        statusColor = isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.2);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : AppColors.forest900).withValues(alpha: 0.05),
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lp.lessonTitle,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: lp.progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lp.status,
                  style: AppTypography.label.copyWith(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Accuracy: ${(lp.accuracy * 100).toInt()}%',
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5),
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

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return BrandCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: isDark ? AppColors.gold500.withValues(alpha: 0.5) : AppColors.gold700, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white : AppColors.forest900, 
              fontSize: 14,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeatmap(EducatorStudent student) {
    final now = DateTime.now();
    final last30Days = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return dateKey;
    });
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '30-DAY ACTIVITY HEATMAP',
              style: AppTypography.label.copyWith(
                color: isDark ? AppColors.gold500 : AppColors.gold700,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Last 30 days',
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                fontSize: 8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: last30Days.map((dateKey) {
            final isActive = student.activityMap[dateKey] == true;
            return Tooltip(
              message: dateKey,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.gold500
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(4),
                  border: isActive 
                      ? null 
                      : Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}




