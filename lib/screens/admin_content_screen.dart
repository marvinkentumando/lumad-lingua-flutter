import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/badges.dart';
import '../models/admin_models.dart';
import '../services/haptic_service.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});
  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final Map<String, bool> _dialectToggles = {
    'Mansaka': true,
    'Mandaya': true,
    'Manobo': true,
    'Bagobo': true,
    'Kagan': false,
  };

  final List<ContentEntry> _content = [
    ContentEntry(
      id: 'c1',
      term: 'Maayong Buntag',
      dialect: 'Mansaka',
      partOfSpeech: 'phrase',
      status: 'validated',
      contributorName: 'Elder V.',
      submittedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ContentEntry(
      id: 'c2',
      term: 'Kagawasan',
      dialect: 'Manobo',
      partOfSpeech: 'noun',
      status: 'validated',
      contributorName: 'Teacher J.',
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ContentEntry(
      id: 'c3',
      term: 'Buntag',
      dialect: 'Mandaya',
      partOfSpeech: 'noun',
      status: 'pending',
      contributorName: 'Maria M.',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ContentEntry(
      id: 'c4',
      term: 'Lipad',
      dialect: 'Mansaka',
      partOfSpeech: 'verb',
      status: 'validated',
      contributorName: 'Datu M.',
      submittedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ContentEntry(
      id: 'c5',
      term: 'Buklod',
      dialect: 'Bagobo',
      partOfSpeech: 'noun',
      status: 'pending',
      contributorName: 'Agila M.',
      submittedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    ContentEntry(
      id: 'c6',
      term: 'Kalayo',
      dialect: 'Kagan',
      partOfSpeech: 'noun',
      status: 'rejected',
      contributorName: 'Juan D.',
      rejectionReason: 'Duplicate entry',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<ContentEntry> get _filtered {
    if (_searchQuery.isEmpty) return _content;
    return _content
        .where(
          (c) =>
              c.term.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.contributorName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pending = filtered.where((c) => c.status == 'pending').toList();
    final published = filtered.where((c) => c.status == 'validated').toList();
    final rejected = filtered.where((c) => c.status == 'rejected').toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/topo_map.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search terms or contributors...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : AppColors.creamText3,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.gold500,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark 
                          ? AppColors.forest800.withValues(alpha: 0.5)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.creamBorder,
                        ),
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _sectionLabel('REVIEW QUEUE (${pending.length})'),
                        const SizedBox(height: 16),
                        ...pending.asMap().entries.map(
                          (e) => _contentCard(e.value, e.key),
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (published.isNotEmpty) ...[
                        _sectionLabel('PUBLISHED (${published.length})'),
                        const SizedBox(height: 16),
                        ...published.asMap().entries.map(
                          (e) => _contentCard(e.value, e.key + pending.length),
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (rejected.isNotEmpty) ...[
                        _sectionLabel('REJECTED (${rejected.length})'),
                        const SizedBox(height: 16),
                        ...rejected.asMap().entries.map(
                          (e) => _contentCard(
                            e.value,
                            e.key + pending.length + published.length,
                          ),
                        ),
                      ],
                      if (filtered.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.search_off_rounded,
                                  color: Colors.white10,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No matching content.',
                                  style: AppTypography.h3.copyWith(
                                    color: Colors.white24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.forest900.withValues(alpha: 0.8)
            : AppColors.creamBg,
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.creamBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold500.withValues(alpha: 0.2),
              ),
            ),
            child: const Text('🛡️', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN CONSOLE',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Content Moderation',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: const Icon(
                Icons.settings_suggest_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
            onPressed: _showSystemActionsModal,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: AppTypography.mono.copyWith(
      color: isDark ? Colors.white24 : AppColors.creamText3,
      fontSize: 9,
      letterSpacing: 2,
    ),
  );

  Widget _contentCard(ContentEntry data, int index) {
    final status = data.status;
    final badgeStyle = status == 'validated'
        ? BrandBadgeStyle.green
        : status == 'rejected'
        ? BrandBadgeStyle.dark
        : BrandBadgeStyle.gold;
    final badgeText = status == 'validated'
        ? '✓ Published'
        : status == 'rejected'
        ? '✗ Rejected'
        : '⏳ Pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child:
          Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.forest700.withValues(alpha: 0.3)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.creamBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              (status == 'pending'
                                      ? AppColors.gold500
                                      : status == 'rejected'
                                      ? AppColors.semanticRed
                                      : AppColors.semanticBlue)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          status == 'pending'
                              ? Icons.rate_review_outlined
                              : status == 'rejected'
                              ? Icons.cancel_outlined
                              : Icons.auto_awesome_outlined,
                          color: status == 'pending'
                              ? AppColors.gold500
                              : status == 'rejected'
                              ? AppColors.semanticRed
                              : AppColors.semanticBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.term,
                              style: AppTypography.h3.copyWith(
                                color: isDark ? Colors.white : AppColors.forest500,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${data.dialect} · ${data.partOfSpeech}',
                                  style: AppTypography.label.copyWith(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '·',
                                  style: TextStyle(color: Colors.white12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'by ${data.contributorName}',
                                  style: AppTypography.mono.copyWith(
                                    color: AppColors.gold500.withValues(
                                      alpha: 0.4,
                                    ),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            if (data.rejectionReason != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Reason: ${data.rejectionReason}',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.semanticRed.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          BrandBadge(text: badgeText, style: badgeStyle),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (status == 'pending') ...[
                                _actionIcon(
                                  Icons.check_circle_rounded,
                                  () => _approveContent(data),
                                  color: AppColors.semanticGreen,
                                ),
                                const SizedBox(width: 8),
                                _actionIcon(
                                  Icons.cancel_rounded,
                                  () => _rejectContent(data),
                                  color: AppColors.semanticRed,
                                ),
                                const SizedBox(width: 8),
                              ],
                              _actionIcon(
                                Icons.edit_note_rounded,
                                () => _showEditContentForm(data),
                              ),
                              const SizedBox(width: 8),
                              _actionIcon(
                                Icons.delete_sweep_rounded,
                                () => _deleteContent(data),
                                color: AppColors.semanticRed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 60))
              .slideX(begin: 0.05),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Colors.white70, size: 18),
      ),
    );
  }

  void _approveContent(ContentEntry data) {
    setState(() => data.status = 'validated');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${data.term}" approved'),
        backgroundColor: AppColors.semanticGreen,
      ),
    );
  }

  void _rejectContent(ContentEntry data) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reject "${data.term}"?',
          style: AppTypography.h3.copyWith(color: AppColors.semanticRed),
        ),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Reason for rejection',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: AppColors.forest800,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          BrandButton(
            text: 'Reject',
            type: BrandButtonType.primary,
            onTap: () {
              Navigator.pop(ctx);
              setState(() {
                data.status = 'rejected';
                data.rejectionReason = reasonCtrl.text.isNotEmpty
                    ? reasonCtrl.text
                    : 'No reason provided';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${data.term}" rejected'),
                  backgroundColor: AppColors.semanticRed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _deleteContent(ContentEntry data) {
    _showConfirmAction(
      'Delete "${data.term}"?',
      'This action cannot be undone.',
      () {
        setState(() => _content.removeWhere((c) => c.id == data.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${data.term}" deleted'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      },
    );
  }

  void _showEditContentForm(ContentEntry data) {
    final termCtrl = TextEditingController(text: data.term);
    final dialectCtrl = TextEditingController(text: data.dialect);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest700,
        title: Text(
          'Edit Content',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: termCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Term',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: AppColors.forest800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dialectCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Dialect',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: AppColors.forest800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          BrandButton(
            text: 'Save Changes',
            type: BrandButtonType.primary,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                data.term = termCtrl.text;
                data.dialect = dialectCtrl.text;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Content updated')));
            },
          ),
        ],
      ),
    );
  }

  void _showSystemActionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.forest900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SYSTEM ACTIONS',
              style: AppTypography.label.copyWith(
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _systemAction(
              icon: Icons.language_rounded,
              color: AppColors.semanticBlue,
              title: 'Dialect Settings',
              subtitle: 'Enable or disable dialects',
              onTap: () {
                Navigator.pop(context);
                _showDialectSettings();
              },
            ),
            const Divider(color: Colors.white10),
            _systemAction(
              icon: Icons.download_outlined,
              color: AppColors.semanticGreen,
              title: 'Export to CSV',
              subtitle: 'Copy all entries as CSV',
              onTap: () {
                Navigator.pop(context);
                _exportData('csv');
              },
            ),
            const Divider(color: Colors.white10),
            _systemAction(
              icon: Icons.code_outlined,
              color: AppColors.gold500,
              title: 'Export to JSON',
              subtitle: 'Copy all entries as JSON',
              onTap: () {
                Navigator.pop(context);
                _exportData('json');
              },
            ),
            const Divider(color: Colors.white10),
            _systemAction(
              icon: Icons.cleaning_services_outlined,
              color: AppColors.semanticBlue,
              title: 'Clear App Cache',
              subtitle: 'Remove locally cached data',
              onTap: () {
                Navigator.pop(context);
                _showConfirmAction(
                  'Clear Cache',
                  'This will clear all locally cached content.',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache cleared'),
                        backgroundColor: AppColors.semanticGreen,
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(color: Colors.white10),
            _systemAction(
              icon: Icons.warning_amber_outlined,
              color: AppColors.semanticRed,
              title: 'Reset Platform',
              subtitle: 'Danger: wipe all pending submissions',
              onTap: () {
                Navigator.pop(context);
                _showConfirmAction(
                  'Reset Platform',
                  'This will permanently delete ALL pending submissions.',
                  () {
                    setState(
                      () => _content.removeWhere((c) => c.status == 'pending'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pending submissions cleared'),
                        backgroundColor: AppColors.semanticRed,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDialectSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.forest700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Dialect Settings',
            style: AppTypography.h3.copyWith(color: AppColors.gold500),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _dialectToggles.entries
                .map(
                  (e) => SwitchListTile(
                    title: Text(
                      e.key,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: e.value
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    value: e.value,
                    activeThumbColor: AppColors.gold500,
                    onChanged: (v) {
                      HapticService.light();
                      setDialogState(() => _dialectToggles[e.key] = v);
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            BrandButton(
              text: 'Save',
              type: BrandButtonType.primary,
              onTap: () {
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dialect settings saved'),
                    backgroundColor: AppColors.semanticGreen,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.body.copyWith(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.label.copyWith(
          color: Colors.white38,
          fontSize: 11,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      onTap: onTap,
    );
  }

  void _showConfirmAction(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest700,
        title: Text(
          title,
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          BrandButton(
            text: 'Confirm',
            type: BrandButtonType.primary,
            onTap: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  void _exportData(String format) {
    final data = _content
        .map(
          (e) => {
            'term': e.term,
            'dialect': e.dialect,
            'pos': e.partOfSpeech,
            'status': e.status,
          },
        )
        .toList();
    String output;
    if (format == 'json') {
      output = const JsonEncoder.withIndent('  ').convert(data);
    } else {
      final rows =
          ['term,dialect,pos,status'] +
          data
              .map(
                (e) =>
                    '${e['term']},${e['dialect']},${e['pos']},${e['status']}',
              )
              .toList();
      output = rows.join('\n');
    }
    Clipboard.setData(ClipboardData(text: output));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${format.toUpperCase()} copied to clipboard (${data.length} entries)',
        ),
        backgroundColor: AppColors.semanticGreen,
      ),
    );
  }
}
