import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/campus_button.dart';
import '../../../core/widgets/campus_issue_card.dart';
import '../../../core/widgets/campus_status_chip.dart';

/// Explicit component preview gallery for design system components.
/// Separated from the live Issues feed to avoid masquerading fake data as live records.
class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Component Preview Gallery')),
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: AppSpacing.xxxl,
        ),
        children: [
          // Explicit disclaimer banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadius.mdBorderRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Design System Previews',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'These sample cards demonstrate design tokens, layouts, and status chip styling. They do not represent live data.',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'CampusIssueCard Variants',
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          CampusIssueCard(
            title: 'Broken projector in Science Lecture Hall 301',
            category: 'Audio/Visual',
            location: 'Science Complex • Room 301',
            status: IssueStatus.open,
            timeAgo: '10m ago',
            onTap: () => _showNotice(context),
          ),

          const SizedBox(height: AppSpacing.md),

          CampusIssueCard(
            title: 'Water fountain pressure issue and low flow',
            category: 'Plumbing',
            location: 'Library • 2nd Floor North',
            status: IssueStatus.inProgress,
            timeAgo: '2h ago',
            onTap: () => _showNotice(context),
          ),

          const SizedBox(height: AppSpacing.md),

          CampusIssueCard(
            title: 'Air conditioning malfunction in Dormitory Block B',
            category: 'HVAC',
            location: 'Residential Quad • Block B',
            status: IssueStatus.critical,
            timeAgo: '4h ago',
            onTap: () => _showNotice(context),
          ),

          const SizedBox(height: AppSpacing.md),

          CampusIssueCard(
            title: 'Elevator door sensor calibrated and serviced',
            category: 'Facility',
            location: 'Student Union • Main Elevator',
            status: IssueStatus.resolved,
            timeAgo: 'Yesterday',
            onTap: () => _showNotice(context),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'CampusButton Variants',
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          CampusButton(
            label: 'Primary Button',
            icon: Icons.check_rounded,
            onPressed: () {},
            variant: CampusButtonVariant.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          CampusButton(
            label: 'Secondary Button',
            icon: Icons.list_alt_rounded,
            onPressed: () {},
            variant: CampusButtonVariant.secondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          CampusButton(
            label: 'Outlined Button',
            icon: Icons.tune_rounded,
            onPressed: () {},
            variant: CampusButtonVariant.outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          CampusButton(
            label: 'Danger Button',
            icon: Icons.delete_outline_rounded,
            onPressed: () {},
            variant: CampusButtonVariant.danger,
          ),
        ],
      ),
    );
  }

  void _showNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Component preview demonstration item tapped.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
