import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/dictionary_entry.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../utils/file_downloader.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_search_bar.dart';
import '../widgets/brand_text_field.dart';
import '../widgets/preview_audio_player.dart';
import '../widgets/admin/import_dictionary_modal.dart';

class AdminDictionaryScreen extends ConsumerStatefulWidget {
  const AdminDictionaryScreen({super.key});

  @override
  ConsumerState<AdminDictionaryScreen> createState() => _AdminDictionaryScreenState();
}

class _AdminDictionaryScreenState extends ConsumerState<AdminDictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDialect = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordsAsync = ref.watch(globalDictionaryStreamProvider(
      ValidatorQuery('', 100, search: _searchQuery, dialect: _selectedDialect),
    ));
    final dialectsAsync = ref.watch(dialectsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.forest900),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'DICTIONARY ARCHIVE',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.gold500),
            tooltip: 'Export CSV',
            onPressed: () => _exportDictionary(wordsAsync.value ?? []),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.gold500),
            tooltip: 'Import CSV',
            onPressed: () => _showImportModal(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 8),
                _buildDialectFilters(dialectsAsync, isDark),
              ],
            ),
          ),
          Expanded(
            child: wordsAsync.when(
              data: (words) => words.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: words.length,
                      itemBuilder: (context, index) => _buildWordCard(words[index], isDark, index),
                    ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryDialog(context, null),
        backgroundColor: AppColors.gold500,
        child: const Icon(Icons.add_rounded, color: AppColors.forest900),
      ),
    );
  }

  Widget _buildSearchBar() {
    return BrandSearchBar(
      controller: _searchController,
      hintText: 'Search indigenous or translation...',
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  Widget _buildDialectFilters(AsyncValue<List<String>> dialectsAsync, bool isDark) {
    return dialectsAsync.when(
      data: (dialects) => SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: dialects.length,
          itemBuilder: (context, i) {
            final d = dialects[i];
            final isSelected = _selectedDialect == d;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(d),
                selected: isSelected,
                onSelected: (s) => setState(() => _selectedDialect = d),
                selectedColor: AppColors.gold500,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : null,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildWordCard(DictionaryEntry word, bool isDark, int index) {
    return BrandCard(
      theme: isDark ? BrandCardTheme.cream : BrandCardTheme.gold,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      word.indigenousWord,
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.gold500.withValues(alpha: 0.1)
                            : AppColors.forest900.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        word.partOfSpeechLabel.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          color: isDark ? AppColors.gold500 : AppColors.gold900,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  word.usageContext.isNotEmpty ? word.usageContext : word.translation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${word.language} • ${word.status.name.toUpperCase()}',
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          if (word.audioUrl != null && word.audioUrl!.isNotEmpty)
            PreviewAudioPlayer(
              audioUrl: word.audioUrl!,
              size: 32,
              color: isDark ? AppColors.gold500 : AppColors.forest900,
            ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              Icons.edit_rounded,
              color: isDark ? AppColors.gold500 : AppColors.forest900,
              size: 20,
            ),
            onPressed: () => _showEntryDialog(context, word),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.semanticRed, size: 20),
            onPressed: () => _confirmDelete(word),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No matching words found.',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black38),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DictionaryEntry word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text('Are you sure you want to delete "${word.indigenousWord}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final term = word.indigenousWord;
              context.pop();
              await ref.read(firebaseServiceProvider).deleteWord(word.id);
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('"$term" deleted.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showEntryDialog(BuildContext context, DictionaryEntry? entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntryFormSheet(entry: entry),
    );
  }

  void _showImportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImportDictionaryModal(),
    );
  }

  Future<void> _exportDictionary(List<DictionaryEntry> words) async {
    HapticService.light();
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No dictionary entries available to export.')),
      );
      return;
    }

    try {
      final rows = [
        ['term', 'pos', 'dialect', 'definition', 'example_native', 'example_translation'],
        ...words.map((w) => [
          w.indigenousWord,
          w.partOfSpeech.name,
          w.language,
          w.usageContext,
          w.usageExampleNative ?? '',
          w.usageExampleTranslation ?? '',
        ]),
      ];

      final csvData = const CsvEncoder().convert(rows);
      final fileName = 'lumad_lingua_dictionary_${_selectedDialect.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final path = await FileDownloader.downloadCsv(csvData, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${words.length} entries ($path)'),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export dictionary: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }
}

class _EntryFormSheet extends ConsumerStatefulWidget {
  final DictionaryEntry? entry;
  const _EntryFormSheet({this.entry});

