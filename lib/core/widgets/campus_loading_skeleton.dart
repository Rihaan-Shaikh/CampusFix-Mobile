import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Clean, high-performance skeleton card placeholders for feed loading states.
class CampusLoadingSkeleton extends StatelessWidget {
  const CampusLoadingSkeleton({this.itemCount = 3, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppRadius.lgBorderRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 90,
                    height: 16,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: AppRadius.smBorderRadius,
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 20,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: AppRadius.smBorderRadius,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                height: 18,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: AppRadius.smBorderRadius,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 200,
                height: 14,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: AppRadius.smBorderRadius,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: AppRadius.smBorderRadius,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: AppRadius.smBorderRadius,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
