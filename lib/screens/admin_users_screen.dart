import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/admin_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/ambient_topo_background.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _userSearch = '';
  String _roleFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientTopoBackground(
        child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _userSearch = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: const TextStyle(
                        color: Colors.white24,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.gold500,
                        size: 20,
                      ),
                      suffixIcon: _userSearch.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _userSearch = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.forest800.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRoleTabs(),
                usersAsync.when(
                  data: (users) {
                    final filtered = _getFiltered(users);
                    return Expanded(
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
                                    color: Colors.white24,
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
                                      color: AppColors.gold500.withValues(alpha: 0.1),
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
                            child: filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.person_search_rounded,
                                          color: Colors.white10,
                                          size: 64,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No users found.',
                                          style: AppTypography.h3.copyWith(
                                            color: Colors.white24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      100,
                                    ),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, i) =>
                                        _userRow(filtered[i], i)
                                            .animate()
                                            .fadeIn(
                                              delay: Duration(
                                                milliseconds: i * 50,
                                              ),
                                            )
                                            .slideX(begin: 0.05),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Expanded(
                    child: Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
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
      'Validator',
      'Contributor',
      'Learner',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: roles.map((r) {
          final isSelected = _roleFilter == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _roleFilter = r),
              child: Chip(
                label: Text(r),
                backgroundColor: isSelected
                    ? AppColors.gold500
                    : Colors.white.withValues(alpha: 0.05),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.forest900 : Colors.white70,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.forest900.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
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
                    color: Colors.white.withValues(alpha: 0.3),
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
    return ColorFiltered(
      colorFilter: isSuspended
          ? const ColorFilter.matrix([
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.forest700.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSuspended
                ? AppColors.semanticRed.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
            width: isSuspended ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _showUserDetailSheet(user),
            borderRadius: BorderRadius.circular(20),
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
                                ? Colors.white24
                                : color.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Text(
                            user.name[0],
                            style: TextStyle(
                              color: isSuspended ? Colors.white38 : color,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
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
                              color: AppColors.forest900,
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
                            color: isSuspended ? Colors.white38 : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            decoration: isSuspended
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _roleBadge(
                              user.role,
                              isSuspended ? Colors.white24 : color,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Â·',
                              style: TextStyle(color: Colors.white24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${user.xp} XP',
                              style: AppTypography.mono.copyWith(
                                color: AppColors.gold500.withValues(
                                  alpha: isSuspended ? 0.2 : 0.6,
                                ),
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
                    icon: const Icon(Icons.more_horiz, color: Colors.white24),
                    padding: EdgeInsets.zero,
                    color: AppColors.forest800,
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (val) => _handleUserAction(val, user),
                    itemBuilder: (context) => [
                      _buildPopupItem(
                        'edit',
                        'Edit Profile',
                        Icons.edit_outlined,
                      ),
                      _buildPopupItem(
                        'promote',
                        'Change Role',
                        Icons.shield_outlined,
                      ),
                      const PopupMenuDivider(height: 1),
                      _buildPopupItem(
                        'suspend',
                        isSuspended ? 'Unsuspend' : 'Suspend',
                        Icons.block_flipped,
                        color: AppColors.semanticRed,
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

  void _showUserDetailSheet(AdminUser user) {
    final isSuspended = user.status == 'suspended';
    final color = _roleColor(user.role);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest900,
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Text(
                        user.name[0],
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: AppTypography.h2.copyWith(color: Colors.white),
                    ),
                    Text(
                      user.email,
                      style: AppTypography.body.copyWith(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _roleBadge(user.role, color),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _detailStat(
                    'CONTRIBUTIONS',
                    user.totalContributions.toString(),
                    Icons.edit_rounded,
                  ),
                  const SizedBox(width: 12),
                  _detailStat('XP', user.xp.toString(), Icons.star_rounded),
                  const SizedBox(width: 12),
                  _detailStat(
                    'JOINED',
                    '${user.joinedAt.month}/${user.joinedAt.year}',
                    Icons.calendar_today_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.forestDarkCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white24,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last active: ${_formatLastActive(user.lastActive)}',
                      style: AppTypography.body.copyWith(
                        color: Colors.white38,
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
                                color: Colors.white70,
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

  Widget _detailStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.forestDarkCard,
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
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: Colors.white24,
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
    String selectedRole = 'contributor';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.forest700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Invite New Staff',
            style: AppTypography.h3.copyWith(color: AppColors.gold500),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.forest800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                dropdownColor: AppColors.forest800,
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.forest800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                items: ['contributor', 'validator', 'educator', 'admin']
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r[0].toUpperCase() + r.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedRole = v!),
              ),
            ],
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
              text: 'Send Invite',
              type: BrandButtonType.primary,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invitation sent to ${emailCtrl.text}'),
                    backgroundColor: AppColors.semanticGreen,
                  ),
                );
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
    IconData icon, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.white70),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color ?? Colors.white, fontSize: 13),
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
        return Colors.white54;
    }
  }

  void _handleUserAction(String action, AdminUser user) {
    switch (action) {
      case 'promote':
        _showRoleSwitcherModal(user);
      case 'suspend':
        _toggleUserStatus(user);
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit profile for "${user.name}"')),
        );
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action "$action" triggered.')));
    }
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest900,
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'CHANGE ROLE: ${user.name}',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
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
            ),
            _roleOption(
              user,
              'contributor',
              'Contributor',
              'Can submit new cultural content',
              Icons.edit_note_rounded,
            ),
            _roleOption(
              user,
              'educator',
              'Educator',
              'Can create and manage lessons',
              Icons.menu_book_rounded,
            ),
            _roleOption(
              user,
              'validator',
              'Validator',
              'Can verify and approve content',
              Icons.verified_user_outlined,
            ),
            _roleOption(
              user,
              'admin',
              'Administrator',
              'Full system and user control',
              Icons.shield_outlined,
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
  ) {
    final isCurrent = user.role == roleId;
    final color = _roleColor(roleId);
    return ListTile(
      onTap: () async {
        Navigator.pop(context);
        await ref.read(firebaseServiceProvider).updateUserRole(user.id, roleId);
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
        child: Icon(icon, color: isCurrent ? color : Colors.white24, size: 20),
      ),
      title: Text(
        label,
        style: AppTypography.h3.copyWith(
          color: isCurrent ? color : Colors.white70,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        sub,
        style: AppTypography.body.copyWith(color: Colors.white24, fontSize: 11),
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




