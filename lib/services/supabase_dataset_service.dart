import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_dataset_entry.dart';

class SupabaseDatasetService {
  final SupabaseClient _client;

  SupabaseDatasetService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  /// Discovers and resolves all available dataset entries directly from Supabase Storage `audio/dataset`.
  /// Relies exclusively on Supabase Storage object hierarchy without any Firestore dependency.
  Future<List<SupabaseDatasetEntry>> discoverDatasetEntries() async {
    try {
      // 1. List folders inside 'dataset' in the 'audio' bucket
      final folders = await _client.storage.from('audio').list(path: 'dataset');
      if (folders.isEmpty) {
        debugPrint('SupabaseDatasetService: No folders found in audio/dataset');
        return [];
      }

      List<SupabaseDatasetEntry> entries = [];

      for (var folderObj in folders) {
        final folderName = folderObj.name;
        if (folderName.isEmpty) continue;

        // 2. List files inside 'dataset/<folderName>'
        final folderPath = 'dataset/$folderName';
        List<FileObject> fileObjects = [];
        try {
          fileObjects = await _client.storage.from('audio').list(path: folderPath);
        } catch (e) {
          debugPrint('Failed to list files in $folderPath: $e');
          continue;
        }

        // 3. Locate verified preprocessed WAV reference (Exclude raw files)
        String? referenceFileName;
        String runId = 'RUN-2026-0004';

        for (var file in fileObjects) {
          final nameLower = file.name.toLowerCase();

          // Reject raw recordings or non-WAV files
          if (!nameLower.endsWith('.wav')) continue;
          if (nameLower.contains('raw')) continue;

          // Prefer files matching run identifier signature '__RUN-'
          if (file.name.contains('__RUN-')) {
            referenceFileName = file.name;
            final match = RegExp(r'RUN-\d{4}-\d{4}').firstMatch(file.name);
            if (match != null) {
              runId = match.group(0)!;
            } else {
              // Extract string following '__' if RegExp misses
              final parts = file.name.split('__');
              if (parts.length > 1) {
                runId = parts.last.replaceAll('.wav', '');
              }
            }
            break;
          }

          // Fallback to non-raw WAV if signature is missing
          referenceFileName ??= file.name;
        }

        // Exclude folders without a valid preprocessed WAV
        if (referenceFileName == null) {
          debugPrint('SupabaseDatasetService: Folder "$folderName" has no valid preprocessed reference WAV.');
          continue;
        }

        final relativePath = '$folderPath/$referenceFileName';
        final publicUrl = _client.storage.from('audio').getPublicUrl(relativePath);
        final title = SupabaseDatasetEntry.formatTitleFromFolder(folderName);
        final subtitle = 'Preprocessed Reference Audio ($runId)';

        entries.add(SupabaseDatasetEntry(
          folderName: folderName,
          title: title,
          subtitle: subtitle,
          referenceFileName: referenceFileName,
          referenceAudioPath: relativePath,
          referenceAudioUrl: publicUrl,
          runId: runId,
          isAvailable: true,
        ));
      }

      return entries;
    } catch (e) {
      debugPrint('Error discovering Supabase dataset entries: $e');
      return [];
    }
  }
}

final supabaseDatasetServiceProvider = Provider<SupabaseDatasetService>((ref) {
  return SupabaseDatasetService();
});

final supabaseDatasetEntriesProvider = FutureProvider<List<SupabaseDatasetEntry>>((ref) async {
  final service = ref.watch(supabaseDatasetServiceProvider);
  return await service.discoverDatasetEntries();
});
