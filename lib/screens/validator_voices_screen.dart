import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/voice_submission.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_box.dart';

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
  final Set<String> _selectedIds = {};
  String _searchQuery = "";
  String _selectedDialect = "All";
  String? _playingId;
  double _playbackSpeed = 1.0;

  // ── Real Audio Player state ──
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  final List<String> _dialects = [
    "All",
    "Mansaka",
    "Tboli",
    "Hanunuo",
    "Mandaya",
  ];

  @override
  void initState() {
    super.initState();
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

  Future<void> _togglePlayback(String id, String audioUrl) async {
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
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      await _audioPlayer.play(UrlSource(audioUrl));
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
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      floatingActionButton:
          (_isSelectionMode && _selectedIds.isNotEmpty && !_isProcessing)
          ? FloatingActionButton.extended(
              onPressed: () async {
                setState(() => _isProcessing = true);
                final firebaseService = ref.read(firebaseServiceProvider);
                final user = ref.read(authStateProvider).value;
                final userProfile = ref.read(userProfileProvider).value;
                final validatorRole = userProfile?['role'] ?? 'Validator';

                if (user == null) return;

                int count = 0;
                for (final id in _selectedIds) {
                  try {
                    await firebaseService.approveVoiceSubmission(
                      id,
                      user.uid,
                      validatorRole,
                    );
                    count++;
                  } catch (e) {
                    debugPrint("Error approving $id: $e");
                  }
                }

                setState(() {
                  _isProcessing = false;
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bulk Approved $count items!'),
                      backgroundColor: AppColors.semanticGreen,
                    ),
                  );
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
      body: SafeArea(
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
                                : 'Audio Voices',
                            style: AppTypography.displayBold.copyWith(
                              fontSize: _isSelectionMode ? 24 : 32,
                              color: AppColors.gold500,
                            ),
                          ),
                          if (_isSelectionMode)
                            ref
                                .watch(pendingVoiceSubmissionsProvider(50))
                                .when(
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
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.gold500,
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
                            color: isDark
                                ? AppColors.forest700
                                : AppColors.creamBorder,
                          ),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.creamText,
                          ),
                          decoration: InputDecoration(
                            icon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.gold500,
                              size: 20,
                            ),
                            hintText: 'Search by title, dialect, or name...',
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.creamText3,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _dialects.map((dialect) {
                            final isSelected = _selectedDialect == dialect;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedDialect = dialect),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.gold500
                                        : (isDark
                                              ? AppColors.forest800
                                              : Colors.white),
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
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ref
                      .watch(pendingVoiceSubmissionsProvider(50))
                      .when(
                        data: (voices) {
                          var filteredList = voices;

                          if (_selectedDialect != "All") {
                            filteredList = filteredList
                                .where(
                                  (item) => item.dialect == _selectedDialect,
                                )
                                .toList();
                          }

                          if (_searchQuery.isNotEmpty) {
                            final query = _searchQuery.toLowerCase();
                            filteredList = filteredList.where((item) {
                              final title = item.title.toLowerCase();
                              final dialect = item.dialect.toLowerCase();
                              final name = item.contributorName.toLowerCase();
                              return title.contains(query) ||
                                  dialect.contains(query) ||
                                  name.contains(query);
                            }).toList();
                          }

                          if (filteredList.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 60,
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.search_off_rounded,
                                      color: AppColors.forest700,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No results found",
                                      style: AppTypography.h3.copyWith(
                                        color: AppColors.forest700,
                                      ),
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
            Text(
              "Submission ID: #ANC-${item.id.substring(0, 4)}",
              style: AppTypography.mono.copyWith(
                color: AppColors.creamText3,
                fontSize: 12,
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
                              SizedBox(
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
    final userProfile = ref.watch(userProfileProvider).value;
    final validatorRole = userProfile?['role'] ?? 'Validator';

    return Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.contributorName,
                  style: AppTypography.body.copyWith(
                    color: isDark ? AppColors.creamBg : AppColors.forest900,
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
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
                    const SizedBox(height: 2),
                    Row(
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
          ],
        ),
        const Spacer(),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gold500,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.forest900,
                  ),
                ),
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
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showFlagActionSheet(submission),
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
                'Flag for Clarification',
                style: AppTypography.h2ExtraBold.copyWith(
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ask the contributor for more info about "${submission.title}"',
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
              SizedBox(
                width: double.infinity,
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
                    final validatorRole = userProfile?['role'] ?? 'Validator';
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
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}




