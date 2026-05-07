import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import '../models/dictionary_entry.dart';
import '../widgets/brand_card.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/brand_text_field.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/wotd_widget.dart';
import '../widgets/impact_card.dart';
import '../services/impact_service.dart';

class ContributorScreen extends ConsumerStatefulWidget {
  const ContributorScreen({super.key});

  @override
  ConsumerState<ContributorScreen> createState() => _ContributorScreenState();
}

class _ContributorScreenState extends ConsumerState<ContributorScreen>
    with SingleTickerProviderStateMixin {
  final _wordController = TextEditingController();
  final _phoneticController = TextEditingController();
  final _englishController = TextEditingController();
  final _filipinoController = TextEditingController();
  final _languageController = TextEditingController();
  final _definitionController = TextEditingController();
  final _usageNativeController = TextEditingController();
  final _usageTranslationController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _barangayController = TextEditingController();
  String? _selectedDistrict;
  PartOfSpeech _selectedPOS = PartOfSpeech.noun;
  String? _selectedLanguage;

  final List<String> _davaoDistricts = [
    'Poblacion',
    'Talomo',
    'Agdao',
    'Buhangin',
    'Bunawan',
    'Paquibato',
    'Baguio',
    'Calinan',
    'Marilog',
    'Toril',
    'Tugbok',
  ];

  final Map<String, List<String>> _regionData = {
    'Davao del Sur': [
      'Davao City',
      'Digos City',
      'Santa Cruz',
      'Bansalan',
      'Hagonoy',
      'Magsaysay',
      'Matanao',
      'Padada',
      'Santa Maria',
      'Sulop',
    ],
    'Davao del Norte': [
      'Tagum City',
      'Panabo City',
      'Island Garden City of Samal',
      'Carmen',
      'Kapalong',
      'New Corella',
      'Santo Tomas',
      'Talaingod',
    ],
    'Davao de Oro': [
      'Nabunturan',
      'Compostela',
      'Laak',
      'Mabini',
      'Maco',
      'Maragusan',
      'Mawab',
      'Monkayo',
      'Montevista',
      'Pantukan',
    ],
    'Davao Oriental': [
      'Mati City',
      'Baganga',
      'Banaybanay',
      'Boston',
      'Caraga',
      'Cateel',
      'Lupon',
      'Manay',
      'San Isidro',
      'Tarragona',
    ],
    'Davao Occidental': [
      'Malita',
      'Don Marcelino',
      'Jose Abad Santos',
      'Sarangani',
      'Santa Maria',
    ],
  };

  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _recordedAudioPath;
  bool _isUploading = false;
  bool _isRecording = false;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  String _filterStatus = 'all'; // 'all', 'approved', 'pending'

  // Hardcoded fallback data removed in favor of Firebase streams

  Widget _buildGuardianHeader(String name, int points, String? photoUrl) {
    String rank;
    IconData rankIcon;
    Color rankColor;

    if (points > 300) {
      rank = 'GREAT ELDER GUARDIAN';
      rankIcon = Icons.auto_awesome_rounded;
      rankColor = AppColors.gold500;
    } else if (points > 100) {
      rank = 'VILLAGE HISTORIAN';
      rankIcon = Icons.castle_rounded;
      rankColor = AppColors.semanticBlue;
    } else {
      rank = 'SEEDLING CONTRIBUTOR';
      rankIcon = Icons.eco_rounded;
      rankColor = AppColors.semanticGreen;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forest800,
            AppColors.forest900.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            const Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.shield_rounded,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rankColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: rankColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(rankIcon, size: 12, color: rankColor),
                              const SizedBox(width: 6),
                              Text(
                                rank,
                                style: AppTypography.label.copyWith(
                                  color: rankColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Maayong Adlaw,\nGuardian $name',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your contributions keep the ancestral flame alive.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white24,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold500.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      image: DecorationImage(
                        image: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/images/user1.png')
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveStats(int approved, int pending, int flagged) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'VALIDATED',
            approved.toString(),
            AppColors.semanticGreen,
            _filterStatus == 'approved',
            () => setState(
              () => _filterStatus = _filterStatus == 'approved'
                  ? 'all'
                  : 'approved',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'PENDING',
            pending.toString(),
            AppColors.gold500,
            _filterStatus == 'pending',
            () => setState(
              () => _filterStatus = _filterStatus == 'pending'
                  ? 'all'
                  : 'pending',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'FLAGGED',
            flagged.toString(),
            AppColors.terracotta,
            _filterStatus == 'flagged',
            () => setState(
              () => _filterStatus = _filterStatus == 'flagged'
                  ? 'all'
                  : 'flagged',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : AppColors.forest800,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? color
                    : Colors.white.withValues(alpha: 0.05),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: AppTypography.h1ExtraBold.copyWith(
                    color: isSelected ? color : Colors.white,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: isSelected ? color : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: BrandButton(
            text: 'New Cultural Entry',
            type: BrandButtonType.primary,
            icon: Icons.add_circle_outline_rounded,
            onTap: _showAddEntrySheet,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: BrandButton(
            text: 'Bulk Upload Entries',
            type: BrandButtonType.primary,
            icon: Icons.upload_file_rounded,
            onTap: _showBulkUploadSheet,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BrandButton(
                text: 'Record Fragment',
                type: BrandButtonType.secondary,
                icon: Icons.mic_none_rounded,
                onTap: _showNewRecordingSheet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BrandButton(
                text: 'Batch Recording',
                type: BrandButtonType.secondary,
                icon: Icons.mic_external_on_rounded,
                onTap: _showBatchRecordingSheet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegacySection(List<DictionaryEntry> contributions) {
    final filtered = _filterStatus == 'all'
        ? contributions
        : contributions.where((c) {
            return c.status.name == _filterStatus;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Legacy Tracker',
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            if (_filterStatus != 'all')
              GestureDetector(
                onTap: () => setState(() => _filterStatus = 'all'),
                child: Text(
                  'Clear Filter',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(
                    Icons.history_edu_rounded,
                    color: Colors.white10,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No contributions found.',
                    style: AppTypography.body.copyWith(color: Colors.white24),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTrackerCard(entry: c),
            ),
          ),
      ],
    );
  }

  // Dialects in need are now dynamic

  void _showAddEntrySheet({String? initialLanguage}) {
    // Clear any previous recording state
    _recordedAudioPath = null;
    _isRecording = false;

    if (initialLanguage != null) {
      _selectedLanguage = initialLanguage;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final dialectsAsync = ref.watch(dialectsInNeedProvider);
            final existingDialects = dialectsAsync.value?.keys.toList() ?? [];
            final profile = ref.watch(userProfileProvider).value;
            final user = ref.watch(authStateProvider).value;

            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New Cultural Entry',
                              style: AppTypography.h2ExtraBold.copyWith(
                                color: AppColors.gold500,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.creamText3,
                              ),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Dialect Dropdown
                        Text(
                          "Language / Dialect",
                          style: AppTypography.label.copyWith(
                            color: AppColors.creamText3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.forest900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value:
                                  existingDialects.contains(_selectedLanguage)
                                  ? _selectedLanguage
                                  : null,
                              hint: const Text(
                                "Select Dialect",
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 14,
                                ),
                              ),
                              dropdownColor: AppColors.forest900,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.gold500,
                              ),
                              items: existingDialects.map((String dialect) {
                                return DropdownMenuItem<String>(
                                  value: dialect,
                                  child: Text(
                                    dialect,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setModalState(() {
                                  _selectedLanguage = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Part of Speech Dropdown
                        Text(
                          "Part of Speech",
                          style: AppTypography.label.copyWith(
                            color: AppColors.creamText3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.forest900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<PartOfSpeech>(
                              value: _selectedPOS,
                              dropdownColor: AppColors.forest900,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.gold500,
                              ),
                              items: PartOfSpeech.values.map((
                                PartOfSpeech pos,
                              ) {
                                return DropdownMenuItem<PartOfSpeech>(
                                  value: pos,
                                  child: Text(
                                    pos.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (PartOfSpeech? newValue) {
                                if (newValue != null) {
                                  setModalState(() {
                                    _selectedPOS = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        BrandTextField(
                          controller: _wordController,
                          labelText: "Indigenous Word",
                          prefixIcon: Icons.translate_rounded,
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(
                          controller: _phoneticController,
                          labelText: "Phonetic (Optional)",
                          prefixIcon: Icons.record_voice_over_rounded,
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(
                          controller: _englishController,
                          labelText: "English Translation",
                          prefixIcon: Icons.language_rounded,
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(
                          controller: _filipinoController,
                          labelText: "Filipino Translation",
                          prefixIcon: Icons.flag_rounded,
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(
                          controller: _definitionController,
                          labelText: "Definition",
                          prefixIcon: Icons.description_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(
                          controller: _usageNativeController,
                          labelText: "Usage Example (Native)",
                          prefixIcon: Icons.history_edu_rounded,
                        ),
                        const SizedBox(height: 16),
                        BrandTextField(
                          controller: _usageTranslationController,
                          labelText: "Usage Example (Translation)",
                          prefixIcon: Icons.auto_stories_rounded,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Audio Pronunciation",
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        if (_recordedAudioPath == null)
                          Row(
                            children: [
                              Expanded(
                                child: BrandButton(
                                  text: _isRecording
                                      ? 'Recording...'
                                      : 'Record',
                                  type: _isRecording
                                      ? BrandButtonType.primary
                                      : BrandButtonType.secondary,
                                  icon: _isRecording
                                      ? Icons.stop_circle
                                      : Icons.mic_none_rounded,
                                  onTap: () async {
                                    if (_isRecording) {
                                      final path = await _stopRecording();
                                      setModalState(() {
                                        _recordedAudioPath = path;
                                      });
                                    } else {
                                      await _startRecording();
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: BrandButton(
                                  text: 'Upload',
                                  type: BrandButtonType.secondary,
                                  icon: Icons.upload_file_rounded,
                                  onTap: () => _pickAudio(setModalState),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.forest900,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.gold500.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.audio_file_rounded,
                                  color: AppColors.gold500,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _recordedAudioPath!.split('/').last,
                                    style: AppTypography.mono.copyWith(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isPlaying
                                        ? Icons.stop_circle_rounded
                                        : Icons.play_circle_filled_rounded,
                                    color: AppColors.gold500,
                                    size: 28,
                                  ),
                                  onPressed: () => _playPreview(
                                    _recordedAudioPath!,
                                    setModalState,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.terracotta,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    if (_isPlaying) _audioPlayer.stop();
                                    setModalState(() {
                                      _recordedAudioPath = null;
                                      _isPlaying = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: BrandButton(
                            text: 'Submit for Validation',
                            type: BrandButtonType.primary,
                            onTap: () async {
                              // Enhanced Validation
                              if (_selectedLanguage == null) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a dialect.'),
                                  ),
                                );
                                return;
                              }
                              if (_wordController.text.isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Indigenous word is required.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_englishController.text.isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'English translation is required.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_definitionController.text.length < 10) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Definition must be at least 10 characters.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              String? audioUrl;
                              if (_recordedAudioPath != null) {
                                setModalState(() => _isUploading = true);
                                try {
                                  final fileName =
                                      'word_${DateTime.now().millisecondsSinceEpoch}.m4a';
                                  audioUrl = await ref
                                      .read(firebaseServiceProvider)
                                      .uploadAudio(
                                        _recordedAudioPath!,
                                        fileName,
                                      );
                                } catch (e) {
                                  if (sheetContext.mounted) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error uploading audio: $e',
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  setModalState(() => _isUploading = false);
                                }
                              }

                              final entry = DictionaryEntry(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                indigenousWord: _wordController.text,
                                phonetic: _phoneticController.text,
                                translation: _englishController.text,
                                translationFilipino: _filipinoController.text,
                                partOfSpeech: _selectedPOS,
                                language: _selectedLanguage!,
                                usageContext: _definitionController.text,
                                usageExampleNative: _usageNativeController.text,
                                usageExampleTranslation:
                                    _usageTranslationController.text,
                                audioUrl: audioUrl,
                                contributorName:
                                    profile?['username'] ?? 'Tribe Member',
                                contributorId: user?.uid ?? 'unknown',
                              );

                              await ref
                                  .read(firebaseServiceProvider)
                                  .addWord(entry);
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                                // Use the screen's context for the dialog since the sheet is now gone
                                if (context.mounted) {
                                  _showSuccessDialog(context);
                                }
                                _clearControllers(
                                  keepLocation: _rememberLocation,
                                );
                                if (mounted) {
                                  setState(() {
                                    _recordedAudioPath = null;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                        if (_isUploading)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.gold500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDialectFocusSection(AsyncValue<Map<String, int>> dialectsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emergency_rounded,
              color: AppColors.semanticRed,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'DIALECTS IN NEED',
              style: AppTypography.label.copyWith(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        dialectsAsync.when(
          data: (counts) {
            // Sort dialects by count (ascending) to find those in need
            final sortedDialects = counts.entries.toList()
              ..sort((a, b) => a.value.compareTo(b.value));

            // Map colors to dialects
            final colors = [
              AppColors.gold500,
              AppColors.semanticBlue,
              AppColors.terracotta,
              AppColors.semanticGreen,
            ];

            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sortedDialects.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final dialect = sortedDialects[index];
                  final color = colors[index % colors.length];
                  return GestureDetector(
                    onTap: () =>
                        _showAddEntrySheet(initialLanguage: dialect.key),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.forest800,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dialect.key,
                            style: AppTypography.h3.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dialect.value} ENTRIES',
                            style: AppTypography.label.copyWith(
                              color: color,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold500),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    final contributionsAsync = user != null
        ? ref.watch(userContributionsStreamProvider(user.uid))
        : const AsyncValue<List<DictionaryEntry>>.loading();
    final dialectsAsync = ref.watch(dialectsInNeedProvider);
    final impactAsync = ref.watch(contributionImpactProvider);

    final displayName = profile?['username'] ?? 'Tribe Member';
    final totalPoints = profile?['xp'] ?? 0;
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: AppColors.forest900,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuardianHeader(displayName, totalPoints, photoUrl),
              const SizedBox(height: 24),
              impactAsync.when(
                data: (impact) => ImpactCard(
                  studentsHelped: impact.studentsHelpedToday,
                  totalEncounters: impact.totalReach,
                  accuracyRate: impact.accuracyRate,
                  wordsValidated: impact.validatedWords,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold500),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              const WotdWidget(),
              const SizedBox(height: 32),
              contributionsAsync.when(
                data: (contributions) {
                  final approvedCount = contributions
                      .where((c) => c.status == ValidationStatus.approved)
                      .length;
                  final pendingCount = contributions
                      .where((c) => c.status == ValidationStatus.pending)
                      .length;
                  final flaggedCount = contributions
                      .where(
                        (c) =>
                            c.status == ValidationStatus.flagged ||
                            c.status == ValidationStatus.rejected,
                      )
                      .length;
                  return _buildInteractiveStats(
                    approvedCount,
                    pendingCount,
                    flaggedCount,
                  );
                },
                loading: () => _buildInteractiveStats(0, 0, 0),
                error: (_, __) => _buildInteractiveStats(0, 0, 0),
              ),
              const SizedBox(height: 32),
              _buildDialectFocusSection(dialectsAsync),
              const SizedBox(height: 32),
              _buildActionButtons(),
              const SizedBox(height: 40),
              contributionsAsync.when(
                data: (contributions) => _buildLegacySection(contributions),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, __) => Text('Error: $err'),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.forest800,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_s2lryxtd.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
              Text(
                'Entry Submitted!',
                style: AppTypography.h2ExtraBold.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Your contribution has been sent for validation. You earned 100 XP!',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              BrandButton(
                text: 'Continue',
                type: BrandButtonType.primary,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  void _clearControllers({bool keepLocation = false}) {
    _wordController.clear();
    _phoneticController.clear();
    _englishController.clear();
    _filipinoController.clear();
    if (!keepLocation) {
      _languageController.clear();
      _selectedLanguage = null;
    }
    _selectedPOS = PartOfSpeech.noun;
    _definitionController.clear();
    _usageNativeController.clear();
    _usageTranslationController.clear();

    if (!keepLocation) {
      _municipalityController.clear();
      _provinceController.clear();
      _barangayController.clear();
      _selectedDistrict = null;
      _selectedProvince = null;
      _selectedMunicipality = null;
    }
  }

  Future<void> _getCurrentLocation(Function(VoidCallback) setModalState) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are disabled.'),
            action: SnackBarAction(
              label: 'ENABLE',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions are permanently denied.'),
            action: SnackBarAction(
              label: 'SETTINGS',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();

      // Perform Reverse Geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final province = place.administrativeArea; // e.g. Davao del Sur
        final municipality = place.locality; // e.g. Davao City
        final barangay = place.subLocality; // e.g. Brgy. 76-A

        setModalState(() {
          // Attempt to match the detected province with our region data keys
          if (province != null) {
            final matchedProvince = _regionData.keys.firstWhere(
              (k) => k.toLowerCase().contains(province.toLowerCase()),
              orElse: () => _regionData.keys.first,
            );
            _selectedProvince = matchedProvince;

            // Attempt to match municipality
            if (municipality != null) {
              final municipalities = _regionData[matchedProvince] ?? [];
              final matchedMunicipality = municipalities.firstWhere(
                (m) => m.toLowerCase().contains(municipality.toLowerCase()),
                orElse: () => municipalities.isNotEmpty
                    ? municipalities.first
                    : municipality,
              );
              _selectedMunicipality = matchedMunicipality;
            }
          }

          if (barangay != null && barangay.isNotEmpty) {
            _barangayController.text = barangay;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  String _selectedSpeaker = 'Self';
  final ValueNotifier<bool> _isRecordingNotifier = ValueNotifier(false);
  bool _rememberLocation = false;
  late AudioRecorder _recorder;
  final ValueNotifier<double> _amplitudeNotifier = ValueNotifier(-160.0);
  Timer? _amplitudeTimer;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig();
        await _recorder.start(config, path: path);

        _isRecordingNotifier.value = true;

        // Start amplitude tracking for visual feedback
        _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (
          timer,
        ) async {
          final amplitude = await _recorder.getAmplitude();
          _amplitudeNotifier.value = amplitude.current;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required to record audio.',
              ),
              backgroundColor: AppColors.semanticRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  Future<String?> _stopRecording() async {
    _amplitudeTimer?.cancel();
    _amplitudeNotifier.value = -160.0;
    final path = await _recorder.stop();
    _isRecordingNotifier.value = false;
    return path;
  }

  Future<void> _playPreview(
    String path,
    Function(VoidCallback) setModalState,
  ) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setModalState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
        setModalState(() => _isPlaying = true);

        _audioPlayer.onPlayerComplete.first.then((_) {
          if (mounted) {
            setModalState(() => _isPlaying = false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing preview: $e')));
      }
    }
  }

  Future<void> _pickAudio(Function(VoidCallback) setModalState) async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setModalState(() {
        _recordedAudioPath = result.files.single.path;
      });
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _phoneticController.dispose();
    _englishController.dispose();
    _filipinoController.dispose();
    _languageController.dispose();
    _definitionController.dispose();
    _usageNativeController.dispose();
    _usageTranslationController.dispose();
    _municipalityController.dispose();
    _provinceController.dispose();
    _barangayController.dispose();
    _waveformController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _amplitudeTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitVoiceFragment(BuildContext context, String path) async {
    // Show Loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing voice fragment...")),
    );

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception("User not logged in");

      // Validate required metadata
      if (_selectedProvince == null || _selectedMunicipality == null) {
        throw Exception("Please complete the location information.");
      }

      // Upload to Storage
      final audioUrl = await ref
          .read(firebaseServiceProvider)
          .uploadVoiceFragment(user.uid, path);

      // Save Metadata to Firestore
      final municipalityId =
          _selectedMunicipality?.toLowerCase().replaceAll(' ', '_') ??
          'unknown';
      await ref.read(firebaseServiceProvider).addRecording(municipalityId, {
        'title': 'New Pronunciation',
        'speakerName': user.displayName ?? 'Tribe Member',
        'speakerRole': _selectedSpeaker,
        'province': _selectedProvince,
        'municipality': _selectedMunicipality,
        'district': _selectedDistrict,
        'barangay': _barangayController.text,
        'audioUrl': audioUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'contributorId': user.uid,
      });

      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog(context);
        _clearControllers(keepLocation: _rememberLocation);
        if (mounted) {
          setState(() {
            _recordedAudioPath = null;
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  void _showNewRecordingSheet() {
    // Clear any previous recording state
    _recordedAudioPath = null;
    _isRecordingNotifier.value = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isRecordingNotifier,
          builder: (context, isRecording, child) {
            return StatefulBuilder(
              builder: (statefulContext, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Voice of the Forest',
                          style: AppTypography.h2ExtraBold.copyWith(
                            color: AppColors.gold500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help preserve the authentic sound.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.creamText3,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Waveform Section
                        Container(
                          height: 100,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: isRecording
                              ? ValueListenableBuilder<double>(
                                  valueListenable: _amplitudeNotifier,
                                  builder: (context, amplitude, child) {
                                    return AnimatedBuilder(
                                      animation: _waveformController,
                                      builder: (context, child) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(20, (index) {
                                            // Map amplitude (-160 to 0) to height (10 to 80)
                                            final normalizedAmp =
                                                (amplitude + 160).clamp(
                                                  0,
                                                  160,
                                                ) /
                                                160;
                                            final baseHeight =
                                                10 + (normalizedAmp * 70);
                                            // Add some variance to each bar
                                            final height =
                                                (baseHeight *
                                                        (0.8 +
                                                            0.4 *
                                                                (index %
                                                                    3 /
                                                                    3)))
                                                    .clamp(4.0, 80.0);

                                            return Container(
                                              width: 4,
                                              height: height,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.semanticRed,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    );
                                  },
                                )
                              : Center(
                                  child: Container(
                                    height: 2,
                                    width: 150,
                                    color: Colors.white10,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 32),

                        // Speaker Selector
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'WHO IS SPEAKING?',
                            style: AppTypography.label.copyWith(
                              color: AppColors.creamText3,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                [
                                  'Self',
                                  'Elder',
                                  'Village Chief',
                                  'Community',
                                ].map((speaker) {
                                  final isSelected =
                                      _selectedSpeaker == speaker;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setModalState(
                                        () => _selectedSpeaker = speaker,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.gold500
                                              : AppColors.forest900,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.gold500
                                                : Colors.white10,
                                          ),
                                        ),
                                        child: Text(
                                          speaker,
                                          style: AppTypography.label.copyWith(
                                            color: isSelected
                                                ? AppColors.forest900
                                                : AppColors.creamText3,
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'PROVINCE',
                            style: AppTypography.label.copyWith(
                              color: AppColors.creamText3,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.forest900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedProvince,
                              hint: const Text(
                                "Select Province",
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 14,
                                ),
                              ),
                              dropdownColor: AppColors.forest900,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.gold500,
                              ),
                              items: _regionData.keys.map((String province) {
                                return DropdownMenuItem<String>(
                                  value: province,
                                  child: Text(
                                    province,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setModalState(() {
                                  _selectedProvince = newValue;
                                  _selectedMunicipality =
                                      null; // Reset municipality
                                  _selectedDistrict = null;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CITY / MUNICIPALITY',
                            style: AppTypography.label.copyWith(
                              color: AppColors.creamText3,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.forest900,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedMunicipality,
                                    hint: const Text(
                                      "Select City/Municipality",
                                      style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 14,
                                      ),
                                    ),
                                    dropdownColor: AppColors.forest900,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.gold500,
                                    ),
                                    items:
                                        (_selectedProvince != null
                                                ? _regionData[_selectedProvince]!
                                                : <String>[])
                                            .map((String municipality) {
                                              return DropdownMenuItem<String>(
                                                value: municipality,
                                                child: Text(
                                                  municipality,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(),
                                    onChanged: (String? newValue) {
                                      setModalState(() {
                                        _selectedMunicipality = newValue;
                                        _selectedDistrict = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _getCurrentLocation(setModalState),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.gold500.withValues(alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.gold500.withValues(alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.gold500,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_selectedMunicipality != null &&
                            _selectedMunicipality!.toLowerCase().contains(
                              'davao city',
                            )) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'DISTRICT (DAVAO CITY)',
                              style: AppTypography.label.copyWith(
                                color: AppColors.creamText3,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.forest900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDistrict,
                                hint: const Text(
                                  "Select District",
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 14,
                                  ),
                                ),
                                dropdownColor: AppColors.forest900,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.gold500,
                                ),
                                items: _davaoDistricts.map((String district) {
                                  return DropdownMenuItem<String>(
                                    value: district,
                                    child: Text(
                                      district,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setModalState(() {
                                    _selectedDistrict = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'BARANGAY',
                            style: AppTypography.label.copyWith(
                              color: AppColors.creamText3,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _barangayController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "e.g. Brgy. 76-A",
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: AppColors.forest900,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Batch Selection Toggle
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _rememberLocation = !_rememberLocation;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _rememberLocation
                                  ? AppColors.gold500.withValues(alpha: 0.1)
                                  : AppColors.forest900.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _rememberLocation
                                    ? AppColors.gold500
                                    : Colors.white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _rememberLocation
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  color: _rememberLocation
                                      ? AppColors.gold500
                                      : Colors.white24,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Remember this location",
                                        style: AppTypography.body.copyWith(
                                          color: _rememberLocation
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Auto-fills for your next entries this session.",
                                        style: AppTypography.label.copyWith(
                                          color: Colors.white24,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _rememberLocation,
                                  onChanged: (val) {
                                    setModalState(() {
                                      _rememberLocation = val;
                                    });
                                  },
                                  activeThumbColor: AppColors.gold500,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        if (_recordedAudioPath != null && !isRecording) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.forest900,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.gold500.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.audio_file_rounded,
                                  color: AppColors.gold500,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _recordedAudioPath!.split('/').last,
                                    style: AppTypography.mono.copyWith(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isPlaying
                                        ? Icons.stop_circle_rounded
                                        : Icons.play_circle_filled_rounded,
                                    color: AppColors.gold500,
                                    size: 28,
                                  ),
                                  onPressed: () => _playPreview(
                                    _recordedAudioPath!,
                                    setModalState,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.terracotta,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    if (_isPlaying) _audioPlayer.stop();
                                    setModalState(() {
                                      _recordedAudioPath = null;
                                      _isPlaying = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: BrandButton(
                              text: 'Submit Fragment',
                              type: BrandButtonType.primary,
                              icon: Icons.send_rounded,
                              onTap: () {
                                if (_isPlaying) _audioPlayer.stop();
                                _submitVoiceFragment(
                                  statefulContext,
                                  _recordedAudioPath!,
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: BrandButton(
                                  text: isRecording ? 'Stop' : 'Record',
                                  type: isRecording
                                      ? BrandButtonType.primary
                                      : BrandButtonType.secondary,
                                  icon: isRecording
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  onTap: () async {
                                    if (isRecording) {
                                      final path = await _stopRecording();
                                      if (path != null &&
                                          statefulContext.mounted) {
                                        setModalState(() {
                                          _recordedAudioPath = path;
                                        });
                                      }
                                    } else {
                                      if (_selectedMunicipality == null) {
                                        ScaffoldMessenger.of(
                                          statefulContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Please select a municipality first.",
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      await _startRecording();
                                      // setModalState(() {}); // Not needed as notifier triggers rebuild
                                    }
                                  },
                                ),
                              ),
                              if (!isRecording) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: BrandButton(
                                    text: 'Upload',
                                    type: BrandButtonType.secondary,
                                    icon: Icons.upload_file_rounded,
                                    onTap: () => _pickAudio(setModalState),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      // Reset state when sheet closes
      _isRecordingNotifier.value = false;
    });
  }

  Widget _buildTrackerCard({required DictionaryEntry entry}) {
    final status = entry.status;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case ValidationStatus.approved:
        statusColor = AppColors.semanticGreen;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'APPROVED';
        break;
      case ValidationStatus.flagged:
        statusColor = AppColors.gold500;
        statusIcon = Icons.flag_rounded;
        statusText = 'REVISION NEEDED';
        break;
      case ValidationStatus.rejected:
        statusColor = AppColors.semanticRed;
        statusIcon = Icons.cancel_rounded;
        statusText = 'REJECTED';
        break;
      case ValidationStatus.pending:
        statusColor = AppColors.creamText3;
        statusIcon = Icons.access_time_filled_rounded;
        statusText = 'PENDING';
        break;
    }

    return BrandCard(
      theme: BrandCardTheme.vibrant,
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.forest900.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.creamText3,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.indigenousWord,
                      style: AppTypography.body.copyWith(
                        color: AppColors.creamBg,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CATEGORY: ${entry.language}',
                      style: AppTypography.label.copyWith(
                        color: AppColors.creamText3,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: AppTypography.label.copyWith(
                      color: statusColor,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (entry.validatorFeedback != null &&
              entry.validatorFeedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.feedback_rounded, color: statusColor, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.validatorFeedback!,
                      style: AppTypography.body.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (status == ValidationStatus.flagged) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // Pre-fill controllers with existing data
                    _wordController.text = entry.indigenousWord;
                    _phoneticController.text = entry.phonetic ?? '';
                    _englishController.text = entry.translation;
                    _filipinoController.text = entry.translationFilipino;
                    _definitionController.text = entry.usageContext;
                    _usageNativeController.text =
                        entry.usageExampleNative ?? '';
                    _usageTranslationController.text =
                        entry.usageExampleTranslation ?? '';
                    _selectedLanguage = entry.language;
                    _selectedPOS = entry.partOfSpeech;

                    _showAddEntrySheet(initialLanguage: entry.language);
                    // Note: We might want to update the existing entry instead of adding a new one,
                    // but for now this is the simplest "revision" flow.
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(
                    'REVISE ENTRY',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 10,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showBulkUploadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bulk Upload Utility',
                style: AppTypography.h2ExtraBold.copyWith(
                  color: AppColors.gold500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload multiple dictionary entries at once using a CSV or JSON file.',
                style: AppTypography.body.copyWith(color: AppColors.creamText3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white24,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.upload_file_rounded,
                      color: AppColors.gold500,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a file to upload',
                      style: AppTypography.body.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              BrandButton(
                text: 'DOWNLOAD TEMPLATE',
                type: BrandButtonType.secondary,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template download started.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBatchRecordingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch Recording Mode',
                style: AppTypography.h2ExtraBold.copyWith(
                  color: AppColors.gold500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quickly record voice fragments for multiple words in sequence.',
                style: AppTypography.body.copyWith(color: AppColors.creamText3),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: 5, // Mock data
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.forest900,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Word ${index + 1}',
                                  style: AppTypography.h3.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Translation for Word ${index + 1}',
                                  style: AppTypography.body.copyWith(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.mic_rounded,
                              color: AppColors.semanticRed,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Recording started...'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}




