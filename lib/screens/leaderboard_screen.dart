import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/badges.dart';
import '../widgets/skeleton.dart';
import '../widgets/branded_empty_state.dart';
import '../widgets/spirit_particle_overlay.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import 'package:go_router/go_router.dart';

class LeaderboardEntry {
  final String name;
  final int xp;
  final int rank;
  final String? uid;
  final String? avatar;
  final int rankChange; // positive for up, negative for down, 0 for same

  const LeaderboardEntry({
    required this.name,
    required this.xp,
    required this.rank,
    this.uid,
    this.avatar,
    this.rankChange = 0,
  });
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _timeFilter = 'all';
  String _searchQuery = '';
  final Set<int> _celebratedTabs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  Future<void> _checkRankImprovement(List<LeaderboardEntry> entries, String? userId) async {
    final tabIndex = _tabController.index;
    if (_celebratedTabs.contains(tabIndex) || userId == null) return;

    final myEntry = entries.where((e) => e.uid == userId).firstOrNull;
    if (myEntry == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'last_rank_${tabIndex}_$userId';
    final lastRank = prefs.getInt(key);

    if (lastRank != null && myEntry.rank < lastRank) {
      // Improved! (Smaller number is better rank)
      if (mounted) {
        _celebratedTabs.add(tabIndex);
        showSpiritParticles(context, duration: const Duration(seconds: 4));
        HapticService.celebration();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CLIMB SUCCESSFUL! You moved from #$lastRank to #${myEntry.rank}!',
              style: AppTypography.label.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.semanticGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Update stored rank
    await prefs.setInt(key, myEntry.rank);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  List<LeaderboardEntry> _mapToEntries(
    List<Map<String, dynamic>> data,
    bool isXP,
  ) {
    return data.asMap().entries.map((e) {
      final index = e.key;
      final val = e.value;
      return LeaderboardEntry(
        uid: val['uid'],
        rank: index + 1,
        name: val['username'] ?? 'Anonymous',
        xp: isXP ? (val['xp'] ?? 0) : (val['wordCount'] ?? 0),
        avatar: val['photoURL'] ?? val['avatarUrl'], // In case we have real URLs
        rankChange: 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isLearnerTab = _tabController.index == 0;

    final leaderboardData = (isLearnerTab
            ? ref.watch(topLearnersProvider)
            : ref.watch(topContributorsProvider))
        .value;

    LeaderboardEntry? myEntry;
    LeaderboardEntry? nextEntry;

    if (leaderboardData != null && user != null) {
      final allEntries = _mapToEntries(leaderboardData, isLearnerTab);
      final foundMe = allEntries.where((e) => e.uid == user.uid).firstOrNull;
      if (foundMe != null) {
        myEntry = foundMe;
        if (foundMe.rank > 1) {
          nextEntry = allEntries.where((e) => e.rank == foundMe.rank - 1).firstOrNull;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.forest900,
      body: Stack(
        children: [
          // Background Topo Map
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/topo_map.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom AppBar with Background image
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: AppColors.forest900,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  'COMMUNITY PEAK',
                  style: AppTypography.display.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 6,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/topo_map.png',
                        fit: BoxFit.cover,
                      ),
                      // Atmospheric Fog/Mist
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.forest900.withValues(alpha: 0.4),
                              AppColors.forest900.withValues(alpha: 0.8),
                              AppColors.forest900,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // Top Glow
                      Positioned(
                        top: -50,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold500.withValues(alpha: 0.15),
                                blurRadius: 120,
                                spreadRadius: 60,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // The Podium
                      Padding(
                        padding: const EdgeInsets.only(top: 180),
                        child:
                            (isLearnerTab
                                    ? ref.watch(topLearnersProvider)
                                    : ref.watch(topContributorsProvider))
                                .when(
                                  data: (data) {
                                    final entries = _mapToEntries(
                                      data,
                                      isLearnerTab,
                                    );

                                    // Trigger celebration if rank improved
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _checkRankImprovement(entries, user?.uid);
                                    });

                                    if (entries.isEmpty) {
                                      return const SizedBox();
                                    }
                                    return _buildPodium(
                                      entries.take(3).toList(),
                                      isLearnerTab ? 'XP' : 'words',
                                    );
                                  },
                                  loading: () => Center(child: _buildPodiumSkeleton()),
                                  error: (err, _) =>
                                      Center(child: Text('Error: $err')),
                                ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.forest900,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.gold500,
                      labelColor: AppColors.gold500,
                      unselectedLabelColor: Colors.white38,
                      dividerColor: Colors.transparent,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: 'LEARNERS'),
                        Tab(text: 'CONTRIBUTORS'),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter & Search Row (Sticky)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 80,
                  maxHeight: 80,
                  child: _buildFilterRow(),
                ),
              ),

              // Ranking List
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver:
                    (isLearnerTab
                            ? ref.watch(topLearnersProvider)
                            : ref.watch(topContributorsProvider))
                        .when(
                          data: (data) {
                            final entries = _applyFilter(
                              _mapToEntries(data, isLearnerTab),
                            );

                            if (entries.isEmpty && _searchQuery.isNotEmpty) {
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 60),
                                  child: BrandedEmptyState(
                                    title: 'Quiet Peaks',
                                    message: 'No climbers found matching your search.',
                                    icon: Icons.search_off_rounded,
                                  ),
                                ),
                              );
                            }

                            final displayEntries = _searchQuery.isEmpty
                                ? entries.skip(math.min(3, entries.length)).toList()
                                : entries;

                            return SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final entry = displayEntries[index];
                                return _buildRankRow(
                                      entry,
                                      isLearnerTab ? 'XP' : 'words',
                                      entry.uid == user?.uid,
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: Duration(milliseconds: index * 50),
                                    )
                                    .slideX(
                                      begin: 0.1,
                                      curve: Curves.easeOutCubic,
                                    );
                              }, childCount: displayEntries.length),
                            );
                          },
                          loading: () => _buildRankingListSkeleton(),
                          error: (err, _) => SliverToBoxAdapter(
                            child: Center(child: Text('Error: $err')),
                          ),
                        ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // Pinned "My Rank" card at the bottom
          if (user != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildMyRankCard(
                user.displayName,
                ref.watch(userProfileProvider).value?[isLearnerTab
                    ? 'xp'
                    : 'wordCount'],
                user.uid,
                isLearnerTab,
                user.photoURL,
                myEntry,
                nextEntry,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        // Time filter tabs
        _filterChip('This Week', 'week'),
        const SizedBox(width: 8),
        _filterChip('All Time', 'all'),
        const SizedBox(width: 12),
        // Search
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white24,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.forest800,
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
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              isDense: true,
            ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _timeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _timeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold500
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.gold500
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: isSelected ? AppColors.forest900 : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  List<LeaderboardEntry> _applyFilter(List<LeaderboardEntry> entries) {
    if (_searchQuery.isEmpty) return entries;
    return entries
        .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildPodiumSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _podiumSpotSkeleton(100),
        const SizedBox(width: 8),
        _podiumSpotSkeleton(140),
        const SizedBox(width: 8),
        _podiumSpotSkeleton(80),
      ],
    );
  }

  Widget _podiumSpotSkeleton(double height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Skeleton(width: 64, height: 64, isCircle: true),
        const SizedBox(height: 12),
        const Skeleton(width: 60, height: 12),
        const SizedBox(height: 4),
        const Skeleton(width: 40, height: 10),
        const SizedBox(height: 12),
        Skeleton(width: 80, height: height, borderRadius: 20),
      ],
    );
  }

  Widget _buildRankingListSkeleton() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: const Skeleton(height: 70, borderRadius: 20),
        ),
        childCount: 5,
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3, String label) {
    if (top3.length < 3) return const SizedBox.shrink();

    final first = top3.firstWhere((e) => e.rank == 1);
    final second = top3.firstWhere((e) => e.rank == 2);
    final third = top3.firstWhere((e) => e.rank == 3);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _podiumSpot(
          second,
          100,
          AppColors.forest500,
          label,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(width: 8),
        _podiumSpot(
          first,
          140,
          AppColors.gold500,
          label,
          isFirst: true,
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        const SizedBox(width: 8),
        _podiumSpot(
          third,
          80,
          AppColors.forest600,
          label,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _podiumSpot(
    LeaderboardEntry e,
    double height,
    Color color,
    String label, {
    bool isFirst = false,
  }) {
    return BouncyPressable(
      onTap: () => context.push('/member/${e.uid}'),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // The Pillar
          CustomPaint(
            size: Size(100, height + 60),
            painter: _SacredPillarPainter(
              color: color,
              rank: e.rank,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 3.seconds,
                color: Colors.white12,
              ),

          // Content
          Positioned(
            bottom: height + 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),

                // Avatar with Frame
                _buildTribalAvatar(e, isFirst),

                const SizedBox(height: 12),
                Text(
                  e.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: Colors.white,
                    fontWeight: isFirst ? FontWeight.w900 : FontWeight.bold,
                    fontSize: isFirst ? 14 : 12,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${e.xp} $label',
                  style: AppTypography.mono.copyWith(
                    color: isFirst ? AppColors.gold500 : Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Rank Number on Pillar
          Positioned(
            bottom: height - 40,
            child: Text(
              '#${e.rank}',
              style: AppTypography.display.copyWith(
                fontSize: isFirst ? 48 : 36,
                color: Colors.white.withValues(alpha: 0.15),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTribalAvatar(LeaderboardEntry e, bool isFirst) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isFirst)
          // Halo glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold500.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scaleXY(begin: 0.8, end: 1.2, duration: 2.seconds),

        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isFirst ? AppColors.gold500 : Colors.white24,
              width: isFirst ? 3 : 1.5,
            ),
            boxShadow: [
              if (isFirst)
                BoxShadow(
                  color: AppColors.gold500.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: CircleAvatar(
            radius: isFirst ? 42 : 32,
            backgroundColor: AppColors.forest800,
            backgroundImage: e.avatar != null
                ? (e.avatar!.startsWith('http')
                      ? NetworkImage(e.avatar!) as ImageProvider
                      : AssetImage(e.avatar!))
                : null,
            child: e.avatar == null
                ? Text(
                    e.name[0].toUpperCase(),
                    style: AppTypography.h2.copyWith(color: Colors.white),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _sendCheer(String targetUid, String targetName) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final myName = user.displayName ?? 'A Fellow Traveler';

    try {
      await ref.read(firebaseServiceProvider).addNotification(targetUid, {
        'type': 'cheer',
        'title': 'Tribal Salute! 🌿',
        'message': '$myName sent you a Sacred Spark for your progress!',
        'senderId': user.uid,
        'senderName': myName,
      });

      if (mounted) {
        HapticService.light();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salute sent to $targetName!'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.gold500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send salute.')),
        );
      }
    }
  }

  Widget _buildRankRow(LeaderboardEntry e, String label, bool isMe) {
    return BouncyPressable(
      onTap: () {
        if (isMe) {
          context.push('/profile');
        } else {
          context.push('/member/${e.uid}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isMe
                ? [AppColors.gold500, AppColors.gold700]
                : [Colors.white12, Colors.transparent],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.forest800
                : AppColors.forest700.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              // Rank Container with Slanted Design
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMe ? AppColors.gold500.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  '${e.rank}',
                  style: AppTypography.mono.copyWith(
                    color: isMe ? AppColors.gold500 : Colors.white38,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMe ? AppColors.gold500 : Colors.white10,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: isMe
                      ? AppColors.gold500
                      : AppColors.forest900,
                  backgroundImage: e.avatar != null
                      ? (e.avatar!.startsWith('http')
                            ? NetworkImage(e.avatar!) as ImageProvider
                            : AssetImage(e.avatar!))
                      : null,
                  child: e.avatar == null
                      ? Text(
                          isMe ? '★' : e.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? AppColors.forest900 : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'You' : e.name,
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.gold500.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMe
                        ? AppColors.gold500.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  '${e.xp} $label',
                  style: AppTypography.mono.copyWith(
                    color: isMe ? AppColors.gold500 : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isMe && e.uid != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendCheer(e.uid!, e.name),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  color: AppColors.gold500.withValues(alpha: 0.6),
                  iconSize: 20,
                  tooltip: 'Send Tribal Salute',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyRankCard(
    String? displayName,
    int? xp,
    String? uid,
    bool isXP,
    String? photoUrl,
    LeaderboardEntry? myEntry,
    LeaderboardEntry? nextEntry,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.forest900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold500, width: 2),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.gold500,
              backgroundImage: photoUrl != null
                  ? (photoUrl.startsWith('http')
                        ? NetworkImage(photoUrl) as ImageProvider
                        : AssetImage(photoUrl))
                  : null,
              child: photoUrl == null
                  ? Text(
                      (displayName ?? 'Y')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.forest900,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'YOUR POSITION',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (myEntry != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '#${myEntry.rank}',
                        style: AppTypography.mono.copyWith(
                          color: AppColors.gold500,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  displayName ?? 'You',
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                if (myEntry != null && nextEntry != null) ...[
                  const SizedBox(height: 8),
                  _buildMiniProgressBar(myEntry.xp, nextEntry.xp, nextEntry.rank, isXP),
                ],
              ],
            ),
          ),
          BrandBadge(
                text: '${xp ?? 0} ${isXP ? 'XP' : 'words'}',
                style: BrandBadgeStyle.gold,
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2.seconds, color: AppColors.gold200),
        ],
      ),
    );
  }

  Widget _buildMiniProgressBar(int currentXp, int targetXp, int nextRank, bool isXP) {
    final diff = targetXp - currentXp;
    if (diff <= 0) return const SizedBox.shrink();

    // Calculate progress ratio. If they are the same it's 1.0
    // To make it look like a progress bar, we can use a simple ratio or a relative one.
    final ratio = (currentXp / targetXp).clamp(0.1, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4,
          width: 140,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.gold500,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$diff ${isXP ? 'XP' : 'words'} until #$nextRank',
          style: AppTypography.mono.copyWith(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.forest900.withValues(alpha: 0.7),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class _SacredPillarPainter extends CustomPainter {
  final Color color;
  final int rank;

  _SacredPillarPainter({required this.color, required this.rank});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    // Tapered Pillar (wider at bottom)
    path.moveTo(size.width * 0.15, 0);
    path.lineTo(size.width * 0.85, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Decorative tribal border (very subtle)
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, linePaint);

    // Add very subtle tribal "notches"
    final notchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var i = 1; i < 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), notchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BouncyPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncyPressable({super.key, required this.child, required this.onTap});

  @override
  State<BouncyPressable> createState() => _BouncyPressableState();
}

class _BouncyPressableState extends State<BouncyPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}



