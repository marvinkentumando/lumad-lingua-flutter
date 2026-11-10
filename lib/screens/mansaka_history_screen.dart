import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_button.dart';
import '../services/haptic_service.dart';
import '../providers/student_provider.dart';
import '../widgets/spirit_particle_overlay.dart';
import '../utils/app_localization.dart';

class MansakaHistoryScreen extends ConsumerStatefulWidget {
  const MansakaHistoryScreen({super.key});

  @override
  ConsumerState<MansakaHistoryScreen> createState() => _MansakaHistoryScreenState();
}

class _MansakaHistoryScreenState extends ConsumerState<MansakaHistoryScreen> {
  final Set<String> _exploredSections = {};
  bool _quizPassed = false;
  final ScrollController _scrollController = ScrollController();

  void _exploreSection(String sectionKey, String sectionTitle) {
    HapticService.selection();
    if (!_exploredSections.contains(sectionKey)) {
      setState(() {
        _exploredSections.add(sectionKey);
      });
      ref.read(studentProvider.notifier).addXp(15);

      if (_exploredSections.length >= 5) {
        HapticService.celebration();
        showSpiritParticles(context, duration: const Duration(seconds: 3));
        ref.read(studentProvider.notifier).addXp(100);
        ref.read(studentProvider.notifier).addMistCrystals(50);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Mastered Mansaka History! +100 XP & +50 Mist Crystals earned!'),
            backgroundColor: AppColors.semanticGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Explored "$sectionTitle"! +15 XP earned ⭐'),
            backgroundColor: AppColors.gold500,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _playAudioSimulation(String title, String description) {
    HapticService.light();
    bool isPlaying = true;
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            return AlertDialog(
              backgroundColor: isDark ? AppColors.forest900 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.gold500, width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.volume_up_rounded, color: AppColors.gold500, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Audio Archive: $title',
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlaying ? 'Playing authentic Mansaka pronunciation...' : 'Paused audio archive',
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              isPlaying = !isPlaying;
                            });
                            HapticService.light();
                          },
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            color: AppColors.gold500,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.gold500,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: isPlaying ? null : 0.4,
                                backgroundColor: AppColors.gold500.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold500),
                                minHeight: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CLOSE', style: TextStyle(color: AppColors.gold500, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTableOfContentsModal(bool isDark) {
    HapticService.light();
    final chapters = [
      {'key': 'Origins', 'title': 'Tribal Origin & Homeland', 'icon': '🏔️'},
      {'key': 'Dagmay', 'title': 'Sacred Arts & Weaving', 'icon': '🧵'},
      {'key': 'Governance', 'title': 'Governance & Customator Law', 'icon': '⚖️'},
      {'key': 'Spirituality', 'title': 'Spirituality & Oral Traditions', 'icon': '🌿'},
      {'key': 'Language', 'title': 'Language & Digital Revitalization', 'icon': '📜'},
      {'key': 'Sources', 'title': 'Research Sources & References', 'icon': '📚'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forest800 : AppColors.creamBg,
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
                    'Table of Contents',
                    style: AppTypography.h2.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...chapters.map((ch) {
                final isExplored = _exploredSections.contains(ch['key']);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(ch['icon']!, style: const TextStyle(fontSize: 20)),
                  title: Text(
                    ch['title']!,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  trailing: isExplored
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.semanticGreen, size: 18)
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gold500),
                  onTap: () {
                    Navigator.of(modalContext).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showHeritageQuizModal() {
    HapticService.light();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        int currentQuestion = 0;
        int score = 0;

        final questions = [
          {
            'question': 'What is the sacred hand-woven abaca textile of the Mansaka called?',
            'options': ['Dagmay', 'Malong', 'Inabel', 'T\'nalak'],
            'answer': 0,
          },
          {
            'question': 'What is the council of respected elders and tribal leaders called in Mansaka custom?',
            'options': ['Datu', 'Matikadong', 'Panglima', 'Sultan'],
            'answer': 1,
          },
          {
            'question': 'Where is the traditional ancestral domain of the Mansaka primarily centered?',
            'options': ['Luzon highlands', 'Davao de Oro / Upriver tributaries', 'Sulu archipelago', 'Batanes islands'],
            'answer': 1,
          },
        ];

        return StatefulBuilder(
          builder: (context, setStateQuiz) {
            final q = questions[currentQuestion];
            final options = q['options'] as List<String>;

            return AlertDialog(
              backgroundColor: isDark ? AppColors.forest900 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.gold500, width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.quiz_rounded, color: AppColors.gold500, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Heritage Quiz (${currentQuestion + 1}/${questions.length})',
                    style: AppTypography.h3.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q['question'] as String,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(options.length, (optIdx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticService.selection();
                            final correct = optIdx == q['answer'];
                            if (correct) score++;
                            if (currentQuestion < questions.length - 1) {
                              setStateQuiz(() {
                                currentQuestion++;
                              });
                            } else {
                              Navigator.of(ctx).pop();
                              _finishHeritageQuiz(score, questions.length);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : AppColors.forest900,
                            side: BorderSide(color: AppColors.gold500.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            alignment: Alignment.centerLeft,
                          ),
                          child: Text(options[optIdx], style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _finishHeritageQuiz(int score, int total) {
    final passed = score >= 2;
    if (passed) {
      setState(() {
        _quizPassed = true;
      });
      ref.read(studentProvider.notifier).addXp(50);
      ref.read(studentProvider.notifier).addMistCrystals(25);
      HapticService.celebration();
      showSpiritParticles(context, duration: const Duration(seconds: 3));
    } else {
      HapticService.error();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          passed
              ? 'Quiz passed ($score/$total)! Earned +50 XP & +25 Mist Crystals 💎🎉'
              : 'Score: $score/$total. Review the history archive and try again!',
        ),
        backgroundColor: passed ? AppColors.semanticGreen : AppColors.gold500,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }



  void _copyCitation(String citationText) {
    HapticService.light();
    Clipboard.setData(ClipboardData(text: citationText));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Citation copied to clipboard 📋'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.forest800,
      ),
    );
  }



  void _showGlossaryDialog(String term, String definition, String phonetic) {
    HapticService.light();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.forest900 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.gold500, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.gold500, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  term,
                  style: AppTypography.h2.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pronunciation: / $phonetic /',
                  style: const TextStyle(
                    color: AppColors.gold500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                definition,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: AppColors.gold500, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark, l10n),
              _buildReadingProgressBar(isDark),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGlossaryQuickAccess(isDark),
                      const SizedBox(height: 24),

                      // Section 1: Origins & Homeland
                      _buildSectionHeader('TRIBAL ORIGIN & HOMELAND 🏔️', 'Origins', isDark),
                      const SizedBox(height: 12),
                      _buildDetailedCard(
                        context,
                        sectionKey: 'Origins',
                        title: 'People of the Upriver',
                        subtitle: 'Etymology: "Man" (People) + "Saka" (To Ascend / Upriver)',
                        details: 'The term "Mansaka" derives from the native words "man" (people) and "saka" (to ascend or go upriver), translating literally to "the people who inhabit the mountain slopes and river headwaters."\n\n'
                            'Historically, the Mansaka established settlements throughout the province of Davao de Oro (formerly Compostela Valley), Davao del Norte (including Tagum, Pantukan, Maragusan, Mabini, Maco, Monkayo, and Nabunturan), and coastal-mountain corridors of Davao Oriental in Mindanao, Philippines.',
                        bulletPoints: [
                          'Geographical Heart: Major river channels including Agusan, Hijo, Kingking, and Matiao rivers.',
                          'Traditional Lifestyle: Riverine agriculture (rice, corn, tubers), forest hunting (pangaso), fishing, and artisanal gold panning.',
                          'Ecological Stewardship: Deep spiritual relationship with mountain ecosystems, river basins, and sacred forests.',
                        ],
                        imageAsset: 'assets/images/dagmay.png',
                        isDark: isDark,
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
                      const SizedBox(height: 20),

                      // Section 2: Dagmay & Sacred Arts
                      _buildSectionHeader('SACRED ARTS & WEAVING 🧵', 'Dagmay', isDark),
                      const SizedBox(height: 12),
                      _buildDetailedCard(
                        context,
                        sectionKey: 'Dagmay',
                        title: 'Dagmay Abaca Ikat Weaving & Gold Crafting',
                        subtitle: 'Handwoven sacred textiles, natural resist-dyeing, and pre-colonial gold mastery',
                        details: 'Dagmay is the sacred handwoven abaca cloth crafted exclusively by female master weavers using backstrap tension looms (ilongan). Fibers from native abaca (Musa textilis) are dyed using organic plant extracts, tree barks (kutu), and mineral-rich mud (tud-tud) through the intricate ikat resist-dyeing method.\n\n'
                            'In addition to textile weaving, historical Mansaka artisans (parag-bulawan) were celebrated across Mindanao as master goldsmiths who fashioned intricate gold breastplates (paratina), silver bangles (agmay), and brass betel nut boxes (kamagi).',
                        bulletPoints: [
                          'Sacred Motifs (Batek): Designs depicting python scales (maku), river meanders, forest flora, and sacred crocodiles (buaya).',
                          'Spiritual Guidance: Weavers receive complex geometric patterns through ancestral dreams (tagon-on).',
                          'Cultural Prestige: Wearing Dagmay signifies chieftainship, spiritual authority, and honor during sacred gatherings.',
                        ],
                        imageAsset: 'assets/images/artifact_weave.png',
                        isDark: isDark,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
                      const SizedBox(height: 20),

                      // Section 3: Governance & Customary Law
                      _buildSectionHeader('GOVERNANCE & CUSTOMARY LAW ⚖️', 'Governance', isDark),
                      const SizedBox(height: 12),
                      _buildDetailedCard(
                        context,
                        sectionKey: 'Governance',
                        title: 'Matikadong Council & Restorative Justice',
                        subtitle: 'Traditional governance guided by respected elders, Bagani warriors, and Customary Inggadan',
                        details: 'Mansaka society is governed by the Matikadong—a council of highly respected tribal elders and chieftains who uphold the unwritten customary laws known as Customary Inggadan (or Sukat).\n\n'
                            'Conflict resolution (Pagonongan) centers on mediation and restorative justice. Rather than punitive incarceration, disputes are resolved by securing communal restitution (pantaw or bayad) to restore harmony (Kadayawan) among clans.',
                        bulletPoints: [
                          'Matikadong: Elders who serve as judges, peacekeepers, and custodians of ancestral territory.',
                          'Bagani Warrior Guild: Traditional warrior class responsible for defending ancestral domains (Lumuton); identified by distinct red headcloths (pudong).',
                          'Customary Inggadan: Traditional jurisprudence governing land usage, marriage, inheritance, and inter-tribal peace treaties.',
                        ],
                        isDark: isDark,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
                      const SizedBox(height: 20),

                      // Section 4: Spirituality & Oral Literature
                      _buildSectionHeader('SPIRITUALITY & ORAL TRADITIONS 🌿', 'Spirituality', isDark),
                      const SizedBox(height: 12),
                      _buildDetailedCard(
                        context,
                        sectionKey: 'Spirituality',
                        title: 'Magbabaya, Balyan Shamans & Epic Chants',
                        subtitle: 'Cosmology, ancestral spirit reverence, and chant literature (Dawot)',
                        details: 'Mansaka spiritual life is centered on belief in Magbabaya (the Supreme Creator) and nature spirits (Diwata) who safeguard mountains, rivers, and crops. The Balyan (spiritual shaman) serves as healer, ritualist, and intermediary between humans and the spiritual realm.\n\n'
                            'The tribe preserves its history through rich oral literature, including epic poetry (Dawot), poetic riddles (Tutubang), and ancestral maxims (Awat) handed down orally through generations.',
                        bulletPoints: [
                          'Balyan: Shamanic healers who conduct diagnostic rituals, interpret visions, and invoke ancestral blessing.',
                          'Balilig Ritual: Major communal healing and thanksgiving ceremony featuring music on bamboo zithers (sludoy) and gongs (agung).',
                          'Dawot Epic Chants: Chanted epics detailing tribal origins, heroism, creation, and ecological wisdom.',
                        ],
                        isDark: isDark,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),
                      const SizedBox(height: 20),

                      // Section 5: Language & Revitalization
                      _buildSectionHeader('LANGUAGE & DIGITAL REVITALIZATION 📜', 'Language', isDark),
                      const SizedBox(height: 12),
                      _buildDetailedCard(
                        context,
                        sectionKey: 'Language',
                        title: 'Preserving the Mansaka Language',
                        subtitle: 'Austronesian linguistic roots, community preservation, and Lumad Lingua',
                        details: 'The Mansaka language belongs to the Central Philippine branch of the Austronesian family, categorized within the Mansakan sub-group alongside Mandaya, Kalagan, and Tagakaulo.\n\n'
                            'To safeguard this linguistic legacy against urban displacement, Lumad Lingua partners with tribal elders, educators (IPEd), and researchers to document vocabulary, pronunciation, and oral literature in a gamified, accessible digital archive.',
                        bulletPoints: [
                          'Linguistic Affinity: Close structural relationship with Mandaya and Kalagan dialects.',
                          'IPEd Integration: Supported by Indigenous Peoples Education programs in Davao Region schools.',
                          'Lumad Lingua Platform: Interactive audio dictionary, sentiment analysis, and gamified lesson paths.',
                        ],
                        isDark: isDark,
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),
                      const SizedBox(height: 20),

                      // Section 6: Research Sources & References
                      _buildSectionHeader('RESEARCH SOURCES & SCHOLARLY REFERENCES 📚', 'Sources', isDark),
                      const SizedBox(height: 12),
                      _buildSourcesCard(isDark),
                      const SizedBox(height: 20),

                      const SizedBox(height: 8),
                      _buildInteractiveCallout(context, isDark),
                      const SizedBox(height: 20),
                      _buildHeroCard(context, isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppLocalization l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticService.light();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.forest900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.gold500, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.translate('cultural_heritage_archive'),
                        style: TextStyle(
                          color: isDark ? AppColors.gold500 : AppColors.forest700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.translate('mansaka_history_title'),
                  style: AppTypography.h2.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _showTableOfContentsModal(isDark),
            icon: const Icon(Icons.list_alt_rounded, color: AppColors.gold500, size: 22),
            tooltip: 'Table of Contents',
          ),
        ],
      ),
    );
  }



  Widget _buildReadingProgressBar(bool isDark) {
    const totalChapters = 5;
    final exploredCount = _exploredSections.length.clamp(0, totalChapters);
    final progress = exploredCount / totalChapters;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Progress',
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white70 : AppColors.forest900,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$exploredCount / $totalChapters Chapters Explored',
                style: const TextStyle(
                  color: AppColors.gold500,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold500),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forest800, AppColors.forest900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.castle_rounded, color: AppColors.gold500, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The Sacred Heritage of Davao de Oro',
                  style: AppTypography.h2.copyWith(
                    color: isDark ? AppColors.gold500 : AppColors.forest900,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'The Mansaka are one of Southeastern Mindanao\'s major Lumad indigenous groups, renowned for their ancestral upriver settlements, sacred Dagmay abaca textiles, master goldsmithing, Matikadong elder councils, and rich oral chant traditions.',
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showHeritageQuizModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _quizPassed ? AppColors.semanticGreen.withValues(alpha: 0.2) : AppColors.gold500,
                foregroundColor: _quizPassed ? AppColors.semanticGreen : AppColors.forest900,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: _quizPassed ? const BorderSide(color: AppColors.semanticGreen, width: 1.5) : BorderSide.none,
                ),
              ),
              icon: Icon(
                _quizPassed ? Icons.check_circle_rounded : Icons.quiz_rounded,
                size: 18,
                color: _quizPassed ? AppColors.semanticGreen : AppColors.forest900,
              ),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _quizPassed ? 'Heritage Quiz Passed ✓' : 'Test Heritage Knowledge',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _quizPassed ? AppColors.semanticGreen : AppColors.forest900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _quizPassed ? 'Completed (Tap to Retake)' : '(+50 XP / +25 Gems)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: _quizPassed ? AppColors.semanticGreen.withValues(alpha: 0.8) : AppColors.forest900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossaryQuickAccess(bool isDark) {
    final terms = [
      {'term': 'Matikadong', 'phonetic': 'mah-tee-kah-DONG', 'def': 'Council of respected elders and chieftains who enforce customary laws and guide governance.'},
      {'term': 'Dagmay', 'phonetic': 'duhg-MAY', 'def': 'Sacred handwoven abaca textile produced through natural ikat resist-dyeing and ancestral motifs.'},
      {'term': 'Balyan', 'phonetic': 'bahl-YAHN', 'def': 'Spiritual shaman and healer who serves as intermediary between humans and nature deities (Diwata).'},
      {'term': 'Dawot', 'phonetic': 'dah-WOT', 'def': 'Sacred epic chants performed during gatherings to transmit ancestral history and folklore.'},
      {'term': 'Customary Inggadan', 'phonetic': 'ing-gah-DAN', 'def': 'Traditional customary law governing land usage, marriage, dispute settlement, and ethics.'},
      {'term': 'Magbabaya', 'phonetic': 'mahg-bah-bah-YAH', 'def': 'The Supreme Creator deity in traditional Mansaka cosmology.'},
    ];

    return BrandCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.gold500, size: 18),
              const SizedBox(width: 8),
              Text(
                'Key Cultural Terms',
                style: AppTypography.h3.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Tap term to view',
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: terms.map((item) {
              return InkWell(
                onTap: () => _showGlossaryDialog(item['term']!, item['def']!, item['phonetic']!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['term']!,
                        style: const TextStyle(
                          color: AppColors.gold500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.info_outline_rounded, color: AppColors.gold500, size: 12),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sectionKey, bool isDark) {
    final isExplored = _exploredSections.contains(sectionKey);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: isDark ? AppColors.gold500 : AppColors.forest800,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (isExplored) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.semanticGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.semanticGreen.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    '✓ Explored',
                    style: TextStyle(
                      color: AppColors.semanticGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

      ],
    );
  }

  void _showChapterReaderModal({
    required String sectionKey,
    required String title,
    required String subtitle,
    required String details,
    required List<String> bulletPoints,
    String? imageAsset,
    required bool isDark,
  }) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final modalIsDark = Theme.of(modalContext).brightness == Brightness.dark;
        final isExplored = _exploredSections.contains(sectionKey);

        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.82,
          decoration: BoxDecoration(
            color: modalIsDark ? AppColors.forest800 : AppColors.creamBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: AppColors.gold500, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Chapter Archive',
                          style: AppTypography.h3.copyWith(
                            color: modalIsDark ? Colors.white : AppColors.forest900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: AppColors.gold500, size: 20),
                          onPressed: () {
                            final shareText = '$title\n$subtitle\n\nVia LUMAD Lingua Cultural Archive';
                            SharePlus.instance.share(ShareParams(text: shareText));
                          },
                          tooltip: 'Share Chapter',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h2.copyWith(
                          color: modalIsDark ? Colors.white : AppColors.forest900,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.gold500,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        details,
                        style: AppTypography.body.copyWith(
                          color: modalIsDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      if (bulletPoints.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: modalIsDark ? Colors.white.withValues(alpha: 0.05) : AppColors.gold50,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: bulletPoints.map((pt) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(
                                        color: AppColors.gold500,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        pt,
                                        style: AppTypography.body.copyWith(
                                          color: modalIsDark ? Colors.white70 : Colors.black87,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      if (imageAsset != null) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            imageAsset,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _playAudioSimulation(title, subtitle),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.gold500,
                                side: BorderSide(color: AppColors.gold500.withValues(alpha: 0.6)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.volume_up_rounded, size: 18),
                              label: const Text('Listen Audio Archive', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isExplored
                                  ? null
                                  : () {
                                      _exploreSection(sectionKey, title);
                                      Navigator.of(modalContext).pop();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isExplored ? Colors.grey.withValues(alpha: 0.3) : AppColors.gold500,
                                foregroundColor: AppColors.forest900,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: Icon(isExplored ? Icons.check_circle_rounded : Icons.star_rounded, size: 18),
                              label: Text(
                                isExplored ? 'Chapter Explored (+15 XP)' : 'Mark Chapter Read (+15 XP)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isExplored ? (modalIsDark ? Colors.white60 : Colors.black54) : AppColors.forest900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedCard(
    BuildContext context, {
    required String sectionKey,
    required String title,
    required String subtitle,
    required String details,
    required List<String> bulletPoints,
    String? imageAsset,
    required bool isDark,
  }) {
    final isExplored = _exploredSections.contains(sectionKey);

    return BrandCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.gold500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: isDark ? AppColors.gold500 : AppColors.forest700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isExplored)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.semanticGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded, size: 12, color: AppColors.semanticGreen),
                      SizedBox(width: 4),
                      Text(
                        'Explored',
                        style: TextStyle(
                          color: AppColors.semanticGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⏱️ 3 min read',
                    style: TextStyle(
                      color: AppColors.gold500,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showChapterReaderModal(
                  sectionKey: sectionKey,
                  title: title,
                  subtitle: subtitle,
                  details: details,
                  bulletPoints: bulletPoints,
                  imageAsset: imageAsset,
                  isDark: isDark,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold500,
                  foregroundColor: AppColors.forest900,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 14),
                label: const Text(
                  'Read Chapter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesCard(bool isDark) {
    final sources = [
      {
        'category': 'GOVERNMENT & INSTITUTIONAL REPORTS',
        'title': 'Ancestral Domain Assessment of the Mansaka Cultural Community in Davao de Oro',
        'author': 'National Commission on Indigenous Peoples (NCIP)',
        'year': '2020',
        'pub': 'NCIP Regional Office XI, Davao City, Philippines.',
        'citation': 'National Commission on Indigenous Peoples. (2020). Ancestral Domain Assessment of the Mansaka Cultural Community in Davao de Oro. NCIP Region XI.',
      },
      {
        'category': 'GOVERNMENT & INSTITUTIONAL REPORTS',
        'title': 'Traditional Textiles and Weaving Arts of Mindanao: The Dagmay of Davao Region',
        'author': 'National Commission for Culture and the Arts (NCCA)',
        'year': '2018',
        'pub': 'NCCA Cultural Heritage Series, Manila.',
        'citation': 'National Commission for Culture and the Arts. (2018). Traditional Textiles and Weaving Arts of Mindanao: The Dagmay of Davao Region. NCCA Publications.',
      },
      {
        'category': 'SCHOLARLY MONOGRAPHS & ETHNOGRAPHIES',
        'title': 'Manuvu\' and Mansaka Ethnography: Social Organization and Customary Law',
        'author': 'Manuel, E. Arsenio',
        'year': '1973',
        'pub': 'Philippine Social Sciences Council (PSSC), Manila.',
        'citation': 'Manuel, E. A. (1973). Manuvu\' and Mansaka Ethnography: Social Organization and Customary Law. Philippine Social Sciences Council.',
      },
      {
        'category': 'SCHOLARLY MONOGRAPHS & ETHNOGRAPHIES',
        'title': 'The Wild Tribes of Davao District, Mindanao',
        'author': 'Cole, Fay-Cooper',
        'year': '1913',
        'pub': 'Field Museum of Natural History, Publication 170, Anthropological Series, Vol. XII, No. 2, Chicago.',
        'citation': 'Cole, F.-C. (1913). The Wild Tribes of Davao District, Mindanao. Field Museum of Natural History, Anthropological Series, XII(2).',
      },
      {
        'category': 'LINGUISTIC DOCUMENTATION',
        'title': 'Proto-Mansakan and Heritage Languages of Southeastern Mindanao',
        'author': 'Gallman, Andrew Franklin',
        'year': '1997',
        'pub': 'Linguistic Society of the Philippines, Monograph Series No. 42, Manila.',
        'citation': 'Gallman, A. F. (1997). Proto-Mansakan and Heritage Languages of Southeastern Mindanao. Linguistic Society of the Philippines.',
      },
      {
        'category': 'LINGUISTIC DOCUMENTATION',
        'title': 'Mansaka Grammar Outline and Vocabulary Archives',
        'author': 'Summer Institute of Linguistics (SIL) Philippines',
        'year': '1975',
        'pub': 'SIL International, Dallas, Texas.',
        'citation': 'Summer Institute of Linguistics. (1975). Mansaka Grammar Outline and Vocabulary Archives. SIL International.',
      },
      {
        'category': 'CULTURAL STUDIES & CUSTOMARY LAW',
        'title': 'The Indigenous Peoples of Mindanao: Cultural Heritage, Customary Laws, and Ancestral Domain Rights',
        'author': 'Magos, Alicia P.',
        'year': '1998',
        'pub': 'University of the Philippines Center for Integrative and Development Studies (UP CIDS), Quezon City.',
        'citation': 'Magos, A. P. (1998). The Indigenous Peoples of Mindanao: Cultural Heritage, Customary Laws, and Ancestral Domain Rights. UP CIDS.',
      },
    ];

    return BrandCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, color: AppColors.gold500, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Academic References & Sources',
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Below are the published ethnographies, government reports, and linguistic studies utilized to compile this cultural history archive:',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: sources.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.gold50.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold500.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['category']!,
                              style: const TextStyle(
                                color: AppColors.gold500,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _copyCitation(item['citation']!),
                          icon: const Icon(Icons.copy_rounded, color: AppColors.gold500, size: 14),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Copy APA Citation',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title']!,
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['author']} (${item['year']}). ${item['pub']}',
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCallout(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest800.withValues(alpha: 0.6) : AppColors.gold50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: AppColors.gold500, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Mansaka Artifacts & Language',
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Unlock sacred items in your Vault or practice Mansaka words in the dictionary.',
                      style: TextStyle(
                        color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BrandButton(
                  text: 'Ancestral Vault',
                  onTap: () {
                    HapticService.light();
                    context.push('/ancestral-vault-shop');
                  },
                  type: BrandButtonType.small,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BrandButton(
                  text: 'Mansaka Words',
                  onTap: () {
                    HapticService.light();
                    context.push('/dictionary');
                  },
                  type: BrandButtonType.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
