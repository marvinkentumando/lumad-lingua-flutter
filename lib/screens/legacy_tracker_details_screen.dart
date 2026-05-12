import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dictionary_entry.dart';
import '../models/voice_submission.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/preview_audio_player.dart';

class LegacyTrackerDetailsScreen extends ConsumerStatefulWidget {
  const LegacyTrackerDetailsScreen({super.key});

  @override
  ConsumerState<LegacyTrackerDetailsScreen> createState() => _LegacyTrackerDetailsScreenState();
}

class _LegacyTrackerDetailsScreenState extends ConsumerState<LegacyTrackerDetailsScreen> with SingleTickerProviderStateMixin {
  String _selectedDialect = 'All';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedDialect = 'All'; // Reset filter when switching tabs
        });
      } else {
        // Trigger a rebuild when the tab is fully changed to update the filter chips
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final wordsAsync = ref.watch(userContributionsStreamProvider(user.uid));
    final voicesAsync = ref.watch(userVoiceSubmissionsStreamProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.forest900,
      body: AmbientTopoBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              const SizedBox(height: 16),
              _buildFilterChips(wordsAsync, voicesAsync),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWordsTab(wordsAsync),
                    _buildVoicesTab(voicesAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    AsyncValue<List<DictionaryEntry>> wordsAsync,
    AsyncValue<List<VoiceSubmission>> voicesAsync,
  ) {
    final Set<String> dialects = {'All'};

    // Populate chips based on the active tab
    if (_tabController.index == 0) {
      wordsAsync.whenData((words) {
        for (var word in words) {
          dialects.add(_capitalize(word.language.trim()));
        }
      });
    } else {
      voicesAsync.whenData((voices) {
        for (var voice in voices) {
          dialects.add(_capitalize(voice.dialect.trim()));
        }
      });
    }

    final sortedDialects = dialects.toList()..sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return a.compareTo(b);
    });

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: sortedDialects.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final dialect = sortedDialects[index];
          final isSelected = _selectedDialect == dialect;
          return GestureDetector(
            onTap: () => setState(() => _selectedDialect = dialect),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold500 : AppColors.forest800,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.gold500 : Colors.white10,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold500.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Text(
                dialect.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: isSelected ? AppColors.forest900 : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Legacy Details',
            style: AppTypography.h2ExtraBold.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.forest800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.gold500,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.forest900,
        unselectedLabelColor: Colors.white60,
        labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'WORDS'),
          Tab(text: 'AUDIOS'),
        ],
      ),
    );
  }

  Widget _buildWordsTab(AsyncValue<List<DictionaryEntry>> wordsAsync) {
    return wordsAsync.when(
      data: (words) {
        if (words.isEmpty) return _buildEmptyState('No words found');
        
        final filteredWords = _selectedDialect == 'All'
            ? words
            : words.where((w) => w.language.trim().toLowerCase() == _selectedDialect.toLowerCase()).toList();

        if (filteredWords.isEmpty) return _buildEmptyState('No words for $_selectedDialect');

        final grouped = <String, List<DictionaryEntry>>{};
        for (var word in filteredWords) {
          final normalizedDialect = _capitalize(word.language.trim());
          grouped.putIfAbsent(normalizedDialect, () => []).add(word);
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: grouped.entries.map((e) => _buildDialectGroup(e.key, e.value)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildVoicesTab(AsyncValue<List<VoiceSubmission>> voicesAsync) {
    return voicesAsync.when(
      data: (voices) {
        if (voices.isEmpty) return _buildEmptyState('No audio recordings found');

        final filteredVoices = _selectedDialect == 'All'
            ? voices
            : voices.where((v) => v.dialect.trim().toLowerCase() == _selectedDialect.toLowerCase()).toList();

        if (filteredVoices.isEmpty) return _buildEmptyState('No recordings for $_selectedDialect');

        final grouped = <String, List<VoiceSubmission>>{};
        for (var voice in filteredVoices) {
          final normalizedDialect = _capitalize(voice.dialect.trim());
          grouped.putIfAbsent(normalizedDialect, () => []).add(voice);
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: grouped.entries.map((e) => _buildVoiceDialectGroup(e.key, e.value)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildDialectGroup(String dialect, List<DictionaryEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.language_rounded, color: AppColors.gold500, size: 16),
              const SizedBox(width: 8),
              Text(
                dialect.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: AppColors.gold500.withOpacity(0.2))),
            ],
          ),
        ),
        ...entries.map((entry) => _buildEntryCard(entry)),
      ],
    );
  }

  Widget _buildVoiceDialectGroup(String dialect, List<VoiceSubmission> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.mic_rounded, color: AppColors.semanticBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                dialect.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.semanticBlue,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: AppColors.semanticBlue.withOpacity(0.2))),
            ],
          ),
        ),
        ...entries.map((entry) => _buildVoiceCard(entry)),
      ],
    );
  }

  Widget _buildEntryCard(DictionaryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            if (entry.audioUrl != null && entry.audioUrl!.isNotEmpty) ...[
              PreviewAudioPlayer(audioUrl: entry.audioUrl!, size: 32),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.indigenousWord,
                    style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    entry.translation,
                    style: AppTypography.body.copyWith(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(entry.status.name),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCard(VoiceSubmission voice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            if (voice.audioUrl.isNotEmpty)
              PreviewAudioPlayer(audioUrl: voice.audioUrl, size: 32)
            else
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white24, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voice.title,
                    style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    voice.speakerRole,
                    style: AppTypography.body.copyWith(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(voice.status.name),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = AppColors.semanticGreen;
        break;
      case 'pending':
        color = AppColors.gold500;
        break;
      case 'rejected':
      case 'flagged':
        color = AppColors.semanticRed;
        break;
      default:
        color = Colors.white24;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.label.copyWith(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_edu_rounded, color: Colors.white10, size: 64),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.body.copyWith(color: Colors.white24)),
        ],
      ),
    );
  }
}
