import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum CampusButtonVariant { primary, secondary, outlined, danger }

/// Accessible, styled CampusFix button supporting multiple visual variants,
/// loading indicators, disabled states, and optional leading icons.
class CampusButton extends StatelessWidget {
  const CampusButton({
    required this.label,
    required this.onPressed,
    this.variant = CampusButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final CampusButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isInteractive = onPressed != null && !isLoading;

    final Color bgColor;
    final Color fgColor;
    final BorderSide borderSide;

    switch (variant) {
      case CampusButtonVariant.primary:
        bgColor = isInteractive
            ? (isDark ? AppColors.brandAmber : AppColors.deepNavy)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1));
        fgColor = isInteractive
            ? (isDark ? AppColors.deepNavy : Colors.white)
            : (isDark ? const Color(0xFF64748B) : const Color(0xFF64748B));
        borderSide = BorderSide.none;
      case CampusButtonVariant.secondary:
        bgColor = isInteractive
            ? (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9))
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
        fgColor = isInteractive
            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
        borderSide = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        );
      case CampusButtonVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = isInteractive
            ? (isDark ? AppColors.brandAmber : AppColors.deepNavy)
            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
        borderSide = BorderSide(
          color: isInteractive
              ? (isDark
                    ? AppColors.brandAmber.withValues(alpha: 0.6)
                    : AppColors.deepNavy.withValues(alpha: 0.3))
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.2,
        );
      case CampusButtonVariant.danger:
        bgColor = isInteractive
            ? AppColors.statusCritical
            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));
        fgColor = Colors.white;
        borderSide = BorderSide.none;
    }

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(fgColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fgColor),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(color: fgColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );

    final buttonWidget = Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBorderRadius,
        side: borderSide,
      ),
      child: InkWell(
        onTap: isInteractive ? onPressed : null,
        borderRadius: AppRadius.mdBorderRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }

    return buttonWidget;
  }
}
