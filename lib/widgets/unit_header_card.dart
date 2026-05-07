import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class UnitHeaderCard extends StatefulWidget {
  final String unitNumber;
  final String title;
  final bool isCompleted;
  final int completedCount;
  final int totalCount;
  final IconData? icon;
  final int stars;
  final List<Widget> children;
  final VoidCallback? onTap;

  const UnitHeaderCard({
    super.key,
    required this.unitNumber,
    required this.title,
    this.isCompleted = false,
    this.completedCount = 0,
    this.totalCount = 0,
    this.icon,
    this.stars = 0,
    this.children = const [],
    this.onTap,
  });

  @override
  State<UnitHeaderCard> createState() => _UnitHeaderCardState();
}

class _UnitHeaderCardState extends State<UnitHeaderCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Vertical path line
        Positioned(
          left: 20,
          top: 0,
          bottom: -40, // Extends to connect with the next unit
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Node circle on the vertical line
        Positioned(
          left: 10,
          top: 40,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.isCompleted
                  ? AppColors.gold500
                  : (isDark ? Colors.grey.shade900 : Colors.grey.shade300),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold500, width: 2),
            ),
            child: widget.isCompleted
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                : null,
          ),
        ),

        // Horizontal connecting line
        Positioned(
          left: 34,
          top: 50,
          child: Container(
            width: 26, // Connects from left: 34 to left: 60
            height: 4,
            color: AppColors.gold500.withValues(alpha: 0.3),
          ),
        ),

        // The actual card content
        Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242C26) : AppColors.creamBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                width: 1.5,
              ),
              image: !isDark
                  ? const DecorationImage(
                      image: AssetImage('assets/images/paper_texture.png'),
                      fit: BoxFit.cover,
                      opacity: 0.05,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header section (Tap to expand/collapse or trigger custom action)
                GestureDetector(
                  onTap: widget.onTap ?? (widget.children.isNotEmpty
                      ? () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        }
                      : null),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.unitNumber.toUpperCase(),
                              style: AppTypography.label.copyWith(
                                color: isDark ? Colors.white30 : Colors.black26,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (widget.isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.terracotta,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'LEVEL COMPLETE',
                                  style: AppTypography.label.copyWith(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.icon != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(widget.icon, color: AppColors.gold500, size: 28),
                              ),
                            if (widget.icon != null) const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: AppTypography.h1ExtraBold.copyWith(
                                      color: isDark ? Colors.white : AppColors.forest700,
                                      fontSize: 20,
                                      height: 1.1,
                                    ),
                                  ),
                                  if (widget.stars > 0) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: List.generate(
                                        3,
                                        (i) => Icon(
                                          Icons.star_rounded,
                                          color: i <
                                                  (widget.stars /
                                                          (widget.totalCount > 0
                                                              ? widget.totalCount
                                                              : 1))
                                                      .round()
                                              ? AppColors.gold500
                                              : Colors.grey.withValues(alpha: 0.3),
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (widget.children.isNotEmpty)
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                        if (widget.totalCount > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '${widget.completedCount}/${widget.totalCount} LESSONS',
                                style: AppTypography.label.copyWith(
                                  color: isDark ? Colors.white30 : Colors.black38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${widget.totalCount > 0 ? (widget.completedCount * 100 ~/ widget.totalCount) : 0}%',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.gold500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: widget.totalCount > 0 ? widget.completedCount / widget.totalCount : 0,
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.gold500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Children (Lessons) section - Expandable
                if (widget.children.isNotEmpty)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: !_isExpanded
                        ? const SizedBox.shrink()
                        : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.4),
                              border: Border(
                                top: BorderSide(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 4),
                            child: Column(
                              children: widget.children,
                            ),
                          ),
                  ),

                // Bottom colored border
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gold500 : AppColors.forest500,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



