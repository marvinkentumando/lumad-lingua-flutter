import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/preview_audio_player.dart';
import '../services/firebase_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/badges.dart';
import '../models/voice_submission.dart';
import '../models/lesson.dart';
import '../models/dictionary_entry.dart';
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

  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
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
          if (_isSelectionMode)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildBulkActionsBar(),
            ),
        ],
      ),
    );
  }

  void _handleSelectAll() {
    List<String> idsToSelect = [];
    if (_tabController.index == 0) {
      final words = ref.read(allWordsProvider).value ?? [];
      idsToSelect = words.where((w) =>
          w.indigenousWord.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (w.contributorName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        ).map((e) => e.id).toList();
    } else if (_tabController.index == 1) {
       final recordings = ref.read(allVoiceSubmissionsProvider).value ?? [];
       idsToSelect = recordings.where((v) =>
          v.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.contributorName.toLowerCase().contains(_searchQuery.toLowerCase())
        ).map((e) => e.id).toList();
    } else if (_tabController.index == 2) {
       final lessons = ref.read(allLessonsStreamProvider).value ?? [];
       idsToSelect = lessons.where((l) =>
          l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.category.toLowerCase().contains(_searchQuery.toLowerCase())
        ).map((e) => e.id).toList();
    }

    setState(() {
      // If all are already selected, deselect all. Otherwise, select all filtered items.
      bool allSelected = idsToSelect.isNotEmpty && idsToSelect.every((id) => _selectedIds.contains(id));
      if (allSelected) {
        for (var id in idsToSelect) {
          _selectedIds.remove(id);
        }
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.addAll(idsToSelect);
        _isSelectionMode = true;
      }
    });
  }

  Widget _buildBulkActionsBar() {
    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} SELECTED',
            style: AppTypography.mono.copyWith(
              color: AppColors.forest900,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.select_all_rounded, color: AppColors.forest900),
            onPressed: _handleSelectAll,
            tooltip: 'Select All Filtered',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.forest900),
            onPressed: _handleBulkApprove,
            tooltip: 'Bulk Approve',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.semanticRed),
            onPressed: _handleBulkDelete,
            tooltip: 'Bulk Delete',
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.forest900),
            onPressed: () => setState(() {
              _selectedIds.clear();
              _isSelectionMode = false;
            }),
          ),
        ],
      ),
    );
  }

  void _handleBulkApprove() async {
    final validatorId = ref.read(authServiceProvider).currentUser?.uid ?? 'admin';
    final validatorRole = 'Administrator';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest800 : Colors.white,
        title: Text('Confirm Bulk Approval', style: TextStyle(color: AppColors.gold500)),
        content: Text('Are you sure you want to approve ${_selectedIds.length} items? This will make them live on the platform.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticGreen),
            child: const Text('APPROVE ALL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_tabController.index == 0) {
      await ref.read(firebaseServiceProvider).bulkApproveWords(_selectedIds.toList(), validatorId, validatorRole);
    } else if (_tabController.index == 1) {
      await ref.read(firebaseServiceProvider).bulkApproveVoiceSubmissions(_selectedIds.toList(), validatorId, validatorRole);
    } else if (_tabController.index == 2) {
      await ref.read(firebaseServiceProvider).bulkApproveLessons(_selectedIds.toList(), validatorId, validatorRole);
    }
    
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bulk approval successful'), backgroundColor: AppColors.semanticGreen),
      );
    }
  }

  void _handleBulkDelete() {
    _showDeletePasswordDialog('Selected Items', () async {
      if (_tabController.index == 0) {
        await ref.read(firebaseServiceProvider).bulkDeleteWords(_selectedIds.toList());
      } else if (_tabController.index == 1) {
        await ref.read(firebaseServiceProvider).bulkDeleteVoiceSubmissions(_selectedIds.toList());
      } else if (_tabController.index == 2) {
        await ref.read(firebaseServiceProvider).bulkDeleteLessons(_selectedIds.toList());
      }
      
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    });
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
    final wordsAsync = ref.watch(allWordsProvider);

    return wordsAsync.when(
      data: (words) {
        final filtered = words.where((w) => 
          w.indigenousWord.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (w.contributorName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        ).toList();

        if (filtered.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _dictionaryCard(filtered[index], index),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildRecordingsTab() {
    final recordingsAsync = ref.watch(allVoiceSubmissionsProvider);

    return recordingsAsync.when(
      data: (recordings) {
        final filtered = recordings.where((v) => 
          v.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.contributorName.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

        if (filtered.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _recordingCard(filtered[index], index),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildLessonsTab() {
    final lessonsAsync = ref.watch(allLessonsStreamProvider);

    return lessonsAsync.when(
      data: (lessons) {
        final filtered = lessons.where((l) => 
          l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.category.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

        if (filtered.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _lessonCard(filtered[index], index),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
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

  Widget _dictionaryCard(DictionaryEntry data, int index) {
    return _baseContentCard(
      id: data.id,
      index: index,
      icon: Icons.menu_book_rounded,
      iconColor: AppColors.gold500,
      title: data.indigenousWord,
      subtitle: '${data.language} · ${data.partOfSpeechLabel}',
      author: 'by ${data.contributorName ?? 'Unknown'}',
      status: data.status.name,
      onEdit: () => _showEditDictionaryDialog(data),
      onDelete: () => _showDeletePasswordDialog(data.indigenousWord, () {
        ref.read(firebaseServiceProvider).deleteWord(data.id);
      }),
    );
  }

  Widget _recordingCard(VoiceSubmission data, int index) {
    return _baseContentCard(
      id: data.id,
      index: index,
      icon: Icons.mic_rounded,
      iconColor: AppColors.semanticBlue,
      title: data.title,
      subtitle: '${data.dialect} · Audio Recording',
      author: 'by ${data.contributorName}',
      status: data.status.name,
      audioUrl: data.audioUrl,
      onDelete: () => _showDeletePasswordDialog(data.title, () {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording deletion requested'))
        );
      }),
    );
  }

  Widget _lessonCard(Lesson data, int index) {
    return _baseContentCard(
      id: data.id,
      index: index,
      icon: Icons.school_rounded,
      iconColor: AppColors.semanticGreen,
      title: data.title,
      subtitle: '${data.language} · ${data.category}',
      author: 'Level ${data.level} · Unit ${data.unitNumber}',
      status: data.status.toString().split('.').last.toLowerCase(),
      onEdit: () => _showEditLessonDialog(data),
      onDelete: () => _showDeletePasswordDialog(data.title, () {
        ref.read(firebaseServiceProvider).deleteLesson(data.id);
      }),
    );
  }

  Widget _baseContentCard({
    required String id,
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String author,
    required String status,
    required VoidCallback onDelete,
    VoidCallback? onEdit,
    String? audioUrl,
  }) {
    final isSelected = _selectedIds.contains(id);
    final statusStyle = status == 'validated' || status == 'published' || status == 'approved'
        ? BrandBadgeStyle.green
        : status == 'rejected'
        ? BrandBadgeStyle.dark
        : BrandBadgeStyle.gold;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => _toggleSelection(id),
        onTap: _isSelectionMode ? () => _toggleSelection(id) : null,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.gold500.withValues(alpha: 0.1)
                : (isDark ? AppColors.forest700.withValues(alpha: 0.3) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? AppColors.gold500 
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder),
              width: isSelected ? 2 : 1,
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
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: AppColors.gold500,
                    ),
                  ),
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
                      if (audioUrl != null && audioUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: PreviewAudioPlayer(audioUrl: audioUrl, size: 24),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    BrandBadge(text: status.toUpperCase(), style: statusStyle),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (onEdit != null)
                          _actionIcon(
                            Icons.edit_outlined,
                            onEdit,
                            color: AppColors.gold500,
                          ),
                        if (onEdit != null) const SizedBox(width: 8),
                        _actionIcon(
                          Icons.delete_outline_rounded,
                          onDelete,
                          color: AppColors.semanticRed,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  void _showEditDictionaryDialog(DictionaryEntry data) {
    final wordCtrl = TextEditingController(text: data.indigenousWord);
    final translationCtrl = TextEditingController(text: data.translation);
    final translationFilipinoCtrl = TextEditingController(text: data.translationFilipino);
    final phoneticCtrl = TextEditingController(text: data.phonetic ?? '');
    final contextCtrl = TextEditingController(text: data.usageContext);
    PartOfSpeech selectedPOS = data.partOfSpeech;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.forest800 : Colors.white,
          title: Text('Edit Dictionary Entry', style: AppTypography.h3.copyWith(color: AppColors.gold500)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: wordCtrl,
                  decoration: const InputDecoration(labelText: 'Indigenous Word'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                TextField(
                  controller: phoneticCtrl,
                  decoration: const InputDecoration(labelText: 'Phonetic (Optional)'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                TextField(
                  controller: translationCtrl,
                  decoration: const InputDecoration(labelText: 'English Translation'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                TextField(
                  controller: translationFilipinoCtrl,
                  decoration: const InputDecoration(labelText: 'Filipino Translation'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PartOfSpeech>(
                  initialValue: selectedPOS,
                  items: PartOfSpeech.values.map((pos) => DropdownMenuItem(
                    value: pos,
                    child: Text(pos.name.toUpperCase()),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedPOS = val!),
                  decoration: const InputDecoration(labelText: 'Part of Speech'),
                  dropdownColor: isDark ? AppColors.forest800 : Colors.white,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contextCtrl,
                  decoration: const InputDecoration(labelText: 'Usage Context / Definition'),
                  maxLines: 2,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            BrandButton(
              text: 'Save',
              type: BrandButtonType.primary,
              onTap: () async {
                final updatedEntry = DictionaryEntry(
                  id: data.id,
                  indigenousWord: wordCtrl.text,
                  phonetic: phoneticCtrl.text.isEmpty ? null : phoneticCtrl.text,
                  translation: translationCtrl.text,
                  translationFilipino: translationFilipinoCtrl.text,
                  partOfSpeech: selectedPOS,
                  language: data.language,
                  usageContext: contextCtrl.text,
                  usageExampleNative: data.usageExampleNative,
                  usageExampleTranslation: data.usageExampleTranslation,
                  audioUrl: data.audioUrl,
                  status: data.status,
                  contributorId: data.contributorId,
                  contributorName: data.contributorName,
                  validatorId: data.validatorId,
                  validatorRole: data.validatorRole,
                  validatedAt: data.validatedAt,
                  validatorFeedback: data.validatorFeedback,
                );
                await ref.read(firebaseServiceProvider).updateWord(data.id, updatedEntry.toFirestore());
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLessonDialog(Lesson data) {
    final titleCtrl = TextEditingController(text: data.title);
    final descCtrl = TextEditingController(text: data.description);
    final categoryCtrl = TextEditingController(text: data.category);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest800 : Colors.white,
        title: Text('Edit Lesson', style: AppTypography.h3.copyWith(color: AppColors.gold500)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          BrandButton(
            text: 'Save',
            type: BrandButtonType.primary,
            onTap: () async {
              final newLesson = Lesson(
                id: data.id,
                title: titleCtrl.text,
                description: descCtrl.text,
                category: categoryCtrl.text,
                language: data.language,
                level: data.level,
                unitNumber: data.unitNumber,
                tasks: data.tasks,
                isPremium: data.isPremium,
                icon: data.icon,
                status: data.status,
                prerequisiteId: data.prerequisiteId,
                isMistUnit: data.isMistUnit,
              );
              await ref.read(firebaseServiceProvider).saveLesson(newLesson);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
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
                    () async {
                      final words = await ref.read(allWordsProvider.future);
                      final pendingWords = words.where((w) => w.status == ValidationStatus.pending).map((w) => w.id).toList();
                      if (pendingWords.isNotEmpty) {
                        await ref.read(firebaseServiceProvider).bulkDeleteWords(pendingWords);
                      }

                      final recordings = await ref.read(allVoiceSubmissionsProvider.future);
                      final pendingRecs = recordings.where((r) => r.status == VoiceStatus.pending).map((r) => r.id).toList();
                      if (pendingRecs.isNotEmpty) {
                        await ref.read(firebaseServiceProvider).bulkDeleteVoiceSubmissions(pendingRecs);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Platform reset successful'),
                            backgroundColor: AppColors.semanticGreen,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDialectSettings() {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, child) {
          final settingsAsync = ref.watch(dialectSettingsProvider);
          return settingsAsync.when(
            data: (settings) => AlertDialog(
              backgroundColor: isDark ? AppColors.forest700 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Dialect Settings',
                style: AppTypography.h3.copyWith(color: AppColors.gold500),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: settings.entries
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
                              final newSettings = Map<String, bool>.from(settings);
                              newSettings[e.key] = v;
                              ref.read(firebaseServiceProvider).updateDialectSettings(newSettings);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              actions: [
                BrandButton(
                  text: 'Close',
                  type: BrandButtonType.primary,
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          );
        },
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

  void _exportData(String format) async {
    List<Map<String, dynamic>> data = [];
    
    if (_tabController.index == 0) {
      final words = await ref.read(allWordsProvider.future);
      data = words.map((e) => {
        'term': e.indigenousWord,
        'dialect': e.language,
        'pos': e.partOfSpeechLabel,
        'status': e.status.name,
      }).toList();
    } else if (_tabController.index == 1) {
      final recordings = await ref.read(allVoiceSubmissionsProvider.future);
       data = recordings.map((e) => {
        'title': e.title,
        'dialect': e.dialect,
        'contributor': e.contributorName,
        'status': e.status.name,
      }).toList();
    } else {
      final lessons = await ref.read(allLessonsStreamProvider.future);
      data = lessons.map((e) => {
        'title': e.title,
        'dialect': e.language,
        'category': e.category,
        'status': e.status.toString(),
      }).toList();
    }

    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export'))
        );
      }
      return;
    }

    String output;
    if (format == 'json') {
      output = const JsonEncoder.withIndent('  ').convert(data);
    } else {
      final headers = data.first.keys.join(',');
      final rows = [headers] +
          data.map((e) => e.values.join(',')).toList();
      output = rows.join('\n');
    }
    Clipboard.setData(ClipboardData(text: output));
    if (mounted) {
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
}

