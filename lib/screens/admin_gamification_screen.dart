import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/gamification_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_box.dart';
import '../widgets/brand_card.dart';
import 'package:intl/intl.dart'; 

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest900,
      appBar: AppBar(
        title: Text('GAMIFICATION & ECONOMICS', style: AppTypography.h3.copyWith(color: AppColors.gold500)),
        backgroundColor: AppColors.forest900,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.gold500,
          labelColor: AppColors.gold500,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'SEASONS', icon: Icon(Icons.calendar_month_rounded)),
            Tab(text: 'REWARDS', icon: Icon(Icons.military_tech_rounded)),
            Tab(text: 'SHOP', icon: Icon(Icons.shopping_bag_rounded)),
            Tab(text: 'DUELS', icon: Icon(Icons.bolt_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeasonsTab(),
          _buildRewardsTab(),
          _buildShopTab(),
          _buildDuelsTab(),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRewardCategory('CONTRIBUTIONS', [
            _rewardTile('Word Approval', config.wordApprovalXp, (val) => _updateConfig('wordApprovalXp', val)),
            _rewardTile('Lesson Approval', config.lessonApprovalXp, (val) => _updateConfig('lessonApprovalXp', val)),
          ]),
          const SizedBox(height: 24),
          _buildRewardCategory('LEARNING PATH', [
            _rewardTile('Lesson Completion (Base)', config.lessonCompletionBaseXp, (val) => _updateConfig('lessonCompletionBaseXp', val)),
            _rewardTile('Perfect Task Bonus', config.lessonTaskPerfectXp, (val) => _updateConfig('lessonTaskPerfectXp', val)),
            _rewardTile('Task Retry Reward', config.lessonTaskRetryXp, (val) => _updateConfig('lessonTaskRetryXp', val)),
          ]),
          const SizedBox(height: 24),
          _buildRewardCategory('DAILY RITUALS', [
            _rewardTile('SRS Card Review', config.cardReviewXp, (val) => _updateConfig('cardReviewXp', val)),
            _rewardTile('SRS Completion Bonus (per card)', config.cardCompletionBonusXp, (val) => _updateConfig('cardCompletionBonusXp', val)),
          ]),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildRewardCategory(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.mono.copyWith(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 12),
        GlassBox(
          borderRadius: 16,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _rewardTile(String label, int value, Function(int) onUpdate) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value XP', style: const TextStyle(color: AppColors.gold500, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.white60),
            onPressed: () => _showRewardEditDialog(label, value, onUpdate),
          ),
        ],
      ),
    );
  }

  void _showRewardEditDialog(String label, int currentValue, Function(int) onUpdate) {
    final controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: Text('Edit $label', style: const TextStyle(color: AppColors.gold500)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'XP Points',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              onUpdate(int.parse(controller.text));
              Navigator.pop(context);
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateConfig(String key, int value) async {
    await ref.read(firebaseServiceProvider).updateAppConfig({key: value});
  }

  Widget _buildSeasonsTab() {
    final seasonsAsync = ref.watch(seasonsStreamProvider);
    return seasonsAsync.when(
      data: (seasons) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: seasons.length + 1,
        itemBuilder: (context, index) {
          if (index == seasons.length) {
            return _buildAddSeasonCard();
          }
          final season = seasons[index];
          return _buildSeasonCard(season);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildSeasonCard(LearningSeason season) {
    return BrandCard(
      theme: season.isActive ? BrandCardTheme.gold : BrandCardTheme.vibrant,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(season.title, style: AppTypography.h3.copyWith(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('MMM d').format(season.startDate)} - ${DateFormat('MMM d, y').format(season.endDate)}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text('Badge ID: ${season.badgeId}', style: const TextStyle(color: Colors.white60, fontSize: 12)),ze: 10)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: () => _showSeasonDialog(season),
            ),
            Switch(
              value: season.isActive,
              activeThumbColor: AppColors.gold500,
              onChanged: (val) => ref.read(firebaseServiceProvider).updateSeason(season.id, {'isActive': val}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSeasonCard() {
    return GestureDetector(
      onTap: () => _showSeasonDialog(),
      child: GlassBox(
        borderRadius: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.add_circle_outline_rounded, color: AppColors.gold500, size: 32),
              const SizedBox(height: 8),
              Text('CREATE NEW SEASON', style: AppTypography.label.copyWith(color: AppColors.gold500)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSeasonDialog([LearningSeason? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final badgeIdController = TextEditingController(text: existing?.badgeId ?? '');
    DateTime start = existing?.startDate ?? DateTime.now();
    DateTime end = existing?.endDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.forest800,
          title: Text(existing == null ? 'New Season' : 'Edit Season', style: const TextStyle(color: AppColors.gold500)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Season Title', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: badgeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Badge ID / Asset Path', 
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'e.g. seasonal_badge_harvest',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Dates', style: TextStyle(color: Colors.white)),
                  subtitle: Text('${DateFormat('yMMMd').format(start)} - ${DateFormat('yMMMd').format(end)}', style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.gold500),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: DateTimeRange(start: start, end: end),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        start = picked.start;
                        end = picked.end;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                final season = LearningSeason(
                  id: existing?.id ?? '',
                  title: titleController.text,
                  startDate: start,
                  endDate: end,
                  badgeId: badgeIdController.text.isNotEmpty 
                      ? badgeIdController.text 
                      : 'seasonal_badge_${titleController.text.toLowerCase().replaceAll(' ', '_')}',
                  isActive: existing?.isActive ?? false,
                );
                if (existing == null) {
                  ref.read(firebaseServiceProvider).addSeason(season);
                } else {
                  ref.read(firebaseServiceProvider).updateSeason(existing.id, season.toFirestore());
                }
                Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopTab() {
    final shopAsync = ref.watch(shopItemsStreamProvider);
    return shopAsync.when(
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _buildAddShopItemCard();
          }
          final item = items[index];
          return BrandCard(
            theme: BrandCardTheme.cream,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.forest900.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: item.icon.length < 3 
                    ? Text(item.icon, style: const TextStyle(fontSize: 24))
                    : const Icon(Icons.inventory_2_rounded, color: AppColors.forest900),
              ),
              title: Text(item.title, style: AppTypography.h3.copyWith(color: AppColors.forest900)),
              subtitle: Text(item.description, style: const TextStyle(color: AppColors.forest500)),
              trailing: IntrinsicWidth(
                child: Row(
                  children: [
                    Text('${item.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest900)),
                    const SizedBox(width: 4),
                    const Icon(Icons.diamond, size: 16, color: Colors.blue),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showShopItemDialog(item),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAddShopItemCard() {
    return GestureDetector(
      onTap: () => _showShopItemDialog(),
      child: GlassBox(
        borderRadius: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.add_shopping_cart_rounded, color: AppColors.gold500, size: 32),
              const SizedBox(height: 8),
              Text('ADD NEW SHOP ITEM', style: AppTypography.label.copyWith(color: AppColors.gold500)),
            ],
          ),
        ),
      ),
    );
  }

  void _showShopItemDialog([ShopItem? item]) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '100');
    final iconController = TextEditingController(text: item?.icon ?? '💰');
    final typeController = TextEditingController(text: item?.type ?? 'misc');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: Text(item == null ? 'New Shop Item' : 'Edit ${item.title}', style: const TextStyle(color: AppColors.gold500)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Item Name', labelStyle: TextStyle(color: Colors.white70)),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white70)),
                style: const TextStyle(color: Colors.white),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (Crystals)', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: iconController,
                      decoration: const InputDecoration(labelText: 'Icon/Emoji', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(labelText: 'Item Type', labelStyle: TextStyle(color: Colors.white70)),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final newItem = ShopItem(
                id: item?.id ?? '',
                title: titleController.text,
                description: descController.text,
                price: int.parse(priceController.text),
                icon: iconController.text,
                type: typeController.text,
              );
              
              if (item == null) {
                ref.read(firebaseServiceProvider).addShopItem(newItem);
              } else {
                ref.read(firebaseServiceProvider).updateShopItem(item.id, newItem.toFirestore());
              }
              Navigator.pop(context);
            },
            child: Text(item == null ? 'CREATE' : 'UPDATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDuelsTab() {
    final duelsAsync = ref.watch(linguaDuelsStreamProvider);
    return duelsAsync.when(
      data: (duels) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: duels.length,
        itemBuilder: (context, index) {
          final duel = duels[index];
          final isFlagged = duel['flagged'] == true;
          return BrandCard(
            theme: isFlagged ? BrandCardTheme.vibrant : BrandCardTheme.cream,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${duel['player1Name']} vs ${duel['player2Name']}', style: TextStyle(color: isFlagged ? Colors.white : AppColors.forest900)),
              subtitle: Text('Status: ${duel['status']}', style: TextStyle(color: isFlagged ? Colors.white70 : AppColors.forest500)),
              trailing: isFlagged 
                ? IconButton(
                    icon: const Icon(Icons.gavel_rounded, color: AppColors.gold500),
                    onPressed: () => _showDuelResolutionDialog(duel['id']),
                  )
                : null,
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showDuelResolutionDialog(String duelId) {
    final resolutionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: const Text('Resolve Duel Dispute', style: TextStyle(color: AppColors.gold500)),
        content: TextField(
          controller: resolutionController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter resolution details...', hintStyle: TextStyle(color: Colors.white24)),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(firebaseServiceProvider).resolveDuelDispute(duelId, resolutionController.text);
              Navigator.pop(context);
            },
            child: const Text('RESOLVE'),
          ),
        ],
      ),
    );
  }
}
