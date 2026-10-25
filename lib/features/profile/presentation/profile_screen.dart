import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/campus_button.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../auth/presentation/auth_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out of CampusFix? You will need to sign in again to submit and manage reports.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusCritical,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isSigningOut = true);
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        setState(() => _isSigningOut = false);
        context.go('/sign-in');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: AppSpacing.xxxl,
          ),
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadius.xlBorderRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark
                        ? const Color(0xFF141D2E)
                        : const Color(0xFF0E1728),
                    child: user != null && user.name.isNotEmpty
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.brandAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : const Icon(
                            Icons.person_outline_rounded,
                            size: 28,
                            color: AppColors.brandAmber,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user?.name ?? 'Unauthenticated Session',
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandAmber.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: AppRadius.smBorderRadius,
                                  border: Border.all(
                                    color: AppColors.brandAmber.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  user.role,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.brandAmber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          user?.email ?? 'Sign in with campus account to report and track issues.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Appearance Settings
            Text(
              'Appearance',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadius.lgBorderRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: isDark
                        ? AppColors.brandAmber.withValues(alpha: 0.25)
                        : AppColors.brandAmber.withValues(alpha: 0.15),
                    selectedForegroundColor: isDark
                        ? AppColors.brandAmber
                        : AppColors.brandAmberHover,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBorderRadius,
                    ),
                  ),
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('System'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (newSelection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(newSelection.first);
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Application & Campus Information Section
            Text(
              'About CampusFix',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
                  _buildInfoRow('Application', 'CampusFix Mobile', isDark),
                  const Divider(height: AppSpacing.lg),
                  _buildInfoRow('Release Version', '1.0.0 (Build 1)', isDark),
                  const Divider(height: AppSpacing.lg),
                  _buildInfoRow(
                    'Network Platform',
                    'Campus Facilities Maintenance',
                    isDark,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildInfoRow(
                    'Account Status',
                    'Active & Synchronized',
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Sign Out / Sign In Action
            if (user != null)
              CampusButton(
                label: 'Sign Out',
                icon: Icons.logout_rounded,
                variant: CampusButtonVariant.danger,
                isLoading: _isSigningOut,
                onPressed: _isSigningOut ? null : _handleSignOut,
              )
            else
              CampusButton(
                label: 'Sign In',
                icon: Icons.login_rounded,
                variant: CampusButtonVariant.primary,
                onPressed: () => context.push('/sign-in'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
