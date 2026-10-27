import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/campus_brand_logo.dart';
import '../../../core/widgets/campus_button.dart';
import '../../../core/widgets/campus_empty_state.dart';
import '../../../core/widgets/campus_error_state.dart';
import '../../../core/widgets/campus_issue_card.dart';
import '../../../core/widgets/campus_loading_skeleton.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../auth/presentation/auth_state.dart';
import '../../issues/data/models/issue_model.dart';
import '../../issues/data/repositories/issue_repository.dart';
import '../../issues/presentation/issues_notifier.dart';

class RecentIssuesNotifier extends Notifier<AsyncValue<List<IssueModel>>> {
  @override
  AsyncValue<List<IssueModel>> build() {
    return const AsyncData([]);
  }

  Future<void> fetch({bool isRefresh = false}) async {
    if (!isRefresh && !state.hasValue) {
      state = const AsyncLoading();
    }
    final repo = ref.read(issueRepositoryProvider);
    try {
      final result = await repo.listIssues(page: 1, limit: 5);
      state = AsyncData(result.items);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }
}

final recentIssuesNotifierProvider =
    NotifierProvider<RecentIssuesNotifier, AsyncValue<List<IssueModel>>>(() {
      return RecentIssuesNotifier();
    });

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentIssuesNotifierProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        ref.read(recentIssuesNotifierProvider.notifier).fetch(isRefresh: true);
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final recentIssuesAsync = ref.watch(recentIssuesNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : 'Campus Member';
    final userRole = authState is AuthAuthenticated
        ? authState.user.role
        : 'MEMBER';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(recentIssuesNotifierProvider.notifier).fetch(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    bottom: AppSpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Elegant Welcome Hero Card aligned with Website Navy Aesthetic
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.deepNavy,
                          borderRadius: AppRadius.xlBorderRadius,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.navyBorder,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.3 : 0.08,
                              ),
                              offset: const Offset(0, 4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CampusBrandLogo(size: 32),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CampusFix Mobile',
                                        style: AppTypography.titleLarge
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.3,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: AppSpacing.xs,
                                        children: [
                                          Text(
                                            'Welcome, $userName',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.85),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandAmber
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  AppRadius.smBorderRadius,
                                              border: Border.all(
                                                color: AppColors.brandAmber
                                                    .withValues(alpha: 0.5),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              userRole,
                                              style: const TextStyle(
                                                color: AppColors.brandAmber,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Report facilities issues, track ongoing maintenance, and improve our campus together.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Primary Call to Action
                      CampusButton(
                        label: 'Report a Campus Incident',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: () => context.push('/report-issue'),
                      ),

                      if (userRole == 'STAFF' || userRole == 'ADMIN') ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFEFF6FF),
                            borderRadius: AppRadius.lgBorderRadius,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.5)
                                  : const Color(0xFF93C5FD),
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(issuesNotifierProvider.notifier)
                                  .setScope('assigned');
                              context.go('/issues');
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.2),
                                    borderRadius: AppRadius.mdBorderRadius,
                                  ),
                                  child: const Icon(
                                    Icons.assignment_turned_in_outlined,
                                    color: Color(0xFF3B82F6),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Technician Operations Queue',
                                        style: AppTypography.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Review assigned work orders & update status.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Color(0xFF3B82F6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      // Secondary Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: CampusButton(
                              label: 'Browse Issues',
                              icon: Icons.list_alt_rounded,
                              variant: CampusButtonVariant.secondary,
                              onPressed: () => context.go('/issues'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: CampusButton(
                              label: 'App Settings',
                              icon: Icons.tune_rounded,
                              variant: CampusButtonVariant.secondary,
                              onPressed: () => context.go('/profile'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Recent Issues Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Recent Campus Issues',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                          ),
                          recentIssuesAsync.maybeWhen(
                            data: (issues) => issues.isNotEmpty
                                ? TextButton(
                                    onPressed: () => context.go('/issues'),
                                    child: Text(
                                      'View All',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: isDark
                                            ? AppColors.brandAmber
                                            : AppColors.brandAmberHover,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Recent issues content state
                      recentIssuesAsync.when(
                        data: (issues) {
                          if (issues.isEmpty) {
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                borderRadius: AppRadius.lgBorderRadius,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                  width: 1,
                                ),
                              ),
                              child: CampusEmptyState(
                                icon: Icons.assignment_turned_in_outlined,
                                title: 'No Recent Issues Loaded',
                                description: 'There are no recent incidents logged on campus. Notice a problem in classrooms or labs? Report it now.',
                                actionLabel: 'Report an Issue',
                                onAction: () => context.push('/report-issue'),
                              ),
                            );
                          }

                          return Column(
                            children: issues.map((issue) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: CampusIssueCard.fromModel(
                                  issue: issue,
                                  onTap: () =>
                                      context.push('/issues/${issue.id}'),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () =>
                            const CampusLoadingSkeleton(itemCount: 2),
                        error: (err, _) {
                          final isAuthError = err is UnauthorizedException;
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius: AppRadius.lgBorderRadius,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: isAuthError
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandAmber
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 32,
                                          color: AppColors.brandAmber,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Authentication Required',
                                        style: AppTypography.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Sign in to access campus incidents, track progress, and submit work orders.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      CampusButton(
                                        label: 'Sign In to CampusFix',
                                        icon: Icons.login_rounded,
                                        isFullWidth: false,
                                        onPressed: () =>
                                            context.push('/sign-in'),
                                      ),
                                    ],
                                  )
                                : CampusErrorState(
                                    title: 'Unable to Load Incidents',
                                    message: err is AppException
                                        ? err.message
                                        : 'Failed to load recent issues.',
                                    onRetry: () => ref
                                        .read(
                                          recentIssuesNotifierProvider.notifier,
                                        )
                                        .fetch(),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
