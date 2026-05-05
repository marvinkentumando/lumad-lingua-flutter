import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../models/educator_models.dart';

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

  String _selectedFilter = 'All Villages';
  StudentSort _currentSort = StudentSort.name;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<EducatorStudent> _students = [
    const EducatorStudent(
      id: 's1',
      name: 'Datu Marubay',
      level: 'Intermediate',
      progress: 0.85,
      avatar: 'assets/images/user1.png',
      village: 'Village A',
      lessonsCompleted: 14,
      streakDays: 5,
      isStruggling: false,
      lessonBreakdown: [
        StudentLessonProgress(
          lessonTitle: 'Basic Greetings',
          progress: 1.0,
          status: 'Completed',
        ),
        StudentLessonProgress(
          lessonTitle: 'Counting 1-100',
          progress: 1.0,
          status: 'Completed',
        ),
        StudentLessonProgress(
          lessonTitle: 'Family Lineage',
          progress: 0.6,
          status: 'In Progress',
        ),
        StudentLessonProgress(
          lessonTitle: 'Farming Phrases',
          progress: 0.0,
          status: 'Not Started',
        ),
      ],
    ),
    const EducatorStudent(
      id: 's2',
      name: 'Guardian Tala',
      level: 'Beginner',
      progress: 0.42,
      avatar: 'assets/images/user2.png',
      village: 'Village B',
      lessonsCompleted: 6,
      streakDays: 2,
      isStruggling: true,
      lessonBreakdown: [
        StudentLessonProgress(
          lessonTitle: 'Basic Greetings',
          progress: 1.0,
          status: 'Completed',
        ),
        StudentLessonProgress(
          lessonTitle: 'Counting 1-100',
          progress: 0.3,
          status: 'In Progress',
        ),
        StudentLessonProgress(
          lessonTitle: 'Family Lineage',
          progress: 0.0,
          status: 'Not Started',
        ),
      ],
    ),
    const EducatorStudent(
      id: 's3',
      name: 'Elena Mansaka',
      level: 'Expert',
      progress: 0.98,
      avatar: 'assets/images/user3.png',
      village: 'Village A',
      lessonsCompleted: 22,
      streakDays: 14,
      isStruggling: false,
      lessonBreakdown: [
        StudentLessonProgress(
          lessonTitle: 'Basic Greetings',
          progress: 1.0,
          status: 'Completed',
        ),
        StudentLessonProgress(
          lessonTitle: 'Counting 1-100',
          progress: 1.0,
          status: 'Completed',
        ),
        StudentLessonProgress(
          lessonTitle: 'Family Lineage',
          progress: 1.0,
          status: 'Completed',
        ),
        StudentLessonProgress(
          lessonTitle: 'Farming Phrases',
          progress: 0.9,
          status: 'In Progress',
        ),
      ],
    ),
    const EducatorStudent(
      id: 's4',
      name: 'Juan Mandaya',
      level: 'Beginner',
      progress: 0.15,
      avatar: 'assets/images/user4.png',
      village: 'Youth Group',
      lessonsCompleted: 2,
      streakDays: 0,
      isStruggling: true,
      lessonBreakdown: [
        StudentLessonProgress(
          lessonTitle: 'Basic Greetings',
          progress: 0.4,
          status: 'In Progress',
        ),
        StudentLessonProgress(
          lessonTitle: 'Counting 1-100',
          progress: 0.0,
          status: 'Not Started',
        ),
      ],
    ),
    const EducatorStudent(
      id: 's5',
      name: 'Bai Rosa',
      level: 'Intermediate',
      progress: 0.62,
      avatar: 'assets/images/user1.png',
      village: 'Village B',
      lessonsCompleted: 10,
      streakDays: 3,
      isStruggling: false,
      lessonBreakdown: [
        StudentLessonProgress(
          lessonTitle: 'Basic Greetings',
          progress: 1.0,
          status: 'Completed',
        ),
        StudentLessonProgress(
          lessonTitle: 'Counting 1-100',
          progress: 0.8,
          status: 'In Progress',
        ),
        StudentLessonProgress(
          lessonTitle: 'Family Lineage',
          progress: 0.2,
          status: 'In Progress',
        ),
      ],
    ),
    const EducatorStudent(
      id: 's6',
      name: 'Kadaw Lumad',
      level: 'Beginner',
      progress: 0.08,
      avatar: 'assets/images/user2.png',
      village: 'Youth Group',
      lessonsCompleted: 1,
      streakDays: 0,
      isStruggling: true,
      lessonBreakdown: [
        StudentLessonProgress(
          lessonTitle: 'Basic Greetings',
          progress: 0.1,
          status: 'In Progress',
        ),
      ],
    ),
  ];

  List<EducatorStudent> get _filteredStudents {
    var list = _students.where((s) {
      final matchesFilter =
          _selectedFilter == 'All Villages' || s.village == _selectedFilter;
      final matchesSearch =
          _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.level.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
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
    final students = _filteredStudents;
    final strugglingCount = _students.where((s) => s.isStruggling).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
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
                        '${_students.length} learners',
                        style: AppTypography.body.copyWith(
                          color: isDark ? Colors.white24 : AppColors.creamText3,
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
                            color: AppColors.semanticRed.withOpacity(0.15,
                            ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.forestDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : AppColors.creamBorder,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.creamText,
                  ),
                  decoration: InputDecoration(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.gold500,
                      size: 20,
                    ),
                    hintText: 'Search students...',
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
              ),
            ),
            const SizedBox(height: 16),
            // Filters + sort row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: _buildStudentFilterTabs()),
                  const SizedBox(width: 8),
                  _buildSortDropdown(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Result count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${students.length} result${students.length == 1 ? '' : 's'}',
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white24 : AppColors.creamText3,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: students.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: students.length + 1, // +1 for bottom spacing
                      itemBuilder: (context, index) {
                        if (index == students.length) {
                          return const SizedBox(height: 100);
                        }
                        return _buildStudentCard(students[index]);
                      },
                    ),
            ),
          ],
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
            Icons.person_search_rounded,
            color: isDark ? Colors.white10 : AppColors.creamBorder,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No students found.',
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white24 : AppColors.creamText3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filter.',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white12 : AppColors.creamBorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<StudentSort>(
      onSelected: (sort) => setState(() => _currentSort = sort),
      color: isDark ? AppColors.forest800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
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
                    : (isDark ? Colors.white70 : AppColors.creamText),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentFilterTabs() {
    final filters = ['All Villages', 'Village A', 'Village B', 'Youth Group'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Chip(
                label: Text(filter),
                backgroundColor: isSelected
                    ? AppColors.gold500
                    : Colors.white.withOpacity(0.05),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.forest900
                      : (isDark ? Colors.white70 : AppColors.creamText2),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide.none,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudentCard(EducatorStudent student) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _showStudentDetailSheet(student),
        child: BrandCard(
          theme: BrandCardTheme.vibrant,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.gold500.withOpacity(0.1),
                    backgroundImage: AssetImage(student.avatar),
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
                            color: isDark ? Colors.white : AppColors.creamText,
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
                        const SizedBox(width: 8),
                        Text(
                          '• ${student.village}',
                          style: AppTypography.label.copyWith(
                            color: isDark ? Colors.white24 : AppColors.creamText3,
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
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
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
                      : (isDark ? Colors.white24 : AppColors.creamText3),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
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
                    color: isDark ? Colors.white24 : AppColors.creamBorder,
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
                          backgroundColor: AppColors.gold500.withOpacity(0.1,
                          ),
                          backgroundImage: AssetImage(student.avatar),
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
                        color: isDark ? Colors.white : AppColors.creamText,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          student.level.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${student.village}',
                          style: AppTypography.label.copyWith(
                            color: isDark ? Colors.white38 : AppColors.creamText3,
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'STREAK',
                      '${student.streakDays} Days',
                      Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'PROGRESS',
                      '${(student.progress * 100).toInt()}%',
                      Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Heatmap
              _buildAttendanceHeatmap(),
              const SizedBox(height: 24),
              // Lesson breakdown
              Text(
                'LESSON BREAKDOWN',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ...student.lessonBreakdown.map(
                (lp) => _buildLessonProgressItem(lp),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        foregroundColor: AppColors.forest900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showMessageTemplateDialog(student);
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'Message Student',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.forestDarkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.creamBorder,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Guardian contacted for ${student.name}.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.gold500,
                      ),
                      tooltip: 'Contact Guardian',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonProgressItem(StudentLessonProgress lp) {
    Color statusColor;
    switch (lp.status) {
      case 'Completed':
        statusColor = AppColors.semanticGreen;
        break;
      case 'In Progress':
        statusColor = AppColors.gold500;
        break;
      default:
        statusColor = Colors.white24;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.forestDarkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
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
                      color: Colors.white,
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
                          color: Colors.white.withOpacity(0.05),
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
                    color: Colors.white54,
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

  void _showMessageTemplateDialog(EducatorStudent student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forestDarkCard,
        title: Text(
          'Message ${student.name}',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a template:',
              style: AppTypography.body.copyWith(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            _buildTemplateOption(
              ctx,
              student,
              'Great progress on the recent lessons! Keep it up!',
            ),
            _buildTemplateOption(
              ctx,
              student,
              'I noticed you\'re struggling with some vocabulary. Want to review together?',
            ),
            _buildTemplateOption(
              ctx,
              student,
              'Don\'t forget to complete your pending assignments.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(
    BuildContext ctx,
    EducatorStudent student,
    String text,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent to ${student.name}'),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.forest800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return BrandCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold500.withOpacity(0.5), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 16),
          ),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: Colors.white24,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeatmap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '30-DAY ACTIVITY HEATMAP',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(30, (index) {
            final isActive = index % 3 != 0;
            return Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.gold500.withOpacity((index % 4 + 1) * 0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}


