import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/campus_button.dart';
import '../../../core/widgets/campus_error_state.dart';
import '../../../core/widgets/campus_issue_card.dart';
import '../../../core/widgets/campus_loading_indicator.dart';
import '../../../core/widgets/campus_priority_badge.dart';
import '../../../core/widgets/campus_status_chip.dart';
import '../../../core/widgets/campus_text_field.dart';
import '../../../core/widgets/campus_timeline_item.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../auth/presentation/auth_state.dart';
import '../../home/presentation/home_screen.dart';
import '../data/models/issue_model.dart';
import '../data/repositories/issue_repository.dart';
import 'issues_notifier.dart';

class IssueDetailScreen extends ConsumerStatefulWidget {
  const IssueDetailScreen({required this.issueId, super.key});

  final String issueId;

  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  IssueModel? _issue;

  @override
  void initState() {
    super.initState();
    _fetchIssueDetails();
  }

  Future<void> _fetchIssueDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final issue = await ref
          .read(issueRepositoryProvider)
          .getIssueById(widget.issueId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _issue = issue;
        });
      }
    } catch (e) {
      if (mounted) {
        final message = e is AppException
            ? e.message
            : 'Unable to load incident details.';
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      }
    }
  }

  Future<void> _showStatusUpdateSheet(
    BuildContext context,
    IssueModel issue,
  ) async {
    final noteController = TextEditingController();
    String selectedStatus = issue.status;
    bool isUpdating = false;
    String? sheetError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.xl,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Incident Status',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Authorized staff and administrators can transition facilities maintenance states.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (sheetError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.statusCriticalBgDark
                          : AppColors.statusCriticalBg,
                      borderRadius: AppRadius.smBorderRadius,
                    ),
                    child: Text(
                      sheetError!,
                      style: const TextStyle(
                        color: AppColors.statusCritical,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: ['OPEN', 'IN_PROGRESS', 'RESOLVED'].map((st) {
                    final isSelected = selectedStatus == st;
                    final label = st == 'IN_PROGRESS'
                        ? 'In Progress'
                        : st == 'RESOLVED'
                        ? 'Resolved'
                        : 'Open';
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: InkWell(
                          onTap: () => setSheetState(() => selectedStatus = st),
                          borderRadius: AppRadius.smBorderRadius,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandAmber
                                  : (isDark
                                        ? AppColors.darkCard
                                        : AppColors.lightCard),
                              borderRadius: AppRadius.smBorderRadius,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandAmberHover
                                    : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.deepNavy
                                    : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                CampusTextField(
                  label: 'Progress Note (Optional)',
                  hint: 'e.g., Replacement parts ordered or repair verified',
                  controller: noteController,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                CampusButton(
                  label: 'Confirm Status Change',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: isUpdating,
                  onPressed: isUpdating
                      ? null
                      : () async {
                          setSheetState(() {
                            isUpdating = true;
                            sheetError = null;
                          });
                          try {
                            final updated = await ref
                                .read(issueRepositoryProvider)
                                .updateIssueStatus(
                                  id: issue.id,
                                  status: selectedStatus,
                                  note: noteController.text.trim().isNotEmpty
                                      ? noteController.text.trim()
                                      : null,
                                );
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            if (!mounted) return;
                            setState(() => _issue = updated);
                            unawaited(
                              ref
                                  .read(issuesNotifierProvider.notifier)
                                  .refresh(),
                            );
                            unawaited(
                              ref
                                  .read(recentIssuesNotifierProvider.notifier)
                                  .fetch(isRefresh: true),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Status updated to $selectedStatus.',
                                ),
                                backgroundColor: AppColors.statusResolved,
                              ),
                            );
                          } catch (e) {
                            setSheetState(() {
                              isUpdating = false;
                              sheetError = e is AppException
                                  ? e.message
                                  : 'Failed to update status.';
                            });
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final isStaffOrAdmin =
        authState is AuthAuthenticated && authState.user.isStaffOrAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _issue?.referenceCode.isNotEmpty == true
              ? _issue!.referenceCode
              : 'Incident Details',
        ),
        actions: [
          if (_issue != null && isStaffOrAdmin)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Update Status',
              onPressed: () => _showStatusUpdateSheet(context, _issue!),
            ),
        ],
      ),
      body: _buildBody(context, isDark, isStaffOrAdmin),
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: AppRadius.lgBorderRadius,
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                          ),
                        ),
                      )
                    : (!kIsWeb && File(imageUrl).existsSync())
                    ? Image.file(
                        File(imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        child: const Icon(Icons.image_outlined, size: 48),
                      ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, bool isStaffOrAdmin) {
    if (_isLoading) {
      return const CampusLoadingIndicator(
        message: 'Loading incident details...',
      );
    }

    if (_errorMessage != null) {
      return CampusErrorState(
        message: _errorMessage!,
        onRetry: _fetchIssueDetails,
      );
    }

    if (_issue == null) {
      return const CampusErrorState(
        message: 'This incident could not be found.',
      );
    }

    final issue = _issue!;
    final history = issue.statusHistory ?? [];

    return RefreshIndicator(
      onRefresh: _fetchIssueDetails,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        children: [
          // Primary Header Card: Reference Code, Status, Priority & Title
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadius.xlBorderRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        issue.referenceCode,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.brandAmber
                              : AppColors.deepNavy,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    CampusStatusChip.fromString(issue.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  issue.title,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CampusPriorityBadge(priority: issue.priority),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
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
                        issue.category,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Problem Description Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadius.lgBorderRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.brandAmber
                          : AppColors.brandAmberHover,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Problem Description',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  issue.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Location and Reporter Details
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadius.lgBorderRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Campus Location',
                  value: issue.location,
                  isDark: isDark,
                ),
                const Divider(height: AppSpacing.lg),
                _buildDetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Reported By',
                  value: issue.createdBy.name,
                  isDark: isDark,
                ),
                const Divider(height: AppSpacing.lg),
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Reported Date',
                  value:
                      '${formatTimeAgo(issue.createdAt)} (${issue.createdAt.day}/${issue.createdAt.month}/${issue.createdAt.year})',
                  isDark: isDark,
                ),
                if (issue.assignedTo != null) ...[
                  const Divider(height: AppSpacing.lg),
                  _buildDetailRow(
                    icon: Icons.engineering_outlined,
                    label: 'Assigned Staff',
                    value: issue.assignedTo!.name,
                    isDark: isDark,
                  ),
                ],
                if (issue.resolvedAt != null) ...[
                  const Divider(height: AppSpacing.lg),
                  _buildDetailRow(
                    icon: Icons.task_alt_rounded,
                    label: 'Resolved At',
                    value:
                        '${issue.resolvedAt!.day}/${issue.resolvedAt!.month}/${issue.resolvedAt!.year}',
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),

          // Photographic Evidence & Attachments Section
          if (issue.attachments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadius.lgBorderRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 18,
                        color: isDark
                            ? AppColors.brandAmber
                            : AppColors.brandAmberHover,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Photographic Evidence (${issue.attachments.length})',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: issue.attachments.map((url) {
                      return InkWell(
                        onTap: () => _openImageViewer(context, url, isDark),
                        borderRadius: AppRadius.mdBorderRadius,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.mdBorderRadius,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: AppRadius.mdBorderRadius,
                            child: url.startsWith('http')
                                ? Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 32,
                                    ),
                                  )
                                : (!kIsWeb && File(url).existsSync())
                                ? Image.file(
                                    File(url),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.image_outlined,
                                      size: 32,
                                    ),
                                  )
                                : Container(
                                    color: isDark
                                        ? const Color(0xFF141D2E)
                                        : const Color(0xFFF1F5F9),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.attachment_rounded,
                                          size: 22,
                                          color: AppColors.brandAmber,
                                        ),
                                        const SizedBox(height: 2),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            url.split('/').last,
                                            style: const TextStyle(fontSize: 9),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // Facilities Management & Staff Operations
          if (isStaffOrAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF141D2E)
                    : const Color(0xFFEFF6FF),
                borderRadius: AppRadius.lgBorderRadius,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                      : const Color(0xFF93C5FD),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          borderRadius: AppRadius.smBorderRadius,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 18,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Staff & Operations Controls',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'As authorized facilities personnel, you can progress this maintenance ticket through resolution and log technician remarks.',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CampusButton(
                    label: 'Transition Status / Log Note',
                    icon: Icons.edit_note_rounded,
                    onPressed: () => _showStatusUpdateSheet(context, issue),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Status History Section
          Row(
            children: [
              Text(
                'Status Audit & Progress Timeline',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.brandAmber,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadius.lgBorderRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Text(
                'No status changes have been recorded yet.',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            )
          else
            ...List.generate(history.length, (index) {
              return CampusTimelineItem(
                item: history[index],
                isLast: index == history.length - 1,
              );
            }),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.brandAmber : AppColors.brandAmberHover,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
