import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pill badge for visualizing issue priority level.
class CampusPriorityBadge extends StatelessWidget {
  const CampusPriorityBadge({
    required this.priority,
    this.compact = false,
    super.key,
  });

  final String priority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = priority.toUpperCase();

    final Color bgColor;
    final Color fgColor;
    final String label;

    switch (normalized) {
      case 'HIGH':
        label = 'High Priority';
        bgColor = isDark
            ? AppColors.statusCriticalBgDark
            : AppColors.statusCriticalBg;
        fgColor = AppColors.statusCritical;
      case 'MEDIUM':
        label = 'Medium Priority';
        bgColor = isDark ? AppColors.statusOpenBgDark : AppColors.statusOpenBg;
        fgColor = AppColors.statusOpen;
      case 'LOW':
      default:
        label = 'Low Priority';
        bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        fgColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fgColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            compact ? normalized : label,
            style: AppTypography.labelSmall.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
