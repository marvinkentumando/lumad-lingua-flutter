import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../models/gamification_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('GAMIFICATION & ECONOMICS', style: AppTypography.h3.copyWith(color: AppColors.gold500)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: AppColors.gold500,
          labelColor: AppColors.gold500,
          unselectedLabelColor: isDark ? Colors.white60 : Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'REWARDS', icon: Icon(Icons.military_tech_rounded)),
            Tab(text: 'SHOP', icon: Icon(Icons.shopping_bag_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRewardsTab(isDark),
          _buildShopTab(isDark),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(bool isDark) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRewardCategory('CONTRIBUTIONS', [
            _rewardTile('Word Approval', config.wordApprovalXp, (val) => _updateConfig('wordApprovalXp', val, 'Word Approval'), isDark),
            _rewardTile('Lesson Approval', config.lessonApprovalXp, (val) => _updateConfig('lessonApprovalXp', val, 'Lesson Approval'), isDark),
          ], isDark),
          const SizedBox(height: 24),
          _buildRewardCategory('LEARNING PATH', [
            _rewardTile('Lesson Completion (Base)', config.lessonCompletionBaseXp, (val) => _updateConfig('lessonCompletionBaseXp', val, 'Lesson Completion (Base)'), isDark),
            _rewardTile('Perfect Task Bonus', config.lessonTaskPerfectXp, (val) => _updateConfig('lessonTaskPerfectXp', val, 'Perfect Task Bonus'), isDark),
            _rewardTile('Task Retry Reward', config.lessonTaskRetryXp, (val) => _updateConfig('lessonTaskRetryXp', val, 'Task Retry Reward'), isDark),
          ], isDark),
          const SizedBox(height: 24),
          _buildRewardCategory('DAILY RITUALS', [
            _rewardTile('SRS Card Review', config.cardReviewXp, (val) => _updateConfig('cardReviewXp', val, 'SRS Card Review'), isDark),
            _rewardTile('SRS Completion Bonus (per card)', config.cardCompletionBonusXp, (val) => _updateConfig('cardCompletionBonusXp', val, 'SRS Completion Bonus'), isDark),
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

  Widget _rewardTile(String label, int value, Function(int) onUpdate, bool isDark) {
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
            onPressed: () => _showRewardEditDialog(label, value, onUpdate, isDark),
          ),
        ],
      ),
    );
  }

  void _showRewardEditDialog(String label, int currentValue, Function(int) onUpdate, bool isDark) {
    final controller = TextEditingController(text: currentValue.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest800 : Theme.of(context).colorScheme.surface,
        title: Text('Edit $label', style: const TextStyle(color: AppColors.gold500)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandTextField(
                controller: controller,
                labelText: 'XP Points',
                prefixIcon: Icons.stars_rounded,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an XP value';
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null) {
                    return 'Please enter a valid whole number';
                  }
                  if (parsed < 0) {
                    return 'XP cannot be negative';
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
            child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest700)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final parsed = int.tryParse(controller.text.trim()) ?? currentValue;
                Navigator.pop(dialogCtx);
                await onUpdate(parsed);
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateConfig(String key, int value, [String? label]) async {
    try {
      await ref.read(firebaseServiceProvider).updateAppConfig({key: value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${label ?? key} updated to $value XP'),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ${label ?? key}: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  Widget _buildShopTab(bool isDark) {
    final shopAsync = ref.watch(shopItemsStreamProvider);
    return shopAsync.when(
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _buildAddShopItemCard(isDark);
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
                        isAvail ? 'ACTIVE' : 'HIDDEN',
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
                                    val ? '"${item.title}" is now visible in shop.' : '"${item.title}" is now hidden from shop.',
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
                                  content: Text('Failed to update availability: $e'),
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
                        onPressed: () => _showShopItemDialog(item, isDark),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.semanticRed,
                        ),
                        onPressed: () => _confirmDeleteShopItem(item, isDark),
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

  Widget _buildAddShopItemCard(bool isDark) {
    return GestureDetector(
      onTap: () => _showShopItemDialog(null, isDark),
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
              'ADD NEW SHOP ITEM', 
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

  void _confirmDeleteShopItem(ShopItem item, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest800 : Theme.of(context).colorScheme.surface,
        title: Text('Delete ${item.title}', style: const TextStyle(color: AppColors.gold500)),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest700)),
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
                    content: Text('"${item.title}" has been deleted.'),
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
                    content: Text('Failed to delete shop item: $e'),
                    backgroundColor: AppColors.semanticRed,
                  ),
                );
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showShopItemDialog([ShopItem? item, bool? isDarkParam]) {
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
          title: Text(item == null ? 'New Shop Item' : 'Edit ${item.title}', style: const TextStyle(color: AppColors.gold500)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandTextField(
                    controller: titleController,
                    labelText: 'Item Name',
                    prefixIcon: Icons.shopping_bag_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  BrandTextField(
                    controller: descController,
                    labelText: 'Description',
                    prefixIcon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BrandTextField(
                          controller: priceController,
                          labelText: 'Price (Crystals)',
                          prefixIcon: Icons.diamond_outlined,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter price';
                            }
                            final parsed = int.tryParse(val.trim());
                            if (parsed == null) {
                              return 'Invalid number';
                            }
                            if (parsed < 0) {
                              return 'Min price 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BrandTextField(
                          controller: iconController,
                          labelText: 'Icon/Emoji',
                          prefixIcon: Icons.emoji_emotions_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BrandTextField(
                    controller: typeController,
                    labelText: 'Item Type',
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
                        'Item Availability',
                        style: TextStyle(
                          color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        isAvailable ? 'Visible to learners in Ancestral Vault' : 'Hidden from shop catalog',
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
              child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest700)),
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
                        content: Text(item == null ? '"${newItem.title}" created successfully!' : '"${newItem.title}" updated successfully!'),
                        backgroundColor: AppColors.semanticGreen,
                      ),
                    );
                  } catch (e) {
                    HapticService.error();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to save shop item: $e'),
                        backgroundColor: AppColors.semanticRed,
                      ),
                    );
                  }
                }
              },
              child: Text(item == null ? 'CREATE' : 'UPDATE'),
            ),
          ],
        ),
      ),
    );
  }
}
