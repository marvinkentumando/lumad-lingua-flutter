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

class AudioComparisonScreen extends ConsumerStatefulWidget {
  const AudioComparisonScreen({super.key});

  @override
  ConsumerState<AudioComparisonScreen> createState() => _AudioComparisonScreenState();
}

class _AudioComparisonScreenState extends ConsumerState<AudioComparisonScreen> {
  bool _isRecording = false;
  bool _hasResult = false;
  double _score = 0.0;
  
  late final RecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();
  }

  @override
  void dispose() {
    _recorderController.dispose();
    super.dispose();
  }

  void _toggleRecording() async {
    HapticService.selection();
    if (!_isRecording) {
      await _recorderController.record();
      setState(() {
        _isRecording = true;
        _hasResult = false;
      });
    } else {
      await _recorderController.stop();
      setState(() {
        _isRecording = false;
        _isComparing = true;
      });
      
      // Mock comparison delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isComparing = false;
            _hasResult = true;
            _score = 0.85; // Hardcoded mock score
          });
          HapticService.success();
        }
      });
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
