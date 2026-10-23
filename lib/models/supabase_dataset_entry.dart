class SupabaseDatasetEntry {
  final String folderName;
  final String title;
  final String subtitle;
  final String referenceFileName;
  final String referenceAudioPath;
  final String referenceAudioUrl;
  final String runId;
  final bool isAvailable;

  const SupabaseDatasetEntry({
    required this.folderName,
    required this.title,
    this.subtitle = '',
    required this.referenceFileName,
    required this.referenceAudioPath,
    required this.referenceAudioUrl,
    this.runId = 'RUN-2026-0004',
    this.isAvailable = true,
  });

  /// Helper to convert raw folder name (e.g. "agtura__tura_ng_ugbos") into human-readable title ("Agtura - tura ng ugbos")
  static String formatTitleFromFolder(String folder) {
    if (folder.isEmpty) return '';
    // Replace double underscore with ' - ' or single space, and single underscore with space
    String formatted = folder.replaceAll('__', ' - ').replaceAll('_', ' ');
    if (formatted.isEmpty) return folder;
    // Capitalize first letter
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  SupabaseDatasetEntry copyWith({
    String? folderName,
    String? title,
    String? subtitle,
    String? referenceFileName,
    String? referenceAudioPath,
    String? referenceAudioUrl,
    String? runId,
    bool? isAvailable,
  }) {
    return SupabaseDatasetEntry(
      folderName: folderName ?? this.folderName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      referenceFileName: referenceFileName ?? this.referenceFileName,
      referenceAudioPath: referenceAudioPath ?? this.referenceAudioPath,
      referenceAudioUrl: referenceAudioUrl ?? this.referenceAudioUrl,
      runId: runId ?? this.runId,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
