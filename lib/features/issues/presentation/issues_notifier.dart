import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/models/issue_model.dart';
import '../data/repositories/issue_repository.dart';

@immutable
class IssuesState {
  const IssuesState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.items = const [],
    this.meta,
    this.errorMessage,
    this.selectedStatus,
    this.selectedCategory,
    this.selectedPriority,
    this.searchQuery = '',
    this.scope = 'all',
  });

  final bool isLoading;
  final bool isLoadingMore;
  final List<IssueModel> items;
  final PaginationMeta? meta;
  final String? errorMessage;
  final String? selectedStatus;
  final String? selectedCategory;
  final String? selectedPriority;
  final String searchQuery;
  final String scope;

  bool get hasMore => meta?.hasNextPage ?? false;
  int get currentPage => meta?.page ?? 1;

  IssuesState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<IssueModel>? items,
    PaginationMeta? meta,
    String? errorMessage,
    bool clearError = false,
    String? selectedStatus,
    bool clearStatus = false,
    String? selectedCategory,
    bool clearCategory = false,
    String? selectedPriority,
    bool clearPriority = false,
    String? searchQuery,
    String? scope,
  }) {
    return IssuesState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedPriority: clearPriority
          ? null
          : (selectedPriority ?? this.selectedPriority),
      searchQuery: searchQuery ?? this.searchQuery,
      scope: scope ?? this.scope,
    );
  }
}

class IssuesNotifier extends Notifier<IssuesState> {
  @override
  IssuesState build() {
    return const IssuesState();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(issueRepositoryProvider);
    try {
      final result = await repo.listIssues(
        page: 1,
        limit: 20,
        status: state.selectedStatus,
        category: state.selectedCategory,
        priority: state.selectedPriority,
        search: state.searchQuery,
        scope: state.scope,
      );
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        meta: result.meta,
      );
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'Unable to load campus issues.';
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  Future<void> refresh() async {
    final repo = ref.read(issueRepositoryProvider);
    try {
      final result = await repo.listIssues(
        page: 1,
        limit: 20,
        status: state.selectedStatus,
        category: state.selectedCategory,
        priority: state.selectedPriority,
        search: state.searchQuery,
        scope: state.scope,
      );
      state = state.copyWith(
        items: result.items,
        meta: result.meta,
        clearError: true,
      );
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'Failed to refresh issues.';
      state = state.copyWith(errorMessage: message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final repo = ref.read(issueRepositoryProvider);
    try {
      final nextPage = state.currentPage + 1;
      final result = await repo.listIssues(
        page: nextPage,
        limit: 20,
        status: state.selectedStatus,
        category: state.selectedCategory,
        priority: state.selectedPriority,
        search: state.searchQuery,
        scope: state.scope,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...result.items],
        meta: result.meta,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<IssueModel> updateIssueStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    final repo = ref.read(issueRepositoryProvider);
    final updated = await repo.updateIssueStatus(
      id: id,
      status: status,
      note: note,
    );
    final newItems = state.items.map((item) {
      return item.id == id ? updated : item;
    }).toList();
    state = state.copyWith(items: newItems);
    return updated;
  }

  void setStatusFilter(String? status) {
    if (state.selectedStatus == status) return;
    state = state.copyWith(selectedStatus: status, clearStatus: status == null);
    loadInitial();
  }

  void setCategoryFilter(String? category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
    loadInitial();
  }

  void setPriorityFilter(String? priority) {
    if (state.selectedPriority == priority) return;
    state = state.copyWith(
      selectedPriority: priority,
      clearPriority: priority == null,
    );
    loadInitial();
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    loadInitial();
  }

  void setScope(String scope) {
    if (state.scope == scope) return;
    state = state.copyWith(scope: scope);
    loadInitial();
  }
}

final issuesNotifierProvider = NotifierProvider<IssuesNotifier, IssuesState>(
  () {
    return IssuesNotifier();
  },
);
