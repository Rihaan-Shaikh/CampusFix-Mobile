import 'package:campusfix/core/errors/app_exception.dart';
import 'package:campusfix/core/widgets/campus_empty_state.dart';
import 'package:campusfix/features/auth/data/models/user_model.dart';
import 'package:campusfix/features/auth/presentation/auth_notifier.dart';
import 'package:campusfix/features/auth/presentation/auth_state.dart';
import 'package:campusfix/features/home/presentation/home_screen.dart';
import 'package:campusfix/features/issues/data/models/issue_model.dart';
import 'package:campusfix/features/issues/data/repositories/issue_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

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
  group('HomeScreen layout & empty state', () {
    testWidgets(
      'renders clean welcome hero and honest recent issues empty state without dev clutter',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              issueRepositoryProvider.overrideWithValue(_MockIssueRepository()),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify header and brand title
        expect(find.text('CampusFix Mobile'), findsOneWidget);
        expect(find.text('Target API Configuration'), findsNothing);

        // Verify Quick actions
        expect(find.text('Browse Issues'), findsOneWidget);
        expect(find.text('App Settings'), findsOneWidget);

        // Verify honest empty state
        expect(find.text('Recent Campus Issues'), findsOneWidget);
        expect(find.text('No Recent Issues Loaded'), findsOneWidget);
        expect(find.byType(CampusEmptyState), findsOneWidget);

        // Ensure no fabricated counts or records are shown
        expect(find.text('Active Issues: 12'), findsNothing);
        expect(find.text('Pending: 5'), findsNothing);
      },
    );

    testWidgets(
      'renders dual quick action buttons without overflow on narrow width',
      (tester) async {
        // 320dp width
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              issueRepositoryProvider.overrideWithValue(_MockIssueRepository()),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Browse Issues'), findsOneWidget);
        expect(find.text('App Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders Technician Operations Queue card when user is STAFF', (
      tester,
    ) async {
      const staffUser = UserModel(
        id: 'usr_staff',
        name: 'Alex Maintenance',
        email: 'alex@campus.edu',
        role: 'STAFF',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            issueRepositoryProvider.overrideWithValue(_MockIssueRepository()),
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(staffUser)),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Technician Operations Queue'), findsOneWidget);
    });
  });
}
