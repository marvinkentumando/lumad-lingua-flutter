import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../models/gamification_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/app_localization.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_text_field.dart';

class AdminGamificationScreen extends ConsumerStatefulWidget {
  const AdminGamificationScreen({super.key});

  @override
  ConsumerState<AdminGamificationScreen> createState() => _AdminGamificationScreenState();
}

class _AdminGamificationScreenState extends ConsumerState<AdminGamificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.translate('gamification_economics'), 
          style: AppTypography.h3.copyWith(color: AppColors.gold500),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: AppColors.gold500,
          labelColor: AppColors.gold500,
          unselectedLabelColor: isDark ? Colors.white60 : Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: [
            Tab(text: l10n.translate('rewards_caps'), icon: const Icon(Icons.military_tech_rounded)),
            Tab(text: l10n.translate('shop_caps'), icon: const Icon(Icons.shopping_bag_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRewardsTab(isDark, l10n),
          _buildShopTab(isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(bool isDark, AppLocalization l10n) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRewardCategory(l10n.translate('contributions_caps'), [
            _rewardTile(
              l10n.translate('word_approval'), 
              config.wordApprovalXp, 
              (val) => _updateConfig('wordApprovalXp', val, l10n.translate('word_approval'), l10n), 
              isDark, 
              l10n,
            ),
            _rewardTile(
              l10n.translate('lesson_approval'), 
              config.lessonApprovalXp, 
              (val) => _updateConfig('lessonApprovalXp', val, l10n.translate('lesson_approval'), l10n), 
              isDark, 
              l10n,
            ),
          ], isDark),
          const SizedBox(height: 24),
          _buildRewardCategory(l10n.translate('learning_path_caps'), [
            _rewardTile(
              l10n.translate('lesson_completion_base'), 
              config.lessonCompletionBaseXp, 
              (val) => _updateConfig('lessonCompletionBaseXp', val, l10n.translate('lesson_completion_base'), l10n), 
              isDark, 
              l10n,
            ),
            _rewardTile(
              l10n.translate('perfect_task_bonus'), 
              config.lessonTaskPerfectXp, 
              (val) => _updateConfig('lessonTaskPerfectXp', val, l10n.translate('perfect_task_bonus'), l10n), 
              isDark, 
              l10n,
            ),
            _rewardTile(
              l10n.translate('task_retry_reward'), 
              config.lessonTaskRetryXp, 
              (val) => _updateConfig('lessonTaskRetryXp', val, l10n.translate('task_retry_reward'), l10n), 
              isDark, 
              l10n,
            ),
          ], isDark),
          const SizedBox(height: 24),
          _buildRewardCategory(l10n.translate('daily_rituals'), [
            _rewardTile(
              l10n.translate('srs_card_review'), 
              config.cardReviewXp, 
              (val) => _updateConfig('cardReviewXp', val, l10n.translate('srs_card_review'), l10n), 
              isDark, 
              l10n,
            ),
            _rewardTile(
              l10n.translate('srs_completion_bonus'), 
              config.cardCompletionBonusXp, 
              (val) => _updateConfig('cardCompletionBonusXp', val, l10n.translate('srs_completion_bonus'), l10n), 
              isDark, 
              l10n,
            ),
          ], isDark),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
      error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
    );
  }

  Widget _buildRewardCategory(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: AppTypography.mono.copyWith(
            color: isDark ? Colors.white24 : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6), 
            fontSize: 10, 
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.forestDarkCard : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _rewardTile(String label, int value, Function(int) onUpdate, bool isDark, AppLocalization l10n) {
    return ListTile(
      title: Text(
        label, 
        style: TextStyle(
          color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface, 
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value XP', style: const TextStyle(color: AppColors.gold500, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.edit, 
              size: 18, 
              color: isDark ? Colors.white60 : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _showRewardEditDialog(label, value, onUpdate, isDark, l10n),
          ),
        ],
      ),
    );
  }

  void _showRewardEditDialog(String label, int currentValue, Function(int) onUpdate, bool isDark, AppLocalization l10n) {
    final controller = TextEditingController(text: currentValue.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest800 : Theme.of(context).colorScheme.surface,
        title: Text(
          l10n.translate('edit_label', params: {'label': label}), 
          style: const TextStyle(color: AppColors.gold500),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandTextField(
                controller: controller,
                labelText: l10n.translate('xp_points'),
                prefixIcon: Icons.stars_rounded,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.translate('please_enter_xp');
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null) {
                    return l10n.translate('please_enter_valid_number');
                  }
                  if (parsed < 0) {
                    return l10n.translate('xp_cannot_be_negative');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx), 
            child: Text(
              l10n.translate('cancel').toUpperCase(), 
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final parsed = int.tryParse(controller.text.trim()) ?? currentValue;
                Navigator.pop(dialogCtx);
                await onUpdate(parsed);
              }
            },
            child: Text(l10n.translate('update_caps')),
          ),
        ],
      ),
    );
  }

  Future<void> _updateConfig(String key, int value, String label, AppLocalization l10n) async {
    try {
      await ref.read(firebaseServiceProvider).updateAppConfig({key: value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('config_updated_msg', params: {'label': label, 'value': value.toString()})),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('config_update_failed_msg', params: {'label': label, 'error': e.toString()})),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  Widget _buildShopTab(bool isDark, AppLocalization l10n) {
    final shopAsync = ref.watch(shopItemsStreamProvider);
    return shopAsync.when(
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _buildAddShopItemCard(isDark, l10n);
          }
          final item = items[index];
          final isAvail = item.isAvailable;

          final titleColor = isDark
              ? Colors.white
              : (isAvail ? AppColors.forest900 : Theme.of(context).colorScheme.onSurfaceVariant);
          final subtitleColor = isDark
              ? (isAvail ? Colors.white70 : Colors.white38)
              : (isAvail ? AppColors.forest700 : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6));

          return Opacity(
            opacity: isAvail ? 1.0 : 0.65,
            child: BrandCard(
              theme: isDark
                  ? (isAvail ? BrandCardTheme.vibrant : BrandCardTheme.gold)
                  : (isAvail ? BrandCardTheme.gold : BrandCardTheme.cream),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.forest900.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.icon.length < 3 
                      ? Text(item.icon, style: const TextStyle(fontSize: 24))
                      : Icon(
                          Icons.inventory_2_rounded,
                          color: isDark ? AppColors.gold500 : AppColors.forest900,
                        ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.h3.copyWith(
                          color: titleColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAvail
                            ? AppColors.semanticGreen.withValues(alpha: 0.15)
                            : (isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAvail ? AppColors.semanticGreen : (isDark ? Colors.white30 : AppColors.creamBorder),
                        ),
                      ),
                      child: Text(
                        isAvail ? l10n.translate('active') : l10n.translate('hidden_caps'),
                        style: AppTypography.mono.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isAvail
                              ? AppColors.semanticGreen
                              : (isDark ? Colors.white70 : AppColors.creamText3),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  item.description,
                  style: TextStyle(
                    color: subtitleColor,
                  ),
                ),
                trailing: IntrinsicWidth(
                  child: Row(
                    children: [
                      Text(
                        '${item.price}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.diamond, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Switch(
                        value: isAvail,
                        activeThumbColor: AppColors.gold500,
                        onChanged: (val) async {
                          HapticService.toggle();
                          try {
                            await ref
                                .read(firebaseServiceProvider)
                                .updateShopItem(item.id, {'isAvailable': val});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val 
                                        ? l10n.translate('item_now_visible', params: {'title': item.title}) 
                                        : l10n.translate('item_now_hidden', params: {'title': item.title}),
                                  ),
                                  backgroundColor: AppColors.semanticGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              HapticService.error();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.translate('failed_update_availability', params: {'error': e.toString()})),
                                  backgroundColor: AppColors.semanticRed,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 18,
                          color: isDark ? Colors.white70 : AppColors.forest900,
                        ),
                        onPressed: () => _showShopItemDialog(item, isDark, l10n),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.semanticRed,
                        ),
                        onPressed: () => _confirmDeleteShopItem(item, isDark, l10n),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
      error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
    );
  }

  Widget _buildAddShopItemCard(bool isDark, AppLocalization l10n) {
    return GestureDetector(
      onTap: () => _showShopItemDialog(null, isDark, l10n),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.forestDarkCard : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.gold500.withValues(alpha: 0.3) : AppColors.creamBorder,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.add_shopping_cart_rounded, color: AppColors.gold500, size: 32),
            const SizedBox(height: 8),
            Text(
              l10n.translate('add_new_shop_item'), 
              style: AppTypography.label.copyWith(
                color: isDark ? AppColors.gold500 : AppColors.forest900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteShopItem(ShopItem item, bool isDark, AppLocalization l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest800 : Theme.of(context).colorScheme.surface,
        title: Text(
          l10n.translate('delete_item_title', params: {'title': item.title}), 
          style: const TextStyle(color: AppColors.gold500),
        ),
        content: Text(
          l10n.translate('delete_item_confirm', params: {'title': item.title}),
          style: TextStyle(color: isDark ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n.translate('cancel').toUpperCase(), 
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
            onPressed: () async {
              HapticService.delete();
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogCtx);
              try {
                await ref.read(firebaseServiceProvider).deleteShopItem(item.id);
                if (dialogCtx.mounted) {
                  navigator.pop();
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('item_deleted_msg', params: {'title': item.title})),
                    backgroundColor: AppColors.semanticGreen,
                  ),
                );
              } catch (e) {
                if (dialogCtx.mounted) {
                  navigator.pop();
                }
                HapticService.error();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('failed_delete_item', params: {'error': e.toString()})),
                    backgroundColor: AppColors.semanticRed,
                  ),
                );
              }
            },
            child: Text(l10n.translate('delete_caps'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showShopItemDialog([ShopItem? item, bool? isDarkParam, AppLocalization? l10nParam]) {
    final AppLocalization l10n = l10nParam ?? ref.read(localizationProvider);
    final isDark = isDarkParam ?? (Theme.of(context).brightness == Brightness.dark);
    final titleController = TextEditingController(text: item?.title ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '100');
    final iconController = TextEditingController(text: item?.icon ?? '💰');
    final typeController = TextEditingController(text: item?.type ?? 'misc');
    bool isAvailable = item?.isAvailable ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.forest800 : Theme.of(context).colorScheme.surface,
          title: Text(
            item == null 
                ? l10n.translate('new_shop_item') 
                : l10n.translate('edit_item_title', params: {'title': item.title}), 
            style: const TextStyle(color: AppColors.gold500),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandTextField(
                    controller: titleController,
                    labelText: l10n.translate('item_name_label'),
                    prefixIcon: Icons.shopping_bag_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.translate('please_enter_item_name');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  BrandTextField(
                    controller: descController,
                    labelText: l10n.translate('description_label'),
                    prefixIcon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BrandTextField(
                          controller: priceController,
                          labelText: l10n.translate('price_crystals'),
                          prefixIcon: Icons.diamond_outlined,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n.translate('enter_price');
                            }
                            final parsed = int.tryParse(val.trim());
                            if (parsed == null) {
                              return l10n.translate('invalid_number');
                            }
                            if (parsed < 0) {
                              return l10n.translate('min_price_zero');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BrandTextField(
                          controller: iconController,
                          labelText: l10n.translate('icon_emoji'),
                          prefixIcon: Icons.emoji_emotions_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BrandTextField(
                    controller: typeController,
                    labelText: l10n.translate('item_type'),
                    prefixIcon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : AppColors.creamBorder),
                    ),
                    child: SwitchListTile(
                      activeThumbColor: AppColors.gold500,
                      title: Text(
                        l10n.translate('item_availability'),
                        style: TextStyle(
                          color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        isAvailable 
                            ? l10n.translate('visible_to_learners') 
                            : l10n.translate('hidden_from_shop'),
                        style: TextStyle(
                          color: isAvailable
                              ? AppColors.gold500
                              : (isDark ? Colors.white54 : AppColors.creamText3),
                          fontSize: 11,
                        ),
                      ),
                      value: isAvailable,
                      onChanged: (val) {
                        setDialogState(() {
                          isAvailable = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx), 
              child: Text(
                l10n.translate('cancel').toUpperCase(), 
                style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest700),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final price = int.tryParse(priceController.text.trim()) ?? (item?.price ?? 100);
                  final newItem = ShopItem(
                    id: item?.id ?? '',
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    price: price,
                    icon: iconController.text.trim().isNotEmpty ? iconController.text.trim() : '💰',
                    type: typeController.text.trim().isNotEmpty ? typeController.text.trim() : 'misc',
                    isAvailable: isAvailable,
                  );
                  
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(dialogCtx);

                  try {
                    if (item == null) {
                      await ref.read(firebaseServiceProvider).addShopItem(newItem);
                    } else {
                      await ref.read(firebaseServiceProvider).updateShopItem(item.id, newItem.toFirestore());
                    }
                    if (dialogCtx.mounted) {
                      navigator.pop();
                    }
                    HapticService.success();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          item == null 
                              ? l10n.translate('item_created_success', params: {'title': newItem.title}) 
                              : l10n.translate('item_updated_success', params: {'title': newItem.title}),
                        ),
                        backgroundColor: AppColors.semanticGreen,
                      ),
                    );
                  } catch (e) {
                    HapticService.error();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.translate('failed_save_shop_item', params: {'error': e.toString()})),
                        backgroundColor: AppColors.semanticRed,
                      ),
                    );
                  }
                }
              },
              child: Text(item == null ? l10n.translate('create_caps') : l10n.translate('update_caps')),
            ),
          ],
        ),
      ),
    );
  }
}
