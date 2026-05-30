import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' hide Source;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/dictionary_entry.dart';
import '../models/voice_submission.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_storage_service.dart';
import '../utils/audio_validator.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_text_field.dart';
import '../widgets/preview_audio_player.dart';

class LegacyTrackerDetailsScreen extends ConsumerStatefulWidget {
  const LegacyTrackerDetailsScreen({super.key});

  @override
  ConsumerState<LegacyTrackerDetailsScreen> createState() => _LegacyTrackerDetailsScreenState();
}

class _LegacyTrackerDetailsScreenState extends ConsumerState<LegacyTrackerDetailsScreen> with SingleTickerProviderStateMixin {
  String _selectedDialect = 'All';
  late TabController _tabController;
  late AudioRecorder _recorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
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
    _recorder.dispose();
    _audioPlayer.dispose();
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
                          color: AppColors.gold500.withValues(alpha: 0.3),
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
              Expanded(child: Divider(color: AppColors.gold500.withValues(alpha: 0.2))),
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
              Expanded(child: Divider(color: AppColors.semanticBlue.withValues(alpha: 0.2))),
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
        onTap: () => _showEntryDetails(entry),
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
        onTap: () => _showVoiceDetails(voice),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  // --- Detailed View & Editing Logic ---

  void _showEntryDetails(DictionaryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.indigenousWord,
                      style: AppTypography.h1ExtraBold.copyWith(color: AppColors.gold500),
                    ),
                  ),
                  _buildStatusBadge(entry.status.name),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${entry.partOfSpeechLabel.toUpperCase()} • ${entry.language.toUpperCase()}',
                style: AppTypography.label.copyWith(color: Colors.white60, letterSpacing: 1.2),
              ),
              const SizedBox(height: 24),
              _buildDetailItem('English Translation', entry.translation),
              _buildDetailItem('Filipino Translation', entry.translationFilipino),
              if (entry.phonetic != null && entry.phonetic!.isNotEmpty)
                _buildDetailItem('Phonetic', entry.phonetic!),
              _buildDetailItem('Definition', entry.usageContext),
              if (entry.usageExampleNative != null && entry.usageExampleNative!.isNotEmpty)
                _buildDetailItem('Usage (Native)', entry.usageExampleNative!),
              if (entry.usageExampleTranslation != null && entry.usageExampleTranslation!.isNotEmpty)
                _buildDetailItem('Usage (Translation)', entry.usageExampleTranslation!),
              const SizedBox(height: 16),
              if (entry.audioUrl != null && entry.audioUrl!.isNotEmpty) ...[
                Text('Pronunciation', style: AppTypography.label.copyWith(color: AppColors.gold500)),
                const SizedBox(height: 8),
                PreviewAudioPlayer(audioUrl: entry.audioUrl!, size: 48),
                const SizedBox(height: 24),
              ],
              if (entry.validatorFeedback != null && entry.validatorFeedback!.isNotEmpty)
                _buildFeedbackSection(entry.validatorFeedback!),
              const SizedBox(height: 24),
              _buildVersionHistorySection('words', entry.id),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: BrandButton(
                  text: 'EDIT ENTRY',
                  type: BrandButtonType.primary,
                  icon: Icons.edit_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditEntrySheet(entry);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoiceDetails(VoiceSubmission voice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      voice.title,
                      style: AppTypography.h1ExtraBold.copyWith(color: AppColors.semanticBlue),
                    ),
                  ),
                  _buildStatusBadge(voice.status.name),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${voice.speakerRole.toUpperCase()} • ${voice.dialect.toUpperCase()}',
                style: AppTypography.label.copyWith(color: Colors.white60, letterSpacing: 1.2),
              ),
              const SizedBox(height: 24),
              if (voice.transcript.isNotEmpty)
                _buildDetailItem('Indigenous Phrase', voice.transcript),
              if (voice.culturalNote != null && voice.culturalNote!.isNotEmpty)
                _buildDetailItem('Cultural Note', voice.culturalNote!),
              _buildDetailItem('Location', '${voice.barangay ?? ''}, ${voice.municipality ?? ''}, ${voice.province ?? ''}'),
              const SizedBox(height: 16),
              if (voice.audioUrl.isNotEmpty) ...[
                Text('Audio Recording', style: AppTypography.label.copyWith(color: AppColors.semanticBlue)),
                const SizedBox(height: 8),
                PreviewAudioPlayer(audioUrl: voice.audioUrl, size: 48),
                const SizedBox(height: 24),
              ],
              if (voice.validatorFeedback != null && voice.validatorFeedback!.isNotEmpty)
                _buildFeedbackSection(voice.validatorFeedback!),
              const SizedBox(height: 24),
              _buildVersionHistorySection('voice_submissions', voice.id),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: BrandButton(
                  text: 'EDIT RECORDING',
                  type: BrandButtonType.primary,
                  icon: Icons.edit_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditVoiceSheet(voice);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.label.copyWith(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.body.copyWith(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(String feedback) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.feedback_rounded, color: AppColors.gold500, size: 16),
              const SizedBox(width: 8),
              Text('VALIDATOR FEEDBACK', style: AppTypography.label.copyWith(color: AppColors.gold500, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(feedback, style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildVersionHistorySection(String collection, String id) {
    return Consumer(
      builder: (context, ref, child) {
        final historyAsync = ref.watch(versionHistoryProvider((path: collection, id: id)));

        return historyAsync.when(
          data: (history) {
            if (history.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppColors.gold500, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'VERSION HISTORY',
                      style: AppTypography.label.copyWith(color: AppColors.gold500, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...history.map((version) => _buildVersionItem(version)),
              ],
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold500),
          )),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildVersionItem(Map<String, dynamic> version) {
    final timestamp = (version['timestamp'] as Timestamp?)?.toDate();
    final snapshot = version['snapshot'] as Map<String, dynamic>?;
    final status = snapshot?['status'] ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timestamp != null ? _formatDateTime(timestamp) : 'Unknown Date',
                style: AppTypography.label.copyWith(color: Colors.white38, fontSize: 10),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Archived state before update',
            style: AppTypography.body.copyWith(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showEditEntrySheet(DictionaryEntry entry) {
    final wordController = TextEditingController(text: entry.indigenousWord);
    final phoneticController = TextEditingController(text: entry.phonetic);
    final englishController = TextEditingController(text: entry.translation);
    final filipinoController = TextEditingController(text: entry.translationFilipino);
    final definitionController = TextEditingController(text: entry.usageContext);
    final usageNativeController = TextEditingController(text: entry.usageExampleNative);
    final usageTranslationController = TextEditingController(text: entry.usageExampleTranslation);
    String? selectedLanguage = entry.language;
    PartOfSpeech selectedPOS = entry.partOfSpeech;
    String? localAudioPath = entry.audioUrl;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, child) {
                final dialectsAsync = ref.watch(dialectsProvider);
                final List<String> dialects = dialectsAsync.value?.where((d) => d != "All").toList() ?? [];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Edit Entry', style: AppTypography.h2ExtraBold.copyWith(color: AppColors.gold500)),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white60),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField<String>(
                          label: "Language / Dialect",
                          value: dialects.contains(selectedLanguage) ? selectedLanguage : null,
                          items: dialects,
                          onChanged: (val) => setModalState(() => selectedLanguage = val),
                          hint: "Select Dialect",
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField<PartOfSpeech>(
                          label: "Part of Speech",
                          value: selectedPOS,
                          items: PartOfSpeech.values,
                          itemLabel: (pos) => pos.name.toUpperCase(),
                          onChanged: (val) => setModalState(() => selectedPOS = val!),
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(controller: wordController, labelText: "Indigenous Word", prefixIcon: Icons.translate_rounded),
                        const SizedBox(height: 16),
                        BrandTextField(controller: phoneticController, labelText: "Phonetic (Optional)", prefixIcon: Icons.record_voice_over_rounded),
                        const SizedBox(height: 16),
                        BrandTextField(controller: englishController, labelText: "English Translation", prefixIcon: Icons.language_rounded),
                        const SizedBox(height: 16),
                        BrandTextField(controller: filipinoController, labelText: "Filipino Translation", prefixIcon: Icons.flag_rounded),
                        const SizedBox(height: 16),
                        BrandTextField(controller: definitionController, labelText: "Definition", prefixIcon: Icons.description_rounded, maxLines: 3),
                        const SizedBox(height: 16),
                        BrandTextField(controller: usageNativeController, labelText: "Usage Example (Native)", prefixIcon: Icons.history_edu_rounded),
                        const SizedBox(height: 16),
                        BrandTextField(controller: usageTranslationController, labelText: "Usage Example (Translation)", prefixIcon: Icons.auto_stories_rounded),
                        const SizedBox(height: 24),
                        Text("Audio Pronunciation", style: AppTypography.label.copyWith(color: AppColors.gold500)),
                        const SizedBox(height: 12),
                        if (localAudioPath == null || localAudioPath!.isEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: BrandButton(
                                  text: _isRecording ? 'Stop' : 'Record',
                                  type: _isRecording ? BrandButtonType.primary : BrandButtonType.secondary,
                                  icon: _isRecording ? Icons.stop_circle : Icons.mic_none_rounded,
                                  onTap: () async {
                                    if (_isRecording) {
                                      final path = await _stopRecording();
                                      setModalState(() => localAudioPath = path);
                                    } else {
                                      await _startRecording();
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: BrandButton(
                                  text: 'Upload',
                                  type: BrandButtonType.secondary,
                                  icon: Icons.upload_file_rounded,
                                  onTap: () async {
                                    final result = await FilePicker.pickFiles(type: FileType.audio);
                                    if (result != null) setModalState(() => localAudioPath = result.files.single.path);
                                  },
                                ),
                              ),
                            ],
                          )
                        else
                          _buildAudioPreviewRow(localAudioPath!, (path) => setModalState(() => localAudioPath = path)),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: BrandButton(
                            text: 'Update & Resubmit',
                            type: BrandButtonType.primary,
                            onTap: () async {
                              if (selectedLanguage == null || wordController.text.isEmpty || englishController.text.isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                                return;
                              }

                              String? audioUrl = localAudioPath;
                              if (localAudioPath != null && !localAudioPath!.startsWith('http')) {
                                // Validate constraints
                                final audioError = await AudioValidator.validate(localAudioPath!);
                                if (audioError != null) {
                                  if (sheetContext.mounted) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(content: Text(audioError), backgroundColor: AppColors.semanticRed),
                                    );
                                  }
                                  return;
                                }

                                setModalState(() => isUploading = true);
                                try {
                                  final fileName = 'word_edit_${DateTime.now().millisecondsSinceEpoch}.m4a';
                                  audioUrl = await ref.read(supabaseStorageServiceProvider).uploadAudio(File(localAudioPath!), fileName);
                                } catch (e) {
                                  debugPrint('Upload error: $e');
                                } finally {
                                  setModalState(() => isUploading = false);
                                }
                              }

                              final updatedEntry = DictionaryEntry(
                                id: entry.id,
                                indigenousWord: wordController.text,
                                phonetic: phoneticController.text,
                                translation: englishController.text,
                                translationFilipino: filipinoController.text,
                                partOfSpeech: selectedPOS,
                                language: selectedLanguage!,
                                usageContext: definitionController.text,
                                usageExampleNative: usageNativeController.text,
                                usageExampleTranslation: usageTranslationController.text,
                                audioUrl: audioUrl,
                                status: ValidationStatus.pending,
                                contributorId: entry.contributorId,
                                contributorName: entry.contributorName,
                                submittedAt: DateTime.now(),
                              );

                              await ref.read(firebaseServiceProvider).updateWord(entry.id, updatedEntry.toFirestore());
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry updated and sent for re-validation.')));
                              }
                            },
                          ),
                        ),
                        if (isUploading) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator(color: AppColors.gold500))),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditVoiceSheet(VoiceSubmission voice) {
    final titleController = TextEditingController(text: voice.title);
    final transcriptController = TextEditingController(text: voice.transcript);
    final noteController = TextEditingController(text: voice.culturalNote);
    String? localAudioPath = voice.audioUrl;
    String? selectedDialect = voice.dialect;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, child) {
                final dialectsAsync = ref.watch(dialectsProvider);
                final List<String> dialects = dialectsAsync.value?.where((d) => d != "All").toList() ?? [];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Edit Recording', style: AppTypography.h2ExtraBold.copyWith(color: AppColors.semanticBlue)),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white60),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(controller: titleController, labelText: "Title / Label", prefixIcon: Icons.title_rounded),
                        const SizedBox(height: 16),
                        _buildDropdownField<String>(
                          label: "Dialect",
                          value: dialects.contains(selectedDialect) ? selectedDialect : null,
                          items: dialects,
                          onChanged: (val) => setModalState(() => selectedDialect = val),
                          hint: "Select Dialect",
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(controller: transcriptController, labelText: "Transcript", prefixIcon: Icons.notes_rounded, maxLines: 2),
                        const SizedBox(height: 16),
                        BrandTextField(controller: noteController, labelText: "Cultural Note", prefixIcon: Icons.info_outline_rounded, maxLines: 3),
                        const SizedBox(height: 24),
                        Text("Audio Recording", style: AppTypography.label.copyWith(color: AppColors.semanticBlue)),
                        const SizedBox(height: 12),
                        if (localAudioPath == null || localAudioPath!.isEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: BrandButton(
                                  text: _isRecording ? 'Stop' : 'Record',
                                  type: _isRecording ? BrandButtonType.primary : BrandButtonType.secondary,
                                  icon: _isRecording ? Icons.stop_circle : Icons.mic_none_rounded,
                                  onTap: () async {
                                    if (_isRecording) {
                                      final path = await _stopRecording();
                                      setModalState(() => localAudioPath = path);
                                    } else {
                                      await _startRecording();
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ),
                            ],
                          )
                        else
                          _buildAudioPreviewRow(localAudioPath!, (path) => setModalState(() => localAudioPath = path), color: AppColors.semanticBlue),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: BrandButton(
                            text: 'Update & Resubmit',
                            type: BrandButtonType.primary,
                            onTap: () async {
                              if (titleController.text.isEmpty || selectedDialect == null) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Please fill required fields.')));
                                return;
                              }

                              String? audioUrl = localAudioPath;
                              if (localAudioPath != null && !localAudioPath!.startsWith('http')) {
                                // Validate constraints
                                final audioError = await AudioValidator.validate(localAudioPath!);
                                if (audioError != null) {
                                  if (sheetContext.mounted) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(content: Text(audioError), backgroundColor: AppColors.semanticRed),
                                    );
                                  }
                                  return;
                                }

                                setModalState(() => isUploading = true);
                                try {
                                  final fileName = 'voice_edit_${DateTime.now().millisecondsSinceEpoch}.m4a';
                                  audioUrl = await ref.read(supabaseStorageServiceProvider).uploadAudio(File(localAudioPath!), fileName);
                                } catch (e) {
                                  debugPrint('Upload error: $e');
                                } finally {
                                  setModalState(() => isUploading = false);
                                }
                              }

                              final updatedData = {
                                'title': titleController.text,
                                'dialect': selectedDialect,
                                'transcript': transcriptController.text,
                                'culturalNote': noteController.text,
                                'audioUrl': audioUrl,
                                'status': 'pending',
                                'submittedAt': FieldValue.serverTimestamp(),
                              };

                              // Using db directly as FirebaseService doesn't have updateVoiceSubmission
                              await ref.read(firebaseServiceProvider).db.collection('voice_submissions').doc(voice.id).update(updatedData);
                              
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording updated and sent for re-validation.')));
                              }
                            },
                          ),
                        ),
                        if (isUploading) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator(color: AppColors.semanticBlue))),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String? hint,
    String Function(T)? itemLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: Colors.white60)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.forest900, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: hint != null ? Text(hint, style: const TextStyle(color: Colors.white24, fontSize: 14)) : null,
              dropdownColor: AppColors.forest900,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gold500),
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel != null ? itemLabel(item) : item.toString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPreviewRow(String path, void Function(String?) onDelete, {Color color = AppColors.gold500}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forest900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.audio_file_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path.contains('/') ? path.split('/').last : "Audio recording",
              style: AppTypography.mono.copyWith(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatefulBuilder(builder: (context, setInternalState) {
            return IconButton(
              icon: Icon(
                _isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded,
                color: color,
                size: 28,
              ),
              onPressed: () => _playPreview(path, (fn) => setInternalState(fn)),
            );
          }),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.terracotta, size: 20),
            onPressed: () {
              if (_isPlaying) _audioPlayer.stop();
              onDelete(null);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        const config = RecordConfig();
        await _recorder.start(config, path: path);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<String?> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    return path;
  }

  Future<void> _playPreview(String path, Function(VoidCallback) setModalState) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setModalState(() => _isPlaying = false);
        setState(() => _isPlaying = false);
      } else {
        Source source = path.startsWith('http') ? UrlSource(path) : DeviceFileSource(path);
        await _audioPlayer.play(source);
        setModalState(() => _isPlaying = true);
        setState(() => _isPlaying = true);

        _audioPlayer.onPlayerComplete.first.then((_) {
          if (mounted) {
            setModalState(() => _isPlaying = false);
            setState(() => _isPlaying = false);
          }
        });
      }
    } catch (e) {
      debugPrint('Error playing preview: $e');
    }
  }
}
