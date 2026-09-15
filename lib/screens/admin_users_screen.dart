import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../models/admin_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/profile_avatar.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/brand_search_bar.dart';
import '../widgets/branded_empty_state.dart';
import '../providers/admin_users_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _userSearch = '';
  String _roleFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminUsersProvider.notifier).loadUsers();
    }
  }

  List<AdminUser> _getFiltered(List<AdminUser> users) {
    return users.where((u) {
      final matchesRole =
          _roleFilter == 'All' || u.role == _roleFilter.toLowerCase();

      final matchesSearch =
          _userSearch.isEmpty ||
          u.name.toLowerCase().contains(_userSearch.toLowerCase()) ||
          u.email.toLowerCase().contains(_userSearch.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);
    final filtered = _getFiltered(usersState.users);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: BrandSearchBar(
                      controller: _searchCtrl,
                      hintText: 'Search by name or email...',
                      onChanged: (v) => setState(() => _userSearch = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRoleTabs(),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filtered.length} user${filtered.length == 1 ? '' : 's'}',
                                style: AppTypography.label.copyWith(
                                  color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                                  fontSize: 10,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showInviteDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.gold500.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person_add_rounded,
                                        color: AppColors.gold500,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'INVITE',
                                        style: AppTypography.label.copyWith(
                                          color: AppColors.gold500,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filtered.isEmpty && !usersState.isLoading
                              ? BrandedEmptyState(
                                  title: _userSearch.isNotEmpty ? 'User Not Found' : 'Village is Empty',
                                  message: _userSearch.isNotEmpty
                                      ? 'No users match your search criteria.'
                                      : 'No members have registered in the tribe yet.',
                                  icon: _userSearch.isNotEmpty ? Icons.person_search_rounded : Icons.people_outline_rounded,
                                )
                              : ListView.separated(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    100,
                                  ),
                                  itemCount:
                                      filtered.length + (usersState.hasMore ? 1 : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    if (i == filtered.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    return _userRow(filtered[i], i)
                                        .animate()
                                        .fadeIn(
                                          delay: Duration(
                                            milliseconds: i * 50,
                                          ),
                                        )
                                        .slideX(begin: 0.05);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTabs() {
    final roles = [
      'All',
      'Admin',
      'Educator',
      'Learner',
    ];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: roles.map((r) {
          final isSelected = _roleFilter == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
            onTap: () {
              HapticService.selection();
              setState(() {
                _roleFilter = r;
              });
            },
              child: Chip(
                label: Text(r),
                backgroundColor: isSelected
                    ? AppColors.gold500
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.forest900.withValues(alpha: 0.05)),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.forest900 : (isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide.none,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest900.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.forest900.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold500.withValues(alpha: 0.2),
              ),
            ),
            child: const Text('🛡️', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN CONSOLE',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'User Management',
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.forest900.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userRow(AdminUser user, int i) {
    final isSuspended = user.status == 'suspended';
    final color = _roleColor(user.role);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ColorFiltered(
      colorFilter: isSuspended
          ? const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: BrandCard(
        theme: isDark ? BrandCardTheme.cream : BrandCardTheme.gold,
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        borderRadius: 24,
        onTap: () {
          HapticService.selection();
          _showUserDetailSheet(user);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSuspended
                            ? (isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.24))
                            : (isDark ? color.withValues(alpha: 0.3) : AppColors.forest900.withValues(alpha: 0.1)),
                        width: 2,
                      ),
                    ),
                    child: ProfileAvatar(
                      photoUrl: user.photoURL,
                      radius: 22,
                      iconSize: 24,
                      backgroundColor: isDark ? color.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isSuspended
                            ? AppColors.semanticRed
                            : AppColors.semanticGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.forest900 : AppColors.gold500,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTypography.body.copyWith(
                        color: isSuspended 
                            ? (isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.38)) 
                            : (isDark ? Colors.white : AppColors.forest900),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        decoration: isSuspended ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _roleBadge(
                          user.role,
                          isSuspended 
                              ? (isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.24)) 
                              : (isDark ? color : AppColors.forest900.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: TextStyle(color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.24)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user.xp} XP',
                          style: AppTypography.mono.copyWith(
                            color: isDark 
                                ? AppColors.gold500.withValues(alpha: isSuspended ? 0.2 : 0.6)
                                : AppColors.forest900.withValues(alpha: isSuspended ? 0.2 : 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz, 
                  color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                ),
                padding: EdgeInsets.zero,
                color: isDark ? AppColors.forest800 : AppColors.gold50,
                elevation: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isDark ? BorderSide.none : BorderSide(color: AppColors.gold700.withValues(alpha: 0.2)),
                ),
                onSelected: (val) => _handleUserAction(val, user),
                itemBuilder: (context) => [
                  _buildPopupItem(
                    'edit',
                    'Edit Profile',
                    Icons.edit_outlined,
                    isDark,
                  ),
                  _buildPopupItem(
                    'promote',
                    'Change Role',
                    Icons.shield_outlined,
                    isDark,
                  ),
                  const PopupMenuDivider(height: 1),
                  _buildPopupItem(
                    'suspend',
                    isSuspended ? 'Unsuspend' : 'Suspend',
                    Icons.block_flipped,
                    isDark,
                    color: AppColors.semanticRed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetailSheet(AdminUser user) {
    final isSuspended = user.status == 'suspended';
    final color = _roleColor(user.role);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : AppColors.forest900.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? color.withValues(alpha: 0.5) : AppColors.gold500,
                          width: 2,
                        ),
                      ),
                      child: ProfileAvatar(
                        photoUrl: user.photoURL,
                        radius: 50,
                        iconSize: 50,
                        backgroundColor: isDark ? color.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.forest900),
                    ),
                    Text(
                      user.email,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _roleBadge(user.role, isDark ? color : AppColors.gold700),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _detailStat(
                    'STREAK',
                    '${user.streak} DAYS',
                    Icons.local_fire_department_rounded,
                    isDark,
                  ),
                  const SizedBox(width: 12),
                  _detailStat('XP', user.xp.toString(), Icons.star_rounded, isDark),
                  const SizedBox(width: 12),
                  _detailStat(
                    'JOINED',
                    '${user.joinedAt.month}/${user.joinedAt.year}',
                    Icons.calendar_today_rounded,
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.forestDarkCard : AppColors.forest50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last active: ${_formatLastActive(user.lastActive)}',
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSuspended && user.suspensionReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.semanticRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.semanticRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.block_rounded,
                        color: AppColors.semanticRed,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SUSPENSION REASON',
                              style: AppTypography.label.copyWith(
                                color: AppColors.semanticRed,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              user.suspensionReason!,
                              style: AppTypography.body.copyWith(
                                color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : AppColors.forest50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.gold500.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastActive(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    String selectedRole = 'educator';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.forest700 : AppColors.creamBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isDark ? BorderSide.none : const BorderSide(color: AppColors.gold500, width: 2),
          ),
          title: Text(
            'Invite New Staff',
            style: AppTypography.h3.copyWith(color: isDark ? AppColors.gold500 : AppColors.gold700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                style: TextStyle(color: isDark ? Colors.white : AppColors.forest900),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: isDark ? AppColors.forest800 : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                dropdownColor: isDark ? AppColors.forest800 : AppColors.creamBg,
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: isDark ? AppColors.forest800 : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : AppColors.forest900),
                items: ['educator', 'admin']
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r[0].toUpperCase() + r.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() {
                  selectedRole = v!;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5)),
              ),
            ),
            BrandButton(
              text: 'Send Invite',
              type: BrandButtonType.primary,
              onTap: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;

                Navigator.pop(ctx);
                try {
                  await ref.read(firebaseServiceProvider).createInvitation(
                        email,
                        selectedRole,
                      );
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDark ? AppColors.forest800 : AppColors.creamBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: isDark ? BorderSide.none : const BorderSide(color: AppColors.gold500, width: 2),
                        ),
                        title: Text('Invitation Sent! 🌿', style: TextStyle(color: isDark ? AppColors.gold500 : AppColors.gold700)),
                        content: Text(
                          'The invitation for $email is ready.\n\nSince automated emails are pending, please tell the user to:\n\n1. Go to the Sign Up screen.\n2. Use $email specifically.\n3. Their $selectedRole role will activate automatically.',
                          style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7), fontSize: 13, height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('LATER', style: TextStyle(color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4))),
                          ),
                          BrandButton(
                            text: 'SHARE INVITE',
                            icon: Icons.share_rounded,
                            type: BrandButtonType.primary,
                            onTap: () {
                              final text = 'Maayong Adlaw!\n\nYou have been invited to join Lumad Lingua as a ${selectedRole.toUpperCase()}.\n\nPlease sign up at [App Link] using your email: $email\n\nYour staff privileges will activate automatically upon registration.\n\nSee you in the highlands!';
                              SharePlus.instance.share(
                                ShareParams(
                                  text: text,
                                  subject: 'Lumad Lingua Staff Invitation',
                                ),
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send invite: $e'),
                        backgroundColor: AppColors.semanticRed,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    String label,
    IconData icon,
    bool isDark, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? (isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7))),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color ?? (isDark ? Colors.white : AppColors.forest900), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: AppTypography.mono.copyWith(
          color: color,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.gold500;
      case 'educator':
        return AppColors.semanticGreen;
      case 'validator':
        return AppColors.semanticBlue;
      default:
        return AppColors.terracotta;
    }
  }

  void _handleUserAction(String action, AdminUser user) {
    switch (action) {
      case 'promote':
        _showRoleSwitcherModal(user);
      case 'suspend':
        _toggleUserStatus(user);
      case 'edit':
        _showEditUserDialog(user);
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action "$action" triggered.')));
    }
  }

  void _showEditUserDialog(AdminUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final xpCtrl = TextEditingController(text: user.xp.toString());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest700 : AppColors.creamBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark ? BorderSide.none : const BorderSide(color: AppColors.gold500, width: 2),
        ),
        title: Text(
          'Edit User Details',
          style: AppTypography.h3.copyWith(color: isDark ? AppColors.gold500 : AppColors.gold700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: isDark ? Colors.white : AppColors.forest900),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5)),
                filled: true,
                fillColor: isDark ? AppColors.forest800 : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: xpCtrl,
              style: TextStyle(color: isDark ? Colors.white : AppColors.forest900),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'XP',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5)),
                filled: true,
                fillColor: isDark ? AppColors.forest800 : Colors.black.withValues(alpha: 0.05),
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
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5)),
            ),
          ),
          BrandButton(
            text: 'Save Changes',
            type: BrandButtonType.primary,
            onTap: () async {
              final newName = nameCtrl.text.trim();
              final newXp = int.tryParse(xpCtrl.text) ?? user.xp;

              if (newName.isEmpty) return;

              Navigator.pop(ctx);
              try {
                await ref.read(firebaseServiceProvider).updateUserDetails(
                  user.id,
                  {'username': newName, 'xp': newXp},
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User details updated successfully'),
                      backgroundColor: AppColors.semanticGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update user: $e'),
                      backgroundColor: AppColors.semanticRed,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(AdminUser user) {
    final isSusp = user.status == 'suspended';
    if (isSusp) {
      _showConfirmAction(
        'Unsuspend User?',
        'Restore access for ${user.name}.',
        () async {
          await ref
              .read(firebaseServiceProvider)
              .updateUserStatus(user.id, 'active', null);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User unsuspended'),
                backgroundColor: AppColors.semanticGreen,
              ),
            );
          }
        },
      );
    } else {
      final reasonCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.forest700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Suspend ${user.name}?',
            style: AppTypography.h3.copyWith(color: AppColors.semanticRed),
          ),
          content: TextField(
            controller: reasonCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Reason for suspension',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: AppColors.forest800,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            BrandButton(
              text: 'Suspend',
              type: BrandButtonType.primary,
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(firebaseServiceProvider)
                    .updateUserStatus(
                      user.id,
                      'suspended',
                      reasonCtrl.text.isNotEmpty
                          ? reasonCtrl.text
                          : 'No reason provided',
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User suspended'),
                      backgroundColor: AppColors.semanticRed,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    }
  }

  void _showRoleSwitcherModal(AdminUser user) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'CHANGE ROLE: ${user.name}',
              style: AppTypography.label.copyWith(
                color: isDark ? AppColors.gold500 : AppColors.gold700,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            _roleOption(
              user,
              'learner',
              'Learner',
              'Can access lessons and dictionary',
              Icons.school_outlined,
              isDark,
            ),
            _roleOption(
              user,
              'educator',
              'Educator',
              'Can create and manage lessons',
              Icons.menu_book_rounded,
              isDark,
            ),
            _roleOption(
              user,
              'admin',
              'Administrator',
              'Full system and user control',
              Icons.shield_outlined,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(
    AdminUser user,
    String roleId,
    String label,
    String sub,
    IconData icon,
    bool isDark,
  ) {
    final isCurrent = user.role == roleId;
    final color = _roleColor(roleId);
    return ListTile(
      onTap: () async {
        Navigator.pop(context);

        await ref.read(firebaseServiceProvider).updateUserRole(
              user.id,
              roleId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role updated to ${label.toUpperCase()}')),
          );
        }
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon, 
          color: isCurrent ? color : (isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3)), 
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: AppTypography.h3.copyWith(
          color: isCurrent ? (isDark ? color : AppColors.forest900) : (isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.5)),
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        sub,
        style: AppTypography.body.copyWith(
          color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3), 
          fontSize: 11,
        ),
      ),
      trailing: isCurrent
          ? Icon(Icons.check_circle_rounded, color: color, size: 20)
          : null,
    );
  }

  void _showConfirmAction(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest700,
        title: Text(
          title,
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          BrandButton(
            text: 'Confirm',
            type: BrandButtonType.primary,
            onTap: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }
}




