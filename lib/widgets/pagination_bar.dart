import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/haptic_service.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final bool isDark;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    this.pageSizeOptions = const [12, 24, 48, 96],
    required this.onPageChanged,
    required this.onPageSizeChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final startItem = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final endItem = (currentPage * pageSize).clamp(0, totalItems);

    final textColor = isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7);
    final borderColor = isDark ? Colors.white10 : AppColors.forest900.withValues(alpha: 0.1);
    final cardBg = isDark ? AppColors.forest800 : Colors.white.withValues(alpha: 0.9);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: isDesktop ? 12 : 8,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items counter & Page size dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $startItem–$endItem of $totalItems',
                style: AppTypography.caption.copyWith(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Text(
                    'Per page: ',
                    style: AppTypography.caption.copyWith(
                      color: textColor,
                      fontSize: 11,
                    ),
                  ),
                  DropdownButton<int>(
                    value: pageSizeOptions.contains(pageSize) ? pageSize : pageSizeOptions.first,
                    dropdownColor: isDark ? AppColors.forest800 : AppColors.creamBg,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    style: TextStyle(
                      color: isDark ? AppColors.gold500 : AppColors.forest900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    items: pageSizeOptions.map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null && val != pageSize) {
                        HapticService.selection();
                        onPageSizeChanged(val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),

          if (!isDesktop) const SizedBox(height: 8),

          // Page navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First page
              IconButton(
                icon: const Icon(Icons.first_page_rounded, size: 20),
                color: currentPage > 1 ? (isDark ? AppColors.gold500 : AppColors.forest900) : textColor.withValues(alpha: 0.3),
                onPressed: currentPage > 1 ? () => _goToPage(1) : null,
                tooltip: 'First Page',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              // Previous page
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: currentPage > 1 ? (isDark ? AppColors.gold500 : AppColors.forest900) : textColor.withValues(alpha: 0.3),
                onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
                tooltip: 'Previous Page',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(width: 4),

              // Page numbers (smart window)
              ..._buildPageNumbers(isDark),

              const SizedBox(width: 4),

              // Next page
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: currentPage < totalPages ? (isDark ? AppColors.gold500 : AppColors.forest900) : textColor.withValues(alpha: 0.3),
                onPressed: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
                tooltip: 'Next Page',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              // Last page
              IconButton(
                icon: const Icon(Icons.last_page_rounded, size: 20),
                color: currentPage < totalPages ? (isDark ? AppColors.gold500 : AppColors.forest900) : textColor.withValues(alpha: 0.3),
                onPressed: currentPage < totalPages ? () => _goToPage(totalPages) : null,
                tooltip: 'Last Page',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    HapticService.selection();
    onPageChanged(page);
  }

  List<Widget> _buildPageNumbers(bool isDark) {
    final List<Widget> pages = [];
    final int maxVisible = 5;

    int start = (currentPage - (maxVisible ~/ 2)).clamp(1, totalPages);
    int end = (start + maxVisible - 1).clamp(1, totalPages);

    if (end - start + 1 < maxVisible) {
      start = (end - maxVisible + 1).clamp(1, totalPages);
    }

    for (int i = start; i <= end; i++) {
      final isSelected = i == currentPage;
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: () => _goToPage(i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold500
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: isSelected
                      ? AppColors.forest900
                      : (isDark ? Colors.white : AppColors.forest900),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pages;
  }
}
