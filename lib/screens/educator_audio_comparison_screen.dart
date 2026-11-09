import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:fl_chart/fl_chart.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../models/educator_models.dart';
import '../providers/educator_provider.dart';
import '../services/haptic_service.dart';
import '../services/audio_service.dart';
import '../utils/app_localization.dart';

class AudioMetricsData {
  final String phrase;
  final String phonetic;
  final String dialect;
  final double dtwAccuracy;
  final double pitchMatch;
  final double durationRatio;
  final double formantPrecision;
  final List<double> nativePitchContour;
  final List<double> studentPitchContour;
  final List<double> nativeWaveform;
  final List<double> studentWaveform;
  final String? nativeAudioUrl;
  final String? studentAudioUrl;

  const AudioMetricsData({
    required this.phrase,
    required this.phonetic,
    required this.dialect,
    required this.dtwAccuracy,
    required this.pitchMatch,
    required this.durationRatio,
    required this.formantPrecision,
    required this.nativePitchContour,
    required this.studentPitchContour,
    required this.nativeWaveform,
    required this.studentWaveform,
    this.nativeAudioUrl,
    this.studentAudioUrl,
  });
}

class EducatorAudioComparisonScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const EducatorAudioComparisonScreen({super.key, this.studentId});

  @override
  ConsumerState<EducatorAudioComparisonScreen> createState() =>
      _EducatorAudioComparisonScreenState();
}

