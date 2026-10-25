import 'package:campusfix/app/campusfix_app.dart';
import 'package:campusfix/core/errors/app_exception.dart';
import 'package:campusfix/core/widgets/campus_empty_state.dart';
import 'package:campusfix/features/issues/data/models/issue_model.dart';
import 'package:campusfix/features/issues/data/repositories/issue_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockIssueRepository implements IssueRepository {
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
    return (
      items: <IssueModel>[],
      meta: const PaginationMeta(
        page: 1,
        limit: 20,
        totalItems: 0,
        totalPages: 1,
        hasNextPage: false,
        hasPreviousPage: false,
      ),
    );
  }

  @override
  Future<IssueModel> getIssueById(String id) async {
    throw const ApiException(message: 'Not found');
  }

  @override
  Future<IssueModel> createIssue(IssueCreateRequest request) async {
    throw const ApiException(message: 'Not implemented in mock');
  }

  @override
  Future<IssueModel> updateIssueStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    throw const ApiException(message: 'Not implemented in mock');
  }
}

void main() {
  group('CampusFixApp navigation & shell integration', () {
    testWidgets('starts up and renders initial shell with tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            issueRepositoryProvider.overrideWithValue(_MockIssueRepository()),
          ],
          child: const CampusFixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar title
      expect(find.text('CampusFix'), findsOneWidget);

      // Verify bottom navigation destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify Home screen content rendered initially
      expect(find.text('CampusFix Mobile'), findsOneWidget);
      expect(find.text('No Recent Issues Loaded'), findsOneWidget);

      // Navigate to Issues tab
      await tester.tap(find.byIcon(Icons.build_outlined));
      await tester.pumpAndSettle();

      // Verify Issues screen is displayed with search and honest empty state
      expect(
        find.text('Search by title, location or ref code...'),
        findsOneWidget,
      );
      expect(find.byType(CampusEmptyState), findsOneWidget);
      expect(find.text('No Matching Incidents Found'), findsOneWidget);

      // Ensure no fabricated issue records appear on the actual Issues destination
      expect(
        find.text('Broken projector in Science Lecture Hall 301'),
        findsNothing,
      );

      // Navigate to Profile tab
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      // Verify Profile screen is displayed
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('About CampusFix'), findsOneWidget);
      expect(find.text('Unauthenticated Session'), findsOneWidget);
    });

    testWidgets('Home Browse Issues button navigates to Issues tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            issueRepositoryProvider.overrideWithValue(_MockIssueRepository()),
          ],
          child: const CampusFixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Browse Issues on Home screen
      await tester.tap(find.text('Browse Issues').first);
      await tester.pumpAndSettle();

      // Verify we arrived at Issues screen
      expect(find.text('No Matching Incidents Found'), findsOneWidget);
    });

    testWidgets('Theme selection works and persists across tab navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            issueRepositoryProvider.overrideWithValue(_MockIssueRepository()),
          ],
          child: const CampusFixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Profile
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      // Switch to Dark theme
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Verify Dark mode theme is applied to MaterialApp
      var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);

      // Navigate to Home tab
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      // App should still be in Dark mode
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);

      // Switch back to Profile and select Light
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
    });
  });
}
