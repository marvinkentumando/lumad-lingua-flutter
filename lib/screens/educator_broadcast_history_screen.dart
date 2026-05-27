import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/firebase_service.dart';
import '../models/broadcast.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/branded_empty_state.dart';

class EducatorBroadcastHistoryScreen extends ConsumerWidget {
  const EducatorBroadcastHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastsAsync = ref.watch(broadcastsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Broadcast History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.forest900,
      ),
      body: AmbientTopoBackground(
        child: broadcastsAsync.when(
          data: (broadcasts) {
            if (broadcasts.isEmpty) {
              return const BrandedEmptyState(
                title: 'No Broadcasts Found',
                message: 'You haven\'t sent any village announcements yet.',
                icon: Icons.campaign_outlined,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: broadcasts.length,
              itemBuilder: (context, index) {
                final broadcast = broadcasts[index];
                return _BroadcastCard(broadcast: broadcast);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold500),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading history: $err'),
          ),
        ),
      ),
    );
  }
}

class _BroadcastCard extends ConsumerStatefulWidget {
  final VillageBroadcast broadcast;
  const _BroadcastCard({required this.broadcast});

  @override
  ConsumerState<_BroadcastCard> createState() => _BroadcastCardState();
}

class _BroadcastCardState extends ConsumerState<_BroadcastCard> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.broadcast.message);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(widget.broadcast.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.broadcast.title,
                    style: AppTypography.h3.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white24 : AppColors.creamText3,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing) {
                          _controller.text = widget.broadcast.message;
                        }
                      });
                    },
                    icon: Icon(
                      _isEditing ? Icons.close_rounded : Icons.edit_note_rounded,
                      color: AppColors.gold500,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.terracotta,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing)
            Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: null,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.creamText,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppColors.forest800 : AppColors.creamBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (_controller.text.trim().isEmpty) return;
                        await ref
                            .read(firebaseServiceProvider)
                            .updateVillageBroadcast(
                              widget.broadcast.id,
                              _controller.text.trim(),
                            );
                        setState(() => _isEditing = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        foregroundColor: AppColors.forest900,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              widget.broadcast.message,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white70 : AppColors.creamText2,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.gold500),
                const SizedBox(width: 6),
                Text(
                  'Sent to ${widget.broadcast.recipients.length} students',
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white38 : AppColors.creamText3,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.forestDarkCard
            : Colors.white,
        title: const Text('Delete Broadcast?'),
        content: const Text(
          'This will remove the announcement from history. It will not delete individual notifications already sent to students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(firebaseServiceProvider)
                  .deleteVillageBroadcast(widget.broadcast.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
