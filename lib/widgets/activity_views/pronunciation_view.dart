import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../services/pronunciation_service.dart';
import 'speaking_practice_view.dart';

class PronunciationView extends StatelessWidget {
  final String question;
  final String word;
  final String phonetic;
  final bool isRecording;
  final bool hasRecorded;
  final VoidCallback? onToggleRecording;
  final bool isReadOnly;
  final String? audioUrl;
  final String? userAudioPath;
  final RecorderController? recorderController;
  final PronunciationScore? pronunciationScore;
  final bool isEvaluating;
  final VoidCallback? onPlayNativeAudio;

  const PronunciationView({
    super.key,
    required this.question,
    required this.word,
    required this.phonetic,
    this.isRecording = false,
    this.hasRecorded = false,
    this.onToggleRecording,
    this.isReadOnly = false,
    this.audioUrl,
    this.userAudioPath,
    this.recorderController,
    this.pronunciationScore,
    this.isEvaluating = false,
    this.onPlayNativeAudio,
  });

  @override
  Widget build(BuildContext context) {
    return SpeakingPracticeView(
      question: question,
      word: word,
      phonetic: phonetic,
      isRecording: isRecording,
      hasRecorded: hasRecorded,
      onToggleRecording: onToggleRecording,
      isReadOnly: isReadOnly,
      audioUrl: audioUrl,
      userAudioPath: userAudioPath,
      recorderController: recorderController,
      pronunciationScore: pronunciationScore,
      isEvaluating: isEvaluating,
      onPlayNativeAudio: onPlayNativeAudio,
    );
  }
}
