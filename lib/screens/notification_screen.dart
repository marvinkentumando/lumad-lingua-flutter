import 'package:flutter/material.dart';
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
      paginatedNotificationsProvider(NotificationQuery(user.uid, _limit)),
    );
    final echoesAsync = ref.watch(communityFeedProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.forest800,
        appBar: AppBar(
          title: const Text('Sanctuary Alerts'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold500,
            labelColor: AppColors.gold500,
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(text: 'ALERTS', icon: Icon(Icons.notifications_none_rounded)),
              Tab(text: 'ECHOES', icon: Icon(Icons.forum_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Alerts Tab
            notificationsAsync.when(
              loading: () => _limit == 20
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold500))
                  : _buildNotificationList(notificationsAsync.value ?? []),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
              data: (notifications) => _buildNotificationList(notifications),
            ),
            // Echoes Tab
            echoesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
              data: (echoes) => _buildEchoesList(echoes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> notifications) {
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
                          style: isRead ? AppTypography.h3.copyWith(color: Colors.white70) : AppTypography.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['message'] ?? '',
                          style: isRead ? AppTypography.body.copyWith(color: Colors.white54) : AppTypography.body,
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

  Widget _buildEchoesList(List<dynamic> echoes) {
    if (echoes.isEmpty) {
      return _buildEmptyState("🍃", "The village is quiet.", "Recent community activities will appear here.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: echoes.length,
      itemBuilder: (context, index) {
        final echo = echoes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BrandCard(
            onTap: () => context.push('/member/${echo.userId}'),
            theme: BrandCardTheme.vibrant,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.forest700,
                  backgroundImage: echo.userPhotoUrl != null
                      ? (echo.userPhotoUrl.startsWith('http')
                          ? NetworkImage(echo.userPhotoUrl) as ImageProvider
                          : AssetImage(echo.userPhotoUrl))
                      : null,
                  child: echo.userPhotoUrl == null
                      ? Text(echo.userName.isNotEmpty ? echo.userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white24, fontSize: 14))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 13),
                          children: [
                            TextSpan(
                              text: echo.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(text: echo.message),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        echo.relativeTime,
                        style: AppTypography.label.copyWith(color: Colors.white24, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(echo.emoji, style: const TextStyle(fontSize: 22)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String emoji, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.h3.copyWith(color: Colors.white54)),
          Text(sub, style: AppTypography.label.copyWith(color: Colors.white30)),
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
      default:
        return '🔔';
    }
  }
}
