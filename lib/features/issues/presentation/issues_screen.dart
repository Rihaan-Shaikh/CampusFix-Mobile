import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_notifier.dart';
import '../../auth/presentation/auth_state.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/campus_empty_state.dart';
import '../../../core/widgets/campus_error_state.dart';
import '../../../core/widgets/campus_issue_card.dart';
import '../../../core/widgets/campus_loading_skeleton.dart';
import '../../../core/widgets/campus_text_field.dart';
import 'issues_notifier.dart';

class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const List<String> _statusFilters = [
    'ALL',
    'OPEN',
    'IN_PROGRESS',
    'RESOLVED',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(issuesNotifierProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(issuesNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(issuesNotifierProvider);
    final notifier = ref.read(issuesNotifierProvider.notifier);
    final authState = ref.watch(authNotifierProvider);
    final isStaffOrAdmin =
        authState is AuthAuthenticated && authState.user.isStaffOrAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/report-issue'),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Report Issue',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
        backgroundColor: AppColors.brandAmber,
        foregroundColor: AppColors.deepNavy,
        elevation: 3,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar (Search + Filter Chips + Scope)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  CampusTextField(
                    hint: 'Search by title, location or ref code...',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (query) => notifier.setSearchQuery(query),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Status filter chips & Scope toggle
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _statusFilters.map((status) {
                              final isSelected = status == 'ALL'
                                  ? state.selectedStatus == null
                                  : state.selectedStatus == status;

                              final label = switch (status) {
                                'ALL' => 'All',
                                'OPEN' => 'Open',
                                'IN_PROGRESS' => 'In Progress',
                                'RESOLVED' => 'Resolved',
                                _ => status,
                              };

                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.sm,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    notifier.setStatusFilter(
                                      status == 'ALL' ? null : status,
                                    );
                                  },
                                  borderRadius: AppRadius.smBorderRadius,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
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
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isSelected
                                            ? AppColors.deepNavy
                                            : (isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors
                                                        .lightTextSecondary),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Scope selector (All Issues vs Assigned Work Orders vs My Issues)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF141D2E)
                            : const Color(0xFFF1F5F9),
                        borderRadius: AppRadius.smBorderRadius,
                      ),
                      child: Row(
                        children: [
                          _buildScopeTab(
                            'All Campus Issues',
                            'all',
                            state,
                            notifier,
                            isDark,
                          ),
                          if (isStaffOrAdmin)
                            _buildScopeTab(
                              'Assigned to Me',
                              'assigned',
                              state,
                              notifier,
                              isDark,
                            ),
                          _buildScopeTab(
                            'My Reported Issues',
                            'mine',
                            state,
                            notifier,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Issues list view with pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notifier.refresh(),
                child: _buildListContent(context, state, notifier, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeTab(
    String label,
    String scopeValue,
    IssuesState state,
    IssuesNotifier notifier,
    bool isDark,
  ) {
    final isSelected = state.scope == scopeValue;

    return InkWell(
      onTap: () => notifier.setScope(scopeValue),
      borderRadius: AppRadius.smBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCard : Colors.white)
              : Colors.transparent,
          borderRadius: AppRadius.smBorderRadius,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    IssuesState state,
    IssuesNotifier notifier,
    bool isDark,
  ) {
    if (state.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CampusLoadingSkeleton(itemCount: 4),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: CampusErrorState(
          message: state.errorMessage!,
          onRetry: () => notifier.loadInitial(),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: CampusEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No Matching Incidents Found',
            description: state.searchQuery.isNotEmpty
                ? 'No issues match "${state.searchQuery}". Try adjusting your keywords or filters.'
                : 'No incidents have been recorded in this category yet.',
            actionLabel: 'Report an Issue',
            onAction: () => context.push('/report-issue'),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        96, // Clear bottom navigation & FAB safely
      ),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final issue = state.items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: CampusIssueCard.fromModel(
            issue: issue,
            onTap: () => context.push('/issues/${issue.id}'),
          ),
        );
      },
    );
  }
}
