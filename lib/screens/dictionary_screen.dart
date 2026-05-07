import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dictionary_entry.dart';
import '../models/srs_models.dart';
import '../widgets/brand_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../providers/saved_words_provider.dart';
import '../widgets/skeleton.dart';
import '../widgets/brand_search_bar.dart';
import '../widgets/ambient_topo_background.dart';

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  String? _expandedWordId;
  _DictionarySort _selectedSort = _DictionarySort.alphabetical;
  final _searchController = TextEditingController();

  final PageController _pageController = PageController();
  final List<String> _categories = [
    'ALL',
    'SAVED',
    'MANSAKA',
    'MANDAYA',
    'TAGAKAULO',
    'B\'LAAN',
    'BAGOGO',
  ];


  List<DictionaryEntry> _applySort(List<DictionaryEntry> entries) {
    var filtered = List<DictionaryEntry>.from(entries);
    switch (_selectedSort) {
      case _DictionarySort.alphabetical:
        filtered.sort(
          (a, b) => a.indigenousWord.toLowerCase().compareTo(
            b.indigenousWord.toLowerCase(),
          ),
        );
        break;
      case _DictionarySort.reverseAlphabetical:
        filtered.sort(
          (a, b) => b.indigenousWord.toLowerCase().compareTo(
            a.indigenousWord.toLowerCase(),
          ),
        );
        break;
      case _DictionarySort.newest:
        filtered.sort(
          (a, b) => (b.validatedAt ?? DateTime(0)).compareTo(
            a.validatedAt ?? DateTime(0),
          ),
        );
        break;
      case _DictionarySort.oldest:
        filtered.sort(
          (a, b) => (a.validatedAt ?? DateTime(0)).compareTo(
            b.validatedAt ?? DateTime(0),
          ),
        );
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final dictionaryAsync = ref.watch(dictionaryStreamProvider);
    final savedIds = ref.watch(savedWordsProvider);
    final user = ref.watch(authStateProvider).value;
    final srsAsync = user != null
        ? ref.watch(srsProgressStreamProvider(user.uid))
        : const AsyncValue.data(<SRSProgress>[]);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientTopoBackground(
        child: SafeArea(
          child: dictionaryAsync.when(
            data: (entries) {
              return srsAsync.when(
                data: (srsList) {
                  final srsMap = {for (var s in srsList) s.wordId: s};

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            _buildSearchBar(),
                            const SizedBox(height: 24),
                            _buildCategoryRow(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedCategory = _categories[index];
                            });
                          },
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            var items = entries;
                            if (category == 'SAVED') {
                              items = items
                                  .where((e) => savedIds.contains(e.id))
                                  .toList();
                            } else if (category != 'ALL') {
                              items = items
                                  .where(
                                    (e) => e.language.toUpperCase() == category,
                                  )
                                  .toList();
                            }

                            if (_searchQuery.isNotEmpty) {
                              items = items
                                  .where(
                                    (e) =>
                                        e.indigenousWord.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ) ||
                                        e.translation.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ),
                                  )
                                  .toList();
                            }

                            items = _applySort(items);

                            if (items.isEmpty) {
                              return SingleChildScrollView(
                                child: _buildNoResultsState(
                                  isSavedTab: category == 'SAVED',
                                ),
                              );
                            }

                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final entry = items[i];
                                final srs = srsMap[entry.id];
                                return _DictionaryEntryCard(
                                  entry: entry,
                                  isExpanded: _expandedWordId == entry.id,
                                  masteryLevel: srs?.mastery,
                                  onToggleExpanded: () {
                                    setState(() {
                                      _expandedWordId =
                                          _expandedWordId == entry.id
                                          ? null
                                          : entry.id;
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'Error loading mastery: $err',
                    style: const TextStyle(color: AppColors.semanticRed),
                  ),
                ),
              );
            },
            loading: () => ListView.separated(
              itemCount: 5,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, __) =>
                  const Skeleton(height: 80, borderRadius: 24),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error loading dictionary: $err',
                style: const TextStyle(color: AppColors.semanticRed),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState({bool isSavedTab = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              isSavedTab
                  ? Icons.bookmark_outline_rounded
                  : Icons.search_off_rounded,
              color: isDark ? Colors.white24 : AppColors.forest200,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isSavedTab
                  ? 'You haven\'t saved any words yet.'
                  : 'No words match your search.',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white38 : AppColors.creamText2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: BrandSearchBar(
            controller: _searchController,
            hintText: 'Search words...',
            isMinimal: true,
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(width: 12),
        _buildSortMenu(Theme.of(context).brightness == Brightness.dark),
      ],
    );
  }

  Widget _buildSortMenu(bool isDark) {
    return PopupMenuButton<_DictionarySort>(
      initialValue: _selectedSort,
      onSelected: (sort) => setState(() => _selectedSort = sort),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.forestDarkCard
              : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
        child: Icon(
          Icons.sort_rounded,
          color: isDark ? AppColors.gold500 : AppColors.forest500,
          size: 20,
        ),
      ),
      color: isDark ? AppColors.forest800 : AppColors.creamBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => [
        _buildSortItem(
          _DictionarySort.alphabetical,
          'A - Z',
          Icons.sort_by_alpha,
          isDark,
        ),
        _buildSortItem(
          _DictionarySort.reverseAlphabetical,
          'Z - A',
          Icons.sort_by_alpha,
          isDark,
        ),
        _buildSortItem(
          _DictionarySort.newest,
          'Newest First',
          Icons.new_releases_outlined,
          isDark,
        ),
        _buildSortItem(
          _DictionarySort.oldest,
          'Oldest First',
          Icons.history_rounded,
          isDark,
        ),
      ],
    );
  }

  PopupMenuItem<_DictionarySort> _buildSortItem(
    _DictionarySort value,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedSort == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? (isDark ? AppColors.gold500 : AppColors.forest500)
                : (isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.forest500)
                  : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.gold500 : AppColors.forest500)
                      : (isDark
                            ? AppColors.forestLightCard
                            : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  ),
                ),
                child: Text(
                  cat,
                  style: AppTypography.label.copyWith(
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white54 : Colors.black45),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DictionaryEntryCard extends ConsumerStatefulWidget {
  final DictionaryEntry entry;
  final bool isExpanded;
  final MasteryLevel? masteryLevel;
  final VoidCallback onToggleExpanded;

  const _DictionaryEntryCard({
    required this.entry,
    required this.isExpanded,
    this.masteryLevel,
    required this.onToggleExpanded,
  });

  @override
  ConsumerState<_DictionaryEntryCard> createState() =>
      _DictionaryEntryCardState();
}

class _DictionaryEntryCardState extends ConsumerState<_DictionaryEntryCard>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;

  void _togglePlay() {
    if (widget.entry.audioUrl == null || widget.entry.audioUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio available for this entry.')),
      );
      return;
    }

    if (_isPlaying) {
      ref.read(audioServiceProvider).stopPlayback();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      ref.read(audioServiceProvider).playFromUrl(widget.entry.audioUrl!).then((
        _,
      ) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  Color _getMasteryColor(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.mastered:
        return AppColors.semanticGreen;
      case MasteryLevel.reviewing:
        return AppColors.gold500;
      case MasteryLevel.learning:
        return Colors.blue;
      default:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onToggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: widget.isExpanded
                ? (isDark ? AppColors.gold500 : AppColors.forest500).withOpacity(0.3)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Badge, Phonetic, Play
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.forest50.withOpacity(isDark ? 0.1 : 0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white24 : AppColors.forest200,
                    ),
                  ),
                  child: Text(
                    widget.entry.language.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white70 : AppColors.forest700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.masteryLevel != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: _getMasteryColor(widget.masteryLevel!),
                  ),
                ],
                const SizedBox(width: 12),
                Text(
                  widget.entry.phonetic ?? '',
                  style: AppTypography.mono.copyWith(
                    color: isDark ? Colors.white24 : AppColors.creamText3,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isPlaying
                          ? AppColors.gold500
                          : AppColors.terracotta,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Word
            Text(
              widget.entry.indigenousWord,
              style: AppTypography.h1ExtraBold.copyWith(
                color: isDark ? AppColors.gold500 : AppColors.forest500,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 12),
            // Row 3: Translations
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body.copyWith(
                            color: isDark
                                ? Colors.white54
                                : AppColors.creamText2,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: 'ENG ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.creamText3,
                              ),
                            ),
                            TextSpan(text: widget.entry.translation),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body.copyWith(
                            color: isDark
                                ? Colors.white54
                                : AppColors.creamText2,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: 'FIL ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.creamText3,
                              ),
                            ),
                            TextSpan(text: widget.entry.translationFilipino),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Expanded Section
            if (widget.isExpanded) ...[
              const SizedBox(height: 24),
              Divider(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
              const SizedBox(height: 20),
              Text(
                'DEFINITION',
                style: AppTypography.label.copyWith(
                  color: isDark ? AppColors.gold500 : AppColors.forest500,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.entry.usageContext,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.creamText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (widget.entry.usageExampleNative != null &&
                  widget.entry.usageExampleNative!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'USAGE EXAMPLE',
                  style: AppTypography.label.copyWith(
                    color: isDark ? AppColors.gold500 : AppColors.forest500,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDark ? AppColors.gold500 : AppColors.forest500,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"${widget.entry.usageExampleNative}"',
                        style: AppTypography.h1ExtraBold.copyWith(
                          color: isDark
                              ? AppColors.gold500
                              : AppColors.forest500,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.entry.usageExampleTranslation ?? '',
                        style: AppTypography.body.copyWith(
                          color: isDark ? Colors.white38 : AppColors.creamText2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: BrandButton(
                      text: 'SHARE',
                      icon: Icons.share_outlined,
                      type: BrandButtonType.secondary,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Sharing ${widget.entry.indigenousWord} to your network...',
                            ),
                            backgroundColor: AppColors.semanticBlue,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrandButton(
                      text:
                          ref
                              .watch(savedWordsProvider)
                              .contains(widget.entry.id)
                          ? 'SAVED'
                          : 'SAVE',
                      icon:
                          ref
                              .watch(savedWordsProvider)
                              .contains(widget.entry.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      type:
                          ref
                              .watch(savedWordsProvider)
                              .contains(widget.entry.id)
                          ? BrandButtonType.primary
                          : BrandButtonType.secondary,
                      onTap: () {
                        ref
                            .read(savedWordsProvider.notifier)
                            .toggleSave(widget.entry.id, context: context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _DictionarySort { alphabetical, reverseAlphabetical, newest, oldest }
