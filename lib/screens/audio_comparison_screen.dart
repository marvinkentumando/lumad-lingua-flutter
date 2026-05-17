import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../services/haptic_service.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../services/pronunciation_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';

class AudioComparisonScreen extends ConsumerStatefulWidget {
  const AudioComparisonScreen({super.key});

  @override
  ConsumerState<AudioComparisonScreen> createState() => _AudioComparisonScreenState();
}

class _AudioComparisonScreenState extends ConsumerState<AudioComparisonScreen> {
  bool _isRecording = false;
  bool _hasResult = false;
  double _score = 0.0;
  PronunciationStrictness _strictness = PronunciationStrictness.normal;

  late final RecorderController _recorderController;
  late final PlayerController _playerController;
  String? _lastRecordingPath;

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
    super.dispose();
  }

  Future<String> _getAssetPath(String asset) async {
    final byteData = await rootBundle.load(asset);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${asset.split('/').last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  void _toggleRecording() async {
    HapticService.selection();
    if (!_isRecording) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/user_pronunciation.m4a';
      await _recorderController.record(path: path);
      setState(() {
        _isRecording = true;
        _hasResult = false;
        _lastRecordingPath = path;
      });
    } else {
      final path = await _recorderController.stop();
      setState(() {
        _isRecording = false;
        _isComparing = true;
      });

      try {
        // 1. Extract waveform from User recording
        final userWaveform = await _playerController.waveformExtraction.extractWaveformData(
          path: path!,
          noOfSamples: 100,
        );

        // 2. Simulate Native Waveform (In a real app, this would be pre-extracted or extracted from asset)
        // For this demo, we'll try to extract it from a real asset if it exists, otherwise use a fallback
        List<double> nativeWaveform;
        try {
          final nativePath = await _getAssetPath('assets/audio/madyaw_native.mp3');
          nativeWaveform = await _playerController.waveformExtraction.extractWaveformData(
            path: nativePath,
            noOfSamples: 100,
          );
        } catch (e) {
          // Fallback to a mock "perfect" pattern if asset is missing for now
          nativeWaveform = List.generate(100, (i) => (sin(i / 5) * 0.5) + 0.5);
        }

        // 3. Compare using the real DTW algorithm
        final resultScore = PronunciationService.compareWaveforms(
          nativeWaveform,
          userWaveform,
          strictness: _strictness,
        );

        if (mounted) {
          setState(() {
            _isComparing = false;
            _hasResult = true;
            _score = resultScore;
          });
          if (_score > 0.7) {
            HapticService.success();
          } else {
            HapticService.selection();
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

  bool _isComparing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AUDIO COMPARISON',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: AmbientTopoBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStrictnessSelector(isDark),
                const SizedBox(height: 24),
                _buildNativeSpeakerCard(isDark),
                const SizedBox(height: 32),
                _buildUserRecordingCard(isDark),
                const SizedBox(height: 32),
                if (_hasResult) _buildResultCard(isDark).animate().scale().fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrictnessSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: PronunciationStrictness.values.map((s) {
          final isSelected = _strictness == s;
          return GestureDetector(
            onTap: () => setState(() => _strictness = s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold500 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.name.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: isSelected ? Colors.black : (isDark ? Colors.white38 : AppColors.creamText3),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNativeSpeakerCard(bool isDark) {
    return BrandCard(
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
                      'Native Speaker',
                      style: AppTypography.label.copyWith(color: AppColors.gold500),
                    ),
                    Text(
                      'Madyaw na allaw',
                      style: AppTypography.h3.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticService.light();
                  // Mock play native audio
                },
                icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.gold500, size: 40),
              ),
            ],
          ),
        ],
      ),
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
    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'MATCH SCORE',
            style: AppTypography.label.copyWith(color: Colors.black54, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: AppTypography.displayBold.copyWith(color: Colors.black, fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            _score > 0.8 ? 'Excellent! Your tones are true.' : 'Good effort! Focus on the vowel length.',
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
