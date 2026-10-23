import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../services/haptic_service.dart';
import '../services/pronunciation_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/supabase_dataset_service.dart';
import '../models/supabase_dataset_entry.dart';
import '../utils/wav_decoder.dart';
import '../utils/app_localization.dart';
import '../services/pronunciation_comparer_interface.dart';

enum AudioComparisonState {
  idle,       // Ready to start recording
  recording,  // Microhpone is actively capturing audio
  recorded,   // Recording complete, preview & review available
  playing,    // Playing back learner's recorded attempt
  comparing,  // Executing candidate pronunciation comparison
  result,     // Comparison complete, candidate score presented
  error,      // Recoverable error message
}

class AudioComparisonScreen extends ConsumerStatefulWidget {
  const AudioComparisonScreen({super.key});

  @override
  ConsumerState<AudioComparisonScreen> createState() => _AudioComparisonScreenState();
}

class _AudioComparisonScreenState extends ConsumerState<AudioComparisonScreen> {
  AudioComparisonState _state = AudioComparisonState.idle;
  double _scorePercentage = 0.0;
  int _currentIndex = 0;
  bool _isShuffled = false;
  List<SupabaseDatasetEntry> _items = [];
  bool _isLoadingNativeAudio = false;

  String? _recordedFilePath;
  double _recordedDurationSeconds = 0.0;
  int _recordingDurationSeconds = 0;
  Timer? _recordingTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final List<double> _liveAmplitudeBars = List.filled(16, 0.1);

