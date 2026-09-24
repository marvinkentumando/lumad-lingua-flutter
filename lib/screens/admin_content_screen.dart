import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../models/scenario_models.dart';
import '../models/admin_models.dart';
import '../widgets/brand_search_bar.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_text_field.dart';
import '../widgets/branded_empty_state.dart';
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
  late Stream<List<AuditLogEntry>> _auditStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _auditStream = ref.read(firebaseServiceProvider).getAuditTrail();
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
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: Stack(
          children: [
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
                        _buildScenariosTab(),
                        _buildAuditTab(),
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
    } else if (_tabController.index == 3) {
       final scenarios = ref.read(scenariosProvider).value ?? [];
       idsToSelect = scenarios.where((s) =>
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.description.toLowerCase().contains(_searchQuery.toLowerCase())
        ).map((e) => e.id).toList();
    }

    if (idsToSelect.isEmpty) return;

    setState(() {
      bool allSelected = idsToSelect.every((id) => _selectedIds.contains(id));
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

  void _handleBulkDelete() {
    _showDeletePasswordDialog('Selected Items', () async {
      if (_tabController.index == 0) {
        await ref.read(firebaseServiceProvider).bulkDeleteWords(_selectedIds.toList());
      } else if (_tabController.index == 1) {
        await ref.read(firebaseServiceProvider).bulkDeleteVoiceSubmissions(_selectedIds.toList());
      } else if (_tabController.index == 2) {
        await ref.read(firebaseServiceProvider).bulkDeleteLessons(_selectedIds.toList());
      } else if (_tabController.index == 3) {
        for (var id in _selectedIds) {
          await ref.read(firebaseServiceProvider).deleteScenario(id);
        }
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
                  'Content Management',
                  style: TextStyle(
                    color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3) : AppColors.creamText3,
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.settings_suggest_rounded,
                color: isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.secondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BrandSearchBar(
        controller: _searchCtrl,
        hintText: 'Search terms or contributors...',
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        onTap: (_) {
          HapticService.light();
          if (_isSelectionMode) {
            setState(() {
              _selectedIds.clear();
              _isSelectionMode = false;
            });
          }
        },
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.gold500,
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'DICTIONARY'),
          Tab(text: 'RECORDINGS'),
          Tab(text: 'LESSONS'),
          Tab(text: 'SCENARIOS'),
          Tab(text: 'AUDIT'),
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

  Widget _buildScenariosTab() {
    final scenariosAsync = ref.watch(scenariosProvider);

    return scenariosAsync.when(
      data: (scenarios) {
        final filtered = scenarios.where((s) => 
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          s.description.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

        if (filtered.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _scenarioCard(filtered[index], index),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAuditTab() {
    return StreamBuilder<List<AuditLogEntry>>(
      stream: _auditStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const BrandedEmptyState(
            title: 'Silence in the Valley',
            message: 'No audit logs have been recorded yet.',
            icon: Icons.history_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(log.icon, style: const TextStyle(fontSize: 18))),
                  ),
                  title: Text(
                    '${log.action}: ${log.targetName}',
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'by ${log.actorName} · ${log.timeAgo}',
                        style: AppTypography.label.copyWith(color: isDark ? Colors.white60 : AppColors.creamText3, fontSize: 11),
                      ),
                      if (log.metadata != null)
                         Text(
                           log.metadata!.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                           style: AppTypography.mono.copyWith(color: AppColors.gold500.withValues(alpha: 0.6), fontSize: 9),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return BrandedEmptyState(
      title: _searchQuery.isNotEmpty ? 'No Echoes Found' : 'Clean Slate',
      message: _searchQuery.isNotEmpty
          ? 'No matching content found for your search.'
          : 'This section is currently empty.',
      icon: _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.inventory_2_rounded,
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
      onHistory: () => _showVersionHistoryModal(data.id, 'words', data.indigenousWord),
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
      onHistory: () => _showVersionHistoryModal(data.id, 'voice_submissions', data.title),
      onDelete: () => _showDeletePasswordDialog(data.title, () {
        ref.read(firebaseServiceProvider).bulkDeleteVoiceSubmissions([data.id]);
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
      status: data.status,
      onHistory: () => _showVersionHistoryModal(data.id, 'lessons', data.title),
      onDelete: () => _showDeletePasswordDialog(data.title, () {
        ref.read(firebaseServiceProvider).deleteLesson(data.id);
      }),
    );
  }

  Widget _scenarioCard(Scenario data, int index) {
    return _baseContentCard(
      id: data.id,
      index: index,
      icon: Icons.auto_stories_rounded,
      iconColor: AppColors.gold500,
      title: data.title,
      subtitle: '${data.difficulty} · ${data.nodes.length} nodes',
      author: '${data.baseReward} XP Base Reward',
      status: 'active',
      onDelete: () => _showDeletePasswordDialog(data.title, () {
        ref.read(firebaseServiceProvider).deleteScenario(data.id);
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
    VoidCallback? onHistory,
    String? audioUrl,
  }) {
    final isSelected = _selectedIds.contains(id);
    final statusLower = status.toLowerCase();
    final statusStyle = (statusLower == 'validated' || statusLower == 'published' || statusLower == 'approved' || statusLower == 'active')
        ? BrandBadgeStyle.green
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
                : (isDark ? AppColors.forest700.withValues(alpha: 0.3) : AppColors.gold500),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? AppColors.gold500 
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.gold700.withValues(alpha: 0.2)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: isSelected 
                    ? AppColors.gold500.withValues(alpha: 0.2) 
                    : AppColors.gold700.withValues(alpha: 0.1),
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
                      color: isDark ? AppColors.gold500 : AppColors.forest900,
                    ),
                  ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: isDark ? iconColor : AppColors.forest900, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h3.copyWith(
                          color: isDark ? Colors.white : AppColors.forest900,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.label.copyWith(
                          color: isDark ? Colors.white60 : AppColors.forest700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        author,
                        style: AppTypography.mono.copyWith(
                          color: isDark ? AppColors.gold500.withValues(alpha: 0.6) : AppColors.forest900.withValues(alpha: 0.5),
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
                    BrandBadge(
                      text: status.toUpperCase(), 
                      style: isDark ? statusStyle : BrandBadgeStyle.dark,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        if (onHistory != null)
                          _actionIcon(
                            Icons.history_rounded,
                            onHistory,
                            color: isDark ? AppColors.gold500 : AppColors.forest900,
                          ),
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

  void _showVersionHistoryModal(String docId, String collection, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.gold500),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VERSION HISTORY', style: AppTypography.label.copyWith(color: AppColors.gold500, letterSpacing: 2)),
                      Text(title, style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.forest900), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final historyAsync = ref.watch(versionHistoryProvider((path: collection, id: docId)));
                
                return historyAsync.when(
                  data: (history) {
                    if (history.isEmpty) {
                      return const BrandedEmptyState(
                        title: 'No Past Lives',
                        message: 'No version history found for this item.',
                        icon: Icons.history_rounded,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: history.length,
                      itemBuilder: (context, idx) {
                        final item = history[idx];
                        final snapshot = item['snapshot'] as Map<String, dynamic>?;
                        final timestamp = (item['timestamp'] as dynamic)?.toDate() as DateTime?;
                        
                        return Card(
                          color: isDark ? AppColors.forest800 : Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text(
                              timestamp != null ? timestamp.toString().substring(0, 16) : 'Unknown Date',
                              style: AppTypography.body.copyWith(color: isDark ? Colors.white : AppColors.forest900, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Modified by: ${item['actorId'] ?? 'System'}',
                              style: AppTypography.label.copyWith(color: isDark ? Colors.white60 : AppColors.creamText3),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: AppColors.gold500),
                              onPressed: () => _showSnapshotDetails(snapshot ?? {}),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading history: $err')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSnapshotDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        title: const Text('Version Snapshot'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: data.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(text: TextSpan(
                children: [
                  TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold500)),
                  TextSpan(text: '${e.value}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ]
              )),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showDeletePasswordDialog(String itemName, VoidCallback onConfirm) {
    _passwordCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            BrandTextField(
              controller: _passwordCtrl,
              labelText: 'Administrator Password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : AppColors.creamText3)),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  color: isDark ? Colors.white60 : AppColors.creamText3,
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
                icon: Icons.auto_stories_rounded,
                color: AppColors.gold500,
                title: 'Seed Scenarios',
                subtitle: 'Add sample cultural scenarios to database',
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmAction(
                    'Seed Scenarios',
                    'This will add sample scenarios to your Firestore collection.',
                    () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(firebaseServiceProvider).seedScenarios();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Scenarios seeded successfully'),
                          backgroundColor: AppColors.semanticGreen,
                        ),
                      );
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
                                color: Theme.of(context).colorScheme.onSurface,
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
      onTap: () {
        HapticService.selection();
        onTap();
      },
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
          color: isDark ? Colors.white60 : AppColors.creamText3,
          fontSize: 11,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black12),
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
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white54 : AppColors.creamText3),
            ),
          ),
          BrandButton(
            text: 'Confirm',
            type: BrandButtonType.primary,
            onTap: () {
              context.pop();
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
    } else if (_tabController.index == 2) {
      final lessons = await ref.read(allLessonsStreamProvider.future);
      data = lessons.map((e) => {
        'title': e.title,
        'dialect': e.language,
        'category': e.category,
        'status': e.status.toString(),
      }).toList();
    } else if (_tabController.index == 3) {
      final scenarios = await ref.read(scenariosProvider.future);
      data = scenarios.map((e) => {
        'title': e.title,
        'difficulty': e.difficulty,
        'nodes': e.nodes.length.toString(),
        'reward': e.baseReward.toString(),
      }).toList();
    } else if (_tabController.index == 4) {
      final logs = await ref.read(firebaseServiceProvider).getAuditTrail().first;
      data = logs.map((e) => {
        'action': e.action,
        'target': e.targetName,
        'actor': e.actorName,
        'type': e.targetType,
        'time': e.timeAgo,
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
          data.map((e) => e.values.map((v) => '"$v"').join(',')).toList();
      output = rows.join('\n');
    }

    if (!mounted) return;
    
    Clipboard.setData(ClipboardData(text: output));
    if (context.mounted) {
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
