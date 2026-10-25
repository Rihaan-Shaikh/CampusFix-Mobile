import 'package:flutter/material.dart';

import '../../features/issues/data/models/issue_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'campus_priority_badge.dart';
import 'campus_status_chip.dart';

/// Helper to format relative timestamp concisely.
String formatTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
  if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

/// Reusable card component displaying an issue summary.
class CampusIssueCard extends StatelessWidget {
  const CampusIssueCard({
    required this.title,
    required this.category,
    required this.location,
    required this.status,
    required this.timeAgo,
    this.referenceCode,
    this.priority,
    this.onTap,
    super.key,
  });

  factory CampusIssueCard.fromModel({
    required IssueModel issue,
    VoidCallback? onTap,
    Key? key,
  }) {
    return CampusIssueCard(
      title: issue.title,
      category: issue.category,
      location: issue.location,
      status: switch (issue.status.toUpperCase()) {
        'IN_PROGRESS' => IssueStatus.inProgress,
        'RESOLVED' => IssueStatus.resolved,
        'CRITICAL' => IssueStatus.critical,
        'CLOSED' => IssueStatus.closed,
        _ => IssueStatus.open,
      },
      timeAgo: formatTimeAgo(issue.createdAt),
      referenceCode: issue.referenceCode,
      priority: issue.priority,
      onTap: onTap,
      key: key,
    );
  }

  final String title;
  final String category;
  final String location;
  final IssueStatus status;
  final String timeAgo;
  final String? referenceCode;
  final String? priority;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category tag, Reference code & Status chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141D2E)
                          : const Color(0xFFF1F5F9),
                      borderRadius: AppRadius.smBorderRadius,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.6)
                            : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      category,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (referenceCode != null && referenceCode!.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      referenceCode!,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  CampusStatusChip(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Title
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              // Location, Priority & Timestamp
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      location,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (priority != null && priority!.isNotEmpty) ...[
                    CampusPriorityBadge(priority: priority!, compact: true),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    timeAgo,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
