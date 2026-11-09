import 'dart:convert';

class ReferenceAudioTake {
  final int takeNumber; // 1 or 2
  final String fileName;
  final String audioPath;
  final String audioUrl;
  final String runId;

  const ReferenceAudioTake({
    required this.takeNumber,
    required this.fileName,
    required this.audioPath,
    required this.audioUrl,
    required this.runId,
  });

  ReferenceAudioTake copyWith({
    int? takeNumber,
    String? fileName,
    String? audioPath,
    String? audioUrl,
    String? runId,
  }) {
    return ReferenceAudioTake(
      takeNumber: takeNumber ?? this.takeNumber,
      fileName: fileName ?? this.fileName,
      audioPath: audioPath ?? this.audioPath,
      audioUrl: audioUrl ?? this.audioUrl,
      runId: runId ?? this.runId,
    );
  }
}

/// Production helper function to construct unique, collision-free local cache filenames
/// using a deterministic base64url encoding of the complete identity (phrase, RUN ID, and take number).
String buildReferenceCacheFileName(String folderName, String runId, int takeNumber) {
  final identity = '$folderName::$runId::take$takeNumber';
  final encoded = base64UrlEncode(utf8.encode(identity)).replaceAll('=', '');
  return 'ref_$encoded.wav';
}

class SupabaseDatasetEntry {
  final String folderName;
  final String title;
  final String subtitle;
  final String runId;
  final bool isCompatible;
  final List<ReferenceAudioTake> takes;
  final bool isAvailable;
  /// Storage root this entry was discovered from (`dataset`, `dataset_2`, `dataset_3`, `dataset_4`).
  /// `dataset` entries are the learner-facing main references (take 1 default);
  /// `dataset_2`, `dataset_3`, and `dataset_4` entries are supplementary
  /// references used only to improve comparison accuracy across speakers.
  final String sourceRoot;

  const SupabaseDatasetEntry({
    required this.folderName,
    required this.title,
    this.subtitle = '',
    required this.runId,
    required this.isCompatible,
    required this.takes,
    this.isAvailable = true,
    this.sourceRoot = 'dataset',
  });

  /// Supplementary references (e.g. dataset_2) are not learner-facing playback
  /// items; they participate only in pronunciation comparison.
  bool get isSupplementaryReference => sourceRoot != 'dataset';

  /// The main reference the learner should hear and copy: take 1 (default).
  /// Falls back to the first available take if take 1 is missing.
  ReferenceAudioTake? get primaryTake {
    if (takes.isEmpty) return null;
    for (final take in takes) {
      if (take.takeNumber == 1) return take;
    }
    return takes.first;
  }
  String get referenceFileName => primaryTake?.fileName ?? '';
  String get referenceAudioPath => primaryTake?.audioPath ?? '';
  String get referenceAudioUrl => primaryTake?.audioUrl ?? '';

  /// Helper to convert raw folder name (e.g. "agtura__tura_ng_ugbos") into human-readable title ("Agtura - tura ng ugbos")
  static String formatTitleFromFolder(String folder) {
    if (folder.isEmpty) return '';
    String formatted = folder.replaceAll('__', ' - ').replaceAll('_', ' ');
    if (formatted.isEmpty) return folder;
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  SupabaseDatasetEntry copyWith({
    String? folderName,
    String? title,
    String? subtitle,
    String? runId,
    bool? isCompatible,
    List<ReferenceAudioTake>? takes,
    bool? isAvailable,
    String? sourceRoot,
  }) {
    return SupabaseDatasetEntry(
      folderName: folderName ?? this.folderName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      runId: runId ?? this.runId,
      isCompatible: isCompatible ?? this.isCompatible,
      takes: takes ?? this.takes,
      isAvailable: isAvailable ?? this.isAvailable,
      sourceRoot: sourceRoot ?? this.sourceRoot,
    );
  }
}
