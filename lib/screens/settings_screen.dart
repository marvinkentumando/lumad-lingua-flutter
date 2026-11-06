import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../utils/app_localization.dart';
import '../providers/user_preferences_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/role_provider.dart';
import '../widgets/streak_reminder_settings_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = ref.watch(roleProvider);
    final isEducatorOrAdmin = role == UserRole.educator || role == UserRole.admin;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.gold500),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings & Preferences',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.gold500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    Text(
                      'APPEARANCE & LANGUAGE',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        letterSpacing: 1.5,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      Icons.translate_rounded,
                      'App Language',
                      ref.watch(userPreferencesProvider).appLanguage.toUpperCase(),
                      onTap: () => _showLanguageSelector(context, ref, l10n),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      isDark ? l10n.translate('light_sanctuary') : l10n.translate('dark_forest'),
                      l10n.translate('switch_themes'),
                      onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                        activeThumbColor: Colors.black,
                        activeTrackColor: Colors.black26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      Icons.music_note_rounded,
                      'Background Music',
                      'Play ambient forest music during lessons',
                      onTap: () => ref.read(userPreferencesProvider.notifier).setBackgroundMusicEnabled(!ref.read(userPreferencesProvider).backgroundMusicEnabled),
                      trailing: Switch(
                        value: ref.watch(userPreferencesProvider).backgroundMusicEnabled,
                        onChanged: (val) => ref.read(userPreferencesProvider.notifier).setBackgroundMusicEnabled(val),
                        activeThumbColor: Colors.black,
                        activeTrackColor: Colors.black26,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'REMINDERS & ALERTS',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        letterSpacing: 1.5,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      Icons.notifications_active_rounded,
                      l10n.translate('notification_sanctuary'),
                      l10n.translate('notification_desc'),
                      onTap: () => context.push('/notifications'),
                    ),
                    if (!isEducatorOrAdmin) ...[
                      const SizedBox(height: 12),
                      _buildTile(
                        context,
                        Icons.alarm_rounded,
                        'Daily Streak Reminders',
                        'Set daily practice alerts & schedule',
                        onTap: () => showStreakReminderSettingsDialog(context),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'DATA & PRIVACY',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        letterSpacing: 1.5,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      Icons.security_rounded,
                      l10n.translate('data_privacy'),
                      l10n.translate('data_privacy_desc'),
                      onTap: () => context.push('/privacy-settings'),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      Icons.cloud_download_rounded,
                      l10n.translate('offline_wisdom'),
                      l10n.translate('offline_wisdom_desc'),
                      onTap: () => context.push('/offline-wisdom'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    String sub, {
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return BrandCard(
      onTap: onTap,
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
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black54, size: 16),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref, AppLocalization l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select App Language / Dialect',
                style: AppTypography.h3.copyWith(
                  color: AppColors.gold500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _languageOption(context, ref, 'English', 'en'),
              _languageOption(context, ref, 'Filipino (Tagalog)', 'fil'),
              _languageOption(context, ref, 'Cebuano (Binisaya)', 'ceb'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(BuildContext context, WidgetRef ref, String label, String code) {
    final current = ref.watch(userPreferencesProvider).appLanguage;
    final isSelected = current == code;

    return ListTile(
      title: Text(label, style: AppTypography.body.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.gold500) : null,
      onTap: () {
        ref.read(userPreferencesProvider.notifier).setAppLanguage(code);
        context.pop();
      },
    );
  }
}
