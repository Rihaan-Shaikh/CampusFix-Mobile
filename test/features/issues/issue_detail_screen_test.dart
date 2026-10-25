import 'package:campusfix/core/errors/app_exception.dart';
import 'package:campusfix/features/issues/data/models/issue_model.dart';
import 'package:campusfix/features/issues/data/repositories/issue_repository.dart';
import 'package:campusfix/features/issues/presentation/issue_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockIssueRepo implements IssueRepository {
  _MockIssueRepo({this.detailResult, this.detailError});

  IssueModel? detailResult;
  Exception? detailError;
  int getCount = 0;

  @override
  Future<IssueModel> getIssueById(String id) async {
    getCount++;
    if (detailError != null) throw detailError!;
    return detailResult!;
  }

  @override
  Future<({List<IssueModel> items, PaginationMeta meta})> listIssues({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    String? priority,
    String? search,
    String? scope,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<IssueModel> createIssue(IssueCreateRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<IssueModel> updateIssueStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('IssueDetailScreen data rendering & status timeline', () {
    final mockIssue = IssueModel(
      id: 'iss_abc123',
      referenceCode: 'CFX-4921',
      title: 'Water fountain pressure malfunction',
      description:
          'The third floor water fountain has no pressure and sprays unevenly.',
      category: 'Plumbing',
      priority: 'HIGH',
      status: 'IN_PROGRESS',
      location: 'Main Academic Block 3F',
      createdAt: DateTime.parse('2026-06-01T08:00:00.000Z'),
      createdBy: const UserSummaryModel(
        id: 'u1',
        name: 'Jordan Lee',
        email: 'jordan@campus.edu',
      ),
      assignedTo: const UserSummaryModel(id: 'u2', name: 'Maintenance Staff'),
      statusHistory: [
        StatusHistoryItemModel(
          id: 'sh_1',
          newStatus: 'IN_PROGRESS',
          changedBy: const UserSummaryModel(id: 'u_admin', name: 'Admin Jane'),
          note: 'Work order dispatched to plumber.',
          createdAt: DateTime.parse('2026-06-01T09:30:00.000Z'),
        ),
      ],
    );

    testWidgets('renders all issue details, badges, and timeline correctly', (
      tester,
    ) async {
      final mockRepo = _MockIssueRepo(detailResult: mockIssue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [issueRepositoryProvider.overrideWithValue(mockRepo)],
          child: const MaterialApp(
            home: IssueDetailScreen(issueId: 'iss_abc123'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify reference code in header and title
      expect(find.text('CFX-4921'), findsWidgets);
      expect(find.text('Water fountain pressure malfunction'), findsOneWidget);
      expect(
        find.text(
          'The third floor water fountain has no pressure and sprays unevenly.',
        ),
        findsOneWidget,
      );

      // Verify metadata
      expect(find.text('Main Academic Block 3F'), findsOneWidget);
      expect(find.text('Jordan Lee'), findsOneWidget);
      expect(find.text('Maintenance Staff'), findsOneWidget);

      // Verify status history
      expect(find.text('Status Audit & Progress Timeline'), findsOneWidget);
      expect(find.text('Updated by Admin Jane'), findsOneWidget);
      expect(find.text('Work order dispatched to plumber.'), findsOneWidget);
    });

    testWidgets('renders error state with retry button on failure', (
      tester,
    ) async {
      final mockRepo = _MockIssueRepo(
        detailError: const NetworkException(
          'Connection to campus server failed.',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [issueRepositoryProvider.overrideWithValue(mockRepo)],
          child: const MaterialApp(
            home: IssueDetailScreen(issueId: 'iss_abc123'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Connection to campus server failed.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap retry
      mockRepo.detailError = null;
      mockRepo.detailResult = mockIssue;

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Water fountain pressure malfunction'), findsOneWidget);
    });
  });
}
