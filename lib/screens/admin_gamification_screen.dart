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
    _tabController = TabController(length: 3, vsync: this);
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
          indicatorColor: AppColors.gold500,
          labelColor: AppColors.gold500,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'SEASONS', icon: Icon(Icons.calendar_month_rounded)),
            Tab(text: 'SHOP', icon: Icon(Icons.shopping_bag_rounded)),
            Tab(text: 'DUELS', icon: Icon(Icons.swords)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeasonsTab(),
          _buildShopTab(),
          _buildDuelsTab(),
        ],
      ),
    );
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
        subtitle: Text(
          '${DateFormat('MMM d').format(season.startDate)} - ${DateFormat('MMM d, y').format(season.endDate)}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Switch(
          value: season.isActive,
          activeColor: AppColors.gold500,
          onChanged: (val) => ref.read(firebaseServiceProvider).updateSeason(season.id, {'isActive': val}),
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
    DateTime start = existing?.startDate ?? DateTime.now();
    DateTime end = existing?.endDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: Text(existing == null ? 'New Season' : 'Edit Season', style: const TextStyle(color: AppColors.gold500)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Season Title', labelStyle: TextStyle(color: Colors.white70)),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Dates', style: TextStyle(color: Colors.white)),
              subtitle: Text('${DateFormat('yMMMd').format(start)} - ${DateFormat('yMMMd').format(end)}', style: const TextStyle(color: Colors.white70)),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    start = picked.start;
                    end = picked.end;
                  });
                }
              },
            ),
          ],
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
                badgeId: 'seasonal_badge_${titleController.text.toLowerCase().replaceAll(' ', '_')}',
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
    );
  }

  Widget _buildShopTab() {
    final shopAsync = ref.watch(shopItemsStreamProvider);
    return shopAsync.when(
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return BrandCard(
            theme: BrandCardTheme.cream,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Text(item.icon, style: const TextStyle(fontSize: 28)),
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

  void _showShopItemDialog(ShopItem item) {
    final priceController = TextEditingController(text: item.price.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: Text('Edit ${item.title} Price', style: const TextStyle(color: AppColors.gold500)),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price (Crystals)', labelStyle: TextStyle(color: Colors.white70)),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(firebaseServiceProvider).updateShopItem(item.id, {
                'price': int.parse(priceController.text),
              });
              Navigator.pop(context);
            },
            child: const Text('UPDATE'),
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
