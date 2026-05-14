import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/student_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'brand_card.dart';

void showMistCrystalStore(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.forest900 : Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final student = ref.watch(studentProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mist Crystal Store',
                          style: AppTypography.h1ExtraBold.copyWith(
                            color: AppColors.gold500,
                            fontSize: 28,
                          ),
                        ),
                        Text(
                          'Exchange your crystals for sacred items',
                          style: AppTypography.body.copyWith(
                            color: isDark ? Colors.white38 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold500.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${student.mistCrystals}',
                            style: AppTypography.mono.copyWith(
                              color: AppColors.gold500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      _buildStoreItem(
                        context,
                        ref,
                        title: 'Heart Refill',
                        description: 'Restore your hearts to full capacity.',
                        price: 50,
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.semanticRed,
                        onPurchase: () {
                          if (student.hearts < 5) {
                            ref
                                .read(studentProvider.notifier)
                                .spendMistCrystals(50);
                            ref.read(studentProvider.notifier).refillHearts();
                            return true;
                          }
                          return false;
                        },
                      ),
                      _buildStoreItem(
                        context,
                        ref,
                        title: 'Mountain Guide Map',
                        description: 'Unlock a hidden locale on the map.',
                        price: 200,
                        icon: Icons.map_rounded,
                        iconColor: AppColors.gold500,
                        onPurchase: () {
                          ref
                              .read(studentProvider.notifier)
                              .spendMistCrystals(200);
                          return true;
                        },
                      ),
                      _buildStoreItem(
                        context,
                        ref,
                        title: 'Streak Shield',
                        description:
                            'Protects your streak if you miss a day.',
                        price: 100,
                        icon: Icons.shield_rounded,
                        iconColor: AppColors.semanticBlue,
                        onPurchase: () {
                          try {
                            final user = ref
                                .read(authServiceProvider)
                                .currentUser;
                            if (user != null) {
                              ref
                                  .read(firebaseServiceProvider)
                                  .buyStreakShield(user.uid);
                              return true;
                            }
                          } catch (e) {
                            debugPrint("Purchase failed: $e");
                          }
                          return false;
                        },
                      ),
                      _buildStoreItem(
                        context,
                        ref,
                        title: 'Sacred Chant',
                        description:
                            'Unlock a special oral history in the gallery.',
                        price: 500,
                        icon: Icons.music_note_rounded,
                        iconColor: AppColors.gold500,
                        onPurchase: () {
                          ref
                              .read(studentProvider.notifier)
                              .spendMistCrystals(500);
                          return true;
                        },
                      ),
                    ],
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

Widget _buildStoreItem(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String description,
  required int price,
  required IconData icon,
  required Color iconColor,
  required bool Function() onPurchase,
}) {
  final student = ref.watch(studentProvider);
  final canAfford = student.mistCrystals >= price;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.cream,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white38 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: canAfford
                ? () {
                    if (onPurchase()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Purchased $title!'),
                          backgroundColor: AppColors.semanticGreen,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You already have this or cannot use it now.',
                          ),
                          backgroundColor: AppColors.terracotta,
                        ),
                      );
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: canAfford
                    ? AppColors.gold500
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '$price',
                    style: AppTypography.label.copyWith(
                      color: canAfford
                          ? Colors.black
                          : (isDark ? Colors.white24 : Colors.black26),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '✨',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