  @override
  ConsumerState<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends ConsumerState<_EntryFormSheet> {
  late TextEditingController _termCtrl;
  late TextEditingController _transEngCtrl;
  late TextEditingController _transFilCtrl;
  late TextEditingController _defCtrl;
  late TextEditingController _exNativeCtrl;
  late TextEditingController _exTransCtrl;
  
  String _language = 'Mansaka';
  PartOfSpeech _pos = PartOfSpeech.noun;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _termCtrl = TextEditingController(text: widget.entry?.indigenousWord);
    _transEngCtrl = TextEditingController(text: widget.entry?.translation);
    _transFilCtrl = TextEditingController(text: widget.entry?.translationFilipino);
    _defCtrl = TextEditingController(text: widget.entry?.usageContext);
    _exNativeCtrl = TextEditingController(text: widget.entry?.usageExampleNative);
    _exTransCtrl = TextEditingController(text: widget.entry?.usageExampleTranslation);

    if (widget.entry != null) {
      _language = widget.entry!.language;
      _pos = widget.entry!.partOfSpeech;
    }
  }

  @override
  void dispose() {
    _termCtrl.dispose();
    _transEngCtrl.dispose();
    _transFilCtrl.dispose();
    _defCtrl.dispose();
    _exNativeCtrl.dispose();
    _exTransCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialectsAsync = ref.watch(dialectsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest800 : AppColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.entry == null ? 'New Entry' : 'Edit Entry',
                  style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.forest900),
                ),
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Language / Dialect', isDark),
                  dialectsAsync.when(
                    data: (list) => DropdownButtonFormField<String>(
                      initialValue: list.contains(_language) ? _language : list.firstWhere((e) => e != 'All', orElse: () => 'Mansaka'),
                      dropdownColor: isDark ? AppColors.forest800 : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: _inputDecoration(isDark),
                      items: list.where((d) => d != 'All').map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setState(() => _language = v!),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading dialects'),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Part of Speech', isDark),
                  DropdownButtonFormField<PartOfSpeech>(
                    initialValue: _pos,
                    dropdownColor: isDark ? AppColors.forest800 : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: _inputDecoration(isDark),
                    items: PartOfSpeech.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _pos = v!),
                  ),
                  const SizedBox(height: 16),
                  BrandTextField(controller: _termCtrl, labelText: 'Indigenous Term (Word)', prefixIcon: Icons.translate_rounded),
                  const SizedBox(height: 16),
                  BrandTextField(controller: _defCtrl, labelText: 'Definition', prefixIcon: Icons.description_rounded, maxLines: 3),
                  const SizedBox(height: 16),
                  BrandTextField(controller: _exNativeCtrl, labelText: 'Example Sentence (Mansaka)', prefixIcon: Icons.history_edu_rounded),
                  const SizedBox(height: 16),
                  BrandTextField(controller: _exTransCtrl, labelText: 'Example Translation (English)', prefixIcon: Icons.auto_stories_rounded),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: BrandButton(
                      text: _loading ? 'SAVING...' : 'SAVE',
                      type: BrandButtonType.primary,
                      onTap: _loading ? null : _save,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label.copyWith(
          color: isDark ? Colors.white24 : AppColors.creamText3,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _save() async {
    if (_termCtrl.text.isEmpty || _defCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Term and Definition are required.')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);

    try {
      final entry = DictionaryEntry(
        id: widget.entry?.id ?? '',
        indigenousWord: _termCtrl.text.trim(),
        phonetic: widget.entry?.phonetic,
        translation: _transEngCtrl.text.trim(),
        translationFilipino: _transFilCtrl.text.trim(),
        partOfSpeech: _pos,
        language: _language,
        usageContext: _defCtrl.text.trim(),
        usageExampleNative: _exNativeCtrl.text.trim(),
        usageExampleTranslation: _exTransCtrl.text.trim(),
        audioUrl: widget.entry?.audioUrl,
        status: widget.entry?.status ?? ValidationStatus.approved,
        submittedAt: widget.entry?.submittedAt ?? DateTime.now(),
      );

      if (widget.entry == null) {
        await ref.read(firebaseServiceProvider).addWord(entry);
      } else {
        await ref.read(firebaseServiceProvider).updateWord(widget.entry!.id, entry.toFirestore());
      }

      if (mounted) {
        HapticService.success();
        Navigator.of(context).pop();
        messenger.showSnackBar(const SnackBar(content: Text('Entry saved successfully.')));
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
