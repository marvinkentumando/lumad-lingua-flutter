import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lumad_lingua/models/supabase_dataset_entry.dart';
import 'package:lumad_lingua/services/supabase_dataset_service.dart';

class ListRequestLog {
  final String path;
  final int limit;
  final int offset;
  ListRequestLog(this.path, this.limit, this.offset);
}

class FakeSupabaseStorageAdapter implements ISupabaseStorageAdapter {
  final Map<String, List<FileObject>> listResponses = {};
  final Map<String, Uint8List> downloadResponses = {};
  final List<ListRequestLog> requestLogs = [];
  bool throwOnList = false;
  String? failOnPath;
  int? failAtOffset;

  @override
  Future<List<FileObject>> listObjects({required String path, int limit = 100, int offset = 0}) async {
    requestLogs.add(ListRequestLog(path, limit, offset));
    if (throwOnList) {
      throw Exception('Mock Supabase Storage error on path: $path at offset $offset');
    }
    if (failOnPath != null && path == failOnPath && failAtOffset != null && offset >= failAtOffset!) {
      throw Exception('Mock Supabase Storage error on path: $path at offset $offset');
    }
    final allItems = listResponses[path] ?? [];
    if (offset >= allItems.length) return [];
    final end = (offset + limit < allItems.length) ? offset + limit : allItems.length;
    return allItems.sublist(offset, end);
  }

  @override
  Future<Uint8List> downloadFile(String path) async {
    return downloadResponses[path] ?? Uint8List(0);
  }

  @override
  String getPublicUrl(String path) => 'https://example.com/storage/v1/object/public/audio/$path';
}

