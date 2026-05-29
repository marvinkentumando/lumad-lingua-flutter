import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../models/validator_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../widgets/wotd_widget.dart';
import '../services/firebase_service.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/preview_audio_player.dart';
import '../widgets/impact_card.dart';
import '../services/impact_service.dart';
import '../services/haptic_service.dart';

class ValidatorHomeScreen extends ConsumerStatefulWidget {
  const ValidatorHomeScreen({super.key});

  @override
  ConsumerState<ValidatorHomeScreen> createState() =>
      _ValidatorHomeScreenState();
}

class _ValidatorHomeScreenState extends ConsumerState<ValidatorHomeScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  final Set<String> _skippedItemIds = {};

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    final displayName = profile?['username'] ?? 'Elder Validator';
    final currentRank = profile?['rank'] ?? 'Guardian';
    final userDialect = profile?['indigenousGroup'];

    // Ensure providers use a non-null dialect for counts
    final activeDialect = userDialect ?? 'Mansaka';

    // Live Metrics
    final pendingEntries =
        ref.watch(pendingWordsCountProvider(activeDialect)).value ?? 0;
    final pendingVoices =
        ref.watch(pendingVoiceSubmissionsCountProvider(activeDialect)).value ?? 0;
    final pendingLessons =
        ref.watch(pendingLessonsCountProvider(activeDialect)).value ?? 0;

    final uid = profile?['uid'] ?? profile?['id'] ?? '';
    final impactAsync = ref.watch(roleImpactProvider(uid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientTopoBackground(
        child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _skippedItemIds.clear();
            });
            ref.invalidate(urgentQueueProvider(activeDialect));
            ref.invalidate(pendingWordsCountProvider(activeDialect));
            ref.invalidate(pendingVoiceSubmissionsCountProvider(activeDialect));
            ref.invalidate(pendingLessonsCountProvider);
            ref.invalidate(roleImpactProvider(uid));
          },
          color: AppColors.gold500,
          backgroundColor: isDark ? AppColors.forest800 : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(displayName, currentRank),
                const SizedBox(height: 24),
                const WotdWidget(),
                const SizedBox(height: 32),
                _buildVerificationOverview(
                  entries: pendingEntries,
                  voices: pendingVoices,
                  lessons: pendingLessons,
                ),
                const SizedBox(height: 32),
                
                impactAsync.when(
                  data: (impact) => ImpactCard(impact: impact),
                  loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.gold500))),
                  error: (e, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),
                Text(
                  'URGENT QUEUE',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                ref
                    .watch(urgentQueueProvider(activeDialect))
                    .when(
                      data: (items) {
                        final filteredItems = items
                            .where((item) => !_skippedItemIds.contains(item.id))
                            .toList();

                        if (filteredItems.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: isDark
                                        ? AppColors.forest700
                                        : AppColors.forest200,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "All caught up!",
                                    style: AppTypography.body.copyWith(
                                      color: isDark
                                          ? AppColors.forest700
                                          : AppColors.forest300,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => context.push('/validator/entries?history=true'),
                                        icon: const Icon(Icons.history_rounded, size: 18),
                                        label: const Text("Check History"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.gold500,
                                          side: const BorderSide(color: AppColors.gold500),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      TextButton(
                                        onPressed: () => context.push('/validator/entries'),
                                        child: Text(
                                          "Browse All",
                                          style: TextStyle(
                                            color: isDark ? Colors.white70 : AppColors.forest500,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: filteredItems
                              .map((item) => _buildUrgentCard(item))
                              .toList(),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gold500,
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error: $err',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.semanticRed,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildUrgentCard(ValidationItem item) {
    IconData itemIcon;
    Color iconColor;
    String route;

    switch (item.type) {
      case 'voice':
        itemIcon = Icons.record_voice_over_rounded;
        iconColor = AppColors.semanticBlue;
        route = '/validator/voices';
        break;
      case 'entry':
        itemIcon = Icons.list_alt_rounded;
        iconColor = AppColors.semanticGreen;
        route = '/validator/entries';
        break;
      case 'lesson':
      default:
        itemIcon = Icons.menu_book_rounded;
        iconColor = AppColors.terracotta;
        route = '/validator/lessons';
    }

    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forest800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.terracotta.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(itemIcon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.priority.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            color: AppColors.terracotta,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.dialect,
                          style: AppTypography.label.copyWith(
                            color: AppColors.creamText3,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: AppTypography.h3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.forest500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: AppTypography.body.copyWith(
                      color: AppColors.creamText3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (item.audioUrl != null && item.audioUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: PreviewAudioPlayer(
                  audioUrl: item.audioUrl!,
                  size: 32,
                  color: AppColors.gold500,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                HapticService.medium();
                setState(() {
                  _skippedItemIds.add(item.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Item snoozed for this session"),
                    action: SnackBarAction(
                      label: "UNDO",
                      onPressed: () {
                        setState(() {
                          _skippedItemIds.remove(item.id);
                        });
                      },
                    ),
                    backgroundColor: AppColors.forest800,
                  ),
                );
              },
              icon: const Icon(Icons.snooze_rounded, color: Colors.white24, size: 20),
              tooltip: 'Snooze',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              splashRadius: 24,
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }
}



