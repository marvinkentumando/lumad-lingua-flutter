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

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest800 : AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Sanctuary Echoes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.forest900),
          onPressed: () => context.pop(),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => _limit == 20
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold500))
            : _buildUnifiedList(notificationsAsync.value ?? []),
        error: (err, stack) => Center(
          child: Text(
            "Error loading echoes: $err",
            style: TextStyle(color: isDark ? Colors.white : AppColors.semanticRed),
          ),
        ),
        data: (notifications) => _buildUnifiedList(notifications),
      ),
    );
  }

  Widget _buildUnifiedList(List<Map<String, dynamic>> notifications) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (notifications.isEmpty) {
      return _buildEmptyState("🌿", "The village is quiet.", "Your tribal journey's updates will appear here.");
    }

    final currentUser = ref.read(authStateProvider).value;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: notifications.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.gold500, strokeWidth: 2)),
          );
        }

        final n = notifications[index];
        final type = n['type'] as String?;
        final isRead = n['isRead'] ?? false;
        final timestamp = n['timestamp'];
        
        // Social fields
        final senderId = n['senderId'] as String?;
        final senderName = n['senderName'] as String? ?? 'Tribe Member';
        final senderPhotoUrl = n['senderPhotoUrl'] as String?;
        
        // System fields
        final title = n['title'] ?? 'Echo';
        final message = n['message'] ?? '';

        final bool isSocial = type == 'cheer' || type == 'like' || type == 'comment';

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
          child: GestureDetector(
            onTap: () {
              if (!isRead && currentUser != null) {
                ref.read(firebaseServiceProvider).markNotificationAsRead(currentUser.uid, n['id']);
              }
              if (isSocial && senderId != null) {
                context.push('/member/$senderId');
              }
            },
            child: BrandCard(
              theme: isRead ? BrandCardTheme.vibrant : BrandCardTheme.cream,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar or Icon based on notification type
                  if (isSocial)
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
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(type).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _getNotificationEmoji(type),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSocial)
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
                          )
                        else ...[
                          Text(
                            title,
                            style: isRead
                                ? AppTypography.h3.copyWith(
                                    color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.6),
                                    fontSize: 15,
                                  )
                                : AppTypography.h3.copyWith(
                                    color: isDark ? Colors.white : AppColors.forest900,
                                    fontSize: 15,
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: isRead
                                ? AppTypography.body.copyWith(
                                    color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
                                    fontSize: 13,
                                  )
                                : AppTypography.body.copyWith(
                                    color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                          ),
                        ],
                        const SizedBox(height: 6),
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
                  if (isSocial)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Text(_getNotificationEmoji(type), style: const TextStyle(fontSize: 18)),
                    ),
                  if (!isRead)
                    const Padding(
                      padding: EdgeInsets.only(top: 12, left: 8),
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
