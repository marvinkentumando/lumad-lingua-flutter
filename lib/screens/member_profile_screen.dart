import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/auth_service.dart';
import '../providers/role_provider.dart';
import '../widgets/brand_card.dart';
import '../models/artifact.dart';
import '../providers/artifact_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/skeleton.dart';
import 'package:go_router/go_router.dart';

final validatorActivityCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(firebaseServiceProvider).getValidatorActivityCount(userId);
});

class MemberProfileScreen extends ConsumerWidget {
  final String userId;

  const MemberProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(otherUserProfileProvider(userId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gold500),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'TRIBE MEMBER',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold500),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          final roleString = profile['role']?.toString().toLowerCase();
          final role = _parseRole(roleString);
          final xp = profile['xp'] as int? ?? 0;
          final streak = profile['streak'] as int? ?? 0;
          final wordsLearned = profile['wordCount'] as int? ?? 0;
          final displayName =
              profile['username'] ?? profile['displayName'] ?? 'Tribe Member';
          final photoUrl = profile['photoURL'];

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatarSection(
                    context,
                    displayName,
                    role,
                    photoUrl,
                    profile,
                  ),
                  if (profile['bio'] != null &&
                      (profile['bio'] as String).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        profile['bio'],
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : AppColors.creamText2,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  _buildStatsRow(context, ref, role, userId, xp, streak, wordsLearned),
                  const SizedBox(height: 40),
                  if (role == UserRole.learner)
                    _buildArtifactsSection(context, ref, userId)
                  else
                    _buildContributionImpact(context, ref, userId, role),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  UserRole _parseRole(String? roleString) {
    switch (roleString) {
      case 'admin':
        return UserRole.admin;
      case 'validator':
        return UserRole.validator;
      case 'contributor':
        return UserRole.contributor;
      case 'educator':
        return UserRole.educator;
      default:
        return UserRole.learner;
    }
  }

  String _getRoleBadge(UserRole role, Map<String, dynamic> profile) {
    final location = profile['location'] ?? 'PHILIPPINES';
    switch (role) {
      case UserRole.admin:
        return 'SYSTEM OVERSEER  •  $location';
      case UserRole.validator:
        return 'ELDER VALIDATOR  •  $location';
      case UserRole.educator:
        return 'WISDOM GUIDE  •  $location';
      case UserRole.contributor:
        return 'CULTURAL KEEPER  •  $location';
      case UserRole.learner:
        return 'ELDER PATHFINDER  •  $location';
    }
  }

  Widget _buildAvatarSection(
    BuildContext context,
    String name,
    UserRole role,
    String? photoUrl,
    Map<String, dynamic> profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.gold500,
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 70,
            backgroundColor: Colors.black,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person_rounded, size: 80, color: Colors.white)
                : null,
          ),
        ).animate().scale(
          begin: const Offset(0.8, 0.8),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        ),
        const SizedBox(height: 24),
        Text(
          name,
          style: AppTypography.h1ExtraBold.copyWith(
            color: isDark ? AppColors.gold500 : AppColors.forest500,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getRoleBadge(role, profile),
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.white38 : AppColors.creamText3,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    String userId,
    int xp,
    int streak,
    int wordsLearned,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricCircle(context, Icons.flash_on, xp.toString(), 'TOTAL XP'),
        _buildMetricCircle(
          context,
          Icons.local_fire_department_rounded,
          streak.toString(),
          'STREAK',
        ),
        _buildMetricCircle(context, Icons.menu_book_rounded, wordsLearned.toString(), 'WORDS'),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildMetricCircle(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BrandCard(
      padding: EdgeInsets.zero,
      borderRadius: 100,
      child: Container(
        width: 100,
        height: 100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDark ? AppColors.gold500 : AppColors.forest500,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.h1ExtraBold.copyWith(
                color: isDark ? Colors.white : AppColors.forest700,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white24 : AppColors.creamText3,
                fontSize: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionImpact(BuildContext context, WidgetRef ref, String userId, UserRole role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activityAsync = ref.watch(validatorActivityCountProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contribution Impact',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.gold500 : AppColors.forest500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        activityAsync.when(
          data: (count) {
            final accuracy = count > 10 ? '98%' : (count > 0 ? '95%' : 'N/A');
            final rank = count > 50 ? 'Top 5%' : (count > 10 ? 'Top 20%' : 'New');
            final spirit = count > 100 ? 'Master' : (count > 20 ? 'Elder' : 'Seeker');
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildImpactCard(context, '⭐', 'Accuracy', accuracy),
                _buildImpactCard(context, '🤝', 'Community', rank),
                _buildImpactCard(context, '🌿', 'Spirit', spirit),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildImpactCard(
    BuildContext context,
    String emoji,
    String label,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BrandCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.h3.copyWith(
                color: isDark ? AppColors.gold500 : AppColors.forest700,
                fontSize: 18,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white24 : AppColors.creamText3,
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtifactsSection(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final artifactsAsync = ref.watch(otherUserArtifactsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earned Artifacts',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.gold500 : AppColors.forest500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        artifactsAsync.when(
          data: (artifacts) {
            final earned = artifacts.where((a) => a.isEarned).toList();
            if (earned.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No artifacts discovered yet...',
                    style: AppTypography.body.copyWith(color: Colors.white24),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: earned.length > 3 ? 3 : earned.length,
                separatorBuilder: (context, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _buildArtifactCard(context, earned[index]);
                },
              ),
            );
          },
          loading: () => const Center(
            child: Skeleton(height: 160, borderRadius: 24),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error loading artifacts',
              style: TextStyle(color: AppColors.semanticRed),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildArtifactCard(BuildContext context, Artifact artifact) {
    final isEarned = artifact.isEarned;
    final tierColor = _getTierColor(artifact.tier);

    return GestureDetector(
      onTap: () => context.push('/artifact-detail', extra: artifact),
      child: Hero(
        tag: 'artifact_${artifact.id}',
        child: BrandCard(
          theme: isEarned ? BrandCardTheme.cream : BrandCardTheme.vibrant,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      borderRadius: 24,
      child: SizedBox(
        width: 110,
        child: Column(
          children: [
            // Emoji/Image badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? tierColor.withValues(alpha: 0.1)
                    : Colors.black26,
                border: Border.all(
                  color: isEarned
                      ? tierColor.withValues(alpha: 0.5)
                      : Colors.white10,
                  width: 2,
                ),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: tierColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Opacity(
                opacity: isEarned ? 1.0 : 0.3,
                child: artifact.imageUrl.isNotEmpty
                    ? Image.asset(artifact.imageUrl, fit: BoxFit.contain)
                    : Text(
                        artifact.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              artifact.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                color: isEarned ? Colors.black : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (!isEarned) ...[
              // Progress Bar for in-progress artifacts
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: artifact.progress,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tierColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${artifact.currentProgress}/${artifact.targetValue}',
                style: AppTypography.label.copyWith(
                  fontSize: 8,
                  color: Colors.white24,
                ),
              ),
            ] else
              Text(
                artifact.tier.name.toUpperCase(),
                style: AppTypography.label.copyWith(
                  fontSize: 8,
                  color: Colors.black54,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Color _getTierColor(ArtifactTier tier) {
    switch (tier) {
      case ArtifactTier.ancient:
        return AppColors.gold500;
      case ArtifactTier.sacred:
        return Colors.purpleAccent;
      case ArtifactTier.legendary:
        return Colors.orangeAccent;
      case ArtifactTier.epic:
        return Colors.deepPurpleAccent;
      case ArtifactTier.rare:
        return Colors.blueAccent;
      case ArtifactTier.common:
        return Colors.greenAccent;
    }
  }
}
