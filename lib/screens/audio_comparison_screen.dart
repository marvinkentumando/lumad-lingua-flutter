import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
import '../models/quest.dart';
import '../providers/student_provider.dart';
import '../providers/quest_provider.dart';
import '../utils/wav_decoder.dart';
import '../utils/app_localization.dart';

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
  static const int maxRecordingDurationSeconds = 15;

  AudioComparisonState _state = AudioComparisonState.idle;
  double _scorePercentage = 0.0;
  int _currentIndex = 0;
  bool _isShuffled = false;
  List<SupabaseDatasetEntry> _items = [];
  bool _isLoadingNativeAudio = false;

  String? _recordedFilePath;
  Uint8List? _preprocessedWavBytes;
  bool _isPreprocessedAudioSelected = false;
  double _recordedDurationSeconds = 0.0;
  int _recordingDurationSeconds = 0;
  Timer? _recordingTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final List<double> _liveAmplitudeBars = List.filled(16, 0.1);

  List<double> _userVisualWaveform = [];
  List<double> _nativeVisualWaveform = [];
  String? _errorMessage;
  bool _isQuietWarning = false;
  bool _isStoppingRecording = false;

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

  Future<void> _playNativeAudio(SupabaseDatasetEntry item) async {
    if (item.takes.isEmpty) return;
    final take = item.primaryTake ?? item.takes.first;
    if (take.audioUrl.isEmpty) return;
    setState(() => _isLoadingNativeAudio = true);
    try {
      await _userPlayer.stop();
      final resolvedUrl = ref.read(supabaseStorageServiceProvider).getAudioUrl(take.audioUrl);
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

  Future<List<double>> _fetchAndDecodeNativePcm(SupabaseDatasetEntry currentItem, ReferenceAudioTake take) async {
    Uint8List nativeBytes;
    File? nativeFile;

    final resolvedNativeUrl = ref.read(supabaseStorageServiceProvider).getAudioUrl(take.audioUrl);

    if (kIsWeb) {
      final response = await http.get(Uri.parse(resolvedNativeUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        nativeBytes = response.bodyBytes;
      } else {
        throw Exception('Failed to download reference WAV (HTTP ${response.statusCode})');
      }
    } else {
      final directory = await getTemporaryDirectory();
      final cacheFileName = buildReferenceCacheFileName(currentItem.folderName, take.runId, take.takeNumber);
      nativeFile = File('${directory.path}/$cacheFileName');

      bool needsDownload = true;
      if (await nativeFile.exists()) {
        if (await nativeFile.length() > 500) {
          needsDownload = false;
        } else {
          await nativeFile.delete();
        }
      }

      if (needsDownload) {
        final response = await http.get(Uri.parse(resolvedNativeUrl)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          await nativeFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download reference WAV (HTTP ${response.statusCode})');
        }
      }
      nativeBytes = await nativeFile.readAsBytes();
    }

    final validNativeWav = WavDecoder.ensureWavBytes(nativeBytes);
    final nativeWavResult = WavDecoder.decodeWavBytes(validNativeWav);
    return nativeWavResult.pcmSamples;
  }

  Future<void> _playUserAudio() async {
    if (_recordedFilePath == null || _recordedFilePath!.isEmpty) return;
    try {
      await _nativePlayer.stop();
      await _userPlayer.stop();

      if (_isPreprocessedAudioSelected && _preprocessedWavBytes != null) {
        await _userPlayer.play(ap.BytesSource(_preprocessedWavBytes!));
      } else {
        if (kIsWeb) {
          await _userPlayer.play(ap.UrlSource(_recordedFilePath!));
        } else {
          if (!File(_recordedFilePath!).existsSync()) return;
          await _userPlayer.play(ap.DeviceFileSource(_recordedFilePath!));
        }
      }

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
        _isQuietWarning = false;
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
        _isQuietWarning = false;
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
      _isQuietWarning = false;
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
      RecordConfig config = const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
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
          autoGain: true,
          echoCancel: true,
        );
      }

      String recordPath = '';
      if (!kIsWeb) {
        final directory = await getTemporaryDirectory();
        recordPath = '${directory.path}/user_pronunciation_16k.wav';
      }

      await _audioRecorder.start(config, path: recordPath);

      _recordingDurationSeconds = 0;
      _isStoppingRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _state == AudioComparisonState.recording) {
          setState(() {
            _recordingDurationSeconds++;
          });
          if (_recordingDurationSeconds >= maxRecordingDurationSeconds) {
            _stopRecording(isAutoStop: true);
          }
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
          _recordedFilePath = kIsWeb ? null : recordPath;
          _state = AudioComparisonState.recording;
          _errorMessage = null;
          _isQuietWarning = false;
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
          _isQuietWarning = false;
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

  Future<void> _stopRecording({bool isAutoStop = false}) async {
    if (_state != AudioComparisonState.recording || _isStoppingRecording) return;
    _isStoppingRecording = true;

    HapticService.selection();
    _recordingTimer?.cancel();
    _amplitudeSubscription?.cancel();

    try {
      final path = await _audioRecorder.stop();
      final targetPath = path ?? _recordedFilePath;

      if (targetPath == null || targetPath.isEmpty) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = 'Recording output is missing.';
            _isQuietWarning = false;
          });
        }
        return;
      }

      Uint8List bytes;
      if (kIsWeb) {
        if (!targetPath.startsWith('blob:') && !targetPath.startsWith('http')) {
          if (mounted) {
            setState(() {
              _state = AudioComparisonState.error;
              _errorMessage = 'Recording failed to generate a valid browser audio URL.';
              _isQuietWarning = false;
            });
          }
          return;
        }
        final response = await http.get(Uri.parse(targetPath));
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          if (mounted) {
            setState(() {
              _state = AudioComparisonState.error;
              _errorMessage = 'Failed to retrieve recorded audio in browser.';
              _isQuietWarning = false;
            });
          }
          return;
        }
        bytes = response.bodyBytes;
      } else {
        final learnerFile = File(targetPath);
        if (!learnerFile.existsSync() || await learnerFile.length() < 100) {
          if (mounted) {
            setState(() {
              _state = AudioComparisonState.error;
              _errorMessage = 'Recording is empty. Please speak clearly and try again.';
              _isQuietWarning = false;
            });
          }
          return;
        }
        bytes = await learnerFile.readAsBytes();
      }

      if (bytes.length < 100) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = 'Recording is empty. Please speak clearly and try again.';
            _isQuietWarning = false;
          });
        }
        return;
      }

      final validWavBytes = WavDecoder.ensureWavBytes(bytes);
      final learnerWavResult = WavDecoder.decodeWavBytes(validWavBytes);
      final learnerPcm = learnerWavResult.pcmSamples;

      if (learnerPcm.length < 1600) { // < 0.1s
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = 'Recording is too short (minimum 0.1s required). Please record again.';
            _isQuietWarning = false;
          });
        }
        return;
      }

      // Check signal for silence/near-silence and quality conditions
      final signal = WavDecoder.analyzeSignal(learnerPcm);
      if (signal.isEmptyOrInvalid || signal.isSilent || signal.isQuiet || signal.hasNoSpeech) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = signal.hasNoSpeech
                ? "No speech detected. Please speak the phrase clearly into the microphone and record again."
                : "We couldn't hear your voice clearly. Please speak closer to the microphone and record again.";
            _isQuietWarning = false;
          });
        }
        return;
      }

      if (signal.isClipped) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = "Your recording sounds distorted or too loud. Please move slightly further from the microphone and record again.";
            _isQuietWarning = false;
          });
        }
        return;
      }

      if (signal.isInterrupted) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = "Microphone connection was interrupted. Please check your audio input device and try again.";
            _isQuietWarning = false;
          });
        }
        return;
      }

      if (signal.isExcessivePause) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = "Long pause detected. Try pronouncing the complete phrase smoothly without stopping.";
            _isQuietWarning = false;
          });
        }
        return;
      }

      if (signal.isMultiSpeaker) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = "Multiple voices detected. Please make sure you are the only one speaking.";
            _isQuietWarning = false;
          });
        }
        return;
      }

      if (signal.isHighNoise) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = "High background noise detected. Please move to a quieter location for better accuracy.";
            _isQuietWarning = false;
          });
        }
        return;
      }

      _recordedDurationSeconds = learnerWavResult.durationSeconds;
      _userVisualWaveform = WavDecoder.extractVisualWaveform(learnerPcm, noOfSamples: 128);

      try {
        final preprocessedPcm = WavDecoder.preprocessPcmRecommendedV1(learnerPcm);
        _preprocessedWavBytes = WavDecoder.encodePcmToWavBytes(preprocessedPcm, sampleRate: 16000);
      } catch (e) {
        debugPrint('Failed to pre-encode preprocessed preview: $e');
        _preprocessedWavBytes = null;
      }

      if (mounted) {
        setState(() {
          _recordedFilePath = targetPath;
          _isPreprocessedAudioSelected = false;
          _state = AudioComparisonState.recorded;
          _errorMessage = null;
          _isQuietWarning = signal.isQuiet;
        });

        if (isAutoStop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum recording time reached (15s). You can listen to your recording or try again.'),
              backgroundColor: AppColors.gold500,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error finalizing recording: $e');
      if (mounted) {
        setState(() {
          _state = AudioComparisonState.error;
          _errorMessage = 'Error parsing recorded audio: ${e.toString().split(':').last.trim()}';
          _isQuietWarning = false;
        });
      }
    } finally {
      _isStoppingRecording = false;
    }
  }

  Future<void> _recordAgain() async {
    await _userPlayer.stop();
    setState(() {
      _state = AudioComparisonState.idle;
      _userVisualWaveform = [];
      _scorePercentage = 0.0;
      _errorMessage = null;
      _isQuietWarning = false;
      _isStoppingRecording = false;
      _isPreprocessedAudioSelected = false;
      _preprocessedWavBytes = null;
    });
    await _startRecording();
  }

  Future<void> _submitForComparison() async {
    if (_items.isEmpty || _recordedFilePath == null || _recordedFilePath!.isEmpty) return;
    if (_state != AudioComparisonState.recorded && _state != AudioComparisonState.playing) return;

    final currentItem = _items[_currentIndex];
    if (!currentItem.isAvailable || !currentItem.isCompatible) {
      if (mounted) {
        setState(() {
          _state = AudioComparisonState.error;
          _errorMessage = 'Selected reference run is unverified or incompatible. Please select a verified compatible run.';
        });
      }
      return;
    }

    final take1 = currentItem.primaryTake ?? currentItem.takes.firstWhere((t) => t.takeNumber == 1, orElse: () => currentItem.takes.first);

    HapticService.selection();

    await _userPlayer.stop();
    await _nativePlayer.stop();

    setState(() {
      _state = AudioComparisonState.comparing;
      _errorMessage = null;
    });

    try {
      // 1. Decode learner audio bytes
      Uint8List learnerBytes;
      File? learnerFile;

      if (kIsWeb) {
        final response = await http.get(Uri.parse(_recordedFilePath!));
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          throw Exception('Failed to load recorded audio in browser.');
        }
        learnerBytes = response.bodyBytes;
      } else {
        learnerFile = File(_recordedFilePath!);
        if (!await learnerFile.exists()) {
          throw Exception('Learner audio recording file not found.');
        }
        learnerBytes = await learnerFile.readAsBytes();
      }

      final validLearnerWav = WavDecoder.ensureWavBytes(learnerBytes);
      final learnerWavResult = WavDecoder.decodeWavBytes(validLearnerWav);
      final learnerPcm = learnerWavResult.pcmSamples;

      final signal = WavDecoder.analyzeSignal(learnerPcm);
      if (signal.isEmptyOrInvalid || signal.isSilent || signal.isQuiet || signal.hasNoSpeech) {
        if (mounted) {
          setState(() {
            _state = AudioComparisonState.error;
            _errorMessage = signal.hasNoSpeech
                ? "No speech detected. Please speak the phrase clearly into the microphone and record again."
                : "We couldn't hear your voice clearly. Please speak closer to the microphone and record again.";
            _isQuietWarning = false;
          });
        }
        return;
      }

      // 2. Fetch & decode Take 1 PCM
      final nativePcm1 = await _fetchAndDecodeNativePcm(currentItem, take1);
      _nativeVisualWaveform = WavDecoder.extractVisualWaveform(nativePcm1, noOfSamples: 128);

      // Compare against Take 1
      final score1 = PronunciationService.analyzePronunciation(
        nativePcm1,
        learnerPcm,
        strictness: PronunciationStrictness.normal,
        algorithm: PronunciationAlgorithm.dtw,
      );

      double finalScore = score1.overallScore;

      // Check if Take 2 exists for extra comparison accuracy
      final take2 = currentItem.takes.where((t) => t.takeNumber == 2).firstOrNull;
      if (take2 != null) {
        try {
          final nativePcm2 = await _fetchAndDecodeNativePcm(currentItem, take2);
          final score2 = PronunciationService.analyzePronunciation(
            nativePcm2,
            learnerPcm,
            strictness: PronunciationStrictness.normal,
            algorithm: PronunciationAlgorithm.dtw,
          );
          // Average the comparison results between Take 1 and Take 2
          finalScore = (score1.overallScore + score2.overallScore) / 2.0;
        } catch (e2) {
          debugPrint('Take 2 comparison skipped due to error: $e2');
        }
      }

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final l10n = ref.read(localizationProvider);

        setState(() {
          _scorePercentage = finalScore;
          _state = AudioComparisonState.result;
        });

        _showResultPopupModal(context, isDark, l10n);

        if (_scorePercentage >= 60.0) {
          HapticService.success();
          try {
            ref.read(studentProvider.notifier).addXp(15);
            ref.read(questActionProvider.notifier).updateProgress(QuestType.pronunciation, 1);
          } catch (e) {
            debugPrint('Error awarding pronunciation XP: $e');
          }
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: AppColors.gold500,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to Connect to Reference Storage',
                    textAlign: TextAlign.center,
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not reach Supabase dataset storage. Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white60 : AppColors.creamText3,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  BrandButton(
                    text: 'RETRY CONNECTION',
                    onTap: () {
                      HapticService.light();
                      ref.invalidate(supabaseDatasetEntriesProvider);
                    },
                    type: BrandButtonType.primary,
                    icon: Icons.refresh_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
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
                          onPressed: () => _playNativeAudio(item),
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Raw Voice (Default)'),
              selected: !_isPreprocessedAudioSelected,
              selectedColor: AppColors.gold500,
              backgroundColor: Colors.white12,
              labelStyle: TextStyle(
                color: !_isPreprocessedAudioSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              onSelected: (selected) {
                if (selected && _isPreprocessedAudioSelected) {
                  _stopUserAudio();
                  setState(() {
                    _isPreprocessedAudioSelected = false;
                  });
                  HapticService.selection();
                  _playUserAudio();
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Preprocessed Voice'),
              selected: _isPreprocessedAudioSelected,
              selectedColor: AppColors.gold500,
              backgroundColor: Colors.white12,
              labelStyle: TextStyle(
                color: _isPreprocessedAudioSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              onSelected: (selected) {
                if (selected && !_isPreprocessedAudioSelected) {
                  _stopUserAudio();
                  setState(() {
                    _isPreprocessedAudioSelected = true;
                  });
                  HapticService.selection();
                  _playUserAudio();
                }
              },
            ),
          ],
        ),
        if (_userVisualWaveform.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSimpleWaveformCanvas(_userVisualWaveform, Colors.white),
        ],
        if (_isQuietWarning) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.semanticWarning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.semanticWarning.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_down_rounded, size: 16, color: AppColors.semanticWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quiet recording detected. Speak closer to the microphone for best accuracy.',
                    style: AppTypography.caption.copyWith(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
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

    if (_state == AudioComparisonState.error) {
      return BrandButton(
        text: 'RECORD AGAIN',
        onTap: _recordAgain,
        type: BrandButtonType.primary,
        icon: Icons.refresh_rounded,
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

    // High contrast dark font colors for excellent legibility over gold card background
    Color scoreColor = const Color(0xFF4E342E);
    String feedback = l10n.translate('feedback_good_effort');

    if (_scorePercentage >= 80.0) {
      scoreColor = const Color(0xFF1B5E20);
      feedback = l10n.translate('feedback_excellent');
    } else if (_scorePercentage < 60.0) {
      scoreColor = const Color(0xFFBF360C);
      feedback = l10n.translate('feedback_needs_work');
    }

    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            l10n.translate('acoustic_match'),
            style: AppTypography.label.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: AppTypography.displayBold.copyWith(
              color: scoreColor,
              fontSize: 52,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (_scorePercentage >= 60.0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  Text(
                    '+15 XP Awarded!',
                    style: AppTypography.label.copyWith(
                      color: const Color(0xFF1B5E20),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showResultPopupModal(BuildContext context, bool isDark, AppLocalization l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forest800 : AppColors.creamBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: AppColors.gold500.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pronunciation Assessment',
                    style: AppTypography.h3.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildResultCard(isDark, l10n),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: BrandButton(
                      text: 'RECORD AGAIN',
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        _recordAgain();
                      },
                      type: BrandButtonType.secondary,
                      icon: Icons.refresh_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrandButton(
                      text: 'DONE',
                      onTap: () {
                        Navigator.of(modalContext).pop();
                      },
                      type: BrandButtonType.primary,
                      icon: Icons.check_circle_rounded,
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
