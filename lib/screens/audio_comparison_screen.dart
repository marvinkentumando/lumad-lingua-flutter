import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../services/haptic_service.dart';
import '../services/pronunciation_service.dart';
import '../models/dictionary_entry.dart';
import '../models/voice_submission.dart';
import '../services/firebase_service.dart';
import '../services/supabase_storage_service.dart';

enum PracticeSource { words, phrases }

class ComparisonItem {
  final String id;
  final String title;
  final String subtitle;
  final String audioUrl;
  final String language;

  ComparisonItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.audioUrl,
    required this.language,
  });
}

class AudioComparisonScreen extends ConsumerStatefulWidget {
  const AudioComparisonScreen({super.key});

  @override
  ConsumerState<AudioComparisonScreen> createState() => _AudioComparisonScreenState();
}

class _AudioComparisonScreenState extends ConsumerState<AudioComparisonScreen> {
  bool _isRecording = false;
  bool _hasResult = false;
  double _score = 0.0;
  PracticeSource _source = PracticeSource.words;
  int _currentIndex = 0;
  bool _isShuffled = false;
  List<ComparisonItem> _gameItems = [];
  bool _isComparing = false;
  bool _isLoadingAudio = false;

  late final RecorderController _recorderController;
  late final PlayerController _playerController;
  final ap.AudioPlayer _nativePlayer = ap.AudioPlayer();

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();
    _playerController = PlayerController();
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _playerController.dispose();
    _nativePlayer.dispose();
    super.dispose();
  }

  Future<void> _playNativeAudio(String audioUrl) async {
    setState(() => _isLoadingAudio = true);
    try {
      final resolvedUrl = ref.read(supabaseStorageServiceProvider).getAudioUrl(audioUrl);
      await _nativePlayer.play(ap.UrlSource(resolvedUrl));
    } catch (e) {
      debugPrint('Error playing native audio: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  void _nextItem() {
    if (_currentIndex < _gameItems.length - 1) {
      setState(() {
        _currentIndex++;
        _hasResult = false;
        _score = 0.0;
      });
      HapticService.light();
    }
  }

  void _previousItem() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _hasResult = false;
        _score = 0.0;
      });
      HapticService.light();
    }
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffled = !_isShuffled;
      if (_isShuffled) {
        _gameItems.shuffle();
      } else {
        // Simple shuffle again if untoggled, since we don't store original order
        _gameItems.shuffle();
      }
      _currentIndex = 0;
      _hasResult = false;
    });
    HapticService.medium();
  }

  List<double> _trimSilence(List<double> waveform, {double threshold = 0.05}) {
    if (waveform.isEmpty) return waveform;
    
    int start = 0;
    while (start < waveform.length && waveform[start].abs() < threshold) {
      start++;
    }

    int end = waveform.length - 1;
    while (end > start && waveform[end].abs() < threshold) {
      end--;
    }

    return waveform.sublist(start, end + 1);
  }

  void _switchSource(PracticeSource newSource) {
    if (_source == newSource) return;
    setState(() {
      _source = newSource;
      _gameItems = []; // Force reload
      _currentIndex = 0;
      _hasResult = false;
      _score = 0.0;
    });
    HapticService.medium();
  }

  void _toggleRecording() async {
    if (_gameItems.isEmpty) return;
    final currentItem = _gameItems[_currentIndex];

    HapticService.selection();
    if (!_isRecording) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/user_pronunciation.m4a';
      await _recorderController.record(path: path);
      setState(() {
        _isRecording = true;
        _hasResult = false;
      });
    } else {
      final path = await _recorderController.stop();
      if (path == null) {
        setState(() => _isRecording = false);
        return;
      }

      setState(() {
        _isRecording = false;
        _isComparing = true;
      });

      try {
        // 1. Extract waveform from User recording
        var userWaveform = await _playerController.waveformExtraction.extractWaveformData(
          path: path,
          noOfSamples: 256, // Reduced for better compatibility
        );

        if (userWaveform.isEmpty) {
          // Fallback if 256 samples fails
          userWaveform = await _playerController.waveformExtraction.extractWaveformData(
            path: path,
            noOfSamples: 128,
          );
        }

        // Trim Silence from User
        userWaveform = _trimSilence(userWaveform);

        // 2. Extract Native Waveform from URL
        List<double> nativeWaveform;
        try {
          final resolvedUrl = ref.read(supabaseStorageServiceProvider).getAudioUrl(currentItem.audioUrl);
          
          if (resolvedUrl.isEmpty) {
            throw Exception('Resolved audio URL is empty');
          }

          final directory = await getTemporaryDirectory();
          
          // Improved extension detection
          String extension = 'mp3';
          if (currentItem.audioUrl.contains('.')) {
            final parts = currentItem.audioUrl.split('?').first.split('.');
            if (parts.length > 1) {
              extension = parts.last.toLowerCase();
            }
          }
          
          // Sanitize ID for filename to avoid FileSystemExceptions
          final sanitizedId = currentItem.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
          final nativeFile = File('${directory.path}/native_temp_$sanitizedId.$extension');

          // Robust check for existing file
          bool needsDownload = true;
          if (await nativeFile.exists()) {
            final size = await nativeFile.length();
            if (size > 100) { 
              needsDownload = false;
            } else {
              await nativeFile.delete();
            }
          }

          if (needsDownload) {
             final response = await http.get(Uri.parse(resolvedUrl)).timeout(const Duration(seconds: 10));
             if (response.statusCode == 200) {
               await nativeFile.writeAsBytes(response.bodyBytes);
               debugPrint('Downloaded native audio to: ${nativeFile.path}');
             } else {
               throw Exception('HTTP ${response.statusCode}: Failed to download audio');
             }
          }

          // Ensure the file exists before extraction
          if (!await nativeFile.exists()) {
            throw Exception('Native audio file could not be saved');
          }

          nativeWaveform = await _playerController.waveformExtraction.extractWaveformData(
            path: nativeFile.path,
            noOfSamples: 256,
          );

          if (nativeWaveform.isEmpty) {
             // Fallback attempt
             nativeWaveform = await _playerController.waveformExtraction.extractWaveformData(
               path: nativeFile.path,
               noOfSamples: 128,
             );
          }

          if (nativeWaveform.isEmpty) {
            throw Exception('Could not extract waveform from native audio');
          }

          // Trim Silence from Native
          nativeWaveform = _trimSilence(nativeWaveform);
        } catch (e) {
          debugPrint('Failed to extract native waveform: $e');
          if (mounted) {
            setState(() => _isComparing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Native audio processing failed: ${e.toString().split(':').last.trim()}"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        // 3. Compare using the upgraded PronunciationService
        final resultScore = PronunciationService.compareWaveforms(
          nativeWaveform,
          userWaveform,
          strictness: PronunciationStrictness.normal,
        );

        if (mounted) {
          setState(() {
            _isComparing = false;
            _hasResult = true;
            _score = resultScore;
          });
          // ... Rest of haptic/audio logic

          if (_score > 0.7) {
            HapticService.success();
            try {
               await _nativePlayer.play(ap.AssetSource('audio/success.MP3'));
            } catch (e) {
               debugPrint('Error playing success sound: $e');
            }
          } else {
            HapticService.selection();
            try {
               await _nativePlayer.play(ap.AssetSource('audio/error.MP3'));
            } catch (e) {
               debugPrint('Error playing error sound: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Comparison error: $e');
        if (mounted) {
          setState(() => _isComparing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch data based on source
    final AsyncValue dataAsync = _source == PracticeSource.words
        ? ref.watch(allWordsProvider)
        : ref.watch(allVoiceSubmissionsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AUDIO COMPARISON',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              color: _isShuffled ? AppColors.gold500 : Colors.white70,
            ),
            onPressed: _toggleShuffle,
            tooltip: 'Shuffle Content',
          ),
        ],
      ),
      body: BrandBackground(
        child: dataAsync.when(
          data: (items) {
            // Process and filter items
            if (_gameItems.isEmpty) {
              if (_source == PracticeSource.words) {
                final words = items as List<DictionaryEntry>;
                _gameItems = words
                    .where((w) => w.audioUrl != null && w.audioUrl!.isNotEmpty)
                    .map((w) => ComparisonItem(
                      id: w.id,
                      title: w.indigenousWord,
                      subtitle: w.translation,
                      audioUrl: w.audioUrl!,
                      language: w.language,
                    ))
                    .toList();
              } else {
                final phrases = items as List<VoiceSubmission>;
                _gameItems = phrases
                    .where((p) => p.audioUrl.isNotEmpty)
                    .map((p) => ComparisonItem(
                      id: p.id,
                      title: p.title,
                      subtitle: p.transcript,
                      audioUrl: p.audioUrl,
                      language: p.dialect,
                    ))
                    .toList();
              }
              if (_isShuffled) _gameItems.shuffle();
            }

            if (_gameItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSourceSelector(isDark),
                    const SizedBox(height: 40),
                    Text(
                      'No ${_source.name} available yet.',
                      style: TextStyle(color: isDark ? Colors.white38 : AppColors.creamText3),
                    ),
                  ],
                ),
              );
            }

            if (_currentIndex >= _gameItems.length) _currentIndex = 0;
            final currentItem = _gameItems[_currentIndex];

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSourceSelector(isDark),
                    const SizedBox(height: 24),
                    _buildNativeSpeakerCard(isDark, currentItem),
                    const SizedBox(height: 32),
                    _buildUserRecordingCard(isDark),
                    const SizedBox(height: 32),
                    if (_hasResult) _buildResultCard(isDark).animate().scale().fadeIn(),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
          error: (e, _) => Center(child: Text('Error loading content', style: TextStyle(color: Colors.white38))),
        ),
      ),
    );
  }

  Widget _buildSourceSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sourceButton(PracticeSource.words, 'WORDS', Icons.menu_book_rounded),
          _sourceButton(PracticeSource.phrases, 'PHRASES', Icons.map_rounded),
        ],
      ),
    );
  }

  Widget _sourceButton(PracticeSource source, String label, IconData icon) {
    final isSelected = _source == source;
    return GestureDetector(
      onTap: () => _switchSource(source),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold500 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isSelected ? Colors.black : Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeSpeakerCard(bool isDark, ComparisonItem item) {
    return Column(
      children: [
        BrandCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.gold500,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Native Speaker (${item.language})',
                          style: AppTypography.label.copyWith(color: AppColors.gold500),
                        ),
                        Text(
                          item.title,
                          style: AppTypography.h3.copyWith(color: Colors.white),
                        ),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _isLoadingAudio
                    ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold500))
                    : IconButton(
                        onPressed: () => _playNativeAudio(item.audioUrl),
                        icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.gold500, size: 40),
                      ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _currentIndex > 0 ? _previousItem : null,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _currentIndex > 0 ? AppColors.gold500 : Colors.white10,
              ),
            ),
            Text(
              'Item ${_currentIndex + 1} of ${_gameItems.length}',
              style: AppTypography.mono.copyWith(color: Colors.white24, fontSize: 10),
            ),
            IconButton(
              onPressed: _currentIndex < _gameItems.length - 1 ? _nextItem : null,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: _currentIndex < _gameItems.length - 1 ? AppColors.gold500 : Colors.white10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserRecordingCard(bool isDark) {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_isRecording)
             AudioWaveforms(
              size: const Size(double.infinity, 60),
              recorderController: _recorderController,
              enableGesture: true,
              waveStyle: const WaveStyle(
                waveColor: Colors.white,
                showMiddleLine: false,
                extendWaveform: true,
              ),
            )
          else if (_isComparing)
            const Column(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text('Comparing Tones...', style: TextStyle(color: Colors.white70)),
              ],
            )
          else
            const Icon(Icons.mic_none_rounded, size: 48, color: Colors.white24),
          
          const SizedBox(height: 24),
          BrandButton(
            text: _isRecording ? 'STOP & COMPARE' : 'START RECORDING',
            onTap: _isComparing ? null : _toggleRecording,
            type: _isRecording ? BrandButtonType.primary : BrandButtonType.secondary,
            icon: _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isDark) {
    final percentage = (_score * 100).toInt();
    
    // Determine color and feedback based on MFCC similarity
    Color scoreColor = AppColors.gold500;
    String feedback = 'Good effort! Focus on the vowel length.';
    
    if (_score >= 0.8) {
      scoreColor = Colors.greenAccent;
      feedback = 'Excellent! Your tones are true.';
    } else if (_score < 0.6) {
      scoreColor = Colors.orangeAccent;
      feedback = 'Needs work. Try matching the elder\'s rhythm.';
    }

    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'MATCH SCORE (MFCC)',
            style: AppTypography.label.copyWith(color: Colors.black54, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: AppTypography.displayBold.copyWith(color: scoreColor, fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            feedback,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('REWARD:', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.flash_on, color: Colors.black, size: 16),
              const Text(' +15 XP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
