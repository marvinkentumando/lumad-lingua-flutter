import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/student_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';

import '../providers/role_provider.dart';

class WisdomProgressionScreen extends ConsumerWidget {
  const WisdomProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    final config = ref.watch(appConfigProvider).value;
    final role = ref.watch(roleProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentStatus(context, student, role),
                      const SizedBox(height: 40),
                      _sectionLabel(role == UserRole.learner ? 'THE ASCENT OF WISDOM' : 'THE PATH OF LEADERSHIP'),
                      const SizedBox(height: 24),
                      _buildProgressionPath(context, student, config, role),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.gold500,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Wisdom Progression',
            style: AppTypography.h2ExtraBold.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.forest900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(BuildContext context, StudentState student, UserRole role) {
    String currentRank;
    if (role == UserRole.learner) {
      currentRank = student.levelTitle;
    } else {
      // Logic from _StaffStatsRow
      if (student.xp < 500) {
        currentRank = 'Novice';
      } else if (student.xp < 2000) {
        currentRank = 'Guardian';
      } else if (student.xp < 5000) {
        currentRank = 'Elder';
      } else {
        currentRank = 'Elite';
      }
    }

    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(28),
      borderRadius: 32,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${student.level}',
                  style: AppTypography.displayBold.copyWith(
                    color: Colors.black,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentRank.toUpperCase(),
                      style: AppTypography.h3.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'CURRENT RANK',
                      style: AppTypography.label.copyWith(
                        color: Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${student.xp} TOTAL XP',
                style: AppTypography.mono.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(student.levelProgress * 100).toInt()}% TO LEVEL ${student.level + 1}',
                style: AppTypography.label.copyWith(
                  color: Colors.black54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: student.levelProgress,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: AppTypography.label.copyWith(
          color: AppColors.gold500,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      );

  Widget _buildProgressionPath(
    BuildContext context,
    StudentState student,
    dynamic config,
    UserRole role,
  ) {
    // Determine the ranks to display based on role
    final List<Map<String, dynamic>> learnerRanks = [
      {'title': 'Novice Shaman', 'minLevel': 1, 'icon': Icons.eco_rounded},
      {'title': 'Spiritual Seeker', 'minLevel': 5, 'icon': Icons.search_rounded},
      {'title': 'Tribal Guardian', 'minLevel': 10, 'icon': Icons.security_rounded},
      {'title': 'Ancestral Sage', 'minLevel': 20, 'icon': Icons.auto_awesome_rounded},
      {'title': 'Elder Guardian', 'minLevel': 40, 'icon': Icons.castle_rounded},
    ];

    final List<Map<String, dynamic>> staffRanks = [
      {'title': 'Novice Seeker', 'minXp': 0, 'icon': Icons.person_search_rounded},
      {'title': 'Guardian of Lore', 'minXp': 500, 'icon': Icons.shield_rounded},
      {'title': 'Village Elder', 'minXp': 2000, 'icon': Icons.elderly_rounded},
      {'title': 'Elite Architect', 'minXp': 5000, 'icon': Icons.auto_awesome_rounded},
    ];

    if (role == UserRole.learner) {
      return Column(
        children: learnerRanks.asMap().entries.map((entry) {
          final index = entry.key;
          final rank = entry.value;
          final isLast = index == learnerRanks.length - 1;
          final minLevel = rank['minLevel'] as int;
          final isUnlocked = student.level >= minLevel;
          final isCurrent = index < learnerRanks.length - 1
              ? (student.level >= minLevel && student.level < learnerRanks[index + 1]['minLevel'])
              : student.level >= minLevel;

          return _buildRankItem(
            context,
            title: rank['title'],
            requirement: 'Requires Level $minLevel',
            icon: rank['icon'],
            isUnlocked: isUnlocked,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        }).toList(),
      );
    } else {
      return Column(
        children: staffRanks.asMap().entries.map((entry) {
          final index = entry.key;
          final rank = entry.value;
          final isLast = index == staffRanks.length - 1;
          final minXp = rank['minXp'] as int;
          final isUnlocked = student.xp >= minXp;
          final isCurrent = index < staffRanks.length - 1
              ? (student.xp >= minXp && student.xp < staffRanks[index + 1]['minXp'])
              : student.xp >= minXp;

          return _buildRankItem(
            context,
            title: rank['title'],
            requirement: 'Requires $minXp XP',
            icon: rank['icon'],
            isUnlocked: isUnlocked,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        }).toList(),
      );
    }
  }

  Widget _buildRankItem(
    BuildContext context, {
    required String title,
    required String requirement,
    required IconData icon,
    required bool isUnlocked,
    required bool isCurrent,
    required bool isLast,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isUnlocked ? AppColors.gold500 : (isDark ? Colors.white12 : Colors.black12);
    final textColor = isUnlocked ? (isDark ? Colors.white : AppColors.forest900) : (isDark ? Colors.white24 : Colors.black26);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUnlocked ? color.withValues(alpha: 0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? AppColors.gold500 : color,
                    width: isCurrent ? 3 : 2,
                  ),
                  boxShadow: isCurrent ? [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.3),
                      blurRadius: 12,
                    )
                  ] : null,
                ),
                child: Icon(
                  icon,
                  color: isCurrent ? AppColors.gold500 : color,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isUnlocked ? AppColors.gold500 : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  title.toUpperCase(),
                  style: AppTypography.h3.copyWith(
                    color: textColor,
                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  requirement,
                  style: AppTypography.label.copyWith(
                    color: isCurrent ? AppColors.gold500 : (isDark ? Colors.white24 : Colors.black26),
                    fontSize: 10,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CURRENT STATUS',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
