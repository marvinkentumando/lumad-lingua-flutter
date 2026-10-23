import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/models/supabase_dataset_entry.dart';

void main() {
  group('SupabaseDatasetEntry Unit Tests', () {
    test('Formats folder names with double underscores to clean human-readable title', () {
      expect(
        SupabaseDatasetEntry.formatTitleFromFolder('agtura__tura_ng_ugbos'),
        equals('Agtura - tura ng ugbos'),
      );

      expect(
        SupabaseDatasetEntry.formatTitleFromFolder('saramat'),
        equals('Saramat'),
      );

      expect(
        SupabaseDatasetEntry.formatTitleFromFolder('dako_ra_yang_bilas_mo'),
        equals('Dako ra yang bilas mo'),
      );
    });

    test('SupabaseDatasetEntry copyWith maintains properties correctly', () {
      const entry = SupabaseDatasetEntry(
        folderName: 'saramat',
        title: 'Saramat',
        subtitle: 'Thank you',
        referenceFileName: 'saramat__RUN-2026-0004.wav',
        referenceAudioPath: 'dataset/saramat/saramat__RUN-2026-0004.wav',
        referenceAudioUrl: 'https://example.com/saramat.wav',
        runId: 'RUN-2026-0004',
      );

      final updated = entry.copyWith(subtitle: 'Universal expression of gratitude');

      expect(updated.folderName, equals('saramat'));
      expect(updated.title, equals('Saramat'));
      expect(updated.subtitle, equals('Universal expression of gratitude'));
      expect(updated.runId, equals('RUN-2026-0004'));
    });
  });
}
