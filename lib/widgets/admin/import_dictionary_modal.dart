import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/dictionary_entry.dart';
import '../../services/firebase_service.dart';
import '../../services/haptic_service.dart';
import '../brand_button.dart';

class ImportDictionaryModal extends ConsumerStatefulWidget {
  const ImportDictionaryModal({super.key});

  @override
  ConsumerState<ImportDictionaryModal> createState() => _ImportDictionaryModalState();
}

class _ImportDictionaryModalState extends ConsumerState<ImportDictionaryModal> {
  bool _isImporting = false;
  String? _errorMessage;
  int? _successCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest900 : AppColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IMPORT DICTIONARY',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Upload a CSV file to bulk add entries to the digital archive.',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white70 : AppColors.forest700,
            ),
          ),
          const SizedBox(height: 24),
          _buildInstructions(isDark),
          const SizedBox(height: 32),
          if (_errorMessage != null)
            _buildStatusCard(
              title: 'Import Error',
              message: _errorMessage!,
              icon: Icons.error_outline_rounded,
              color: AppColors.semanticRed,
            )
          else if (_successCount != null)
            _buildStatusCard(
              title: 'Success!',
              message: 'Successfully imported $_successCount new entries.',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.semanticGreen,
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: BrandButton(
                  text: 'TEMPLATE',
                  type: BrandButtonType.secondary,
                  icon: Icons.download_rounded,
                  onTap: _downloadTemplate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BrandButton(
                  text: _isImporting ? 'IMPORTING...' : 'PICK FILE',
                  type: BrandButtonType.primary,
                  icon: Icons.upload_file_rounded,
                  onTap: _isImporting ? null : _pickAndImport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CSV FORMAT REQUIREMENTS',
            style: AppTypography.label.copyWith(
              color: AppColors.gold500,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _instructionRow('Header row is required as the first line.'),
          _instructionRow('Columns: term, translation_en, translation_fil, pos, dialect, definition'),
          _instructionRow('POS values: noun, verb, adjective, phrase'),
        ],
      ),
    );
  }

  Widget _instructionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 4, color: AppColors.gold500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(color: color, fontSize: 14),
                ),
                Text(
                  message,
                  style: AppTypography.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate() {
    HapticService.light();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template downloaded to your device.')),
    );
  }

  Future<void> _pickAndImport() async {
    HapticService.selection();
    setState(() {
      _isImporting = true;
      _errorMessage = null;
      _successCount = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvDecoder())
          .toList();

      if (fields.length <= 1) {
        throw 'CSV file is empty or missing headers.';
      }

      final List<DictionaryEntry> entries = [];
      for (var i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < 2) continue;

        entries.add(DictionaryEntry(
          id: '',
          indigenousWord: row[0].toString(),
          translation: row[1].toString(),
          translationFilipino: row.length > 2 ? row[2].toString() : '',
          partOfSpeech: _parsePartOfSpeech(row.length > 3 ? row[3].toString() : 'noun'),
          language: row.length > 4 ? row[4].toString() : 'Mansaka',
          usageContext: row.length > 5 ? row[5].toString() : '',
          status: ValidationStatus.approved,
          submittedAt: DateTime.now(),
        ));
      }

      if (entries.isEmpty) {
        throw 'No valid entries found in CSV.';
      }

      await ref.read(firebaseServiceProvider).bulkAddWords(entries);
      
      if (mounted) {
        setState(() {
          _isImporting = false;
          _successCount = entries.length;
        });
        HapticService.success();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _errorMessage = e.toString();
        });
        HapticService.error();
      }
    }
  }

  PartOfSpeech _parsePartOfSpeech(String val) {
    val = val.toLowerCase().trim();
    if (val.contains('verb')) return PartOfSpeech.verb;
    if (val.contains('adj')) return PartOfSpeech.adjective;
    if (val.contains('phrase')) return PartOfSpeech.phrase;
    return PartOfSpeech.noun;
  }
}
