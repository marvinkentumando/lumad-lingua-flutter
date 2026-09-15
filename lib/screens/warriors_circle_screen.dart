import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../services/haptic_service.dart';

import '../widgets/brand_search_bar.dart';

class WarriorsCircleScreen extends ConsumerStatefulWidget {
  const WarriorsCircleScreen({super.key});

  @override
  ConsumerState<WarriorsCircleScreen> createState() =>
      _WarriorsCircleScreenState();
}

class _WarriorsCircleScreenState extends ConsumerState<WarriorsCircleScreen> {
  String _searchQuery = '';
  final List<Map<String, dynamic>> _mockFriends = [
    {
      'name': 'Datu Bago',
      'level': 24,
      'isOnline': true,
      'streak': 42,
      'avatar': '👤',
    },
    {
      'name': 'Bai Bibyaon',
      'level': 31,
      'isOnline': false,
      'streak': 15,
      'avatar': '👸',
    },
    {
      'name': 'Matigsalug Brave',
      'level': 12,
      'isOnline': true,
      'streak': 3,
      'avatar': '🏹',
    },
    {
      'name': 'Mandaya Weaver',
      'level': 18,
      'isOnline': false,
      'streak': 8,
      'avatar': '🧶',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _mockFriends.where((f) => 
      f['name'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

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
                    'WARRIORS CIRCLE',
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
                  hintText: 'Search members...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final friend = filtered[index];
                    return _buildFriendCard(friend, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () {
              HapticService.light();
              // Logic to add friend
            },
            backgroundColor: AppColors.gold500,
            icon: const Icon(Icons.person_add_rounded, color: Colors.black),
            label: Text(
              'INVITE KIN',
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

  Widget _buildFriendCard(Map<String, dynamic> friend, int index) {
    final isOnline = friend['isOnline'] as bool;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                radius: 30,
                backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
                child: Text(
                  friend['avatar'],
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.forest800 : AppColors.gold50, width: 2),
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
                  friend['name'],
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'LEVEL ${friend['level']} WARRIOR',
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white38 : AppColors.forest700.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${friend['streak']} DAY STREAK',
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
          Column(
            children: [
              BrandButton(
                text: 'DUEL',
                onTap: () {
                  HapticService.selection();
                  context.push('/lingua-duel');
                },
                type: BrandButtonType.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }
}



