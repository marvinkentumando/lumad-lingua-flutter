import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/badges.dart';
import '../models/admin_models.dart';
import '../models/voice_submission.dart';
import '../models/lesson.dart';
import '../services/haptic_service.dart';
import '../services/auth_service.dart';

class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});
  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  final Map<String, bool> _dialectToggles = {
    'Mansaka': true,
    'Mandaya': true,
    'Manobo': true,
    'Bagobo': true,
    'Kagan': false,
  };

  final List<ContentEntry> _content = [
    ContentEntry(
      id: 'c1',
      term: 'Maayong Buntag',
      dialect: 'Mansaka',
      partOfSpeech: 'phrase',
      status: 'validated',
      contributorName: 'Elder V.',
      submittedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ContentEntry(
      id: 'c2',
      term: 'Kagawasan',
      dialect: 'Manobo',
      partOfSpeech: 'noun',
      status: 'validated',
      contributorName: 'Teacher J.',
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ContentEntry(
      id: 'c3',
      term: 'Buntag',
      dialect: 'Mandaya',
      partOfSpeech: 'noun',
      status: 'pending',
      contributorName: 'Maria M.',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ContentEntry(
      id: 'c4',
      term: 'Lipad',
      dialect: 'Mansaka',
      partOfSpeech: 'verb',
      status: 'validated',
      contributorName: 'Datu M.',
      submittedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ContentEntry(
      id: 'c5',
      term: 'Buklod',
      dialect: 'Bagobo',
      partOfSpeech: 'noun',
      status: 'pending',
      contributorName: 'Agila M.',
      submittedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    ContentEntry(
      id: 'c6',
      term: 'Kalayo',
      dialect: 'Kagan',
      partOfSpeech: 'noun',
      status: 'rejected',
      contributorName: 'Juan D.',
      rejectionReason: 'Duplicate entry',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<ContentEntry> get _filtered {
    if (_searchQuery.isEmpty) return _content;
    return _content
        .where(
          (c) =>
              c.term.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.contributorName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _passwordCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/topo_map.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchBar(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDictionaryTab(),
                      _buildRecordingsTab(),
                      _buildLessonsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.forest900.withValues(alpha: 0.8)
            : AppColors.creamBg,
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.creamBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold500.withValues(alpha: 0.2),
              ),
            ),
            child: const Text('🛡️', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN CONSOLE',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Content Moderation',
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.creamText3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.settings_suggest_rounded,
                color: isDark ? Colors.white70 : AppColors.forest900,
                size: 20,
              ),
            ),
            onPressed: _showSystemActionsModal,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search terms or contributors...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white24 : AppColors.creamText3,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.gold500,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark 
              ? AppColors.forest800.withValues(alpha: 0.5)
              : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.creamBorder,
            ),
          ),
        ),
        style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.gold500,
        ),
        labelColor: Colors.black,
        unselectedLabelColor: isDark ? Colors.white60 : AppColors.creamText3,
        labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'DICTIONARY'),
          Tab(text: 'RECORDINGS'),
          Tab(text: 'LESSONS'),
        ],
      ),
    );
  }

  Widget _buildDictionaryTab() {
    final filtered = _filtered;
    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _dictionaryCard(filtered[index], index),
    );
  }

  Widget _buildRecordingsTab() {
    final mockRecordings = [
      VoiceSubmission(
        id: 'v1',
        title: 'Traditional Greeting',
        dialect: 'Mansaka',
        contributorId: 'u1',
        contributorName: 'Datu M.',
        audioUrl: '',
        transcript: 'Maayong buntag sa inyong tanan.',
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      VoiceSubmission(
        id: 'v2',
        title: 'Story of the Moon',
        dialect: 'Manobo',
        contributorId: 'u2',
        contributorName: 'Lola B.',
        audioUrl: '',
        transcript: 'Kaniadto, ang bulan...',
        submittedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];

    final filtered = mockRecordings.where((v) => 
      v.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      v.contributorName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _recordingCard(filtered[index], index),
    );
  }

  Widget _buildLessonsTab() {
    final mockLessons = [
      Lesson(
        id: 'l1',
        title: 'Basic Greetings',
        description: 'Learn how to greet others in Mansaka.',
        category: 'Foundations',
        language: 'Mansaka',
        level: 1,
        unitNumber: 1,
        tasks: [],
      ),
      Lesson(
        id: 'l2',
        title: 'Numbers and Counting',
        description: 'Master the numbering system of Mandaya.',
        category: 'Mathematics',
        language: 'Mandaya',
        level: 1,
        unitNumber: 2,
        tasks: [],
      ),
    ];

    final filtered = mockLessons.where((l) => 
      l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      l.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _lessonCard(filtered[index], index),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: isDark ? Colors.white10 : Colors.black12,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No matching content found.',
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white24 : AppColors.creamText3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dictionaryCard(ContentEntry data, int index) {
    return _baseContentCard(
      index: index,
      icon: Icons.menu_book_rounded,
      iconColor: AppColors.gold500,
      title: data.term,
      subtitle: '${data.dialect} · ${data.partOfSpeech}',
      author: 'by ${data.contributorName}',
      status: data.status,
      onDelete: () => _showDeletePasswordDialog(data.term, () {
        setState(() => _content.removeWhere((c) => c.id == data.id));
      }),
    );
  }

  Widget _recordingCard(VoiceSubmission data, int index) {
    return _baseContentCard(
      index: index,
      icon: Icons.mic_rounded,
      iconColor: AppColors.semanticBlue,
      title: data.title,
      subtitle: '${data.dialect} · Audio Recording',
      author: 'by ${data.contributorName}',
      status: data.status.name,
      onDelete: () => _showDeletePasswordDialog(data.title, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording deletion requested'))
        );
      }),
    );
  }

  Widget _lessonCard(Lesson data, int index) {
    return _baseContentCard(
      index: index,
      icon: Icons.school_rounded,
      iconColor: AppColors.semanticGreen,
      title: data.title,
      subtitle: '${data.language} · ${data.category}',
      author: 'Level ${data.level} · Unit ${data.unitNumber}',
      status: 'published',
      onDelete: () => _showDeletePasswordDialog(data.title, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson deletion requested'))
        );
      }),
    );
  }

  Widget _baseContentCard({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String author,
    required String status,
    required VoidCallback onDelete,
  }) {
    final statusStyle = status == 'validated' || status == 'published' || status == 'approved'
        ? BrandBadgeStyle.green
        : status == 'rejected'
        ? BrandBadgeStyle.dark
        : BrandBadgeStyle.gold;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.forest700.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder,
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.forest500,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.label.copyWith(
                        color: isDark ? Colors.white38 : AppColors.creamText3,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      author,
                      style: AppTypography.mono.copyWith(
                        color: AppColors.gold500.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BrandBadge(text: status.toUpperCase(), style: statusStyle),
                  const SizedBox(height: 8),
                  _actionIcon(
                    Icons.delete_outline_rounded,
                    onDelete,
                    color: AppColors.semanticRed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideY(begin: 0.1, curve: Curves.easeOutCubic),
    );
  }

  void _showDeletePasswordDialog(String itemName, VoidCallback onConfirm) {
    _passwordCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.semanticRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.semanticRed, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Security Check',
              style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.forest900),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To delete "$itemName", please enter your administrator password to confirm.',
              style: AppTypography.body.copyWith(color: isDark ? Colors.white70 : AppColors.creamText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.forest900),
              decoration: InputDecoration(
                hintText: 'Enter Password',
                hintStyle: TextStyle(color: isDark ? Colors.white24 : AppColors.creamText3),
                filled: true,
                fillColor: isDark ? AppColors.forest900 : AppColors.creamBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white38 : AppColors.creamText3)),
          ),
          BrandButton(
            text: 'Confirm Delete',
            type: BrandButtonType.primary,
            onTap: () async {
              final authService = ref.read(authServiceProvider);
              final isValid = await authService.verifyPassword(_passwordCtrl.text);
              
              if (!mounted) return;
              
              if (isValid) {
                if (ctx.mounted) Navigator.pop(ctx);
                onConfirm();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully deleted $itemName'),
                      backgroundColor: AppColors.semanticGreen,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect password. Action denied.'),
                      backgroundColor: AppColors.semanticRed,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Colors.white70, size: 18),
      ),
    );
  }

  void _showSystemActionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SYSTEM ACTIONS',
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white38 : AppColors.creamText3,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _systemAction(
              icon: Icons.language_rounded,
              color: AppColors.semanticBlue,
              title: 'Dialect Settings',
              subtitle: 'Enable or disable dialects',
              onTap: () {
                Navigator.pop(context);
                _showDialectSettings();
              },
            ),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            _systemAction(
              icon: Icons.download_outlined,
              color: AppColors.semanticGreen,
              title: 'Export to CSV',
              subtitle: 'Copy all entries as CSV',
              onTap: () {
                Navigator.pop(context);
                _exportData('csv');
              },
            ),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            _systemAction(
              icon: Icons.code_outlined,
              color: AppColors.gold500,
              title: 'Export to JSON',
              subtitle: 'Copy all entries as JSON',
              onTap: () {
                Navigator.pop(context);
                _exportData('json');
              },
            ),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            _systemAction(
              icon: Icons.cleaning_services_outlined,
              color: AppColors.semanticBlue,
              title: 'Clear App Cache',
              subtitle: 'Remove locally cached data',
              onTap: () {
                Navigator.pop(context);
                _showConfirmAction(
                  'Clear Cache',
                  'This will clear all locally cached content.',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache cleared'),
                        backgroundColor: AppColors.semanticGreen,
                      ),
                    );
                  },
                );
              },
            ),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            _systemAction(
              icon: Icons.warning_amber_outlined,
              color: AppColors.semanticRed,
              title: 'Reset Platform',
              subtitle: 'Danger: wipe all pending submissions',
              onTap: () {
                Navigator.pop(context);
                _showConfirmAction(
                  'Reset Platform',
                  'This will permanently delete ALL pending submissions.',
                  () {
                    setState(
                      () => _content.removeWhere((c) => c.status == 'pending'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pending submissions cleared'),
                        backgroundColor: AppColors.semanticRed,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDialectSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.forest700 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Dialect Settings',
            style: AppTypography.h3.copyWith(color: AppColors.gold500),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _dialectToggles.entries
                .map(
                  (e) => SwitchListTile(
                    title: Text(
                      e.key,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontWeight: e.value
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    value: e.value,
                    activeThumbColor: AppColors.gold500,
                    onChanged: (v) {
                      HapticService.light();
                      setDialogState(() => _dialectToggles[e.key] = v);
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            BrandButton(
              text: 'Save',
              type: BrandButtonType.primary,
              onTap: () {
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dialect settings saved'),
                    backgroundColor: AppColors.semanticGreen,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.body.copyWith(color: isDark ? Colors.white : AppColors.forest900),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.label.copyWith(
          color: isDark ? Colors.white38 : AppColors.creamText3,
          fontSize: 11,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black12),
      onTap: onTap,
    );
  }

  void _showConfirmAction(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest700 : Colors.white,
        title: Text(
          title,
          style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.forest900),
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white70 : AppColors.creamText,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white54 : AppColors.creamText3),
            ),
          ),
          BrandButton(
            text: 'Confirm',
            type: BrandButtonType.primary,
            onTap: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  void _exportData(String format) {
    final data = _content
        .map(
          (e) => {
            'term': e.term,
            'dialect': e.dialect,
            'pos': e.partOfSpeech,
            'status': e.status,
          },
        )
        .toList();
    String output;
    if (format == 'json') {
      output = const JsonEncoder.withIndent('  ').convert(data);
    } else {
      final rows =
          ['term,dialect,pos,status'] +
          data
              .map(
                (e) =>
                    '${e['term']},${e['dialect']},${e['pos']},${e['status']}',
              )
              .toList();
      output = rows.join('\n');
    }
    Clipboard.setData(ClipboardData(text: output));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${format.toUpperCase()} copied to clipboard (${data.length} entries)',
        ),
        backgroundColor: AppColors.semanticGreen,
      ),
    );
  }
}
