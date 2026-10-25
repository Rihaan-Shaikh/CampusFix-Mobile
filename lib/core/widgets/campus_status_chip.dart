import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum IssueStatus {
  open,
  inProgress,
  resolved,
  critical,
  closed;

  String get label {
    switch (this) {
      case IssueStatus.open:
        return 'Open';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.resolved:
        return 'Resolved';
      case IssueStatus.critical:
        return 'Critical';
      case IssueStatus.closed:
        return 'Closed';
    }
  }

  IconData get icon {
    switch (this) {
      case IssueStatus.open:
        return Icons.error_outline_rounded;
      case IssueStatus.inProgress:
        return Icons.pending_outlined;
      case IssueStatus.resolved:
        return Icons.check_circle_outline_rounded;
      case IssueStatus.critical:
        return Icons.warning_amber_rounded;
      case IssueStatus.closed:
        return Icons.archive_outlined;
    }
  }
}

/// Compact status chip for issues with semantic color badge and icon.
class CampusStatusChip extends StatelessWidget {
  const CampusStatusChip({required this.status, super.key});

  factory CampusStatusChip.fromString(String statusString, {Key? key}) {
    final normalized = statusString.toUpperCase().replaceAll(' ', '_');
    final status = switch (normalized) {
      'OPEN' => IssueStatus.open,
      'IN_PROGRESS' => IssueStatus.inProgress,
      'RESOLVED' => IssueStatus.resolved,
      'CRITICAL' => IssueStatus.critical,
      'CLOSED' => IssueStatus.closed,
      _ => IssueStatus.open,
    };
    return CampusStatusChip(status: status, key: key);
  }

  final IssueStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor;
    final Color fgColor;

    switch (status) {
      case IssueStatus.open:
        bgColor = isDark ? AppColors.statusOpenBgDark : AppColors.statusOpenBg;
        fgColor = AppColors.statusOpen;
      case IssueStatus.inProgress:
        bgColor = isDark
            ? AppColors.statusInProgressBgDark
            : AppColors.statusInProgressBg;
        fgColor = AppColors.statusInProgress;
      case IssueStatus.resolved:
        bgColor = isDark
            ? AppColors.statusResolvedBgDark
            : AppColors.statusResolvedBg;
        fgColor = AppColors.statusResolved;
      case IssueStatus.critical:
        bgColor = isDark
            ? AppColors.statusCriticalBgDark
            : AppColors.statusCriticalBg;
        fgColor = AppColors.statusCritical;
      case IssueStatus.closed:
        bgColor = isDark
            ? AppColors.statusClosedBgDark
            : AppColors.statusClosedBg;
        fgColor = AppColors.statusClosed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: fgColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: AppTypography.labelSmall.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
