import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_search_bar.dart';
import '../widgets/brand_text_field.dart';
import '../widgets/branded_empty_state.dart';
import '../services/haptic_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/warrior_friend.dart';
import '../providers/friend_provider.dart';
import '../utils/app_localization.dart';

class WarriorsCircleScreen extends ConsumerStatefulWidget {
  const WarriorsCircleScreen({super.key});

  @override
  ConsumerState<WarriorsCircleScreen> createState() =>
      _WarriorsCircleScreenState();
}

class _WarriorsCircleScreenState extends ConsumerState<WarriorsCircleScreen> {
  String _searchQuery = '';
  final Map<String, bool> _sendingRequestState = {};

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: BrandBackground(
          child: Center(
            child: Text(
              l10n.translate('please_login'),
              style: TextStyle(color: isDark ? Colors.white : AppColors.forest900),
            ),
          ),
        ),
      );
    }

    final friendsAsync = ref.watch(userFriendsProvider);
    final pendingRequestsAsync = ref.watch(pendingFriendRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    l10n.translate('warriors_circle'),
                    style: AppTypography.h3.copyWith(
                      color: isDark ? AppColors.gold500 : AppColors.gold700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: BrandSearchBar(
                  hintText: l10n.translate('search_members'),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: _searchQuery.trim().isNotEmpty
                    ? _buildSearchResultsView(user.uid, l10n, isDark)
                    : _buildDefaultFriendsView(
                        user.uid,
                        friendsAsync,
                        pendingRequestsAsync,
                        l10n,
                        isDark,
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteKinModal(context, user.uid, l10n),
        backgroundColor: AppColors.gold500,
        icon: const Icon(Icons.person_add_rounded, color: Colors.black),
        label: Text(
          l10n.translate('invite_kin'),
          style: AppTypography.label.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ).animate().scale(
            delay: 500.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildDefaultFriendsView(
    String userId,
    AsyncValue<List<WarriorFriend>> friendsAsync,
    AsyncValue<List<Map<String, dynamic>>> pendingRequestsAsync,
    AppLocalization l10n,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Pending Requests Section
          pendingRequestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('incoming_kin_requests'),
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...requests.map((req) => _buildPendingRequestCard(userId, req, l10n, isDark)),
                  const SizedBox(height: 20),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 2. Friends List Section
          friendsAsync.when(
            data: (friends) {
              if (friends.isEmpty) {
                return BrandedEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: l10n.translate('warriors_circle'),
                  message: l10n.translate('no_kin_yet'),
                  action: BrandButton(
                    text: l10n.translate('invite_kin'),
                    type: BrandButtonType.primary,
                    onTap: () => _showInviteKinModal(context, userId, l10n),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${l10n.translate('warriors_circle')} (${friends.length})",
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white70 : AppColors.forest700,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...friends.asMap().entries.map((entry) {
                    return _buildFriendCard(userId, entry.value, entry.key, l10n, isDark);
                  }),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold500),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Error loading friends: $err',
                style: const TextStyle(color: AppColors.semanticRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestCard(
    String currentUserId,
    Map<String, dynamic> request,
    AppLocalization l10n,
    bool isDark,
  ) {
    final requesterId = request['fromUserId'] ?? request['id'];
    final requesterName = request['fromUserName'] ?? 'Tribe Member';
    final requesterAvatar = request['fromUserAvatar'] ?? '👤';

    return BrandCard(
      theme: isDark ? BrandCardTheme.cream : BrandCardTheme.vibrant,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.gold500.withValues(alpha: 0.15),
            child: Text(requesterAvatar, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requesterName,
                  style: AppTypography.h3.copyWith(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.forest900,
                  ),
                ),
                Text(
                  l10n.translate('incoming_kin_requests'),
                  style: AppTypography.label.copyWith(
                    fontSize: 10,
                    color: AppColors.gold500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticService.selection();
              try {
                await ref.read(firebaseServiceProvider).declineFriendRequest(
                      currentUserId: currentUserId,
                      requesterId: requesterId,
                    );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.semanticRed),
                  );
                }
              }
            },
            child: Text(
              l10n.translate('decline'),
              style: TextStyle(color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5)),
            ),
          ),
          BrandButton(
            text: l10n.translate('accept'),
            type: BrandButtonType.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onTap: () async {
              HapticService.success();
              try {
                await ref.read(firebaseServiceProvider).acceptFriendRequest(
                      currentUserId: currentUserId,
                      requesterId: requesterId,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.translate('already_kin')}!'),
                      backgroundColor: AppColors.semanticGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.semanticRed),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(
    String currentUserId,
    WarriorFriend friend,
    int index,
    AppLocalization l10n,
    bool isDark,
  ) {
    return BrandCard(
      theme: isDark ? BrandCardTheme.cream : BrandCardTheme.gold,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
                child: Text(
                  friend.avatar,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: friend.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.forest800 : AppColors.gold50,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/member/${friend.id}'),
                  child: Text(
                    friend.name,
                    style: AppTypography.h3.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  'LEVEL ${friend.level} ${l10n.translate('warrior_label')}',
                  style: AppTypography.label.copyWith(
                    color: isDark
                        ? Colors.white60
                        : AppColors.forest700.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${friend.streak} ${l10n.translate('day_streak')}',
                      style: AppTypography.mono.copyWith(
                        color: isDark ? AppColors.gold500 : AppColors.forest900,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.waving_hand_rounded, color: AppColors.gold500, size: 22),
                tooltip: l10n.translate('salute_button'),
                onPressed: () => _handleSendSalute(currentUserId, friend, l10n),
              ),
              const SizedBox(width: 4),
              BrandButton(
                text: l10n.translate('duel_btn'),
                type: BrandButtonType.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onTap: () {
                  HapticService.selection();
                  context.push('/lingua-duel');
                },
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
  }

  Widget _buildSearchResultsView(String currentUserId, AppLocalization l10n, bool isDark) {
    final searchAsync = ref.watch(searchUsersProvider(_searchQuery));
    final friendsAsync = ref.watch(userFriendsProvider);

    final friendIds = (friendsAsync.value ?? []).map((f) => f.id).toSet();

    return searchAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return BrandedEmptyState(
            icon: Icons.search_off_rounded,
            title: l10n.translate('no_members_found'),
            message: 'No tribal members matched "$_searchQuery".',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userItem = users[index];
            final isAlreadyFriend = friendIds.contains(userItem.id);
            final isSending = _sendingRequestState[userItem.id] ?? false;

            return BrandCard(
              theme: isDark ? BrandCardTheme.cream : BrandCardTheme.gold,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              borderRadius: 20,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.gold500.withValues(alpha: 0.15),
                    child: Text(userItem.avatar, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userItem.name,
                          style: AppTypography.h3.copyWith(
                            fontSize: 16,
                            color: isDark ? Colors.white : AppColors.forest900,
                          ),
                        ),
                        Text(
                          'LEVEL ${userItem.level} • ${userItem.streak}d streak',
                          style: AppTypography.label.copyWith(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : AppColors.forest700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAlreadyFriend)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.semanticGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.semanticGreen.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        l10n.translate('already_kin'),
                        style: AppTypography.label.copyWith(
                          color: AppColors.semanticGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    BrandButton(
                      text: isSending
                          ? l10n.translate('waiting')
                          : l10n.translate('add_kin'),
                      type: BrandButtonType.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      onTap: isSending
                          ? null
                          : () => _handleSendFriendRequest(currentUserId, userItem.id, userItem.name, l10n),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold500),
      ),
      error: (err, _) => Center(
        child: Text('Search error: $err', style: const TextStyle(color: AppColors.semanticRed)),
      ),
    );
  }

  Future<void> _handleSendSalute(String senderId, WarriorFriend friend, AppLocalization l10n) async {
    HapticService.selection();
    try {
      await ref.read(firebaseServiceProvider).sendWarriorSalute(
            senderId: senderId,
            targetUserId: friend.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('salute_sent', params: {'name': friend.name})),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('salute_failed')),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  Future<void> _handleSendFriendRequest(
    String currentUserId,
    String targetUserId,
    String targetName,
    AppLocalization l10n,
  ) async {
    HapticService.selection();
    setState(() => _sendingRequestState[targetUserId] = true);

    try {
      await ref.read(firebaseServiceProvider).sendFriendRequest(
            fromUserId: currentUserId,
            toUserId: targetUserId,
          );
      if (mounted) {
        setState(() => _sendingRequestState[targetUserId] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('kin_request_sent')} to $targetName!'),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingRequestState[targetUserId] = false);
        final errMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMessage),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  void _showInviteKinModal(BuildContext context, String currentUserId, AppLocalization l10n) {
    HapticService.light();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalSearchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String modalQuery = modalSearchCtrl.text.trim();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.forest900 : AppColors.creamBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('invite_kin'),
                        style: AppTypography.h2ExtraBold.copyWith(
                          color: AppColors.gold500,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.gold500),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BrandTextField(
                    controller: modalSearchCtrl,
                    labelText: l10n.translate('search_members'),
                    prefixIcon: Icons.search_rounded,
                    onChanged: (v) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: modalQuery.isEmpty
                        ? Center(
                            child: Text(
                              'Type a username or email to search for tribal kin.',
                              style: AppTypography.body.copyWith(
                                color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Consumer(
                            builder: (context, ref, child) {
                              final searchAsync = ref.watch(searchUsersProvider(modalQuery));
                              final friendsAsync = ref.watch(userFriendsProvider);
                              final friendIds = (friendsAsync.value ?? []).map((f) => f.id).toSet();

                              return searchAsync.when(
                                data: (users) {
                                  if (users.isEmpty) {
                                    return Center(
                                      child: Text(
                                        l10n.translate('no_members_found'),
                                        style: TextStyle(color: isDark ? Colors.white54 : AppColors.forest900),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: users.length,
                                    itemBuilder: (context, index) {
                                      final userItem = users[index];
                                      final isAlreadyFriend = friendIds.contains(userItem.id);
                                      final isSending = _sendingRequestState[userItem.id] ?? false;

                                      return BrandCard(
                                        theme: isDark ? BrandCardTheme.cream : BrandCardTheme.vibrant,
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        borderRadius: 16,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: AppColors.gold500.withValues(alpha: 0.15),
                                              child: Text(userItem.avatar, style: const TextStyle(fontSize: 20)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    userItem.name,
                                                    style: AppTypography.h3.copyWith(
                                                      fontSize: 15,
                                                      color: isDark ? Colors.white : AppColors.forest900,
                                                    ),
                                                  ),
                                                  Text(
                                                    'LEVEL ${userItem.level} • ${userItem.streak}d streak',
                                                    style: AppTypography.label.copyWith(
                                                      fontSize: 10,
                                                      color: isDark ? Colors.white60 : AppColors.forest700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isAlreadyFriend)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.semanticGreen.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  l10n.translate('already_kin'),
                                                  style: AppTypography.label.copyWith(
                                                    color: AppColors.semanticGreen,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            else
                                              BrandButton(
                                                text: isSending
                                                    ? l10n.translate('waiting')
                                                    : l10n.translate('add_kin'),
                                                type: BrandButtonType.primary,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                onTap: isSending
                                                    ? null
                                                    : () async {
                                                        setModalState(() {});
                                                        await _handleSendFriendRequest(
                                                          currentUserId,
                                                          userItem.id,
                                                          userItem.name,
                                                          l10n,
                                                        );
                                                        setModalState(() {});
                                                      },
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(color: AppColors.gold500),
                                ),
                                error: (e, _) => Center(
                                  child: Text('Search error: $e', style: const TextStyle(color: AppColors.semanticRed)),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
