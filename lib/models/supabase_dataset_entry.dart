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

  const SupabaseDatasetEntry({
    required this.folderName,
    required this.title,
    this.subtitle = '',
    required this.runId,
    required this.isCompatible,
    required this.takes,
    this.isAvailable = true,
  });

  ReferenceAudioTake? get primaryTake => takes.isNotEmpty ? takes.first : null;
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
  }) {
    return SupabaseDatasetEntry(
      folderName: folderName ?? this.folderName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      runId: runId ?? this.runId,
      isCompatible: isCompatible ?? this.isCompatible,
      takes: takes ?? this.takes,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
