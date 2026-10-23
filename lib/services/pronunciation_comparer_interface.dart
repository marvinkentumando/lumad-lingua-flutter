import 'dart:io';

/// Input request payload for pronunciation analysis
class PronunciationComparisonRequest {
  final String vocabularyId;
  final String referenceAudioPath;
  final File? referenceAudioFile;
  final File? learnerAudioFile;
  final List<double> referencePcmSamples;
  final List<double> learnerPcmSamples;
  final PronunciationAudioMetadata metadata;

  PronunciationComparisonRequest({
    required this.vocabularyId,
    required this.referenceAudioPath,
    this.referenceAudioFile,
    this.learnerAudioFile,
    required this.referencePcmSamples,
    required this.learnerPcmSamples,
    required this.metadata,
  });
}

/// Traceability metadata describing preprocessing settings
class PronunciationAudioMetadata {
  final int sampleRate; // e.g. 16000
  final int numChannels; // e.g. 1 (mono)
  final String runId; // e.g. "RUN-2026-0004"
  final String configHash; // e.g. "3140166e41dc4be9"

  PronunciationAudioMetadata({
    this.sampleRate = 16000,
    this.numChannels = 1,
    this.runId = 'RUN-2026-0004',
    this.configHash = '3140166e41dc4be9',
  });
}

/// Typed comparison result returned by the comparison engine
class PronunciationComparisonResult {
  final double scorePercentage; // 0.0 to 100.0
  final bool isCandidateEvaluation; // True if candidate algorithm pending research lock
  final String feedbackKey;
  final Map<String, dynamic> rawMetrics;

  PronunciationComparisonResult({
    required this.scorePercentage,
    this.isCandidateEvaluation = true,
    required this.feedbackKey,
    this.rawMetrics = const {},
  });
}

/// Abstract contract for pronunciation comparison engines
abstract class IPronunciationComparer {
  Future<PronunciationComparisonResult> compare(PronunciationComparisonRequest request);
}
