import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/firebase_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EditorUtils {
  static Widget buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
    int? maxLength,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white70 : AppColors.creamText2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
          onChanged: onChanged,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white12 : AppColors.creamText3,
            ),
            filled: true,
            fillColor: isDark ? AppColors.forestDarkCard : Colors.white,
            counterStyle: TextStyle(
              color: isDark ? Colors.white38 : AppColors.creamText3,
              fontSize: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildDataTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? hint,
    Key? key,
    int? maxLength,
  }) {
    return SafeDataTextField(
      key: key,
      label: label,
      initialValue: initialValue,
      onChanged: onChanged,
      hint: hint,
      maxLength: maxLength,
    );
  }

  static Widget buildImageAttachment({
    required BuildContext context,
    required String? currentImageUrl,
    required Function(String) onUploadComplete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentImageUrl != null && currentImageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                currentImageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.white10,
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
            ),
          ),
        InkWell(
          onTap: () => _pickAndUpload(
            context: context,
            path: 'lesson_assets/images',
            allowedExtensions: ['jpg', 'jpeg', 'png'],
            onComplete: onUploadComplete,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.creamBorder,
                width: 1.5,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? AppColors.forestDarkCard : Colors.white,
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.gold500,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                    Text(
                      currentImageUrl == null
                          ? 'Browse Village Library'
                          : 'Change Artifact Image',
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white : AppColors.creamText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    'upload a new visual artifact',
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white38 : AppColors.creamText3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildAudioRecorderPlaceholder({
    required BuildContext context,
    required String? currentAudioUrl,
    required Function(String) onUploadComplete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAudio = currentAudioUrl != null && currentAudioUrl.isNotEmpty;
    return InkWell(
      onTap: () => _showAudioSourceSheet(context, onUploadComplete),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasAudio
                ? AppColors.gold500.withValues(alpha: 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.creamBorder),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasAudio
                    ? AppColors.gold500.withValues(alpha: 0.1)
                    : AppColors.semanticRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasAudio ? Icons.audiotrack_rounded : Icons.mic_rounded,
                color: hasAudio ? AppColors.gold500 : AppColors.semanticRed,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAudio ? 'Audio Attached' : 'Record Pronunciation',
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white : AppColors.creamText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    hasAudio
                        ? 'Tap to replace audio artifact'
                        : 'Speak clearly for the students',
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white38 : AppColors.creamText3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasAudio ? Icons.check_circle_rounded : Icons.graphic_eq_rounded,
              color: hasAudio
                  ? AppColors.gold500
                  : (isDark ? Colors.white24 : AppColors.creamText3),
            ),
          ],
        ),
      ),
    );
  }

  static void _showAudioSourceSheet(
    BuildContext context,
    Function(String) onComplete,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest800 : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic_rounded, color: AppColors.gold500),
              title: Text(
                'Record Now',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.creamText,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRecordingDialog(context, onComplete);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload, color: AppColors.gold500),
              title: Text(
                'Choose from Library',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.creamText,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(
                  context: context,
                  path: 'lesson_assets/audio',
                  allowedExtensions: ['mp3', 'wav', 'm4a'],
                  onComplete: onComplete,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showRecordingDialog(
    BuildContext context,
    Function(String) onComplete,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AudioRecorderDialog(onComplete: onComplete),
    );
  }

  static Future<void> _pickAndUpload({
    required BuildContext context,
    required String path,
    required List<String> allowedExtensions,
    required Function(String) onComplete,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading to Ancestral Vault...'),
            duration: Duration(seconds: 2),
          ),
        );

        final String downloadUrl = await FirebaseService().uploadFile(
          path,
          File(result.files.single.path!),
          fileName: result.files.single.name,
        );

        onComplete(downloadUrl);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artifact secured!'),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload artifact: $e'),
          backgroundColor: AppColors.semanticRed,
        ),
      );
    }
  }
}

class SafeDataTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int? maxLength;

  const SafeDataTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.maxLength,
  });

  @override
  State<SafeDataTextField> createState() => _SafeDataTextFieldState();
}

class _SafeDataTextFieldState extends State<SafeDataTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(SafeDataTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller if the initialValue changes externally (e.g. deletion in list)
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white70 : AppColors.creamText2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
          onChanged: widget.onChanged,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white12 : AppColors.creamText3,
            ),
            filled: true,
            fillColor: isDark ? AppColors.forestDarkCard : Colors.white,
            counterStyle: TextStyle(
              color: isDark ? Colors.white38 : AppColors.creamText3,
              fontSize: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class AudioRecorderDialog extends StatefulWidget {
  final Function(String) onComplete;
  const AudioRecorderDialog({super.key, required this.onComplete});

  @override
  State<AudioRecorderDialog> createState() => _AudioRecorderDialogState();
}

class _AudioRecorderDialogState extends State<AudioRecorderDialog> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  Timer? _timer;
  String? _path;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        _path = p.join(
          tempDir.path,
          'recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        await _recorder.start(const RecordConfig(), path: _path!);

        setState(() {
          _isRecording = true;
          _duration = Duration.zero;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _duration += const Duration(seconds: 1));
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path != null && mounted) {
      _uploadAndComplete(path);
    }
  }

  Future<void> _uploadAndComplete(String path) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading recording...')));

      final url = await FirebaseService().uploadFile(
        'lesson_assets/audio',
        File(path),
        fileName: p.basename(path),
      );

      widget.onComplete(url);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload recording: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.forestDarkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text(
            _isRecording ? 'Recording...' : 'Ready to Record',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.creamText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AppColors.gold500,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isRecording ? AppColors.semanticRed : AppColors.gold500,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isRecording
                                ? AppColors.semanticRed
                                : AppColors.gold500)
                            .withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!_isRecording)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.creamText3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}



