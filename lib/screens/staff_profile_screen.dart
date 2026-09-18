import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import '../providers/learning_provider.dart';
import '../widgets/brand_card.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import '../providers/role_provider.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_storage_service.dart';
import '../widgets/daily_check_in_board.dart';
import '../widgets/level_up_modal.dart';
import '../widgets/brand_background.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/skeleton.dart';
import '../services/haptic_service.dart';
import '../widgets/artifacts/artifact_inventory_section.dart';
import '../providers/theme_provider.dart';
import '../utils/app_localization.dart';
import '../providers/user_preferences_provider.dart';

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentXp = ref.watch(xpProvider);
    final currentRole = ref.watch(roleProvider);
    final profile = ref.watch(userProfileProvider).value;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: authState.when(
          loading: () => _buildProfileSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (user) {
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildAvatarSection(context, ref, user, currentRole, profile, l10n),
                    if (profile?['bio'] != null &&
                        (profile?['bio'] as String).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          profile!['bio'],
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
                    _buildStatsRow(
                      context,
                      ref,
                      currentRole,
                      user?.uid ?? '',
                      currentXp,
                      profile,
                      l10n,
                    ),
                    const SizedBox(height: 40),
                    if (currentRole != UserRole.admin && currentRole != UserRole.educator) ...[
                      const ArtifactInventorySection(),
                      const SizedBox(height: 40),
                    ],
                    _buildJourneyManagement(
                      context,
                      ref,
                      currentRole,
                      user,
                      profile,
                      l10n,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getRoleBadge(UserRole role, Map<String, dynamic>? profile, AppLocalization l10n) {
    final location = profile?['location'] ?? l10n.translate('philippines');
    switch (role) {
      case UserRole.admin:
        return '${l10n.translate('system_overseer')}  \u2022  $location';
      case UserRole.staff:
        return '${l10n.translate('researcher_staff')}  \u2022  $location';
      case UserRole.educator:
        return '${l10n.translate('wisdom_guide')}  \u2022  $location';
      case UserRole.learner:
        return '${l10n.translate('elder_pathfinder')}  \u2022  $location';
    }
  }

  Widget _buildAvatarSection(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    UserRole role,
    Map<String, dynamic>? profile,
    AppLocalization l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Diamond glow effect
            Transform.rotate(
              angle: 45 * 3.14 / 180,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.gold500,
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  ProfileAvatar(
                    radius: 70,
                    photoUrl: profile?['photoURL'] ?? user?.photoURL,
                    iconSize: 80,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadImage(context, ref, user?.uid, l10n),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.gold500,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate().scale(
          begin: const Offset(0.8, 0.8),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        ),
        const SizedBox(height: 24),
        Text(
          user?.displayName ?? profile?['username'] ?? l10n.translate('tribe_member'),
          style: AppTypography.h1ExtraBold.copyWith(
            color: isDark ? AppColors.gold500 : AppColors.forest500,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getRoleBadge(role, profile, l10n),
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.white38 : AppColors.creamText3,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        if (role == UserRole.educator) ...[
          const SizedBox(height: 16),
          if (profile?['villageCode'] != null)
            GestureDetector(
              onTap: () {
                final code = profile?['villageCode'] as String;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.translate('village_code_label')} $code')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fort_rounded, size: 14, color: AppColors.gold500),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.translate('village_code_label')} ${profile?['villageCode']}',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildSetupVillageButton(context, ref, user?.uid, l10n),
        ],
      ],
    );
  }

  Widget _buildSetupVillageButton(BuildContext context, WidgetRef ref, String? userId, AppLocalization l10n) {
    return GestureDetector(
      onTap: () async {
        if (userId == null) return;
        HapticService.medium();
        try {
          final code = await ref.read(firebaseServiceProvider).generateUniqueVillageCode();
          await ref.read(firebaseServiceProvider).updateUserProfile(userId, {'villageCode': code});
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.translate('village_activated')),
                backgroundColor: AppColors.semanticGreen,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.translate('activation_failed')} $e'), backgroundColor: AppColors.semanticRed),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.semanticGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.semanticGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_home_rounded, size: 14, color: AppColors.semanticGreen),
            const SizedBox(width: 8),
            Text(
              l10n.translate('activate_village'),
              style: AppTypography.label.copyWith(
                color: AppColors.semanticGreen,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    String userId,
    int xp,
    Map<String, dynamic>? profile,
    AppLocalization l10n,
  ) {
    if (role == UserRole.learner) {
      final streak = profile?['streak'] as int? ?? 0;
      final words = profile?['wordCount'] as int? ?? 0;
      return _ProfileStatsRow(xp: xp, streak: streak, words: words, l10n: l10n);
    }
    return _StaffStatsRow(role: role, userId: userId, xp: xp, l10n: l10n);
  }

  Widget _buildJourneyManagement(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    dynamic user,
    Map<String, dynamic>? profile,
    AppLocalization l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('journey_management'),
          style: AppTypography.h3.copyWith(
            color: AppColors.gold500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildManagementTile(
          context,
          Icons.settings_suggest_rounded,
          l10n.translate('edit_profile'),
          l10n.translate('update_location_bio'),
          onTap: () => _showEditProfileDialog(
            context,
            ref,
            userId: user?.uid ?? '',
            profile: profile,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: 12),
        _buildManagementTile(
          context,
          Icons.translate_rounded,
          'App Language',
          ref.watch(userPreferencesProvider).appLanguage.toUpperCase(),
          onTap: () => _showLanguageSelector(context, ref, l10n),
        ),
        const SizedBox(height: 12),
        if (profile?['role']?.toString().toLowerCase() != 'admin') ...[
          _buildManagementTile(
            context,
            Icons.trending_up_rounded,
            l10n.translate('wisdom_progression'),
            l10n.translate('wisdom_requirements'),
            onTap: () => context.push('/wisdom-progression'),
          ),
          const SizedBox(height: 12),
          _buildManagementTile(
            context,
            Icons.notifications_active_rounded,
            l10n.translate('notification_sanctuary'),
            l10n.translate('notification_desc'),
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 12),
        ],
        _buildManagementTile(
          context,
          Icons.security_rounded,
          l10n.translate('data_privacy'),
          l10n.translate('data_privacy_desc'),
          onTap: () => context.push('/privacy-settings'),
        ),
        const SizedBox(height: 12),
        _buildManagementTile(
          context,
          Icons.cloud_download_rounded,
          l10n.translate('offline_wisdom'),
          l10n.translate('offline_wisdom_desc'),
          onTap: () => context.push('/offline-wisdom'),
        ),
        const SizedBox(height: 12),
        _buildManagementTile(
          context,
          Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          Theme.of(context).brightness == Brightness.dark
              ? l10n.translate('light_sanctuary')
              : l10n.translate('dark_forest'),
          l10n.translate('switch_themes'),
          onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        const SizedBox(height: 12),
        if (role == UserRole.admin) ...[
          _buildManagementTile(
            context,
            Icons.supervised_user_circle_rounded,
            l10n.translate('simulation_mode'),
            l10n.translate('test_content_desc'),
            onTap: () => ref.read(isSimulatingProvider.notifier).state = true,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 40),
        _buildLogOut(context, ref, l10n),
        const SizedBox(height: 40),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildManagementTile(
    BuildContext context,
    IconData icon,
    String title,
    String sub, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Opening $title...')));
          },
      child: BrandCard(
        theme: BrandCardTheme.gold,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        borderRadius: 35,
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    sub,
                    style: AppTypography.body.copyWith(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSkeleton() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Skeleton(width: 140, height: 140, isCircle: true),
            const SizedBox(height: 24),
            const Skeleton(width: 200, height: 32),
            const SizedBox(height: 8),
            const Skeleton(width: 150, height: 16),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Skeleton(width: 100, height: 100, borderRadius: 50),
                Skeleton(width: 100, height: 100, borderRadius: 50),
                Skeleton(width: 100, height: 100, borderRadius: 50),
              ],
            ),
            const SizedBox(height: 40),
            Skeleton(height: 160, borderRadius: 24),
            const SizedBox(height: 40),
            Skeleton(height: 80, borderRadius: 35),
            const SizedBox(height: 12),
            Skeleton(height: 80, borderRadius: 35),
          ],
        ),
      ),
    );
  }

  Widget _buildLogOut(BuildContext context, WidgetRef ref, AppLocalization l10n) {
    return Center(
      child: TextButton(
        onPressed: () async {
          // Sign out from Firebase
          await ref.read(authServiceProvider).signOut();

          // Navigate back to login
          if (context.mounted) {
            context.go('/login');
          }
        },
        child: Text(
          l10n.translate('log_out'),
          style: AppTypography.label.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.gold500
                : AppColors.forest500,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ).animate().fadeIn(delay: 800.ms),
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    String? userId,
    AppLocalization l10n,
  ) async {
    if (userId == null) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.forest900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.face_retouching_natural_rounded, color: AppColors.gold500),
              title: Text(l10n.translate('choose_totem'), style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'character'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.gold500),
              title: Text(l10n.translate('upload_picture'), style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'upload'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.semanticRed),
              title: Text(l10n.translate('remove_picture'), style: const TextStyle(color: AppColors.semanticRed)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );

    if (action == 'character') {
      if (context.mounted) _showCharacterPicker(context, ref, userId, l10n);
      return;
    }

    if (action == 'remove') {
      try {
        await ref.read(firebaseServiceProvider).updateUserProfile(userId, {
          'photoURL': null,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('pic_removed')), backgroundColor: AppColors.semanticGreen),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.semanticRed),
          );
        }
      }
      return;
    }

    if (action != 'upload') return;

    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('uploading_totem'))),
          );
        }

        final url = await ref
            .read(supabaseStorageServiceProvider)
            .uploadImage(file, 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.read(firebaseServiceProvider).updateUserProfile(userId, {
          'photoURL': url,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('pic_updated')),
              backgroundColor: AppColors.semanticGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${l10n.translate('upload_failed')} $e"),
              backgroundColor: AppColors.semanticRed,
            ),
          );
        }
      }
    }
  }

  void _showCharacterPicker(BuildContext context, WidgetRef ref, String userId, AppLocalization l10n) {
    final characters = [
      'assets/images/lumad_character.png',
      'assets/images/lumad_character (1).png',
      'assets/images/lumad_character (2).png',
      'assets/images/lumad_character (3).png',
      'assets/images/lumad_character (4).png',
      'assets/images/lumad_character (5).png',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('choose_your_totem'),
              style: AppTypography.h3.copyWith(color: AppColors.gold500),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 280,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      try {
                        final url = characters[index];
                        // 1. Update Firestore
                        await ref.read(firebaseServiceProvider).updateUserProfile(userId, {
                          'photoURL': url,
                        });
                        
                        // 2. Update Firebase Auth Profile for sync
                        final user = ref.read(authServiceProvider).currentUser;
                        if (user != null) {
                          await user.updatePhotoURL(url);
                        }

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${l10n.translate('failed_update')} $e")),
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          characters[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref, AppLocalization l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(l10n.translate('select_language'), style: AppTypography.h3.copyWith(color: AppColors.gold500)),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.translate('english'), style: const TextStyle(color: Colors.white)),
              trailing: ref.watch(userPreferencesProvider).appLanguage == 'en' ? const Icon(Icons.check, color: AppColors.gold500) : null,
              onTap: () {
                ref.read(userPreferencesProvider.notifier).setAppLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.translate('filipino'), style: const TextStyle(color: Colors.white)),
              trailing: ref.watch(userPreferencesProvider).appLanguage == 'tl' ? const Icon(Icons.check, color: AppColors.gold500) : null,
              onTap: () {
                ref.read(userPreferencesProvider.notifier).setAppLanguage('tl');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.translate('bisaya'), style: const TextStyle(color: Colors.white)),
              trailing: ref.watch(userPreferencesProvider).appLanguage == 'bis' ? const Icon(Icons.check, color: AppColors.gold500) : null,
              onTap: () {
                ref.read(userPreferencesProvider.notifier).setAppLanguage('bis');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    Map<String, dynamic>? profile,
    required AppLocalization l10n,
  }) {
    final nameController = TextEditingController(
      text: profile?['username'] ?? '',
    );
    final bioController = TextEditingController(text: profile?['bio'] ?? '');

    final Map<String, List<String>> regionData = {
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

    String? selectedProvince;
    String? selectedMunicipality;

    final currentLocation = profile?['location'] as String?;
    if (currentLocation != null && currentLocation.contains(', ')) {
      final parts = currentLocation.split(', ');
      if (parts.length == 2) {
        final prov = parts[1].trim();
        final muni = parts[0].trim();
        if (regionData.containsKey(prov)) {
          selectedProvince = prov;
          if (regionData[prov]!.contains(muni)) {
            selectedMunicipality = muni;
          }
        }
      }
    }

    final role = ref.read(roleProvider);
    final isLocationLocked = role == UserRole.staff;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.forest900.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Text(
                    l10n.translate('edit_sacred_profile'),
                    style: AppTypography.h2.copyWith(color: AppColors.gold500),
                  ),
                  const SizedBox(height: 24),
                  _buildEditField(l10n.translate('tribe_name'), nameController),
                  const SizedBox(height: 16),
                  
                  if (isLocationLocked)
                    _buildEditField(
                      l10n.translate('location'),
                      TextEditingController(text: currentLocation),
                      enabled: false,
                      hint: l10n.translate('location_locked'),
                    )
                  else ...[
                    // Province Dropdown
                    _buildLabel(l10n.translate('province'), true),
                    _buildDropdown(
                      context,
                      value: selectedProvince,
                      hint: l10n.translate('select_province'),
                      items: regionData.keys.toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedProvince = val;
                          selectedMunicipality = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Municipality Dropdown
                    _buildLabel(l10n.translate('municipality'), true),
                    _buildDropdown(
                      context,
                      value: selectedMunicipality,
                      hint: l10n.translate('select_municipality'),
                      items: selectedProvince != null ? regionData[selectedProvince]! : [],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedMunicipality = val;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  _buildEditField(
                    l10n.translate('bio'),
                    bioController,
                    maxLines: 3,
                    hint: l10n.translate('bio_hint'),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.translate('close').toUpperCase(), style: const TextStyle(color: Colors.white38)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
                          onPressed: () async {
                            try {
                              final updates = {
                                'username': nameController.text,
                                'bio': bioController.text,
                              };
                              if (!isLocationLocked && selectedProvince != null && selectedMunicipality != null) {
                                updates['location'] = "$selectedMunicipality, $selectedProvince";
                              }

                              await ref.read(firebaseServiceProvider).updateUserProfile(userId, updates);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Update failed: $e')),
                                );
                              }
                            }
                          },
                          child: Text(
                            l10n.translate('save'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: enabled ? AppColors.gold500 : Colors.white24,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          style: TextStyle(color: enabled ? Colors.white : Colors.white38),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.black.withValues(alpha: enabled ? 0.2 : 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool enabled) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: enabled ? AppColors.gold500 : Colors.white24,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
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
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// \u2500\u2500\u2500 Animated Stats Row \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

class _ProfileStatsRow extends ConsumerStatefulWidget {

  final int xp;
  final int streak;
  final int words;
  final AppLocalization l10n;
  const _ProfileStatsRow({required this.xp, required this.streak, required this.words, required this.l10n});

  @override
  ConsumerState<_ProfileStatsRow> createState() => _ProfileStatsRowState();
}

class _ProfileStatsRowState extends ConsumerState<_ProfileStatsRow>
    with TickerProviderStateMixin {

  late final AnimationController _xpController;
  late final AnimationController _streakController;
  late final AnimationController _wordsController;
  late final Animation<double> _xpAnim;
  late final Animation<double> _streakAnim;
  late final Animation<double> _wordsAnim;

  @override
  void initState() {
    super.initState();

    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _wordsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _xpAnim = Tween<double>(
      begin: 0,
      end: widget.xp.toDouble(),
    ).animate(CurvedAnimation(parent: _xpController, curve: Curves.easeOut));
    _streakAnim = Tween<double>(begin: 0, end: widget.streak.toDouble())
        .animate(
          CurvedAnimation(parent: _streakController, curve: Curves.easeOut),
        );
    _wordsAnim = Tween<double>(
      begin: 0,
      end: widget.words.toDouble(),
    ).animate(CurvedAnimation(parent: _wordsController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _xpController.forward();
        _streakController.forward();
        _wordsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _xpController.dispose();
    _streakController.dispose();
    _wordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider).value;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            if (config == null) return;
            final level = (widget.xp / config.xpPerLevel).floor() + 1;

            // Determine rank title based on thresholds
            String rankTitle = 'Novice';
            final sortedThresholds = config.spiritThresholds.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            for (var entry in sortedThresholds) {
              if (widget.xp >= entry.value) {
                rankTitle = entry.key;
                break;
              }
            }

            showLevelUpModal(context, ref, level, rankTitle);
          },
          child: _buildXpCircle(context),
        ),
        GestureDetector(
          onTap: () => showDailyCheckInBoard(context, widget.streak),
          child: _buildCountCircle(
            context,
            Icons.local_fire_department_rounded,
            _streakAnim,
            widget.l10n.translate('day_streak'),
            isInt: true,
          ),
        ),
        _buildCountCircle(
          context,
          Icons.menu_book_rounded,
          _wordsAnim,
          widget.l10n.translate('words'),
          isInt: true,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildXpCircle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _xpController,
      builder: (context, _) {
        final xpVal = _xpAnim.value;
        final display = xpVal >= 1000
            ? '${(xpVal / 1000).toStringAsFixed(1)}k'
            : xpVal.toInt().toString();
        return Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flash_on,
                color: isDark ? AppColors.gold500 : AppColors.forest500,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                display,
                style: AppTypography.h1ExtraBold.copyWith(
                  color: isDark ? Colors.white : AppColors.forest700,
                  fontSize: 22,
                ),
              ),
              Text(
                widget.l10n.translate('total_xp'),
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white24 : AppColors.creamText3,
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountCircle(
    BuildContext context,
    IconData icon,
    Animation<double> anim,
    String label, {
    bool isInt = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final display = isInt
            ? anim.value.toInt().toString()
            : anim.value.toStringAsFixed(1);
        return Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isDark ? AppColors.gold500 : AppColors.forest500,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                display,
                style: AppTypography.h1ExtraBold.copyWith(
                  color: isDark ? Colors.white : AppColors.forest700,
                  fontSize: 22,
                ),
              ),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white24 : AppColors.creamText3,
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StaffStatsRow extends ConsumerWidget {
  final UserRole role;
  final String userId;
  final int xp;
  final AppLocalization l10n;

  const _StaffStatsRow({
    required this.role,
    required this.userId,
    required this.xp,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch stats based on role
    final studentCount = role == UserRole.educator
        ? ref.watch(totalUsersCountProvider).value ?? 0
        : 0;

    final impactAsync = ref.watch(userImpactMetricsProvider(userId));

    if (role == UserRole.admin) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (role == UserRole.staff)
          _buildMetricCircle(
            context,
            Icons.insights_rounded,
            l10n.translate('vitality'),
            l10n.translate('monitor'),
          )
        else if (role == UserRole.educator)
          _buildMetricCircle(
            context,
            Icons.people_rounded,
            studentCount.toString(),
            l10n.translate('students'),
          ),

        impactAsync.when(
          data: (impact) => _buildMetricCircle(
            context,
            Icons.star_rounded,
            (impact['accuracy'] * 5).toStringAsFixed(1),
            l10n.translate('accuracy'),
          ),
          loading: () => _buildMetricCircle(context, Icons.star_rounded, '...', l10n.translate('rating')),
          error: (_, __) => _buildMetricCircle(context, Icons.star_rounded, l10n.translate('na'), l10n.translate('rating')),
        ),

        _buildMetricCircle(
          context,
          Icons.workspace_premium_rounded,
          _getStaffRank(xp),
          l10n.translate('rank'),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  String _getStaffRank(int xp) {
    if (xp < 500) return l10n.translate('novice');
    if (xp < 2000) return l10n.translate('guardian');
    if (xp < 5000) return l10n.translate('elder');
    return l10n.translate('elite');
  }

  Widget _buildMetricCircle(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isDark ? AppColors.gold500 : AppColors.forest500,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.h1ExtraBold.copyWith(
              color: isDark ? Colors.white : AppColors.forest700,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white24 : AppColors.creamText3,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
