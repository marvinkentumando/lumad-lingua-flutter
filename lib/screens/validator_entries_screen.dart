import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/dictionary_entry.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/brand_button.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/glass_box.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class ValidatorEntriesScreen extends ConsumerStatefulWidget {
  const ValidatorEntriesScreen({super.key});

  @override
  ConsumerState<ValidatorEntriesScreen> createState() =>
      _ValidatorEntriesScreenState();
}

class _ValidatorEntriesScreenState
    extends ConsumerState<ValidatorEntriesScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  bool _isSelectionMode = false;
  bool _showHistory = false;
  final Set<String> _selectedIds = {};
  bool _isProcessing = false;
  bool _isFetchingMore = false;
  String _searchQuery = "";
  String _selectedDialect = "All";
  String? _playingEntryId;

  int _documentLimit = 50;
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;
  bool _hasPlayedConfetti = false;

  List<String> _searchHistory = [];
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadSearchHistory();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isFetchingMore) {
          setState(() {
            _isFetchingMore = true;
            _documentLimit += 50;
          });
          // Reset fetching flag after a delay to allow stream to update
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isFetchingMore = false);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _searchHistory =
          prefs.getStringList('validator_search_history') ??
          ["Pagsasalamat", "Diwata", "Kali"];
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    final termTrimmed = term.trim();
    if (termTrimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final currentHistory =
        prefs.getStringList('validator_search_history') ?? [];

    currentHistory.removeWhere(
      (item) => item.toLowerCase() == termTrimmed.toLowerCase(),
    );
    currentHistory.insert(0, termTrimmed);

    if (currentHistory.length > 5) {
      currentHistory.removeLast();
    }

    await prefs.setStringList('validator_search_history', currentHistory);
    if (!mounted) return;
    setState(() {
      _searchHistory = currentHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final userId = userAsync.value?['uid'] ?? userAsync.value?['id'] ?? '';
    final userRole = userAsync.value?['role'] ?? 'VALIDATOR';

    final entriesAsync = _showHistory
        ? ref.watch(
            validatorHistoryStreamProvider(
              ValidatorQuery(userId, _documentLimit, search: _searchQuery),
            ),
          )
        : ref.watch(
            pendingDictionaryStreamProvider(
              ValidatorQuery('', _documentLimit, search: _searchQuery),
            ),
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton:
          (_isSelectionMode && _selectedIds.isNotEmpty && !_isProcessing)
          ? FloatingActionButton.extended(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                setState(() => _isProcessing = true);
                final firebaseService = ref.read(firebaseServiceProvider);
                final List<String> succeededIds = [];
                final List<String> failedIds = [];

                for (final id in _selectedIds) {
                  try {
                    await firebaseService.approveWord(id, userId, userRole);
                    succeededIds.add(id);
                  } catch (e) {
                    failedIds.add(id);
                    debugPrint('Error approving $id: $e');
                  }
                }

                if (!mounted) return;

                setState(() {
                  _selectedIds.removeWhere((id) => succeededIds.contains(id));
                  if (_selectedIds.isEmpty) _isSelectionMode = false;
                  _isProcessing = false;
                });

                if (context.mounted) {
                  if (failedIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bulk Approved!'),
                        backgroundColor: AppColors.semanticGreen,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Approved ${succeededIds.length} items. ${failedIds.length} failed.',
                        ),
                        backgroundColor: AppColors.terracotta,
                      ),
                    );
                  }
                }
              },
              backgroundColor: AppColors.gold500,
              icon: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.forest900,
              ),
              label: Text(
                'APPROVE ${_selectedIds.length} ITEMS',
                style: AppTypography.label.copyWith(
                  color: AppColors.forest900,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ).animate().scale()
          : null,
      body: AmbientTopoBackground(
        child: SafeArea(
        child: Stack(
          children: [
            entriesAsync.when(
              data: (entries) {
                var filteredList = entries;

                if (_selectedDialect != "All") {
                  filteredList = filteredList
                      .where(
                        (item) =>
                            item.language.toLowerCase() ==
                            _selectedDialect.toLowerCase(),
                      )
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filteredList = filteredList.where((item) {
                    final word = item.indigenousWord.toLowerCase();
                    final dialect = item.language.toLowerCase();
                    final name = (item.contributorName ?? '').toLowerCase();
                    return word.contains(query) ||
                        dialect.contains(query) ||
                        name.contains(query);
                  }).toList();
                }

                if (_searchQuery.isEmpty &&
                    !_showHistory &&
                    filteredList.isEmpty &&
                    !_hasPlayedConfetti) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _hasPlayedConfetti = true;
                      _confettiController.play();
                    }
                  });
                } else if (filteredList.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _hasPlayedConfetti = false;
                  });
                }

                return Column(
                  children: [
                    _buildHeader(filteredList),
                    Expanded(
                      child: filteredList.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: AppColors.gold500,
                              backgroundColor: AppColors.forest800,
                              onRefresh: () async {
                                if (_showHistory) {
                                  ref.invalidate(
                                    validatorHistoryStreamProvider,
                                  );
                                } else {
                                  ref.invalidate(
                                    pendingDictionaryStreamProvider,
                                  );
                                }
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                              },
                              child: ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: _buildEntryCard(
                                          filteredList[index],
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(
                                        delay: Duration(
                                          milliseconds: 50 * index,
                                        ),
                                      )
                                      .slideX(begin: 0.05);
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold500),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: AppColors.semanticRed),
                ),
              ),
            ),
            if (_isProcessing)
              Positioned.fill(
                child: GlassBox(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.gold500,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Processing Bulk Approval...",
                          style: AppTypography.h3.copyWith(
                            color: isDark ? Colors.white : AppColors.forest500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Please wait while we sync with the Vault",
                          style: AppTypography.body.copyWith(
                            color: AppColors.creamText3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // blast downwards
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeader(List<DictionaryEntry> currentList) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool allSelected =
        _isSelectionMode &&
        _selectedIds.length == currentList.length &&
        currentList.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSelectionMode
                    ? 'Selection Mode'
                    : (_showHistory ? 'My History' : 'Dictionary Entries'),
                style: AppTypography.displayBold.copyWith(
                  fontSize: _isSelectionMode ? 24 : 32,
                  color: AppColors.gold500,
                ),
              ),
              if (_isSelectionMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (allSelected) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.addAll(currentList.map((e) => e.id));
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: allSelected
                              ? AppColors.forest700
                              : AppColors.gold500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: allSelected
                                ? AppColors.forest600
                                : AppColors.gold500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          allSelected ? 'DESELECT ALL' : 'SELECT ALL',
                          style: AppTypography.label.copyWith(
                            color: allSelected
                                ? (isDark
                                      ? Colors.white70
                                      : AppColors.forest700)
                                : AppColors.gold500,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final allIds = currentList.map((e) => e.id).toSet();
                          final inverted = allIds.difference(_selectedIds);
                          _selectedIds.clear();
                          _selectedIds.addAll(inverted);
                          if (_selectedIds.isEmpty) _isSelectionMode = false;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'INVERT',
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.semanticRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.semanticRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: AppTypography.label.copyWith(
                            color: AppColors.semanticRed,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () => setState(() => _showHistory = !_showHistory),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _showHistory
                          ? AppColors.gold500
                          : (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _showHistory
                            ? AppColors.gold500
                            : (isDark ? Colors.white24 : AppColors.creamBorder),
                      ),
                    ),
                    child: Icon(
                      _showHistory
                          ? Icons.pending_actions_rounded
                          : Icons.history_rounded,
                      color: _showHistory
                          ? AppColors.forest900
                          : AppColors.gold500,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.forest800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.forest700 : AppColors.creamBorder,
              ),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              onSubmitted: (val) => _saveSearchTerm(val),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.creamText,
              ),
              decoration: InputDecoration(
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.gold500,
                  size: 20,
                ),
                hintText: 'Search by word, dialect, or name...',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isEmpty && !_isSelectionMode) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: isDark ? Colors.white38 : AppColors.forest200,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  ..._searchHistory.map(
                    (term) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _searchQuery = term),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.forest50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            term,
                            style: AppTypography.label.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.forest700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_showHistory) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildHistoryStatCard(
                    "APPROVED",
                    "1,240",
                    AppColors.semanticGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHistoryStatCard(
                    "FLAGGED",
                    "312",
                    AppColors.gold500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHistoryStatCard(
                    "REJECTED",
                    "45",
                    AppColors.semanticRed,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final dialectsAsync = ref.watch(dialectsProvider);
              final dialects =
                  dialectsAsync.value ?? ["All", "Mansaka", "Mandaya"];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: dialects.map((dialect) {
                    final isSelected = _selectedDialect == dialect;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDialect = dialect),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold500
                                : (isDark ? AppColors.forest800 : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gold500
                                  : (isDark
                                        ? AppColors.forest700
                                        : AppColors.creamBorder),
                            ),
                          ),
                          child: Text(
                            dialect.toUpperCase(),
                            style: AppTypography.label.copyWith(
                              color: isSelected
                                  ? AppColors.forest900
                                  : AppColors.gold500,
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStatCard(String label, String count, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.forest800
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(count, style: AppTypography.h2ExtraBold.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white54 : AppColors.creamText3,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isAllCaughtUp = _searchQuery.isEmpty && !_showHistory;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showHistory
                  ? Icons.history_edu_rounded
                  : (isAllCaughtUp
                        ? Icons.check_circle_outline_rounded
                        : Icons.search_off_rounded),
              color: isAllCaughtUp
                  ? AppColors.semanticGreen
                  : AppColors.forest700,
              size: 80,
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              _showHistory
                  ? "History is Empty"
                  : (isAllCaughtUp ? "All Caught Up!" : "No results found"),
              style: AppTypography.h3.copyWith(
                color: AppColors.gold500,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _showHistory
                  ? "You haven't validated any entries yet. Your contributions to the community will appear here!"
                  : (isAllCaughtUp
                        ? "There are no pending entries to validate at the moment. Great job!"
                        : "Try adjusting your search or filters to find what you're looking for."),
              style: AppTypography.body.copyWith(
                color: AppColors.creamText3,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (_showHistory) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() => _showHistory = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold500,
                  foregroundColor: AppColors.forest900,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "REVIEW PENDING",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(DictionaryEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = entry.id;
    final isSelected = _selectedIds.contains(id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.gold500.withValues(alpha: 0.1)
            : (isDark ? AppColors.forest800 : Colors.white),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSelected
              ? AppColors.gold500
              : (isDark ? AppColors.forest700 : AppColors.creamBorder),
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.gold500.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedIds.add(id);
                });
              },
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedIds.remove(id);
                      if (_selectedIds.isEmpty) _isSelectionMode = false;
                    } else {
                      _selectedIds.add(id);
                    }
                  });
                } else {
                  _showFullTermSheet(entry);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isSelectionMode)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold500
                                : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check_rounded : Icons.add_rounded,
                            size: 14,
                            color: isSelected
                                ? AppColors.forest900
                                : (isDark ? Colors.white30 : Colors.black26),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5EAD7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.language.toUpperCase(),
                            style: AppTypography.label.copyWith(
                              color: AppColors.forest900,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.phonetic ?? '',
                          style: AppTypography.mono.copyWith(
                            color: AppColors.creamText3,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (!_isSelectionMode)
                          GestureDetector(
                            onTap: () async {
                              if (entry.audioUrl == null ||
                                  entry.audioUrl!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No audio recorded for this entry.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _playingEntryId = entry.id);
                              try {
                                await ref
                                    .read(audioServiceProvider)
                                    .playFromUrl(entry.audioUrl!);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to play audio.'),
                                      backgroundColor: AppColors.semanticRed,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _playingEntryId = null);
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _playingEntryId == entry.id
                                    ? AppColors.gold500
                                    : const Color(0xFFE4581C),
                                shape: BoxShape.circle,
                                boxShadow: _playingEntryId == entry.id
                                    ? [
                                        BoxShadow(
                                          color: AppColors.gold500.withValues(alpha: 0.3,
                                          ),
                                          spreadRadius: 4,
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                _playingEntryId == entry.id
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: _playingEntryId == entry.id
                                    ? AppColors.forest900
                                    : Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.indigenousWord,
                      style: AppTypography.displayBold.copyWith(
                        color: AppColors.gold500,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: AppTypography.body.copyWith(
                                  color: isDark
                                      ? AppColors.creamBg
                                      : AppColors.forest900,
                                  fontSize: 13,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "ENG ",
                                    style: TextStyle(
                                      color: AppColors.creamText3,
                                    ),
                                  ),
                                  TextSpan(text: entry.translation),
                                ],
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                style: AppTypography.body.copyWith(
                                  color: isDark
                                      ? AppColors.creamBg
                                      : AppColors.forest900,
                                  fontSize: 13,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "FIL ",
                                    style: TextStyle(
                                      color: AppColors.creamText3,
                                    ),
                                  ),
                                  TextSpan(text: entry.translationFilipino),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildStatusBadge(entry.status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!_isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  top: 12,
                ),
                child: _buildActionButtons(entry: entry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ValidationStatus status) {
    Color color;
    String label;

    switch (status) {
      case ValidationStatus.approved:
        color = AppColors.semanticGreen;
        label = "APPROVED";
        break;
      case ValidationStatus.flagged:
        color = AppColors.gold500;
        label = "FLAGGED";
        break;
      case ValidationStatus.rejected:
        color = AppColors.semanticRed;
        label = "REJECTED";
        break;
      case ValidationStatus.pending:
        color = AppColors.creamText3;
        label = "PENDING";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.05),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildActionButtons({required DictionaryEntry entry}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(userProfileProvider);
    final userId = userAsync.value?['uid'] ?? userAsync.value?['id'] ?? '';
    final userRole = userAsync.value?['role'] ?? 'VALIDATOR';

    if (entry.status != ValidationStatus.pending) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.creamText3,
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.validatorFeedback ?? "No feedback provided.",
                style: AppTypography.body.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAB9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.forest900,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.contributorName ?? 'Unknown',
                      style: AppTypography.body.copyWith(
                        color: isDark ? AppColors.creamBg : AppColors.forest900,
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "98% APPROVAL",
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 2,
                          height: 2,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "0 FLAGS",
                          style: AppTypography.label.copyWith(
                            color: AppColors.creamText3,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        BrandButton(
          text: "APPROVE",
          icon: Icons.check_circle_outline,
          type: BrandButtonType.primary,
          onTap: () async {
            HapticFeedback.mediumImpact();
            try {
              await ref
                  .read(firebaseServiceProvider)
                  .approveWord(entry.id, userId, userRole);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Submission Approved!'),
                    backgroundColor: AppColors.semanticGreen,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Approval failed: $e'),
                    backgroundColor: AppColors.semanticRed,
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showFlagActionSheet(entry),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.terracotta),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: AppColors.terracotta,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  void _showFlagActionSheet(DictionaryEntry entry) {
    _feedbackController.clear();
    final userAsync = ref.watch(userProfileProvider);
    final userId = userAsync.value?['uid'] ?? userAsync.value?['id'] ?? '';
    final userRole = userAsync.value?['role'] ?? 'VALIDATOR';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Action Required',
                style: AppTypography.h2ExtraBold.copyWith(
                  color: AppColors.gold500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Decide how to handle "${entry.indigenousWord}"',
                style: AppTypography.body.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'e.g., Please provide a clearer audio sample or verify the spelling.',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.forest900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Audio Unclear',
                      'Spelling Error',
                      'Inappropriate Content',
                      'Wrong Translation',
                      'Incorrect POS',
                      'Incomplete Bio',
                      'Missing Context',
                    ].map((reason) {
                      final bool isAudioReason = reason == 'Audio Unclear';
                      final bool hasAudio =
                          entry.audioUrl != null && entry.audioUrl!.isNotEmpty;
                      final bool isDisabled = isAudioReason && !hasAudio;

                      return ActionChip(
                        label: Text(
                          reason,
                          style: AppTypography.label.copyWith(
                            color: isDisabled
                                ? Colors.white30
                                : AppColors.gold500,
                            fontSize: 10,
                          ),
                        ),
                        backgroundColor: isDisabled
                            ? Colors.black26
                            : AppColors.gold500.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: isDisabled
                              ? Colors.white10
                              : AppColors.gold500.withValues(alpha: 0.3),
                        ),
                        onPressed: isDisabled
                            ? null
                            : () {
                                final currentText = _feedbackController.text;
                                if (currentText.isEmpty) {
                                  _feedbackController.text = reason;
                                } else {
                                  _feedbackController.text =
                                      '$currentText, $reason';
                                }
                              },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.forest900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: AppColors.gold500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add Audio Tip',
                        style: AppTypography.body.copyWith(
                          color: AppColors.creamText3,
                        ),
                      ),
                    ),
                    BrandButton(
                      text: 'Record',
                      type: BrandButtonType.secondary,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recording Audio Tip...'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta.withValues(alpha: 0.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.terracotta),
                        ),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final feedback = _feedbackController.text.trim();
                        if (feedback.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please provide feedback for rejection',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        await ref
                            .read(firebaseServiceProvider)
                            .rejectWord(entry.id, userId, userRole, feedback);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Entry Rejected'),
                            backgroundColor: AppColors.semanticRed,
                          ),
                        );
                      },
                      child: Text(
                        'REJECT',
                        style: AppTypography.label.copyWith(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final feedback = _feedbackController.text.trim();
                        if (feedback.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please provide feedback for flagging',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        await ref
                            .read(firebaseServiceProvider)
                            .flagWord(entry.id, userId, userRole, feedback);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clarification request sent'),
                            backgroundColor: AppColors.gold500,
                          ),
                        );
                      },
                      child: Text(
                        'FLAG ENTRY',
                        style: AppTypography.label.copyWith(
                          color: AppColors.forest900,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullTermSheet(DictionaryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5EAD7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.language.toUpperCase(),
                      style: AppTypography.label.copyWith(
                        color: AppColors.forest900,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _searchQuery = entry.indigenousWord;
                            _showHistory = true; // Search in history/existing
                          });
                        },
                        icon: const Icon(
                          Icons.manage_search_rounded,
                          color: AppColors.gold500,
                          size: 18,
                        ),
                        label: Text(
                          "SEARCH EXISTING",
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                entry.indigenousWord,
                style: AppTypography.displayBold.copyWith(
                  color: AppColors.gold500,
                  fontSize: 40,
                ),
              ),
              Text(
                '${entry.phonetic ?? ''} • ${entry.partOfSpeechLabel}',
                style: AppTypography.mono.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DEFINITION",
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.usageContext,
                        style: AppTypography.body.copyWith(
                          color: AppColors.creamBg,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "USAGE EXAMPLE",
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forest800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.gold500,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.usageExampleNative ?? '',
                                    style: AppTypography.h2ExtraBold.copyWith(
                                      color: AppColors.gold500,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.usageExampleTranslation ?? '',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.creamText3,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}




