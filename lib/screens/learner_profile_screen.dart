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
import '../providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_storage_service.dart';
import '../widgets/daily_check_in_board.dart';
import '../widgets/level_up_modal.dart';
import '../widgets/skeleton.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/brand_background.dart';
import '../widgets/artifacts/artifact_inventory_section.dart';
import '../providers/theme_provider.dart';

class LearnerProfileScreen extends ConsumerWidget {
  const LearnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentXp = ref.watch(xpProvider);
    final currentRole = ref.watch(roleProvider);
    final profile = ref.watch(userProfileProvider).value;

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
                    _buildAvatarSection(context, ref, user, currentRole, profile),
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
                    ),
                    const SizedBox(height: 40),
                    if (currentRole == UserRole.learner && 
                        profile?['role']?.toString().toLowerCase() != 'admin' && 
                        profile?['role']?.toString().toLowerCase() != 'educator')
                      const ArtifactInventorySection(),
                    const SizedBox(height: 40),
                    _buildJourneyManagement(
                      context,
                      ref,
                      currentRole,
                      user,
                      profile,
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

  String _getRoleBadge(UserRole role, Map<String, dynamic>? profile, WidgetRef ref) {
    final location = profile?['location'] ?? 'PHILIPPINES';
    switch (role) {
      case UserRole.admin:
        return 'SYSTEM OVERSEER  \u2022  $location';
      case UserRole.staff:
        return 'RESEARCHER STAFF  \u2022  $location';
      case UserRole.educator:
        return 'WISDOM GUIDE  \u2022  $location';
      case UserRole.learner:
        final student = ref.watch(studentProvider);
        return '${student.levelTitle.toUpperCase()}  \u2022  $location';
    }
  }

  Widget _buildAvatarSection(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    UserRole role,
    Map<String, dynamic>? profile,
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
                      onTap: () => _pickAndUploadImage(context, ref, user?.uid),
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
          user?.displayName ?? profile?['username'] ?? 'Tribe Member',
          style: AppTypography.h1ExtraBold.copyWith(
            color: isDark ? AppColors.gold500 : AppColors.forest500,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getRoleBadge(role, profile, ref),
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
    Map<String, dynamic>? profile,
  ) {
    if (role == UserRole.learner) {
      final student = ref.watch(studentProvider);
      final streak = student.displayedStreak;
      final words = ref.watch(masteredWordsCountProvider(userId)).value ?? 0;
      return _ProfileStatsRow(xp: xp, streak: streak, words: words);
    }
    return _StaffStatsRow(role: role, userId: userId, xp: xp);
  }

  Widget _buildJourneyManagement(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    dynamic user,
    Map<String, dynamic>? profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journey Management',
          style: AppTypography.h3.copyWith(
            color: AppColors.gold500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildManagementTile(
          context,
          Icons.settings_suggest_rounded,
          'Edit Profile',
          'Update your location and bio',
          onTap: () => _showEditProfileDialog(
            context,
            ref,
            userId: user?.uid ?? '',
            profile: profile,
          ),
        ),
        const SizedBox(height: 12),
        if (profile?['role']?.toString().toLowerCase() != 'admin') ...[
          _buildManagementTile(
            context,
            Icons.trending_up_rounded,
            'Wisdom Progression',
            'View requirements for your next rank and titles',
            onTap: () => context.push('/wisdom-progression'),
          ),
          const SizedBox(height: 12),
          _buildManagementTile(
            context,
            Icons.notifications_active_rounded,
            'Notification Sanctuary',
            'Manage alerts for daily goals and community messages',
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 12),
        ],
        _buildManagementTile(
          context,
          Icons.security_rounded,
          'Data & Privacy',
          'Export your contributions or manage account security',
          onTap: () => context.push('/privacy-settings'),
        ),
        const SizedBox(height: 12),
        _buildManagementTile(
          context,
          Icons.cloud_download_rounded,
          'Offline Wisdom',
          'Manage cached lessons and audio files for offline use',
          onTap: () => context.push('/offline-wisdom'),
        ),
        const SizedBox(height: 12),
        _buildManagementTile(
          context,
          Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          Theme.of(context).brightness == Brightness.dark
              ? 'Light Sanctuary'
              : 'Dark Forest',
          'Switch between light and dark themes',
          onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        const SizedBox(height: 12),
        if (role == UserRole.learner) ...[
          if (profile?['educatorId'] == null) ...[
            _buildManagementTile(
              context,
              Icons.fort_rounded,
              'Join a Village',
              'Enter a code to connect with your local educator',
              onTap: () => _showJoinVillageDialog(context, ref, user?.uid ?? ''),
            ),
            const SizedBox(height: 12),
          ],
          _buildManagementTile(
            context,
            Icons.forum_rounded,
            'Send Feedback',
            'Message your educators about your journey',
            onTap: () => _showFeedbackDialog(context, ref, profile),
          ),
          const SizedBox(height: 12),
        ],
        if (profile?['role']?.toString().toLowerCase() == 'admin') ...[
          _buildManagementTile(
            context,
            ref.watch(isSimulatingProvider) 
                ? Icons.admin_panel_settings_rounded 
                : Icons.supervised_user_circle_rounded,
            ref.watch(isSimulatingProvider) 
                ? 'Exit Simulation' 
                : 'Simulation Mode',
            ref.watch(isSimulatingProvider)
                ? 'Return to Admin Overview'
                : 'Switch to Learner view to test content',
            onTap: () => ref.read(isSimulatingProvider.notifier).state = !ref.read(isSimulatingProvider),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 40),
        _buildLogOut(context, ref),
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
    return BrandCard(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title...')),
        );
      },
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
    );
  }

  Widget _buildProfileSkeleton() {
    return const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SizedBox(height: 40),
            Skeleton(width: 140, height: 140, isCircle: true),
            SizedBox(height: 24),
            Skeleton(width: 200, height: 32),
            SizedBox(height: 8),
            Skeleton(width: 150, height: 16),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Skeleton(width: 100, height: 100, borderRadius: 50),
                Skeleton(width: 100, height: 100, borderRadius: 50),
                Skeleton(width: 100, height: 100, borderRadius: 50),
              ],
            ),
            SizedBox(height: 40),
            Skeleton(height: 160, borderRadius: 24),
            SizedBox(height: 40),
            Skeleton(height: 80, borderRadius: 35),
            SizedBox(height: 12),
            Skeleton(height: 80, borderRadius: 35),
          ],
        ),
      ),
    );
  }

  Widget _buildLogOut(BuildContext context, WidgetRef ref) {
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
          'LOG  OUT',
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
              title: const Text('Choose Ancestral Totem', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'character'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.gold500),
              title: const Text('Upload New Picture', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'upload'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.semanticRed),
              title: const Text('Remove Picture', style: TextStyle(color: AppColors.semanticRed)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );

    if (action == 'character') {
      if (context.mounted) _showCharacterPicker(context, ref, userId);
      return;
    }

    if (action == 'remove') {
      try {
        await ref.read(firebaseServiceProvider).updateUserProfile(userId, {
          'photoURL': null,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture removed.'), backgroundColor: AppColors.semanticGreen),
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
            const SnackBar(content: Text('Uploading ancestral totem...')),
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
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: AppColors.semanticGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppColors.semanticRed,
            ),
          );
        }
      }
    }
  }

  void _showCharacterPicker(BuildContext context, WidgetRef ref, String userId) {
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
              'Choose Your Ancestral Totem',
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
                            SnackBar(content: Text('Failed to update: $e')),
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

  void _showJoinVillageDialog(BuildContext context, WidgetRef ref, String userId) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.forest900.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Icon(Icons.fort_rounded, color: AppColors.gold500, size: 48),
              const SizedBox(height: 16),
              Text(
                'Join a community village',
                style: AppTypography.h2.copyWith(color: AppColors.gold500),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-character code provided by your educator to join their community.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: AppTypography.displayBold.copyWith(color: Colors.white, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: 'CODE',
                  hintStyle: const TextStyle(color: Colors.white10),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
                      onPressed: () async {
                        if (controller.text.length < 6) return;
                        try {
                          await ref.read(firebaseServiceProvider).joinVillage(userId, controller.text);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Welcome to the village! 🌿'),
                                backgroundColor: AppColors.semanticGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.semanticRed),
                            );
                          }
                        }
                      },
                      child: const Text('JOIN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    Map<String, dynamic>? profile,
  }) {
    final nameController = TextEditingController(
      text: profile?['username'] ?? '',
    );
    final locationController = TextEditingController(
      text: profile?['location'] ?? '',
    );
    final bioController = TextEditingController(text: profile?['bio'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
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
                  'Edit Sacred Profile',
                  style: AppTypography.h2.copyWith(color: AppColors.gold500),
                ),
                const SizedBox(height: 24),
                _buildEditField('Tribe Name', nameController),
                const SizedBox(height: 16),
                _buildEditField(
                  'Location (e.g. Pantukan, DDO)',
                  locationController,
                  enabled: true,
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  'Statement/Bio',
                  bioController,
                  maxLines: 3,
                  hint: 'Teaching philosophy or heritage goals...',
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
                        onPressed: () async {
                          try {
                            await ref.read(firebaseServiceProvider).updateUserProfile(userId, {
                              'username': nameController.text,
                              'location': locationController.text,
                              'bio': bioController.text,
                            });
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e')),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'SAVE',
                          style: TextStyle(
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
    );
  }

  void _showFeedbackDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? profile,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forestDarkCard,
        title: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Have a question or suggestion? Message your educators directly.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: AppColors.forest800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final user = ref.read(authStateProvider).value;
              if (user != null) {
                await ref.read(firebaseServiceProvider).submitStudentFeedback(
                      studentId: user.uid,
                      studentName: profile?['username'] ?? 'Tribe Member',
                      studentPhotoUrl: profile?['photoURL'],
                      message: controller.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feedback sent to educators!'),
                      backgroundColor: AppColors.semanticGreen,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold500,
              foregroundColor: AppColors.forest900,
            ),
            child: const Text('SEND'),
          ),
        ],
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
}

// \u2500\u2500\u2500 Animated Stats Row \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

class _ProfileStatsRow extends ConsumerStatefulWidget {

  final int xp;
  final int streak;
  final int words;
  const _ProfileStatsRow({required this.xp, required this.streak, required this.words});

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
            'DAY STREAK',
            isInt: true,
          ),
        ),
        _buildCountCircle(
          context,
          Icons.menu_book_rounded,
          _wordsAnim,
          'WORDS',
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
                'TOTAL XP',
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

  const _StaffStatsRow({
    required this.role,
    required this.userId,
    required this.xp,
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
            'VITALITY',
            'MONITOR',
          )
        else if (role == UserRole.educator)
          _buildMetricCircle(
            context,
            Icons.people_rounded,
            studentCount.toString(),
            'STUDENTS',
          ),

        impactAsync.when(
          data: (impact) => _buildMetricCircle(
            context,
            Icons.star_rounded,
            (impact['accuracy'] * 5).toStringAsFixed(1),
            'ACCURACY',
          ),
          loading: () => _buildMetricCircle(context, Icons.star_rounded, '...', 'RATING'),
          error: (_, __) => _buildMetricCircle(context, Icons.star_rounded, 'N/A', 'RATING'),
        ),

        _buildMetricCircle(
          context,
          Icons.workspace_premium_rounded,
          _getStaffRank(xp),
          'RANK',
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  String _getStaffRank(int xp) {
    if (xp < 500) return 'NOVICE';
    if (xp < 2000) return 'GUARDIAN';
    if (xp < 5000) return 'ELDER';
    return 'ELITE';
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

