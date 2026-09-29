import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/user_preferences_provider.dart';
import '../providers/student_provider.dart';
import '../services/notification_service.dart';
import '../services/haptic_service.dart';

class StreakReminderSettingsDialog extends ConsumerWidget {
  const StreakReminderSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final prefsNotifier = ref.read(userPreferencesProvider.notifier);
    final student = ref.watch(studentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hour = prefs.streakReminderHour;
    final minute = prefs.streakReminderMinute;
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    final now = DateTime.now();
    final timeFormatted = DateFormat.jm().format(
      DateTime(now.year, now.month, now.day, hour, minute),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forest900 : AppColors.creamBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.gold500.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.gold500,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Streak Reminders',
                        style: AppTypography.h3.copyWith(
                          color: isDark ? Colors.white : AppColors.forest900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Never lose your daily learning flame',
                        style: AppTypography.body.copyWith(
                          color: isDark ? Colors.white60 : AppColors.forest700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Toggle Switch Tile
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.creamBorder,
                ),
              ),
              child: SwitchListTile(
                activeThumbColor: AppColors.gold500,
                title: Text(
                  'Streak Reminders',
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  prefs.streakRemindersEnabled
                      ? 'Enabled - Daily notifications active'
                      : 'Disabled - Reminders paused',
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white54 : AppColors.forest700,
                    fontSize: 11,
                  ),
                ),
                value: prefs.streakRemindersEnabled,
                onChanged: (enabled) async {
                  HapticService.toggle();
                  await prefsNotifier.setStreakRemindersEnabled(enabled);

                  // Update schedule
                  await NotificationService().updateStreakReminderSchedule(
                    enabled: enabled,
                    hour: hour,
                    minute: minute,
                    isCompletedToday: student.displayedStreak > 0,
                  );
                },
              ),
            ),

            if (prefs.streakRemindersEnabled) ...[
              const SizedBox(height: 16),

              // Time Selection Tile
              InkWell(
                onTap: () async {
                  HapticService.light();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: timeOfDay,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.gold500,
                            onPrimary: Colors.black,
                            surface: AppColors.forest900,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    await prefsNotifier.setStreakReminderTime(
                      picked.hour,
                      picked.minute,
                    );

                    await NotificationService().updateStreakReminderSchedule(
                      enabled: true,
                      hour: picked.hour,
                      minute: picked.minute,
                      isCompletedToday: student.displayedStreak > 0,
                    );

                    HapticService.success();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Streak reminder time set to $timeFormatted'),
                          backgroundColor: AppColors.forest700,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.gold500,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder Time',
                              style: AppTypography.body.copyWith(
                                color: isDark ? Colors.white70 : AppColors.forest700,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              timeFormatted,
                              style: AppTypography.h3.copyWith(
                                color: AppColors.gold500,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_calendar_rounded,
                        color: AppColors.gold500,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Test Notification Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold500,
                    side: const BorderSide(color: AppColors.gold500),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    HapticService.medium();
                    await NotificationService().showInstantStreakWarning(
                      title: '🔥 Daily Streak Reminder Test',
                      body: 'Your reminder is active! Daily practice keeps your flame alive.',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test streak notification sent!'),
                          backgroundColor: AppColors.forest700,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                  label: Text(
                    'TEST REMINDER NOTIFICATION',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold500,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'SAVE & CLOSE',
                  style: AppTypography.label.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
  }
}

/// Helper function to show streak reminder settings dialog
void showStreakReminderSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const StreakReminderSettingsDialog(),
  );
}