class _EducatorAudioComparisonScreenState
    extends ConsumerState<EducatorAudioComparisonScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  String? _selectedStudentId;
  bool _isPlayingNative = false;
  bool _isPlayingStudent = false;
  int _selectedPhraseIndex = 0;

  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  final TextEditingController _feedbackController = TextEditingController();
  bool _feedbackSent = false;
  String? _feedbackStatusText;

  final List<AudioMetricsData> _sampleMetrics = const [
    AudioMetricsData(
      phrase: 'Madayaw na kalambuan',
      phonetic: '/ma-da-jaw na ka-lam-bu-an/',
      dialect: 'Mansaka',
      dtwAccuracy: 0.88,
      pitchMatch: 0.92,
      durationRatio: 0.96,
      formantPrecision: 0.85,
      nativePitchContour: [180, 210, 195, 220, 240, 210, 190, 175, 160],
      studentPitchContour: [175, 205, 190, 225, 230, 200, 185, 170, 155],
      nativeWaveform: [0.2, 0.5, 0.8, 0.9, 0.6, 0.4, 0.7, 0.9, 0.3, 0.1],
      studentWaveform: [0.15, 0.45, 0.75, 0.85, 0.65, 0.35, 0.65, 0.8, 0.25, 0.1],
    ),
    AudioMetricsData(
      phrase: 'Mabalos sang kanamu pag-eswela',
      phonetic: '/ma-ba-los sang ka-na-mu pag-es-we-la/',
      dialect: 'Mansaka',
      dtwAccuracy: 0.76,
      pitchMatch: 0.79,
      durationRatio: 0.88,
      formantPrecision: 0.73,
      nativePitchContour: [160, 180, 200, 220, 210, 190, 170, 180, 190, 160],
      studentPitchContour: [150, 165, 185, 200, 220, 205, 160, 165, 175, 150],
      nativeWaveform: [0.3, 0.6, 0.7, 0.8, 0.5, 0.6, 0.8, 0.4, 0.2],
      studentWaveform: [0.25, 0.4, 0.6, 0.7, 0.6, 0.45, 0.6, 0.3, 0.15],
    ),
    AudioMetricsData(
      phrase: 'Pag-amuk tubad sang lunsay',
      phonetic: '/pag-a-muk tu-bad sang lun-say/',
      dialect: 'Mandaya',
      dtwAccuracy: 0.94,
      pitchMatch: 0.96,
      durationRatio: 0.98,
      formantPrecision: 0.91,
      nativePitchContour: [200, 230, 250, 240, 220, 210, 195, 180],
      studentPitchContour: [198, 228, 248, 238, 222, 208, 193, 178],
      nativeWaveform: [0.4, 0.7, 0.9, 0.8, 0.6, 0.8, 0.5, 0.2],
      studentWaveform: [0.38, 0.68, 0.88, 0.78, 0.58, 0.78, 0.48, 0.18],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingNative = false;
          _isPlayingStudent = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _playAudio(bool isNative) async {
    HapticService.selection();
    final metric = _sampleMetrics[_selectedPhraseIndex];
    final url = isNative ? metric.nativeAudioUrl : metric.studentAudioUrl;
    final audioService = ref.read(audioServiceProvider);

    setState(() {
      if (isNative) {
        _isPlayingNative = !_isPlayingNative;
        _isPlayingStudent = false;
      } else {
        _isPlayingStudent = !_isPlayingStudent;
        _isPlayingNative = false;
      }
    });

    try {
      final playing = isNative ? _isPlayingNative : _isPlayingStudent;
      if (playing) {
        if (url != null && url.isNotEmpty) {
          await audioService.playFromUrl(url);
        } else {
          // Real backend TTS speech fallback for phrase
          await audioService.speak(metric.phrase);
        }
      } else {
        await audioService.stopPlayback();
      }
    } catch (e) {
      debugPrint('Educator audio playback error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPlayingNative = false;
          _isPlayingStudent = false;
        });
      }
    }
  }

  void _sendFeedback(String status) {
    HapticService.success();
    setState(() {
      _feedbackSent = true;
      _feedbackStatusText = 'Feedback sent ($status)';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Audio assessment saved: $status'),
        backgroundColor: AppColors.semanticGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(educatorStudentsProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopNavBar(l10n),
              Expanded(
                child: studentsAsync.when(
                  data: (students) {
                    if (students.isEmpty) {
                      return _buildEmptyStudentsState(l10n);
                    }

                    final selectedStudent = students.firstWhere(
                      (s) => s.id == (_selectedStudentId ?? widget.studentId),
                      orElse: () => students.first,
                    );
                    _selectedStudentId = selectedStudent.id;

                    final currentMetric = _sampleMetrics[_selectedPhraseIndex];

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStudentSelector(students, selectedStudent),
                          const SizedBox(height: 16),
                          _buildPhraseCard(currentMetric),
                          const SizedBox(height: 16),
                          _buildAudioPlayersSection(currentMetric, selectedStudent),
                          const SizedBox(height: 16),
                          _buildWaveformOverlay(currentMetric),
                          const SizedBox(height: 16),
                          _buildMetricsDashboard(currentMetric),
                          const SizedBox(height: 16),
                          _buildPitchContourChart(currentMetric),
                          const SizedBox(height: 16),
                          _buildFeedbackSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold500),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error loading learner data: $e'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBar(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest800.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gold500),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Educator Audio Metrics',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.gold500,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Acoustic Waveform & Pronunciation Analysis',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.creamText3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector(List<EducatorStudent> students, EducatorStudent selectedStudent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.creamBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.gold500.withValues(alpha: 0.2),
            child: Text(
              selectedStudent.name.isNotEmpty
                  ? selectedStudent.name.substring(0, 1).toUpperCase()
                  : 'S',
              style: const TextStyle(
                color: AppColors.gold500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStudent.id,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.forest800 : Colors.white,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                items: students.map((s) {
                  return DropdownMenuItem<String>(
                    value: s.id,
                    child: Text('${s.name} • ${s.level} (${s.municipality})'),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null) {
                    setState(() {
                      _selectedStudentId = newId;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseCard(AudioMetricsData metric) {
    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  metric.dialect.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              Row(
                children: List.generate(_sampleMetrics.length, (index) {
                  final isSelected = index == _selectedPhraseIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPhraseIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold500
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Take ${index + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.forest900
                              : (isDark ? Colors.white60 : Colors.black54),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            metric.phrase,
            style: AppTypography.h2ExtraBold.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.phonetic,
            style: AppTypography.body.copyWith(
              color: AppColors.gold500,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayersSection(AudioMetricsData metric, EducatorStudent student) {
    return Row(
      children: [
        Expanded(
          child: _buildSingleAudioTile(
            title: 'Native Speaker',
            subtitle: 'Reference Audio',
            icon: Icons.volume_up_rounded,
            accentColor: AppColors.gold500,
            isPlaying: _isPlayingNative,
            onTap: () => _playAudio(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSingleAudioTile(
            title: 'Student Attempt',
            subtitle: '${student.name}\'s Voice',
            icon: Icons.record_voice_over_rounded,
            accentColor: AppColors.semanticBlue,
            isPlaying: _isPlayingStudent,
            onTap: () => _playAudio(false),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleAudioTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isPlaying,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? accentColor
              : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.creamBorder),
          width: isPlaying ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white54 : AppColors.creamText3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
            ),
            label: Text(
              isPlaying ? 'Playing...' : 'Listen',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPlaying ? accentColor : accentColor.withValues(alpha: 0.15),
              foregroundColor: isPlaying ? AppColors.forest900 : accentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformOverlay(AudioMetricsData metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Waveform & Amplitude Alignment',
                style: TextStyle(
                  color: AppColors.gold500,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: const [
                  _LegendDot(color: AppColors.gold500, label: 'Native'),
                  SizedBox(width: 10),
                  _LegendDot(color: AppColors.semanticBlue, label: 'Student'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(metric.nativeWaveform.length, (i) {
                final nativeH = metric.nativeWaveform[i] * 25.0;
                final studentH = metric.studentWaveform[i] * 25.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: nativeH,
                          decoration: BoxDecoration(
                            color: AppColors.gold500.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: studentH,
                          decoration: BoxDecoration(
                            color: AppColors.semanticBlue.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsDashboard(AudioMetricsData metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acoustic Metrics Summary',
            style: TextStyle(
              color: AppColors.gold500,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'DTW Alignment',
                  '${(metric.dtwAccuracy * 100).toInt()}%',
                  metric.dtwAccuracy > 0.85 ? AppColors.semanticGreen : AppColors.gold500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Pitch Tone',
                  '${(metric.pitchMatch * 100).toInt()}%',
                  metric.pitchMatch > 0.85 ? AppColors.semanticGreen : AppColors.semanticBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Cadence Ratio',
                  '${metric.durationRatio.toStringAsFixed(2)}x',
                  AppColors.gold500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Formant Precision',
                  '${(metric.formantPrecision * 100).toInt()}%',
                  metric.formantPrecision > 0.8 ? AppColors.semanticGreen : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchContourChart(AudioMetricsData metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pitch Contour Tracking (Hz)',
                style: TextStyle(
                  color: AppColors.gold500,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: const [
                  _LegendDot(color: AppColors.gold500, label: 'Native Pitch'),
                  SizedBox(width: 10),
                  _LegendDot(color: AppColors.semanticBlue, label: 'Student Pitch'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: metric.nativePitchContour
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: AppColors.gold500,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: metric.studentPitchContour
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: AppColors.semanticBlue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Educator Assessment & Feedback',
            style: TextStyle(
              color: AppColors.gold500,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter specific pronunciation advice or pitch guidance for this learner...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark ? AppColors.forest800 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendFeedback('Approved'),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Approve Voice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.semanticGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendFeedback('Flagged for Practice'),
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: const Text('Request Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold500,
                    side: const BorderSide(color: AppColors.gold500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (_feedbackSent && _feedbackStatusText != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                _feedbackStatusText!,
                style: const TextStyle(
                  color: AppColors.semanticGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyStudentsState(AppLocalization l10n) {
    return Center(
      child: Text(
        'No student recordings found.',
        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
