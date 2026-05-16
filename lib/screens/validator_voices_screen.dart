import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/voice_submission.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_box.dart';
import '../widgets/ambient_topo_background.dart';
import '../services/supabase_storage_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ValidatorVoicesScreen extends ConsumerStatefulWidget {
  const ValidatorVoicesScreen({super.key});

  @override
  ConsumerState<ValidatorVoicesScreen> createState() =>
      _ValidatorVoicesScreenState();
}

class _ValidatorVoicesScreenState extends ConsumerState<ValidatorVoicesScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  bool _isSelectionMode = false;
  bool _isProcessing = false;
  bool _showHistory = false;
  final Set<String> _selectedIds = {};
  String _searchQuery = "";
  String _activeSearchQuery = "";
  String _sortBy = "latest"; // "latest" or "alpha"
  final String _selectedDialect = "All";
  String? _playingId;
  double _playbackSpeed = 1.0;

  final TextEditingController _searchController = TextEditingController();

  // ── Real Audio Player state ──
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;


  @override
  void initState() {
    super.initState();
    _loadPlaybackSpeed();
    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted && state == PlayerState.completed) {
        setState(() {
          _playingId = null;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSpeed = prefs.getDouble('validator_playback_speed');
    if (savedSpeed != null && mounted) {
      setState(() {
        _playbackSpeed = savedSpeed;
      });
    }
  }

  Future<void> _togglePlayback(String id, String audioUrl) async {
    try {
      if (_playingId == id) {
        await _audioPlayer.pause();
        setState(() => _playingId = null);
      } else {
        if (_playingId != null) await _audioPlayer.stop();
        setState(() {
          _playingId = id;
          _currentPosition = Duration.zero;
          _totalDuration = Duration.zero;
        });
        
        final resolvedUrl =
            ref.read(supabaseStorageServiceProvider).getAudioUrl(audioUrl);
        await _audioPlayer.play(UrlSource(resolvedUrl));
        // Apply speed after play starts to ensure it's not reset by the player
        await _audioPlayer.setPlaybackRate(_playbackSpeed);
      }
    } catch (e) {
      debugPrint('Error playing audio in validator screen: $e');
      if (mounted) {
        setState(() => _playingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load audio fragment.'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  Future<void> _cycleSpeed() async {
    double nextSpeed;
    if (_playbackSpeed == 1.0) {
      nextSpeed = 0.5;
    } else if (_playbackSpeed == 0.5) {
      nextSpeed = 0.75;
    } else {
      nextSpeed = 1.0;
    }
    setState(() => _playbackSpeed = nextSpeed);
    await _audioPlayer.setPlaybackRate(nextSpeed);

    // Persist speed preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('validator_playback_speed', nextSpeed);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _seekToRelativePosition(double x, double maxWidth) {
    if (_totalDuration.inMilliseconds <= 0) return;
    final double relativeProgress = (x / maxWidth).clamp(0.0, 1.0);
    final int targetMs = (_totalDuration.inMilliseconds * relativeProgress).toInt();
    _audioPlayer.seek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final userId = user?.uid ?? "";
    final profile = ref.watch(userProfileProvider).value;
    final userDialect = profile?['indigenousGroup'] ?? 'Mansaka';

    final metricsAsync = ref.watch(voiceValidatorMetricsProvider(userId));

    final submissionsAsync = _showHistory
        ? ref.watch(
            voiceValidatorHistoryProvider(
              ValidatorQuery(userId, 50, dialect: userDialect, search: _activeSearchQuery),
            ),
          )
        : ref.watch(
            pendingVoiceSubmissionsProvider(
              ValidatorQuery('', 50, dialect: userDialect, search: _activeSearchQuery),
            ),
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (_isSelectionMode &&
              _selectedIds.isNotEmpty &&
              !_isProcessing)
          ? FloatingActionButton.extended(
              onPressed: () => _showBulkActionSheet(context),
              backgroundColor: AppColors.gold500,
              icon: const Icon(Icons.playlist_add_check_rounded,
                  color: AppColors.forest900),
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isSelectionMode
                                ? 'Selection Mode'
                                : (_showHistory ? 'Voice History' : 'Audio Voices'),
                            style: AppTypography.displayBold.copyWith(
                              fontSize: _isSelectionMode ? 24 : 32,
                              color: AppColors.gold500,
                            ),
                          ),
                          if (_isSelectionMode)
                            submissionsAsync.when(
                                  data: (voices) {
                                    final allSelected =
                                        _selectedIds.length == voices.length &&
                                        voices.isNotEmpty;
                                    return Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (allSelected) {
                                                _selectedIds.clear();
                                              } else {
                                                _selectedIds.addAll(
                                                  voices.map((e) => e.id),
                                                );
                                              }
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: allSelected
                                                  ? AppColors.forest700
                                                  : AppColors.gold500
                                                        .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: allSelected
                                                    ? AppColors.forest600
                                                    : AppColors.gold500
                                                          .withValues(alpha: 0.3,
                                                          ),
                                              ),
                                            ),
                                            child: Text(
                                              allSelected
                                                  ? 'DESELECT'
                                                  : 'SELECT ALL',
                                              style: AppTypography.label
                                                  .copyWith(
                                                    color: allSelected
                                                        ? Colors.white70
                                                        : AppColors.gold500,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              final allIds = voices
                                                  .map((e) => e.id)
                                                  .toSet();
                                              final inverted = allIds
                                                  .difference(_selectedIds);
                                              _selectedIds.clear();
                                              _selectedIds.addAll(inverted);
                                              if (_selectedIds.isEmpty) {
                                                _isSelectionMode = false;
                                              }
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold500
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.gold500
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              'INVERT',
                                              style: AppTypography.label
                                                  .copyWith(
                                                    color: AppColors.gold500,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 10,
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
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.semanticRed
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.semanticRed
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              'CANCEL',
                                              style: AppTypography.label
                                                  .copyWith(
                                                    color:
                                                        AppColors.semanticRed,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () => const SizedBox(),
                                  error: (_, __) => const SizedBox(),
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
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.forest800 : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.forest700
                                      : AppColors.creamBorder,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                    if (val.isEmpty) {
                                      _activeSearchQuery = "";
                                    }
                                  });
                                },
                                onSubmitted: (val) {
                                  setState(() => _activeSearchQuery = val);
                                },
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.creamText,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search by title...',
                                  hintStyle: AppTypography.body.copyWith(
                                    color: AppColors.creamText3,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() => _activeSearchQuery = _searchController.text);
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
                      if (_showHistory) ...[
                        const SizedBox(height: 24),
                        metricsAsync.when(
                          data:
                              (metrics) => Row(
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
                          loading:
                              () => Row(
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
                ),
                Expanded(
                  child: submissionsAsync.when(
                        data: (voices) {
                          var filteredList = List<VoiceSubmission>.from(voices);

                          if (_selectedDialect != "All") {
                            filteredList = filteredList
                                .where(
                                  (item) => item.dialect == _selectedDialect,
                                )
                                .toList();
                          }

                          if (_activeSearchQuery.isNotEmpty) {
                            final query = _activeSearchQuery.toLowerCase();
                            filteredList = filteredList.where((item) {
                              return item.title.toLowerCase().contains(query);
                            }).toList();
                          }

                          // Apply Sorting
                          if (_sortBy == "a-z") {
                            filteredList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                          } else if (_sortBy == "z-a") {
                            filteredList.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
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

                          if (filteredList.isEmpty) {
                            final bool isSearching = _searchQuery.isNotEmpty;
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 60,
                                  horizontal: 40,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _showHistory
                                          ? Icons.history_edu_rounded
                                          : (isSearching
                                              ? Icons.search_off_rounded
                                              : Icons.check_circle_outline_rounded),
                                      color: AppColors.forest700,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _showHistory
                                          ? "History is Empty"
                                          : (isSearching
                                              ? "No results found"
                                              : "All Caught Up!"),
                                      style: AppTypography.h3.copyWith(
                                        color: AppColors.gold500,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _showHistory
                                          ? "You haven't archived any voices yet. Your cultural contributions will appear here!"
                                          : (isSearching
                                              ? "Try adjusting your search or filters to find what you're looking for."
                                              : "There are no pending voices to validate at the moment. Great job!"),
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.creamText3,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildVoiceCard(filteredList[index]),
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(milliseconds: 50 * index),
                                  )
                                  .slideX(begin: 0.05);
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold500,
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                ),
              ],
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
                          "Archiving Voices...",
                          style: AppTypography.h3.copyWith(
                            color: isDark ? Colors.white : AppColors.forest500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Ensuring cultural clarity in the Vault",
                          style: AppTypography.body.copyWith(
                            color: AppColors.creamText3,
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
    ),
  );
}

  Widget _buildVoiceCard(VoiceSubmission item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = item.id;
    final isSelected = _selectedIds.contains(id);
    final isPlaying = _playingId == id;

    return GestureDetector(
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
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (item.priority)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4DE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "HIGH PRIORITY",
                          style: AppTypography.label.copyWith(
                            color: const Color(0xFF6B2222),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    if (item.priority) const SizedBox(width: 8),
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
                        item.dialect.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          color: AppColors.forest900,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.verified_outlined,
                  color: AppColors.gold500,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: AppTypography.h2ExtraBold.copyWith(
                color: isDark ? AppColors.creamBg : AppColors.forest900,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showSubmissionAuditLog(item),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.forest900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Submission ID: #ANC-${item.id.substring(0, 4)}",
                        style: AppTypography.mono.copyWith(
                          color: AppColors.gold500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: AppColors.gold500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.forest900 : AppColors.forest50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TRANSCRIPT",
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.transcript.isEmpty
                        ? "No transcript provided."
                        : item.transcript,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!_isSelectionMode) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.forest900 : AppColors.forest50,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _togglePlayback(id, item.audioUrl),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? AppColors.gold500
                              : const Color(0xFFE4581C),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isPlaying
                              ? AppColors.forest900
                              : (isDark ? Colors.white : AppColors.forest500),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          // Progress ratio: 0.0 → 1.0
                          final double progress =
                              (isPlaying && _totalDuration.inMilliseconds > 0)
                              ? (_currentPosition.inMilliseconds /
                                        _totalDuration.inMilliseconds)
                                    .clamp(0.0, 1.0)
                              : 0.0;
                          // Seed waveform heights per-card so bars stay stable
                          final rng = Random(id.hashCode);
                          final barHeights = List.generate(
                            30,
                            (_) => 4.0 + rng.nextInt(16),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onHorizontalDragUpdate: (details) {
                                      if (isPlaying) {
                                        _seekToRelativePosition(
                                          details.localPosition.dx,
                                          constraints.maxWidth,
                                        );
                                      }
                                    },
                                    onTapDown: (details) {
                                      if (isPlaying) {
                                        _seekToRelativePosition(
                                          details.localPosition.dx,
                                          constraints.maxWidth,
                                        );
                                      }
                                    },
                                    child: SizedBox(
                                      height: 24,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: List.generate(30, (i) {
                                          final bool isPast = i / 30 < progress;
                                          return Expanded(
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 120,
                                              ),
                                              margin: const EdgeInsets.symmetric(
                                                horizontal: 1,
                                              ),
                                              height: barHeights[i],
                                              decoration: BoxDecoration(
                                                color: isPast
                                                    ? AppColors.gold500
                                                    : AppColors.forest700,
                                                borderRadius: BorderRadius.circular(
                                                  2,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isPlaying
                                        ? _formatDuration(_currentPosition)
                                        : "0:00",
                                    style: AppTypography.mono.copyWith(
                                      color: AppColors.creamText3,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    (isPlaying &&
                                            _totalDuration.inMilliseconds > 0)
                                        ? _formatDuration(_totalDuration)
                                        : (item.duration ?? "0:00"),
                                    style: AppTypography.mono.copyWith(
                                      color: AppColors.creamText3,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _cycleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: AppTypography.mono.copyWith(
                            color: isDark ? Colors.white : AppColors.forest500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(submission: item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons({required VoiceSubmission submission}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ref.read(userProfileProvider).value;
    final validatorRole = userProfile?['role'] ?? 'Validator';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    submission.contributorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: isDark ? AppColors.creamBg : AppColors.forest900,
                      fontSize: 12,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.gold500,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "ACTIVE CONTRIBUTOR",
                            style: AppTypography.label.copyWith(
                              color: AppColors.gold500,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "96% APPROVAL",
                            style: AppTypography.label.copyWith(
                              color: AppColors.creamText3,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
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
                            "1 FLAG",
                            style: AppTypography.label.copyWith(
                              color: AppColors.terracotta,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (submission.status == VoiceStatus.approved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  final user = ref.read(authStateProvider).value;
                  if (user == null) return;

                  try {
                    await ref
                        .read(firebaseServiceProvider)
                        .approveVoiceSubmission(
                          submission.id,
                          user.uid,
                          validatorRole,
                        );
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
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.semanticRed,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gold500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppColors.forest900,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "APPROVE",
                        style: AppTypography.label.copyWith(
                          color: AppColors.forest900,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showFlagActionSheet(submission),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.terracotta.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: AppColors.terracotta,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _showBulkActionSheet(BuildContext context) {
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
                style: AppTypography.h2ExtraBold.copyWith(
                  color: AppColors.gold500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Apply actions to ${_selectedIds.length} selected items',
                style: AppTypography.body.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.creamText,
                ),
                decoration: InputDecoration(
                  hintText: 'Feedback for Reject/Flag (optional for bulk)',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.creamText3,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.forest900
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () =>
                          _handleBulkAction('approve', feedbackController.text),
                      child: Text(
                        'APPROVE ALL',
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                        backgroundColor: AppColors.terracotta.withValues(
                          alpha: 0.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.terracotta),
                        ),
                      ),
                      onPressed: () {
                        if (feedbackController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Feedback required for bulk rejection'),
                              backgroundColor: AppColors.terracotta,
                            ),
                          );
                          return;
                        }
                        _handleBulkAction('reject', feedbackController.text);
                      },
                      child: Text(
                        'REJECT ALL',
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
                        backgroundColor: AppColors.terracotta,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (feedbackController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Feedback required for bulk flag'),
                              backgroundColor: AppColors.terracotta,
                            ),
                          );
                          return;
                        }
                        _handleBulkAction('flag', feedbackController.text);
                      },
                      child: Text(
                        'FLAG ALL',
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

  Future<void> _handleBulkAction(String action, String feedback) async {
    Navigator.pop(context); // Close sheet
    setState(() => _isProcessing = true);

    final firebaseService = ref.read(firebaseServiceProvider);
    final user = ref.read(authStateProvider).value;
    final userProfile = ref.read(userProfileProvider).value;
    final validatorRole = userProfile?['role'] ?? 'Validator';

    if (user == null) return;

    int count = 0;
    final idsToProcess = List<String>.from(_selectedIds);

    for (final id in idsToProcess) {
      try {
        if (action == 'approve') {
          await firebaseService.approveVoiceSubmission(
            id,
            user.uid,
            validatorRole,
          );
        } else if (action == 'reject') {
          await firebaseService.rejectVoiceSubmission(
            id,
            user.uid,
            validatorRole,
            feedback,
          );
        } else if (action == 'flag') {
          await firebaseService.flagVoiceSubmission(
            id,
            user.uid,
            validatorRole,
            feedback,
          );
        }
        count++;
      } catch (e) {
        debugPrint("Error processing $id: $e");
      }
    }

    setState(() {
      _isProcessing = false;
      _isSelectionMode = false;
      _selectedIds.clear();
    });

    if (mounted) {
      String message = '';
      Color bgColor = AppColors.semanticGreen;

      if (action == 'approve') {
        message = 'Bulk Approved $count items!';
      } else if (action == 'reject') {
        message = 'Bulk Rejected $count items!';
        bgColor = AppColors.semanticRed;
      } else if (action == 'flag') {
        message = 'Bulk Flagged $count items!';
        bgColor = AppColors.terracotta;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bgColor,
        ),
      );
    }
  }

  void _showSubmissionAuditLog(VoiceSubmission submission) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Audit Trail',
                    style: AppTypography.h2ExtraBold.copyWith(
                      color: AppColors.gold500,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.creamText3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAuditItem(
                'Full Submission ID',
                submission.id,
                Icons.fingerprint_rounded,
                isDark,
                showCopy: true,
              ),
              const Divider(color: Colors.white10, height: 32),
              _buildAuditItem(
                'Contributor',
                '${submission.contributorName} (${submission.contributorId.substring(0, 6)}...)',
                Icons.person_outline_rounded,
                isDark,
              ),
              const SizedBox(height: 16),
              _buildAuditItem(
                'Submitted On',
                submission.submittedAt != null
                    ? dateFormat.format(submission.submittedAt!)
                    : 'Unknown',
                Icons.calendar_today_rounded,
                isDark,
              ),
              const SizedBox(height: 16),
              _buildAuditItem(
                'Current Status',
                submission.status.name.toUpperCase(),
                Icons.info_outline_rounded,
                isDark,
                valueColor: _getStatusColor(submission.status),
              ),
              if (submission.validatedAt != null) ...[
                const SizedBox(height: 16),
                _buildAuditItem(
                  'Validated On',
                  dateFormat.format(submission.validatedAt!),
                  Icons.verified_user_outlined,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildAuditItem(
                  'Validator Role',
                  submission.validatorRole ?? 'Unknown',
                  Icons.shield_outlined,
                  isDark,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuditItem(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    bool showCopy = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.forest900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.gold500, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: showCopy
                    ? () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ID copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                child: Text(
                  value,
                  style: AppTypography.mono.copyWith(
                    color: valueColor ?? (isDark ? Colors.white : AppColors.forest900),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(VoiceStatus status) {
    switch (status) {
      case VoiceStatus.approved:
        return AppColors.semanticGreen;
      case VoiceStatus.flagged:
        return AppColors.terracotta;
      case VoiceStatus.rejected:
        return AppColors.semanticRed;
      default:
        return AppColors.gold500;
    }
  }

  void _showFlagActionSheet(VoiceSubmission submission) {
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
                'Action Required',
                style: AppTypography.h2ExtraBold.copyWith(
                  color: AppColors.gold500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Decide how to handle "${submission.title}"',
                style: AppTypography.body.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.creamText,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., Audio is clipped, please re-record.',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.creamText3,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.forest900
                      : Colors.black.withValues(alpha: 0.05),
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
                      'Poor Audio',
                      'Background Noise',
                      'Clipped Recording',
                      'Incorrect Dialect',
                      'Muffled Speech',
                      'Other...',
                    ].map((reason) {
                      return ActionChip(
                        label: Text(
                          reason,
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            fontSize: 10,
                          ),
                        ),
                        backgroundColor: AppColors.gold500.withValues(alpha: 0.1,
                        ),
                        side: BorderSide(
                          color: AppColors.gold500.withValues(alpha: 0.3),
                        ),
                        onPressed: () {
                          final currentText = feedbackController.text;
                          if (currentText.isEmpty) {
                            feedbackController.text = reason;
                          } else {
                            feedbackController.text = '$currentText, $reason';
                          }
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta.withValues(
                          alpha: 0.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.terracotta),
                        ),
                      ),
                      onPressed: () async {
                        final user = ref.read(authStateProvider).value;
                        final userProfile = ref.read(userProfileProvider).value;
                        final validatorRole =
                            userProfile?['role'] ?? 'Validator';
                        final feedback = feedbackController.text.trim();

                        if (user == null) return;
                        if (feedback.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please provide feedback for rejection',
                              ),
                              backgroundColor: AppColors.terracotta,
                            ),
                          );
                          return;
                        }

                        try {
                          await ref
                              .read(firebaseServiceProvider)
                              .rejectVoiceSubmission(
                                submission.id,
                                user.uid,
                                validatorRole,
                                feedback,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Voice Recording Rejected'),
                                backgroundColor: AppColors.semanticRed,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.semanticRed,
                              ),
                            );
                          }
                        }
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
                        backgroundColor: AppColors.terracotta,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final user = ref.read(authStateProvider).value;
                        final userProfile = ref.read(userProfileProvider).value;
                        final validatorRole =
                            userProfile?['role'] ?? 'Validator';
                        if (user == null) return;

                        try {
                          await ref
                              .read(firebaseServiceProvider)
                              .flagVoiceSubmission(
                                submission.id,
                                user.uid,
                                validatorRole,
                                feedbackController.text,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Clarification request sent'),
                                backgroundColor: AppColors.terracotta,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.semanticRed,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'SEND REQUEST',
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryStatCard(String label, String count, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
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
}




