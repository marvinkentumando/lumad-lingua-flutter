import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.forest800,
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text(
            "Please login to view notifications.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final notificationsAsync = ref.watch(
      userNotificationsStreamProvider(user.uid),
    );

    return Scaffold(
      backgroundColor: AppColors.forest800,
      appBar: AppBar(title: const Text('Global Alerts')),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold500),
        ),
        error: (err, stack) => Center(
          child: Text(
            "Error: $err",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("ðŸ””", style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    "No alerts yet.",
                    style: AppTypography.h3.copyWith(color: Colors.white54),
                  ),
                  Text(
                    "We'll notify you of your achievements!",
                    style: AppTypography.label.copyWith(color: Colors.white30),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final bool isRead = notification['isRead'] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    if (!isRead) {
                      ref
                          .read(firebaseServiceProvider)
                          .markNotificationAsRead(user.uid, notification['id']);
                    }
                  },
                  child: BrandCard(
                    theme: isRead
                        ? BrandCardTheme.vibrant
                        : BrandCardTheme.cream,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(
                              notification['type'],
                            ).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _getNotificationEmoji(notification['type']),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['title'] ?? 'Alert',
                                style: isRead
                                    ? AppTypography.h3.copyWith(
                                        color: Colors.white70,
                                      )
                                    : AppTypography.h3,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['message'] ?? '',
                                style: isRead
                                    ? AppTypography.body.copyWith(
                                        color: Colors.white54,
                                      )
                                    : AppTypography.body,
                              ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: AppColors.gold500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'validation':
      case 'approval':
        return AppColors.semanticGreen;
      case 'streak':
        return AppColors.gold500;
      case 'achievement':
        return AppColors.semanticBlue;
      default:
        return Colors.white54;
    }
  }

  String _getNotificationEmoji(String? type) {
    switch (type) {
      case 'validation':
      case 'approval':
        return '🌟';
      case 'streak':
        return '🔥';
      case 'achievement':
        return 'ðŸ†';
      default:
        return 'ðŸ””';
    }
  }
}


