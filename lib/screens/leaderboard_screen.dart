import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/badges.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTribalTitle(int rank) {
    if (rank == 1) return 'ANCESTRAL GUARDIAN';
    if (rank <= 3) return 'ELDER SAGE';
    if (rank <= 10) return 'TRIBE WARRIOR';
    if (rank <= 50) return 'HUNTER PATHFINDER';
    return 'SACRED TRAVELER';
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
        avatar: val['avatarUrl'], // In case we have real URLs
        rankChange: 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isLearnerTab = _tabController.index == 0;

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
                stretch: true,
                backgroundColor: AppColors.forest900,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  titlePadding: const EdgeInsets.only(bottom: 60),
                  title: Text(
                    'COMMUNITY PEAK',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      letterSpacing: 4,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/topo_map.png',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.forest900.withValues(alpha: 0.6),
                              AppColors.forest900,
                            ],
                            stops: const [0.2, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // The Podium
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
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
                                    if (entries.isEmpty) {
                                      return const SizedBox();
                                    }
                                    return _buildPodium(
                                      entries.take(3).toList(),
                                      isLearnerTab ? 'XP' : 'words',
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.gold500,
                                    ),
                                  ),
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
                    decoration: BoxDecoration(
                      color: AppColors.forest900,
                      borderRadius: const BorderRadius.vertical(
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
                  child: Container(
                    color: AppColors.forest900,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _buildFilterRow(),
                  ),
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
                            return SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                // Skip top 3 as they are in the podium (unless searching)
                                if (_searchQuery.isEmpty && index < 3) {
                                  return const SizedBox.shrink();
                                }

                                final entry = entries[index];
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
                              }, childCount: entries.length),
                            );
                          },
                          loading: () => const SliverToBoxAdapter(
                            child: Center(child: CircularProgressIndicator()),
                          ),
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
    return GestureDetector(
      onTap: () => context.push('/member/${e.uid}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFirst)
            const Text('👑', style: TextStyle(fontSize: 32))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.15, duration: 800.ms)
                .shimmer(
                  delay: 1000.ms,
                  duration: 1500.ms,
                  color: AppColors.gold200,
                ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(3),
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
          const SizedBox(height: 12),
          Text(
            e.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: isFirst ? FontWeight.w900 : FontWeight.bold,
              fontSize: isFirst ? 14 : 12,
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
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isFirst
                  ? AppColors.gold500.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getTribalTitle(e.rank),
              style: AppTypography.label.copyWith(
                color: isFirst ? AppColors.gold500 : Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color,
                  color.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  '#${e.rank}',
                  style: AppTypography.display.copyWith(
                    fontSize: 28,
                    color: Colors.white24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2500.ms, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildRankRow(LeaderboardEntry e, String label, bool isMe) {
    return GestureDetector(
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
              SizedBox(
                width: 38,
                child: Column(
                  children: [
                    Text(
                      '${e.rank}',
                      style: AppTypography.mono.copyWith(
                        color: isMe ? AppColors.gold500 : Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (e.rankChange != 0)
                      Icon(
                        e.rankChange > 0
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: e.rankChange > 0
                            ? AppColors.semanticGreen
                            : AppColors.semanticRed,
                        size: 20,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
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
                    Text(
                      _getTribalTitle(e.rank),
                      style: AppTypography.label.copyWith(
                        color: isMe
                            ? AppColors.gold500.withValues(alpha: 0.8)
                            : Colors.white24,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
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
              child: Text(
                (displayName ?? 'Y')[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.forest900,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YOUR POSITION',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  displayName ?? 'You',
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
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
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
