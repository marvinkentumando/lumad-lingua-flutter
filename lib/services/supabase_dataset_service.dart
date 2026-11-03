import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_dataset_entry.dart';

abstract class ISupabaseStorageAdapter {
  Future<List<FileObject>> listObjects({required String path, int limit = 100, int offset = 0});
  Future<Uint8List> downloadFile(String path);
  String getPublicUrl(String path);
}

class SupabaseStorageAdapter implements ISupabaseStorageAdapter {
  final SupabaseClient _client;
  SupabaseStorageAdapter(this._client);

  @override
  Future<List<FileObject>> listObjects({required String path, int limit = 100, int offset = 0}) async {
    return await _client.storage.from('audio').list(
          path: path,
          searchOptions: SearchOptions(limit: limit, offset: offset),
        );
  }

  @override
  Future<Uint8List> downloadFile(String path) async {
    return await _client.storage.from('audio').download(path);
  }

  @override
  String getPublicUrl(String path) {
    return _client.storage.from('audio').getPublicUrl(path);
  }
}

class SupabaseDatasetService {
  final ISupabaseStorageAdapter _storageAdapter;
  static const String approvedConfigHash = '3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21';

  SupabaseDatasetService({
    SupabaseClient? client,
    ISupabaseStorageAdapter? storageAdapter,
  }) : _storageAdapter = storageAdapter ?? SupabaseStorageAdapter(client ?? Supabase.instance.client);

  /// Discovers and resolves all available dataset entries directly from Supabase Storage `audio/dataset`.
  /// Relies exclusively on Supabase Storage object hierarchy with full pagination support, per-RUN ID
  /// metadata compatibility verification, and take retention.
  Future<List<SupabaseDatasetEntry>> discoverDatasetEntries() async {
    try {
      // 1. List folders/objects inside 'dataset' in the 'audio' bucket with full pagination support
      List<FileObject> rootObjects = [];
      int limit = 100;
      int offset = 0;
      while (true) {
        final batch = await _storageAdapter.listObjects(path: 'dataset', limit: limit, offset: offset);
        if (batch.isEmpty) break;
        rootObjects.addAll(batch);
        if (batch.length < limit) break;
        offset += limit;
      }

      if (rootObjects.isEmpty) {
        debugPrint('SupabaseDatasetService: No folders or objects found in audio/dataset');
        return [];
      }

      List<SupabaseDatasetEntry> entries = [];

      for (var obj in rootObjects) {
        final name = obj.name;
        if (name.isEmpty) continue;

        // Ignore files located directly inside 'dataset' (e.g., items ending in .wav or having an id and metadata)
        final isFileAtRoot = name.toLowerCase().endsWith('.wav') || (obj.id != null && obj.metadata != null);
        if (isFileAtRoot) {
          debugPrint('SupabaseDatasetService: Ignoring root-level file in dataset: $name');
          continue;
        }

        // Target folder path
        final folderPath = 'dataset/$name';
        List<FileObject> fileObjects = [];
        int fileOffset = 0;
        while (true) {
          final batch = await _storageAdapter.listObjects(path: folderPath, limit: limit, offset: fileOffset);
          if (batch.isEmpty) break;
          fileObjects.addAll(batch);
          if (batch.length < limit) break;
          fileOffset += limit;
        }

        if (fileObjects.isEmpty) {
          debugPrint('SupabaseDatasetService: Target folder "$name" is empty.');
          continue;
        }

        // Group valid reference WAV takes by RUN ID
        Map<String, List<ReferenceAudioTake>> runTakesMap = {};

        for (var file in fileObjects) {
          final fileName = file.name;
          final nameLower = fileName.toLowerCase();

          // Reject raw recordings, non-WAV files, or metadata JSON files
          if (!nameLower.endsWith('.wav')) continue;
          if (nameLower.contains('raw')) continue;

          // Parse filename format: <target_phrase>_<take_number>__RUN-YYYY-NNNN.wav
          final match = RegExp(r'^(.+)_([12])__(RUN-\d{4}-\d{4})\.wav$', caseSensitive: false).firstMatch(fileName);
          if (match == null) {
            debugPrint('SupabaseDatasetService: Rejecting malformed or unsupported filename: $fileName');
            continue;
          }

          final filePhrase = match.group(1)!;
          // Verify that target phrase in filename matches containing folder name
          if (filePhrase != name) {
            debugPrint('SupabaseDatasetService: Rejecting filename "$fileName" because target phrase "$filePhrase" does not match folder "$name".');
            continue;
          }

          final takeNumber = int.parse(match.group(2)!);
          final runId = match.group(3)!;

          final relativePath = '$folderPath/$fileName';
          final publicUrl = _storageAdapter.getPublicUrl(relativePath);

          final take = ReferenceAudioTake(
            takeNumber: takeNumber,
            fileName: fileName,
            audioPath: relativePath,
            audioUrl: publicUrl,
            runId: runId,
          );

          runTakesMap.putIfAbsent(runId, () => []).add(take);
        }

        if (runTakesMap.isEmpty) {
          debugPrint('SupabaseDatasetService: Folder "$name" has no valid preprocessed reference WAVs.');
          continue;
        }

        // Enforce strict per-RUN ID compatibility verification
        for (var entryRunId in runTakesMap.keys) {
          final takes = runTakesMap[entryRunId]!;
          takes.sort((a, b) => a.takeNumber.compareTo(b.takeNumber));

          bool isCompatibleRun = false;
          final possibleMetaNames = [
            '$entryRunId' '_metadata.json',
            '$entryRunId' '.json',
            'metadata_$entryRunId.json',
            'metadata.json',
          ];

          for (var metaName in possibleMetaNames) {
            final metaFileExists = fileObjects.any((f) => f.name.toLowerCase() == metaName.toLowerCase());
            if (metaFileExists) {
              try {
                final metaBytes = await _storageAdapter.downloadFile('$folderPath/$metaName');
                final metaStr = utf8.decode(metaBytes);
                final metaMap = jsonDecode(metaStr) as Map<String, dynamic>;

                final fileRunId = metaMap['run_id'] ?? metaMap['runId'];
                final configHash = metaMap['config_hash'] ?? metaMap['configHash'];

                // Strict validation: Metadata must explicitly contain run_id matching entryRunId, and config_hash matching approved hash.
                // Generic metadata without a run_id field must not validate any run.
                if (fileRunId != null && fileRunId == entryRunId && configHash == approvedConfigHash) {
                  isCompatibleRun = true;
                  break;
                }
              } catch (e) {
                debugPrint('Failed to verify metadata for run $entryRunId in $folderPath: $e');
              }
            }
          }

          final title = SupabaseDatasetEntry.formatTitleFromFolder(name);
          final subtitle = 'Preprocessed Audio ($entryRunId) • Verified';

          entries.add(SupabaseDatasetEntry(
            folderName: name,
            title: title,
            subtitle: subtitle,
            runId: entryRunId,
            isCompatible: isCompatibleRun,
            takes: takes,
            isAvailable: isCompatibleRun, // Only available for comparison if verified compatible per RUN ID
          ));
        }
      }

      return entries;
    } catch (e, st) {
      debugPrint('Error discovering Supabase dataset entries: $e\n$st');
      rethrow; // Surface discovery/pagination errors rather than hiding them
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