  List<double> _userVisualWaveform = [];
  List<double> _nativeVisualWaveform = [];
  String? _errorMessage;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final ap.AudioPlayer _nativePlayer = ap.AudioPlayer();
  final ap.AudioPlayer _userPlayer = ap.AudioPlayer();
  StreamSubscription? _userPlayerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _userPlayerCompleteSubscription = _userPlayer.onPlayerComplete.listen((_) {
      if (mounted && _state == AudioComparisonState.playing) {
        setState(() {
          _state = AudioComparisonState.recorded;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _userPlayerCompleteSubscription?.cancel();
    _audioRecorder.dispose();
    _nativePlayer.dispose();
    _userPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNativeAudio(String url) async {
    if (url.isEmpty) return;
    setState(() => _isLoadingNativeAudio = true);
    try {
      await _userPlayer.stop();
      final resolvedUrl = ref.read(supabaseStorageServiceProvider).getAudioUrl(url);
      await _nativePlayer.stop();
      await _nativePlayer.play(ap.UrlSource(resolvedUrl));
    } catch (e) {
      debugPrint('Error playing native reference audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play reference audio: ${e.toString().split(':').last.trim()}'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingNativeAudio = false);
    }
  }

  Future<void> _playUserAudio() async {
    if (_recordedFilePath == null || !File(_recordedFilePath!).existsSync()) return;
    try {
      await _nativePlayer.stop();
      await _userPlayer.stop();
      await _userPlayer.play(ap.DeviceFileSource(_recordedFilePath!));
      setState(() {
        _state = AudioComparisonState.playing;
      });
    } catch (e) {
      debugPrint('Error playing learner attempt audio: $e');
    }
  }

  Future<void> _stopUserAudio() async {
    try {
      await _userPlayer.stop();
      if (mounted && _state == AudioComparisonState.playing) {
        setState(() {
          _state = AudioComparisonState.recorded;
        });
      }
    } catch (e) {
      debugPrint('Error stopping learner audio playback: $e');
    }
  }

  void _nextItem() {
    if (_currentIndex < _items.length - 1) {
      _stopAllAudioAndRecording();
      setState(() {
        _currentIndex++;
        _state = AudioComparisonState.idle;
        _scorePercentage = 0.0;
        _recordedFilePath = null;
        _userVisualWaveform = [];
        _nativeVisualWaveform = [];
        _errorMessage = null;
      });
      HapticService.light();
    }
  }

  void _previousItem() {
    if (_currentIndex > 0) {
      _stopAllAudioAndRecording();
      setState(() {
        _currentIndex--;
        _state = AudioComparisonState.idle;
        _scorePercentage = 0.0;
        _recordedFilePath = null;
        _userVisualWaveform = [];
        _nativeVisualWaveform = [];
        _errorMessage = null;
      });
      HapticService.light();
    }
  }

  void _toggleShuffle() {
    if (_items.isEmpty) return;
    _stopAllAudioAndRecording();
    setState(() {
      _isShuffled = !_isShuffled;
      _items.shuffle();
      _currentIndex = 0;
      _state = AudioComparisonState.idle;
      _scorePercentage = 0.0;
      _recordedFilePath = null;
      _userVisualWaveform = [];
      _nativeVisualWaveform = [];
      _errorMessage = null;
    });
    HapticService.medium();
  }

  Future<void> _stopAllAudioAndRecording() async {
    _recordingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}
    try {
      await _nativePlayer.stop();
      await _userPlayer.stop();
    } catch (_) {}
  }

  Future<void> _startRecording() async {
    if (_state == AudioComparisonState.recording || _state == AudioComparisonState.comparing) return;

    HapticService.selection();
    await _stopAllAudioAndRecording();

    // Check microphone permission
    bool hasPermission = false;
    try {
      hasPermission = await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('Permission check error: $e');
    }

    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _state = AudioComparisonState.error;
          _errorMessage = 'Microphone permission is required to record audio.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio.'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final recordPath = '${directory.path}/user_pronunciation_16k.wav';

      RecordConfig config = const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      );

      bool isWavSupported = true;
      try {
        isWavSupported = await _audioRecorder.isEncoderSupported(AudioEncoder.wav);
      } catch (_) {}

      if (!isWavSupported) {
        config = const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        );
      }

      await _audioRecorder.start(config, path: recordPath);

      _recordingDurationSeconds = 0;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _state == AudioComparisonState.recording) {
          setState(() {
            _recordingDurationSeconds++;
          });
        }
      });

      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
        if (mounted && _state == AudioComparisonState.recording) {
          setState(() {
            final norm = ((amp.current + 60) / 60).clamp(0.08, 1.0);
            _liveAmplitudeBars.removeAt(0);
            _liveAmplitudeBars.add(norm);
          });
        }
      });

      if (mounted) {
        setState(() {
          _recordedFilePath = recordPath;
          _state = AudioComparisonState.recording;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _recordingTimer?.cancel();
      _amplitudeSubscription?.cancel();
      if (mounted) {
        setState(() {
          _state = AudioComparisonState.error;
          _errorMessage = 'Could not start microphone capture: ${e.toString().split(':').last.trim()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_state != AudioComparisonState.recording) return;

    HapticService.selection();
    _recordingTimer?.cancel();
    _amplitudeSubscription?.cancel();

    try {
      final path = await _audioRecorder.stop();
      final targetPath = path ?? _recordedFilePath;

      if (targetPath == null || !File(targetPath).existsSync()) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = 'Recording output file is missing.';
          });
        }
        return;
      }

      final learnerFile = File(targetPath);
      if (await learnerFile.length() < 100) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = 'Recording is empty. Please speak clearly and try again.';
          });
        }
        return;
      }

      final learnerWavResult = await WavDecoder.decodeWavFile(learnerFile);
      final learnerPcm = learnerWavResult.pcmSamples;

      if (learnerPcm.length < 1600) { // < 0.1s
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = 'Recording is too short (minimum 0.1s required). Please record again.';
          });
        }
        return;
      }

      _recordedDurationSeconds = learnerWavResult.durationSeconds;
      _userVisualWaveform = WavDecoder.extractVisualWaveform(learnerPcm, noOfSamples: 128);

      if (mounted) {
        setState(() {
          _recordedFilePath = targetPath;
          _state = AudioComparisonState.recorded;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error finalizing recording: $e');
      if (mounted) {
        setState(() {
          _state = AudioComparisonState.error;
          _errorMessage = 'Error parsing recorded audio: ${e.toString().split(':').last.trim()}';
        });
      }
    }
  }

  Future<void> _recordAgain() async {
    await _userPlayer.stop();
    setState(() {
      _state = AudioComparisonState.idle;
      _userVisualWaveform = [];
      _scorePercentage = 0.0;
      _errorMessage = null;
    });
    await _startRecording();
  }

  Future<void> _submitForComparison() async {
    if (_items.isEmpty || _recordedFilePath == null) return;
    if (_state != AudioComparisonState.recorded && _state != AudioComparisonState.playing) return;

    final currentItem = _items[_currentIndex];
    HapticService.selection();

    await _userPlayer.stop();
    await _nativePlayer.stop();

    setState(() {
      _state = AudioComparisonState.comparing;
      _errorMessage = null;
    });

    try {
      final learnerFile = File(_recordedFilePath!);
      if (!await learnerFile.exists()) {
        throw Exception('Learner audio recording file not found.');
      }

      // 1. Decode learner 16-bit PCM WAV into 16kHz mono List<double>
      final learnerWavResult = await WavDecoder.decodeWavFile(learnerFile);
      final learnerPcm = learnerWavResult.pcmSamples;

      // 2. Load & decode native reference WAV
      final directory = await getTemporaryDirectory();
      final sanitizedFolder = currentItem.folderName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final nativeFile = File('${directory.path}/ref_$sanitizedFolder.wav');

      bool needsDownload = true;
      if (await nativeFile.exists()) {
        if (await nativeFile.length() > 500) {
          needsDownload = false;
        } else {
          await nativeFile.delete();
        }
      }

      if (needsDownload) {
        final response = await http.get(Uri.parse(currentItem.referenceAudioUrl)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          await nativeFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download reference WAV (HTTP ${response.statusCode})');
        }
      }

      final nativeWavResult = await WavDecoder.decodeWavFile(nativeFile);
      final nativePcm = nativeWavResult.pcmSamples;
      _nativeVisualWaveform = WavDecoder.extractVisualWaveform(nativePcm, noOfSamples: 128);

      // 3. Compare using algorithm-independent request interface & Recommended (v1) preprocessing
      final request = PronunciationComparisonRequest(
        vocabularyId: currentItem.folderName,
        referenceAudioPath: currentItem.referenceAudioPath,
        referenceAudioFile: nativeFile,
        learnerAudioFile: learnerFile,
        referencePcmSamples: nativePcm,
        learnerPcmSamples: learnerPcm,
        metadata: PronunciationAudioMetadata(
          sampleRate: 16000,
          numChannels: 1,
          runId: currentItem.runId,
          configHash: '3140166e41dc4be9',
        ),
      );

      final comparer = PronunciationService();
      final result = await comparer.compare(request);

      if (mounted) {
        setState(() {
          _scorePercentage = result.scorePercentage;
          _state = AudioComparisonState.result;
        });

        if (_scorePercentage >= 60.0) {
          HapticService.success();
          try {
            await _nativePlayer.play(ap.AssetSource('audio/success.MP3'));
          } catch (_) {}
        } else {
          HapticService.selection();
          try {
            await _nativePlayer.play(ap.AssetSource('audio/error.MP3'));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Pronunciation evaluation error: $e');
      if (mounted) {
        setState(() {
          _state = AudioComparisonState.error;
          _errorMessage = 'Audio comparison failed: ${e.toString().split(':').last.trim()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);
    final datasetAsync = ref.watch(supabaseDatasetEntriesProvider);

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
          l10n.translate('audio_comparison'),
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
            tooltip: l10n.translate('shuffle_content'),
          ),
        ],
      ),
      body: BrandBackground(
        child: datasetAsync.when(
          data: (entries) {
            if (_items.isEmpty && entries.isNotEmpty) {
              _items = List.from(entries);
              if (_isShuffled) _items.shuffle();
            }

            if (_items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_off_rounded, size: 64, color: Colors.white38),
                      const SizedBox(height: 16),
                      Text(
                        'No preprocessed Mansaka dataset entries found in Supabase Storage.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.white60 : AppColors.creamText3),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_currentIndex >= _items.length) _currentIndex = 0;
            final currentItem = _items[_currentIndex];

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDatasetBadge(currentItem),
                    const SizedBox(height: 16),
                    _buildNativeSpeakerCard(isDark, currentItem, l10n),
                    const SizedBox(height: 20),
                    _buildUserRecordingCard(isDark, l10n),
                    const SizedBox(height: 20),
                    if (_state == AudioComparisonState.result)
                      _buildResultCard(isDark, l10n).animate().scale().fadeIn(),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
          error: (e, _) => Center(
            child: Text('Error discovering dataset: $e', style: const TextStyle(color: Colors.white54)),
          ),
        ),
      ),
    );
  }

  Widget _buildDatasetBadge(SupabaseDatasetEntry item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: AppColors.gold500),
          const SizedBox(width: 6),
          Text(
            'REF: ${item.runId} • 16kHz WAV',
            style: AppTypography.mono.copyWith(color: AppColors.gold500, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeSpeakerCard(bool isDark, SupabaseDatasetEntry item, AppLocalization l10n) {
    return Column(
      children: [
        BrandCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.gold500,
                    child: Icon(Icons.record_voice_over_rounded, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('native_speaker', params: {'lang': 'Mansaka'}),
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
                          style: AppTypography.body.copyWith(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _isLoadingNativeAudio
                      ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold500))
                      : IconButton(
                          onPressed: () => _playNativeAudio(item.referenceAudioUrl),
                          icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.gold500, size: 40),
                        ),
                ],
              ),
              if (_nativeVisualWaveform.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSimpleWaveformCanvas(_nativeVisualWaveform, AppColors.gold500),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
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
              l10n.translate('item_progress', params: {
                'current': '${_currentIndex + 1}',
                'total': '${_items.length}',
              }),
              style: AppTypography.mono.copyWith(color: Colors.white24, fontSize: 10),
            ),
            IconButton(
              onPressed: _currentIndex < _items.length - 1 ? _nextItem : null,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: _currentIndex < _items.length - 1 ? AppColors.gold500 : Colors.white10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserRecordingCard(bool isDark, AppLocalization l10n) {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_state == AudioComparisonState.recording) ...[
            _buildActiveRecordingIndicator(),
          ] else if (_state == AudioComparisonState.comparing) ...[
            Column(
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(l10n.translate('comparing_tones'), style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ] else if (_state == AudioComparisonState.recorded || _state == AudioComparisonState.playing || _state == AudioComparisonState.result) ...[
            _buildPlaybackPreviewArea(),
          ] else ...[
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.redAccent, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ] else
              const Icon(Icons.mic_none_rounded, size: 44, color: Colors.white24),
          ],

          const SizedBox(height: 16),
          _buildCardActionButtons(l10n),
        ],
      ),
    );
  }

  Widget _buildActiveRecordingIndicator() {
    final min = (_recordingDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_recordingDurationSeconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.3, 1.3),
                  duration: 800.ms,
                ),
            const SizedBox(width: 8),
            Text(
              'RECORDING...',
              style: AppTypography.label.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(width: 12),
            Text(
              '$min:$sec',
              style: AppTypography.mono.copyWith(color: AppColors.gold500, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_liveAmplitudeBars.length, (index) {
              final val = _liveAmplitudeBars[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: (val * 32).clamp(4.0, 32.0),
                decoration: BoxDecoration(
                  color: AppColors.gold500,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackPreviewArea() {
    final isPlaying = _state == AudioComparisonState.playing;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isPlaying ? Icons.volume_up_rounded : Icons.audiotrack_rounded,
                  color: AppColors.gold500,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Your Attempt (${_recordedDurationSeconds.toStringAsFixed(1)}s)',
                  style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: isPlaying ? _stopUserAudio : _playUserAudio,
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: AppColors.gold500,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_userVisualWaveform.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSimpleWaveformCanvas(_userVisualWaveform, Colors.white),
        ],
      ],
    );
  }

  Widget _buildCardActionButtons(AppLocalization l10n) {
    if (_state == AudioComparisonState.recording) {
      return BrandButton(
        text: 'STOP RECORDING',
        onTap: _stopRecording,
        type: BrandButtonType.primary,
        icon: Icons.stop_rounded,
      );
    }

    if (_state == AudioComparisonState.recorded || _state == AudioComparisonState.playing || _state == AudioComparisonState.result) {
      return Column(
        children: [
          BrandButton(
            text: 'COMPARE PRONUNCIATION',
            onTap: _state == AudioComparisonState.comparing ? null : _submitForComparison,
            type: BrandButtonType.primary,
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 8),
          BrandButton(
            text: 'RECORD AGAIN',
            onTap: _recordAgain,
            type: BrandButtonType.secondary,
            icon: Icons.refresh_rounded,
          ),
        ],
      );
    }

    return BrandButton(
      text: l10n.translate('start_recording'),
      onTap: _startRecording,
      type: BrandButtonType.secondary,
      icon: Icons.mic_rounded,
    );
  }

  Widget _buildSimpleWaveformCanvas(List<double> waveform, Color color) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(
        painter: WaveformPainter(waveform: waveform, color: color),
      ),
    );
  }

  Widget _buildResultCard(bool isDark, AppLocalization l10n) {
    final percentage = _scorePercentage.toInt();

    Color scoreColor = AppColors.gold500;
    String feedback = l10n.translate('feedback_good_effort');

    if (_scorePercentage >= 80.0) {
      scoreColor = Colors.greenAccent;
      feedback = l10n.translate('feedback_excellent');
    } else if (_scorePercentage < 60.0) {
      scoreColor = Colors.orangeAccent;
      feedback = l10n.translate('feedback_needs_work');
    }

    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.translate('acoustic_match'),
                style: AppTypography.label.copyWith(color: Colors.black54, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Candidate Model', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: AppTypography.displayBold.copyWith(color: scoreColor, fontSize: 44),
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Candidate Model Score • XP awards disabled pending algorithm validation',
              textAlign: TextAlign.center,
              style: AppTypography.mono.copyWith(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final Color color;

  WaveformPainter({required this.waveform, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / waveform.length;
    final centerY = size.height / 2;

    for (int i = 0; i < waveform.length; i++) {
      final x = i * barWidth;
      final h = (waveform[i] * size.height).clamp(2.0, size.height);
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform || oldDelegate.color != color;
  }
}
