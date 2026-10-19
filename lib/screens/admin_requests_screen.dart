import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/contributor_request.dart';
import '../providers/contributor_request_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_card.dart';
import '../utils/app_localization.dart';

class AdminRequestsScreen extends ConsumerWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final requestsAsync = ref.watch(contributorRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.forest900,
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
                _buildHeader(context, l10n),
                Expanded(
                  child: requestsAsync.when(
                    data: (requests) {
                      final pending = requests
                          .where((r) => r.status == 'pending')
                          .toList();
                      final history = requests
                          .where((r) => r.status != 'pending')
                          .toList();

                      if (requests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.mark_email_read_rounded,
                                color: Colors.white10,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.translate('no_requests_found'),
                                style: AppTypography.h3.copyWith(
                                  color: Colors.white24,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (pending.isNotEmpty) ...[
                            _sectionLabel(l10n.translate('pending_requests')),
                            const SizedBox(height: 16),
                            ...pending.asMap().entries.map(
                              (e) => _requestCard(
                                context,
                                ref,
                                e.value,
                                e.key,
                                l10n,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          if (history.isNotEmpty) ...[
                            _sectionLabel(l10n.translate('processed_history')),
                            const SizedBox(height: 16),
                            ...history.asMap().entries.map(
                              (e) => _historyTile(e.value, l10n),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold500,
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        l10n.translate('error_prefix', params: {'error': '$err'}),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.forest900.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('contributor_requests'),
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  l10n.translate('review_approve_guardians'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: AppTypography.mono.copyWith(
      color: Colors.white24,
      fontSize: 9,
      letterSpacing: 2,
    ),
  );

  Widget _requestCard(
    BuildContext context,
    WidgetRef ref,
    ContributorRequest request,
    int index,
    AppLocalization l10n,
  ) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BrandCard(
            theme: BrandCardTheme.vibrant,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.gold500.withValues(alpha: 0.1,
                        ),
                        child: Text(
                          request.username.isNotEmpty ? request.username[0] : '?',
                          style: const TextStyle(
                            color: AppColors.gold500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.username,
                              style: AppTypography.h3.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              request.userEmail,
                              style: AppTypography.body.copyWith(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(request.createdAt, l10n),
                        style: AppTypography.mono.copyWith(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (request.message != null &&
                      request.message!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.message!,
                        style: AppTypography.body.copyWith(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: BrandButton(
                          text: l10n.translate('reject_caps'),
                          type: BrandButtonType.secondary,
                          onTap: () => _processRequest(
                            context,
                            ref,
                            request,
                            'rejected',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BrandButton(
                          text: l10n.translate('approve_caps'),
                          type: BrandButtonType.primary,
                          onTap: () => _processRequest(
                            context,
                            ref,
                            request,
                            'approved',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideY(begin: 0.1);
  }

  Widget _historyTile(ContributorRequest request, AppLocalization l10n) {
    final isApproved = request.status == 'approved';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forest700.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isApproved ? AppColors.semanticGreen : AppColors.semanticRed,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.username,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  request.userEmail,
                  style: AppTypography.body.copyWith(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            l10n.translate('status_${request.status.toLowerCase()}').toUpperCase(),
            style: AppTypography.mono.copyWith(
              color: isApproved
                  ? AppColors.semanticGreen
                  : AppColors.semanticRed,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt, AppLocalization l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return l10n.translate('mins_ago', params: {'mins': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return l10n.translate('hours_ago', params: {'hours': '${diff.inHours}'});
    }
    return l10n.translate('days_ago', params: {'days': '${diff.inDays}'});
  }

  void _processRequest(
    BuildContext context,
    WidgetRef ref,
    ContributorRequest request,
    String status,
  ) async {
    final l10n = ref.read(localizationProvider);
    final actionWord = status == 'approved'
        ? l10n.translate('approved')
        : l10n.translate('rejected');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest700,
        title: Text(
          status == 'approved'
              ? l10n.translate('approve_request_title')
              : l10n.translate('reject_request_title'),
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        content: Text(
          l10n.translate('confirm_process_request', params: {
            'action': actionWord,
            'username': request.username,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.translate('cancel_caps'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          BrandButton(
            text: l10n.translate('confirm_caps'),
            type: BrandButtonType.primary,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(firebaseServiceProvider)
          .updateContributorRequestStatus(request.id, request.userId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate('request_processed_msg', params: {
                'status': actionWord,
                'username': request.username,
              }),
            ),
            backgroundColor: status == 'approved'
                ? AppColors.semanticGreen
                : AppColors.semanticRed,
          ),
        );
      }
    }
  }
}
