import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/dictionary_entry.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/brand_button.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/glass_box.dart';
import '../widgets/preview_audio_player.dart';
import '../services/supabase_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

class ValidatorEntriesScreen extends ConsumerStatefulWidget {
  final bool showHistory;
  const ValidatorEntriesScreen({super.key, this.showHistory = false});

  @override
  ConsumerState<ValidatorEntriesScreen> createState() =>
      _ValidatorEntriesScreenState();
}

class _ValidatorEntriesScreenState
    extends ConsumerState<ValidatorEntriesScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  bool _isSelectionMode = false;
  late bool _showHistory;
  bool _isGlobalSearch = false;
  final Set<String> _selectedIds = {};
  bool _isProcessing = false;
  bool _isFetchingMore = false;
  String _searchQuery = "";
  String _activeSearchQuery = "";
  String _sortBy = "latest"; // "latest" or "alpha"
  final String _selectedDialect = "All";

  int _documentLimit = 50;
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;
  bool _hasPlayedConfetti = false;

  List<String> _searchHistory = [];
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordedTipPath;
  bool _isRecordingTip = false;

  @override
  void initState() {
    super.initState();
    _showHistory = widget.showHistory;
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
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecordingTip() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/tip_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        setState(() => _isRecordingTip = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecordingTip() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecordingTip = false;
        _recordedTipPath = path;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
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

  Future<void> _deleteSearchTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHistory = prefs.getStringList('validator_search_history') ?? [];
    currentHistory.remove(term);
    await prefs.setStringList('validator_search_history', currentHistory);
    setState(() {
      _searchHistory = currentHistory;
    });
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('validator_search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final userId = userAsync.value?['uid'] ?? userAsync.value?['id'] ?? '';
    final userRole = userAsync.value?['role'] ?? 'VALIDATOR';
    final userDialect = userAsync.value?['indigenousGroup'] ?? 'Mansaka';

    final metricsAsync = ref.watch(validatorMetricsProvider(userId));

    final entriesAsync = _isGlobalSearch
        ? ref.watch(
            globalDictionaryStreamProvider(
              ValidatorQuery(
                '',
                _documentLimit,
                search: _activeSearchQuery,
                dialect: userDialect,
              ),
            ),
          )
        : (_showHistory
            ? ref.watch(
                validatorHistoryStreamProvider(
                  ValidatorQuery(
                    userId,
                    _documentLimit,
                    search: _activeSearchQuery,
                    dialect: userDialect,
                  ),
                ),
              )
            : ref.watch(
                pendingDictionaryStreamProvider(
                  ValidatorQuery(
                    '',
                    _documentLimit,
                    search: _activeSearchQuery,
                    dialect: userDialect,
                  ),
                ),
              ));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton:
          (_isSelectionMode && _selectedIds.isNotEmpty && !_isProcessing)
          ? FloatingActionButton.extended(
              onPressed: () => _showBulkActionSheet(userId, userRole),
              backgroundColor: AppColors.gold500,
              icon: const Icon(
                Icons.playlist_add_check_rounded,
                color: AppColors.forest900,
              ),
              label: Text(
                'ACTIONS (${_selectedIds.length})',
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
                var filteredList = List<DictionaryEntry>.from(entries);

                if (_selectedDialect != "All") {
                  filteredList = filteredList
                      .where(
                        (item) =>
                            item.language.toLowerCase() ==
                            _selectedDialect.toLowerCase(),
                      )
                      .toList();
                }

                if (_activeSearchQuery.isNotEmpty) {
                  final query = _activeSearchQuery.toLowerCase();
                  filteredList = filteredList.where((item) {
                    final word = item.indigenousWord.toLowerCase();
                    return word.contains(query);
                  }).toList();
                }

                // Apply Sorting
                if (_sortBy == "a-z") {
                  filteredList.sort((a, b) => a.indigenousWord.toLowerCase().compareTo(b.indigenousWord.toLowerCase()));
                } else if (_sortBy == "z-a") {
                  filteredList.sort((a, b) => b.indigenousWord.toLowerCase().compareTo(a.indigenousWord.toLowerCase()));
                } else if (_sortBy == "oldest") {
                  filteredList.sort((a, b) {
                    final aTime = a.submittedAt ?? DateTime(0);
                    final bTime = b.submittedAt ?? DateTime(0);
                    return aTime.compareTo(bTime);
                  });
                } else {
                  // latest
                  filteredList.sort((a, b) {
                    final aTime = a.submittedAt ?? DateTime(0);
                    final bTime = b.submittedAt ?? DateTime(0);
                    return bTime.compareTo(aTime);
                  });
                }

                if (_activeSearchQuery.isEmpty &&
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
                    _buildHeader(filteredList, userDialect, metricsAsync),
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
                                itemCount: filteredList.length + (_isFetchingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == filteredList.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 32,
                                      ),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            const CircularProgressIndicator(
                                              color: AppColors.gold500,
                                              strokeWidth: 3,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              "Summoning more ancient knowledge...",
                                              style:
                                                  AppTypography.label.copyWith(
                                                color: AppColors.gold500,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
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

  Widget _buildHeader(
    List<DictionaryEntry> currentList,
    String? validatorDialect,
    AsyncValue<Map<String, dynamic>> metricsAsync,
  ) {
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
                    : (_isGlobalSearch
                        ? 'Duplicate Check'
                        : (_showHistory ? 'My History' : 'Dictionary Entries')),
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
              else if (_isGlobalSearch)
                GestureDetector(
                  onTap: () => setState(() {
                    _isGlobalSearch = false;
                    _searchQuery = "";
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.semanticRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.semanticRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.semanticRed,
                      size: 20,
                    ),
                  ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.forest800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.forest700 : AppColors.creamBorder,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        if (val.isEmpty) {
                          _activeSearchQuery = "";
                          _isGlobalSearch = false;
                        }
                      });
                    },
                    onSubmitted: (val) {
                      setState(() {
                        _activeSearchQuery = val;
                      });
                      _saveSearchTerm(val);
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.creamText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by word...',
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.creamText3,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeSearchQuery = _searchController.text;
                          });
                          _saveSearchTerm(_searchController.text);
                          FocusScope.of(context).unfocus();
                        },
                        child: const Icon(
                          Icons.search_rounded,
                          color: AppColors.gold500,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (val) {
                  setState(() => _sortBy = val);
                },
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : AppColors.creamBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.sort_rounded,
                    color: AppColors.gold500,
                    size: 20,
                  ),
                ),
                color: isDark ? AppColors.forest800 : Colors.white,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "latest",
                    child: Text("Latest - Oldest", style: TextStyle(color: isDark ? Colors.white : AppColors.forest900)),
                  ),
                  PopupMenuItem(
                    value: "oldest",
                    child: Text("Oldest - Latest", style: TextStyle(color: isDark ? Colors.white : AppColors.forest900)),
                  ),
                  PopupMenuItem(
                    value: "a-z",
                    child: Text("A-Z", style: TextStyle(color: isDark ? Colors.white : AppColors.forest900)),
                  ),
                  PopupMenuItem(
                    value: "z-a",
                    child: Text("Z-A", style: TextStyle(color: isDark ? Colors.white : AppColors.forest900)),
                  ),
                ],
              ),
            ],
          ),
          if (_activeSearchQuery.isEmpty && !_isSelectionMode && _searchHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _clearSearchHistory,
                    child: Tooltip(
                      message: "Clear All History",
                      child: Icon(
                        Icons.history_rounded,
                        color: isDark ? AppColors.gold500 : AppColors.forest400,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ..._searchHistory.map(
                    (term) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.forest50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : AppColors.forest100,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchQuery = term;
                                  _activeSearchQuery = term;
                                  _searchController.text = term;
                                });
                              },
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
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _deleteSearchTerm(term),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 10,
                                  color: isDark ? Colors.white38 : AppColors.forest300,
                                ),
                              ),
                            ),
                          ],
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
            metricsAsync.when(
              data: (metrics) => Row(
                children: [
                  Expanded(
                    child: _buildHistoryStatCard(
                      "APPROVED",
                      metrics['approved'].toString(),
                      AppColors.semanticGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHistoryStatCard(
                      "FLAGGED",
                      metrics['flagged'].toString(),
                      AppColors.gold500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHistoryStatCard(
                      "REJECTED",
                      metrics['rejected'].toString(),
                      AppColors.semanticRed,
                    ),
                  ),
                ],
              ),
              loading: () => Row(
                children: [
                  Expanded(
                    child: _buildHistoryStatCard(
                      "APPROVED",
                      "...",
                      AppColors.semanticGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHistoryStatCard(
                      "FLAGGED",
                      "...",
                      AppColors.gold500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHistoryStatCard(
                      "REJECTED",
                      "...",
                      AppColors.semanticRed,
                    ),
                  ),
                ],
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
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
                        if (!_isSelectionMode && entry.audioUrl != null && entry.audioUrl!.isNotEmpty)
                          PreviewAudioPlayer(
                            audioUrl: entry.audioUrl!,
                            size: 32,
                            color: AppColors.gold500,
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
    final userAsync = ref.read(userProfileProvider);
    final userId = userAsync.value?['uid'] ?? userAsync.value?['id'] ?? '';
    final userRole = userAsync.value?['role'] ?? 'VALIDATOR';

    if (entry.status != ValidationStatus.pending) {
      final canEdit = entry.validatorId == userId;
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            Icon(
              canEdit ? Icons.edit_note_rounded : Icons.info_outline,
              color: AppColors.gold500,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: canEdit ? () => _showFlagActionSheet(entry) : null,
                child: Text(
                  entry.validatorFeedback ?? "No feedback provided.",
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white70 : AppColors.forest700,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    decoration: canEdit ? TextDecoration.underline : null,
                    decorationColor: AppColors.gold500.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (entry.status == ValidationStatus.approved)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.semanticGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.semanticGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.semanticGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "APPROVED",
                      style: AppTypography.label.copyWith(
                        color: AppColors.semanticGreen,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              BrandButton(
                text: "APPROVE",
                icon: Icons.check_circle_outline,
                type: BrandButtonType.primary,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Approval'),
                      content: Text('Are you sure you want to approve "${entry.indigenousWord}"? This will make it live in the dictionary.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticGreen),
                          child: const Text('APPROVE', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          ],
        ),
      ],
    );
  }

  void _showBulkActionSheet(String userId, String userRole) {
    final feedbackController = TextEditingController();
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
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bulk Actions',
                style: AppTypography.h2ExtraBold.copyWith(color: AppColors.gold500),
              ),
              const SizedBox(height: 4),
              Text(
                'Apply actions to ${_selectedIds.length} selected entries',
                style: AppTypography.body.copyWith(color: AppColors.creamText3, fontSize: 12),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Feedback for Reject/Flag (required for bulk)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.forest900,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.semanticGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Bulk Approval'),
                            content: Text('Are you sure you want to approve ${_selectedIds.length} entries at once?'),
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
                        if (confirmed == true) {
                          _handleBulkAction('approve', '', userId, userRole);
                        }
                      },
                      child: Text('APPROVE ALL', style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.terracotta)),
                      ),
                      onPressed: () {
                        if (feedbackController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback required for bulk rejection'), backgroundColor: AppColors.terracotta));
                          return;
                        }
                        _handleBulkAction('reject', feedbackController.text, userId, userRole);
                      },
                      child: Text('REJECT ALL', style: AppTypography.label.copyWith(color: AppColors.terracotta, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (feedbackController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback required for bulk flag'), backgroundColor: AppColors.terracotta));
                          return;
                        }
                        _handleBulkAction('flag', feedbackController.text, userId, userRole);
                      },
                      child: Text('FLAG ALL', style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleBulkAction(String action, String feedback, String userId, String userRole) async {
    Navigator.pop(context);
    setState(() => _isProcessing = true);
    final firebaseService = ref.read(firebaseServiceProvider);
    final ids = _selectedIds.toList();

    try {
      if (action == 'approve') {
        await firebaseService.bulkApproveWords(ids, userId, userRole);
      } else if (action == 'reject') {
        await firebaseService.bulkRejectWords(ids, userId, userRole, feedback);
      } else if (action == 'flag') {
        await firebaseService.bulkFlagWords(ids, userId, userRole, feedback);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Bulk ${action.substring(0, 1).toUpperCase() + action.substring(1)}ed ${ids.length} items!'),
          backgroundColor: action == 'approve' ? AppColors.semanticGreen : AppColors.semanticRed,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bulk action failed: $e'), backgroundColor: AppColors.semanticRed));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSelectionMode = false;
          _selectedIds.clear();
        });
      }
    }
  }

  void _showFlagActionSheet(DictionaryEntry entry) {
    _feedbackController.text = entry.validatorFeedback ?? "";
    _recordedTipPath = null;
    _isRecordingTip = false;
    final userAsync = ref.read(userProfileProvider);
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
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    entry.status == ValidationStatus.pending ? 'Action Required' : 'Edit Decision',
                    style: AppTypography.h2ExtraBold.copyWith(color: AppColors.gold500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.status == ValidationStatus.pending
                      ? 'Decide how to handle "${entry.indigenousWord}"'
                      : 'Update your decision or feedback for "${entry.indigenousWord}"',
                    style: AppTypography.body.copyWith(color: AppColors.creamText3, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Please provide a clearer audio sample or verify the spelling.',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.forest900,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Audio Unclear', 'Spelling Error', 'Inappropriate Content', 'Wrong Translation', 'Incorrect POS', 'Incomplete Bio', 'Missing Context',
                    ].map((reason) {
                      final bool isAudioReason = reason == 'Audio Unclear';
                      final bool hasAudio = entry.audioUrl != null && entry.audioUrl!.isNotEmpty;
                      final bool isDisabled = isAudioReason && !hasAudio;

                      return ActionChip(
                        label: Text(reason, style: AppTypography.label.copyWith(color: isDisabled ? Colors.white30 : AppColors.gold500, fontSize: 10)),
                        backgroundColor: isDisabled ? Colors.black26 : AppColors.gold500.withValues(alpha: 0.1),
                        side: BorderSide(color: isDisabled ? Colors.white10 : AppColors.gold500.withValues(alpha: 0.3)),
                        onPressed: isDisabled ? null : () {
                          final currentText = _feedbackController.text;
                          if (currentText.isEmpty) {
                            _feedbackController.text = reason;
                          } else {
                            _feedbackController.text = '$currentText, $reason';
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.forest900, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.mic_rounded, color: AppColors.gold500),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recordedTipPath != null
                                ? 'Tip Recorded: ${_recordedTipPath!.split('/').last}'
                                : (_isRecordingTip ? 'Recording...' : 'Add Audio Tip'),
                            style: AppTypography.body.copyWith(color: AppColors.creamText3, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_recordedTipPath != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.terracotta, size: 20),
                            onPressed: () {
                              setModalState(() => _recordedTipPath = null);
                              setState(() => _recordedTipPath = null);
                            },
                          ),
                        BrandButton(
                          text: _isRecordingTip ? 'Stop' : (_recordedTipPath != null ? 'Play' : 'Record'),
                          type: BrandButtonType.secondary,
                          onTap: () async {
                            if (_isRecordingTip) {
                              final path = await _recorder.stop();
                              setModalState(() {
                                _isRecordingTip = false;
                                _recordedTipPath = path;
                              });
                              setState(() {
                                _isRecordingTip = false;
                                _recordedTipPath = path;
                              });
                            } else if (_recordedTipPath != null) {
                              await _audioPlayer.play(DeviceFileSource(_recordedTipPath!));
                            } else {
                              if (await _recorder.hasPermission()) {
                                final directory = await getTemporaryDirectory();
                                final path = '${directory.path}/tip_${DateTime.now().millisecondsSinceEpoch}.m4a';
                                await _recorder.start(const RecordConfig(), path: path);
                                setModalState(() => _isRecordingTip = true);
                                setState(() => _isRecordingTip = true);
                              }
                            }
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
                            backgroundColor: AppColors.terracotta.withValues(alpha: 0.2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.terracotta)),
                          ),
                          onPressed: () async {
                            final feedback = _feedbackController.text.trim();
                            if (feedback.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide feedback for rejection')));
                              return;
                            }

                            // Upload audio tip if exists
                            String? audioTipUrl;
                            if (_recordedTipPath != null) {
                               setModalState(() => _isProcessing = true);
                               final fileName = 'tip_${DateTime.now().millisecondsSinceEpoch}.m4a';
                               audioTipUrl = await ref.read(supabaseStorageServiceProvider).uploadAudio(File(_recordedTipPath!), fileName);
                               setModalState(() => _isProcessing = false);
                            }

                            await ref.read(firebaseServiceProvider).rejectWord(entry.id, userId, userRole, feedback);
                            
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(entry.status == ValidationStatus.pending ? 'Entry Rejected' : 'Decision Updated'), backgroundColor: AppColors.semanticRed));
                          },
                          child: Text(entry.status == ValidationStatus.rejected ? 'UPDATE REJECT' : 'REJECT', style: AppTypography.label.copyWith(color: AppColors.terracotta, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold500,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final feedback = _feedbackController.text.trim();
                            if (feedback.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide feedback for flagging')));
                              return;
                            }

                            // Upload audio tip if exists
                            String? audioTipUrl;
                            if (_recordedTipPath != null) {
                               setModalState(() => _isProcessing = true);
                               final fileName = 'tip_${DateTime.now().millisecondsSinceEpoch}.m4a';
                               audioTipUrl = await ref.read(supabaseStorageServiceProvider).uploadAudio(File(_recordedTipPath!), fileName);
                               setModalState(() => _isProcessing = false);
                            }

                            await ref.read(firebaseServiceProvider).flagWord(entry.id, userId, userRole, feedback);

                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(entry.status == ValidationStatus.pending ? 'Clarification request sent' : 'Decision Updated'), backgroundColor: AppColors.gold500));
                          },
                          child: Text(entry.status == ValidationStatus.flagged ? 'UPDATE FLAG' : 'FLAG ENTRY', style: AppTypography.label.copyWith(color: AppColors.forest900, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                  if (entry.status != ValidationStatus.pending && entry.status != ValidationStatus.approved) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.semanticGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Change'),
                              content: Text('Change your decision for "${entry.indigenousWord}" to Approved?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticGreen),
                                  child: const Text('CONFIRM', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true) return;

                          await ref.read(firebaseServiceProvider).approveWord(entry.id, userId, userRole);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Decision Changed: Approved!'), backgroundColor: AppColors.semanticGreen));
                        },
                        child: Text('CHANGE TO APPROVE', style: AppTypography.label.copyWith(color: AppColors.semanticGreen, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
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
                            _isGlobalSearch = true; // Global Duplicate Check
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.indigenousWord,
                    style: AppTypography.displayBold.copyWith(
                      color: AppColors.gold500,
                      fontSize: 40,
                    ),
                  ),
                  if (entry.audioUrl != null && entry.audioUrl!.isNotEmpty)
                    PreviewAudioPlayer(
                      audioUrl: entry.audioUrl!,
                      size: 48,
                      color: AppColors.gold500,
                    ),
                ],
              ),
              Text(
                '${entry.phonetic ?? ''} • ${entry.partOfSpeechLabel}',
                style: AppTypography.mono.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildTranslationPill("ENG", entry.translation),
                  const SizedBox(width: 8),
                  _buildTranslationPill("FIL", entry.translationFilipino),
                ],
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

  Widget _buildTranslationPill(String label, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTypography.body.copyWith(fontSize: 14),
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(
                color: AppColors.gold500,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
            TextSpan(
              text: text,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
