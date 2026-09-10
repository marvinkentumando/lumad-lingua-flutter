import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  int _limit = 20;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _markAllRead();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore) {
        setState(() {
          _isFetchingMore = true;
          _limit += 20;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _isFetchingMore = false);
          }
        });
      }
    }
  }

  void _markAllRead() {
    Future.microtask(() {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(firebaseServiceProvider).markAllNotificationsAsRead(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.forest800 : AppColors.creamBg,
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            "Please login to view notifications.",
            style: TextStyle(color: isDark ? Colors.white : AppColors.forest900),
          ),
        ),
      );
    }

    final notificationsAsync = ref.watch(
      paginatedNotificationsProvider(NotificationQuery(user.uid, _limit)),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.forest800 : AppColors.creamBg,
        appBar: AppBar(
          title: const Text('Sanctuary Alerts'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.gold500,
            labelColor: AppColors.gold500,
            unselectedLabelColor: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4),
            tabs: const [
              Tab(text: 'ALERTS', icon: Icon(Icons.notifications_none_rounded)),
              Tab(text: 'ECHOES', icon: Icon(Icons.forum_rounded)),
            ],
          ),
        ),
        body: notificationsAsync.when(
          loading: () => _limit == 20
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold500))
              : _buildTabViews(notificationsAsync.value ?? []),
          error: (err, stack) => Center(
            child: Text(
              "Error: $err",
              style: TextStyle(color: isDark ? Colors.white : AppColors.semanticRed),
            ),
          ),
          data: (notifications) => _buildTabViews(notifications),
        ),
      ),
    );
  }

  Widget _buildTabViews(List<Map<String, dynamic>> allNotifications) {
    final alerts = allNotifications.where((n) {
      final type = n['type'] as String?;
      return type != 'cheer' && type != 'like' && type != 'comment';
    }).toList();

    final echoes = allNotifications.where((n) {
      final type = n['type'] as String?;
      return type == 'cheer' || type == 'like' || type == 'comment';
    }).toList();

    return TabBarView(
      children: [
        _buildNotificationList(alerts),
        _buildEchoesList(echoes),
      ],
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> notifications) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (notifications.isEmpty) {
      return _buildEmptyState("🔔", "No alerts yet.", "We'll notify you of your achievements!");
    }

    final user = ref.read(authStateProvider).value;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: notifications.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.gold500, strokeWidth: 2)),
          );
        }

        final notification = notifications[index];
        final bool isRead = notification['isRead'] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              if (!isRead && user != null) {
                ref.read(firebaseServiceProvider).markNotificationAsRead(user.uid, notification['id']);
              }
            },
            child: BrandCard(
              theme: isRead ? BrandCardTheme.vibrant : BrandCardTheme.cream,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification['type']).withValues(alpha: 0.1),
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
                                  color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.6),
                                )
                              : AppTypography.h3.copyWith(
                                  color: isDark ? Colors.white : AppColors.forest900,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['message'] ?? '',
                          style: isRead
                              ? AppTypography.body.copyWith(
                                  color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
                                )
                              : AppTypography.body.copyWith(
                                  color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: CircleAvatar(radius: 4, backgroundColor: AppColors.gold500),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEchoesList(List<Map<String, dynamic>> echoes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (echoes.isEmpty) {
      return _buildEmptyState(
        "🍃",
        "The village is quiet.",
        "Social interactions from your tribe will appear here.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: echoes.length,
      itemBuilder: (context, index) {
        final notification = echoes[index];
        final senderId = notification['senderId'] as String?;
        final senderName = notification['senderName'] as String? ?? 'Tribe Member';
        final senderPhotoUrl = notification['senderPhotoUrl'] as String?;
        final message = notification['message'] as String? ?? '';
        final type = notification['type'] as String?;
        final timestamp = notification['timestamp'];
        final String relativeTime;

        if (timestamp is Timestamp) {
          final diff = DateTime.now().difference(timestamp.toDate());
          if (diff.inSeconds < 60) {
            relativeTime = 'just now';
          } else if (diff.inMinutes < 60) {
            relativeTime = '${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            relativeTime = '${diff.inHours}h ago';
          } else {
            relativeTime = '${diff.inDays}d ago';
          }
        } else {
          relativeTime = 'recently';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BrandCard(
            onTap: senderId != null ? () => context.push('/member/$senderId') : null,
            theme: BrandCardTheme.vibrant,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? AppColors.forest700 : AppColors.forest100,
                  backgroundImage: senderPhotoUrl != null
                      ? (senderPhotoUrl.startsWith('http')
                          ? NetworkImage(senderPhotoUrl) as ImageProvider
                          : AssetImage(senderPhotoUrl))
                      : null,
                  child: senderPhotoUrl == null
                      ? Text(
                          senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body.copyWith(
                            color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.forest900,
                              ),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(text: message),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relativeTime.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(_getNotificationEmoji(type), style: const TextStyle(fontSize: 22)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String emoji, String title, String sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
            ),
          ),
          Text(
            sub,
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white30 : AppColors.forest900.withValues(alpha: 0.3),
            ),
          ),
        ],
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
      case 'cheer':
      case 'like':
        return AppColors.gold500;
      case 'comment':
        return AppColors.semanticBlue;
      case 'rejection':
      case 'flagged':
        return AppColors.semanticRed;
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
        return '🏆';
      case 'cheer':
        return '✨';
      case 'like':
        return '💖';
      case 'comment':
        return '💬';
      case 'rejection':
        return '❌';
      case 'flagged':
        return '🚩';
      case 'broadcast':
        return '📢';
      default:
        return '🔔';
    }
  }
}
