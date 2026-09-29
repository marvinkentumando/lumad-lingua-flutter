import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/dictionary_entry.dart';
import '../../services/firebase_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../services/haptic_service.dart';
import '../brand_card.dart';
import '../brand_button.dart';

class BulkAudioImportModal extends ConsumerStatefulWidget {
  final List<DictionaryEntry> entries;

  const BulkAudioImportModal({
    super.key,
    required this.entries,
  });

  @override
  ConsumerState<BulkAudioImportModal> createState() => _BulkAudioImportModalState();
}

class _BulkAudioImportModalState extends ConsumerState<BulkAudioImportModal> {
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _statusText = '';

  Future<void> _pickAudioFiles() async {
    HapticService.selection();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting audio files: $e')),
        );
      }
    }
  }

  Map<PlatformFile, DictionaryEntry?> _matchFilesWithEntries() {
    final Map<PlatformFile, DictionaryEntry?> matchMap = {};

    for (var file in _selectedFiles) {
      final nameWithoutExt = file.name.split('.').first.toLowerCase().trim();

      DictionaryEntry? matched;
      for (var entry in widget.entries) {
        final termLower = entry.indigenousWord.toLowerCase().trim();
        final idLower = entry.id.toLowerCase().trim();

        if (nameWithoutExt == termLower ||
            nameWithoutExt.contains(termLower) ||
            nameWithoutExt == idLower) {
          matched = entry;
          break;
        }
      }
      matchMap[file] = matched;
    }

    return matchMap;
  }

  Future<void> _startBulkUpload(Map<PlatformFile, DictionaryEntry?> matchMap) async {
    final matchedItems = matchMap.entries.where((e) => e.value != null).toList();

    if (matchedItems.isEmpty) {
      HapticService.warning();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files matched existing dictionary entries.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusText = 'Starting bulk audio upload...';
    });

    final storage = ref.read(supabaseStorageServiceProvider);
    final firebaseService = ref.read(firebaseServiceProvider);

    int uploadedCount = 0;

    for (int i = 0; i < matchedItems.length; i++) {
      final item = matchedItems[i];
      final file = item.key;
      final entry = item.value!;

      if (file.path == null) continue;

      setState(() {
        _statusText = 'Uploading audio for "${entry.indigenousWord}" (${i + 1}/${matchedItems.length})...';
        _uploadProgress = (i + 1) / matchedItems.length;
      });

      try {
        final localFile = File(file.path!);
        final ext = file.extension ?? 'mp3';
        final storagePath = 'dict_${entry.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        final publicUrl = await storage.uploadAudio(localFile, storagePath);

        if (publicUrl != null) {
          await firebaseService.updateWord(entry.id, {'audioUrl': publicUrl});
          uploadedCount++;
        }
      } catch (e) {
        debugPrint('Failed to process ${file.name}: $e');
      }
    }

    if (mounted) {
      HapticService.success();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully attached audio to $uploadedCount dictionary terms!'),
          backgroundColor: AppColors.semanticGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matchMap = _matchFilesWithEntries();
    final matchedCount = matchMap.values.where((v) => v != null).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest900 : AppColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BULK AUDIO IMPORT',
                style: AppTypography.h2.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _isUploading ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select audio files (MP3/WAV). Files will be automatically matched to dictionary entries by term or ID.',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BrandButton(
                  text: 'SELECT AUDIO FILES',
                  type: BrandButtonType.secondary,
                  icon: Icons.audio_file_rounded,
                  onTap: _isUploading ? null : _pickAudioFiles,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedFiles.isNotEmpty) ...[
            Text(
              'MATCHED: $matchedCount / ${_selectedFiles.length} files',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedFiles.length,
                itemBuilder: (context, i) {
                  final file = _selectedFiles[i];
                  final matchedEntry = matchMap[file];

                  return BrandCard(
                    theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.cream,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          matchedEntry != null ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          color: matchedEntry != null ? AppColors.semanticGreen : AppColors.gold500,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: AppTypography.body.copyWith(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                matchedEntry != null
                                    ? 'Matches: "${matchedEntry.indigenousWord}"'
                                    : 'No matching entry found',
                                style: AppTypography.label.copyWith(
                                  color: matchedEntry != null ? AppColors.semanticGreen : Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  'No audio files selected yet.',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
          if (_isUploading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold500),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: AppTypography.mono.copyWith(color: AppColors.gold500, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          if (_selectedFiles.isNotEmpty && !_isUploading)
            SizedBox(
              width: double.infinity,
              child: BrandButton(
                text: 'UPLOAD & ATTACH ($matchedCount)',
                type: BrandButtonType.primary,
                onTap: matchedCount > 0 ? () => _startBulkUpload(matchMap) : null,
              ),
            ),
        ],
      ),
    );
  }
}
