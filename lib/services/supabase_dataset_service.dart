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

  /// Discovers and resolves dataset entries from Supabase Storage.
  /// Scans `audio/dataset` (primary, RUN-tagged) and `audio/dataset_2`
  /// (additional speaker/takes) so comparison can use a wider, calibrated
  /// reference pool. Relies on Storage object hierarchy with full pagination.
  Future<List<SupabaseDatasetEntry>> discoverDatasetEntries() async {
    try {
      const roots = ['dataset', 'dataset_2'];
      List<SupabaseDatasetEntry> entries = [];
      int limit = 100;

      for (final root in roots) {
        List<FileObject> rootObjects = [];
        int offset = 0;
        while (true) {
          final batch = await _storageAdapter.listObjects(path: root, limit: limit, offset: offset);
          if (batch.isEmpty) break;
          rootObjects.addAll(batch);
          if (batch.length < limit) break;
          offset += limit;
        }

        if (rootObjects.isEmpty) {
          debugPrint('SupabaseDatasetService: No folders or objects found in audio/$root');
          continue;
        }

        for (var obj in rootObjects) {
          final name = obj.name;
          if (name.isEmpty) continue;

          final isFileAtRoot = name.toLowerCase().endsWith('.wav') || (obj.id != null && obj.metadata != null);
          if (isFileAtRoot) {
            debugPrint('SupabaseDatasetService: Ignoring root-level file in $root: $name');
            continue;
          }

          final folderPath = '$root/$name';
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

          Map<String, List<ReferenceAudioTake>> runTakesMap = {};
          final runTagged = RegExp(r'^(.+)_([12])__(RUN-\d{4}-\d{4})\.wav$', caseSensitive: false);
          final simpleTake = RegExp(r'^(.+)_([12])\.wav$', caseSensitive: false);

          for (var file in fileObjects) {
            final fileName = file.name;
            final nameLower = fileName.toLowerCase();
            if (!nameLower.endsWith('.wav')) continue;
            if (nameLower.contains('raw')) continue;

            String filePhrase;
            int takeNumber;
            String runId;

            final taggedMatch = runTagged.firstMatch(fileName);
            if (taggedMatch != null) {
              filePhrase = taggedMatch.group(1)!;
              takeNumber = int.parse(taggedMatch.group(2)!);
              runId = taggedMatch.group(3)!;
            } else {
              final simpleMatch = simpleTake.firstMatch(fileName);
              if (simpleMatch == null) {
                debugPrint('SupabaseDatasetService: Rejecting malformed or unsupported filename: $fileName');
                continue;
              }
              filePhrase = simpleMatch.group(1)!;
              takeNumber = int.parse(simpleMatch.group(2)!);
              // Stable synthetic run id per source root (e.g. dataset_2).
              runId = root.toUpperCase().replaceAll('-', '_');
            }

            if (filePhrase != name) {
              debugPrint('SupabaseDatasetService: Rejecting filename "$fileName" because target phrase "$filePhrase" does not match folder "$name".');
              continue;
            }

            final relativePath = '$folderPath/$fileName';
            final publicUrl = _storageAdapter.getPublicUrl(relativePath);
            runTakesMap.putIfAbsent(runId, () => []).add(ReferenceAudioTake(
              takeNumber: takeNumber,
              fileName: fileName,
              audioPath: relativePath,
              audioUrl: publicUrl,
              runId: runId,
            ));
          }

          if (runTakesMap.isEmpty) {
            debugPrint('SupabaseDatasetService: Folder "$name" has no valid preprocessed reference WAVs.');
            continue;
          }

          for (var entryRunId in runTakesMap.keys) {
            final takes = runTakesMap[entryRunId]!;
            takes.sort((a, b) => a.takeNumber.compareTo(b.takeNumber));

            bool isCompatibleRun = false;
            final isRunTagged = entryRunId.startsWith('RUN-');
            if (isRunTagged) {
              final possibleMetaNames = [
                '${entryRunId}_metadata.json',
                '$entryRunId.json',
                'metadata_$entryRunId.json',
                'metadata.json',
              ];
              final hasMetaFile = possibleMetaNames.any((m) => fileObjects.any((f) => f.name.toLowerCase() == m.toLowerCase()));
              for (var metaName in possibleMetaNames) {
                final metaFileExists = fileObjects.any((f) => f.name.toLowerCase() == metaName.toLowerCase());
                if (metaFileExists) {
                  try {
                    final metaBytes = await _storageAdapter.downloadFile('$folderPath/$metaName');
                    final metaStr = utf8.decode(metaBytes);
                    final metaMap = jsonDecode(metaStr) as Map<String, dynamic>;
                    final fileRunId = metaMap['run_id'] ?? metaMap['runId'];
                    final configHash = metaMap['config_hash'] ?? metaMap['configHash'];
                    if (fileRunId != null && fileRunId == entryRunId && configHash == approvedConfigHash) {
                      isCompatibleRun = true;
                      break;
                    }
                  } catch (e) {
                    debugPrint('Failed to verify metadata for run $entryRunId in $folderPath: $e');
                  }
                }
              }
              if (!hasMetaFile) {
                isCompatibleRun = true;
              }
            } else {
              // Additional-source references (e.g. dataset_2) are preprocessed
              // takes; treat as compatible for multi-reference comparison.
              isCompatibleRun = true;
            }

            final title = SupabaseDatasetEntry.formatTitleFromFolder(name);
            final isSupplementary = root != 'dataset';
            final subtitle = isSupplementary
                ? 'Additional reference'
                : 'Verified';
            entries.add(SupabaseDatasetEntry(
              folderName: name,
              title: title,
              subtitle: subtitle,
              runId: entryRunId,
              isCompatible: isCompatibleRun,
              takes: takes,
              isAvailable: isCompatibleRun,
              sourceRoot: root,
            ));
          }
        }
      }

      // Learner-facing main references first (dataset/take 1 default), then
      // supplementary references (dataset_2) which are used only for comparison.
      entries.sort((a, b) {
        final aSupp = a.isSupplementaryReference ? 1 : 0;
        final bSupp = b.isSupplementaryReference ? 1 : 0;
        if (aSupp != bSupp) return aSupp.compareTo(bSupp);
        final titleCmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (titleCmp != 0) return titleCmp;
        return a.runId.compareTo(b.runId);
      });
      return entries;
    } catch (e, st) {
      debugPrint('Error discovering Supabase dataset entries: $e\n$st');
      rethrow;
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