void main() {
  group('SupabaseDatasetService & Phase 2 Strict Validation Tests', () {
    test('Formats folder names with double underscores to clean human-readable title', () {
      expect(
        SupabaseDatasetEntry.formatTitleFromFolder('agtura__tura_ng_ugbos'),
        equals('Agtura - tura ng ugbos'),
      );
      expect(
        SupabaseDatasetEntry.formatTitleFromFolder('dako_ra_yang_bilas_mo'),
        equals('Dako ra yang bilas mo'),
      );
    });

    test('Cache path helper uses deterministic base64url encoding preventing sanitization collisions', () {
      final path1 = buildReferenceCacheFileName('dako.ra', 'RUN-2026-0003', 1);
      final path2 = buildReferenceCacheFileName('dako_ra', 'RUN-2026-0003', 1);
      final path3 = buildReferenceCacheFileName('dako.ra', 'RUN-2026-0003', 2);

      expect(path1, isNot(equals(path2)));
      expect(path1, isNot(equals(path3)));
      expect(path2, isNot(equals(path3)));
    });

    test('Metadata validation: Valid metadata with matching RUN ID and hash validates successfully', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_val', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_val'] = [
        FileObject.fromJson({'name': 'phrase_val_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'RUN-2026-0003_metadata.json', 'bucket_id': 'audio', 'id': '3'}),
      ];

      adapter.downloadResponses['dataset/phrase_val/RUN-2026-0003_metadata.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'run_id': 'RUN-2026-0003',
          'config_hash': '3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21',
        })),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(1));
      expect(entries.first.isCompatible, isTrue);
      expect(entries.first.isAvailable, isTrue);
    });

    test('Metadata validation: Missing RUN ID marks run unverified/incompatible', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_missing_rid', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_missing_rid'] = [
        FileObject.fromJson({'name': 'phrase_missing_rid_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'RUN-2026-0003_metadata.json', 'bucket_id': 'audio', 'id': '3'}),
      ];

      adapter.downloadResponses['dataset/phrase_missing_rid/RUN-2026-0003_metadata.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'config_hash': '3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21',
        })),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(1));
      expect(entries.first.isCompatible, isFalse);
      expect(entries.first.isAvailable, isFalse);
    });

    test('Metadata validation: Missing config hash marks run unverified/incompatible', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_missing_hash', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_missing_hash'] = [
        FileObject.fromJson({'name': 'phrase_missing_hash_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'RUN-2026-0003_metadata.json', 'bucket_id': 'audio', 'id': '3'}),
      ];

      adapter.downloadResponses['dataset/phrase_missing_hash/RUN-2026-0003_metadata.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'run_id': 'RUN-2026-0003',
        })),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(1));
      expect(entries.first.isCompatible, isFalse);
      expect(entries.first.isAvailable, isFalse);
    });

    test('Metadata validation: Invalid JSON marks run unverified/incompatible', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_bad_json', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_bad_json'] = [
        FileObject.fromJson({'name': 'phrase_bad_json_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'RUN-2026-0003_metadata.json', 'bucket_id': 'audio', 'id': '3'}),
      ];

      adapter.downloadResponses['dataset/phrase_bad_json/RUN-2026-0003_metadata.json'] = Uint8List.fromList(
        utf8.encode('not valid json {'),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(1));
      expect(entries.first.isCompatible, isFalse);
      expect(entries.first.isAvailable, isFalse);
    });

    test('Metadata validation: Mismatched RUN ID marks run unverified/incompatible', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_mismatch_rid', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_mismatch_rid'] = [
        FileObject.fromJson({'name': 'phrase_mismatch_rid_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'RUN-2026-0003_metadata.json', 'bucket_id': 'audio', 'id': '3'}),
      ];

      adapter.downloadResponses['dataset/phrase_mismatch_rid/RUN-2026-0003_metadata.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'run_id': 'RUN-2026-9999',
          'config_hash': '3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21',
        })),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(1));
      expect(entries.first.isCompatible, isFalse);
      expect(entries.first.isAvailable, isFalse);
    });

    test('Metadata validation: Mismatched config hash marks run unverified/incompatible', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_mismatch_hash', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_mismatch_hash'] = [
        FileObject.fromJson({'name': 'phrase_mismatch_hash_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'RUN-2026-0003_metadata.json', 'bucket_id': 'audio', 'id': '3'}),
      ];

      adapter.downloadResponses['dataset/phrase_mismatch_hash/RUN-2026-0003_metadata.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'run_id': 'RUN-2026-0003',
          'config_hash': 'bad_hash_value',
        })),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(1));
      expect(entries.first.isCompatible, isFalse);
      expect(entries.first.isAvailable, isFalse);
    });

    test('Generic metadata.json with run_id validates RUN-2026-0003 but not RUN-2026-0004', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_generic', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_generic'] = [
        FileObject.fromJson({'name': 'phrase_generic_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'phrase_generic_1__RUN-2026-0004.wav', 'bucket_id': 'audio', 'id': '3'}),
        FileObject.fromJson({'name': 'metadata.json', 'bucket_id': 'audio', 'id': '4'}),
      ];

      adapter.downloadResponses['dataset/phrase_generic/metadata.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'run_id': 'RUN-2026-0003',
          'config_hash': '3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21',
        })),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      final entry03 = entries.firstWhere((e) => e.runId == 'RUN-2026-0003');
      final entry04 = entries.firstWhere((e) => e.runId == 'RUN-2026-0004');

      expect(entry03.isCompatible, isTrue);
      expect(entry04.isCompatible, isFalse);
    });

    test('Generic metadata without RUN ID validates neither run', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_norid', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_norid'] = [
        FileObject.fromJson({'name': 'phrase_norid_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'metadata.json', 'bucket_id': 'audio', 'id': '4'}),
      ];

      adapter.downloadResponses['dataset/phrase_norid/metadata.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'config_hash': '3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21',
        })),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(1));
      expect(entries.first.isCompatible, isFalse);
    });

    test('Multiple takes belonging to the same RUN ID are retained and sorted by take number', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'phrase_takes', 'bucket_id': 'audio'}),
      ];

      adapter.listResponses['dataset/phrase_takes'] = [
        FileObject.fromJson({'name': 'phrase_takes_2__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '2'}),
        FileObject.fromJson({'name': 'phrase_takes_1__RUN-2026-0003.wav', 'bucket_id': 'audio', 'id': '3'}),
        FileObject.fromJson({'name': 'RUN-2026-0003_metadata.json', 'bucket_id': 'audio', 'id': '4'}),
      ];

      adapter.downloadResponses['dataset/phrase_takes/RUN-2026-0003_metadata.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'run_id': 'RUN-2026-0003',
          'config_hash': '3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21',
        })),
      );

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(1));
      expect(entries.first.takes.length, equals(2));
      expect(entries.first.takes[0].takeNumber, equals(1));
      expect(entries.first.takes[1].takeNumber, equals(2));
    });

    test('Folder-level pagination failure at offset 100 propagates exception and does not return partial results', () async {
      final adapter = FakeSupabaseStorageAdapter();
      adapter.failOnPath = 'dataset/failing_folder';
      adapter.failAtOffset = 100;

      adapter.listResponses['dataset'] = [
        FileObject.fromJson({'name': 'failing_folder', 'bucket_id': 'audio'}),
      ];

      final batch = List.generate(105, (i) => FileObject.fromJson({'name': 'item_$i.wav', 'bucket_id': 'audio', 'id': '$i'}));
      adapter.listResponses['dataset/failing_folder'] = batch;

      final service = SupabaseDatasetService(storageAdapter: adapter);

      bool threw = false;
      try {
        await service.discoverDatasetEntries();
      } catch (_) {
        threw = true;
      }
      expect(threw, isTrue);

      final folderRequests = adapter.requestLogs.where((r) => r.path == 'dataset/failing_folder').toList();
      expect(folderRequests.length, equals(2));
      expect(folderRequests[0].offset, equals(0));
      expect(folderRequests[0].limit, equals(100));
      expect(folderRequests[1].offset, equals(100));
      expect(folderRequests[1].limit, equals(100));
    });

    test('Discovers single-take RUN-tagged references from dataset_3 and dataset_4 supplementary pools', () async {
      final adapter = FakeSupabaseStorageAdapter();

      adapter.listResponses['dataset'] = [];
      adapter.listResponses['dataset_2'] = [];
      adapter.listResponses['dataset_3'] = [
        FileObject.fromJson({'name': 'madakmul_yang_abol', 'bucket_id': 'audio'}),
      ];
      adapter.listResponses['dataset_3/madakmul_yang_abol'] = [
        FileObject.fromJson({
          'name': 'madakmul_yang_abol__RUN-2026-0003.wav',
          'bucket_id': 'audio',
          'id': 'd3_1',
        }),
      ];

      adapter.listResponses['dataset_4'] = [
        FileObject.fromJson({'name': 'madakmul_yang_abol', 'bucket_id': 'audio'}),
      ];
      adapter.listResponses['dataset_4/madakmul_yang_abol'] = [
        FileObject.fromJson({
          'name': 'madakmul_yang_abol__RUN-2026-0003.wav',
          'bucket_id': 'audio',
          'id': 'd4_1',
        }),
      ];

      final service = SupabaseDatasetService(storageAdapter: adapter);
      final entries = await service.discoverDatasetEntries();

      expect(entries.length, equals(2));

      final d3 = entries.firstWhere((e) => e.sourceRoot == 'dataset_3');
      expect(d3.isSupplementaryReference, isTrue);
      expect(d3.folderName, equals('madakmul_yang_abol'));
      expect(d3.takes.length, equals(1));
      expect(d3.takes.first.takeNumber, equals(1));
      expect(d3.takes.first.runId, equals('RUN-2026-0003'));

      final d4 = entries.firstWhere((e) => e.sourceRoot == 'dataset_4');
      expect(d4.isSupplementaryReference, isTrue);
      expect(d4.folderName, equals('madakmul_yang_abol'));
      expect(d4.takes.length, equals(1));
    });
  });
}
