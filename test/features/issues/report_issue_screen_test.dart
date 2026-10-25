import 'package:campusfix/core/errors/app_exception.dart';
import 'package:campusfix/features/issues/data/models/issue_model.dart';
import 'package:campusfix/features/issues/data/repositories/issue_repository.dart';
import 'package:campusfix/features/issues/presentation/report_issue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockIssueRepo implements IssueRepository {
  _MockIssueRepo({this.createResult, this.createError});

  IssueModel? createResult;
  Exception? createError;
  IssueCreateRequest? capturedRequest;

  @override
  Future<IssueModel> createIssue(IssueCreateRequest request) async {
    capturedRequest = request;
    if (createError != null) throw createError!;
    return createResult!;
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
  Future<IssueModel> updateIssueStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    throw const ApiException(message: 'Not implemented in mock');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  group('ReportIssueScreen validation & submission', () {
    testWidgets('renders all input fields, priority chips and submit button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ReportIssueScreen())),
      );

      expect(find.text('Report Campus Issue'), findsOneWidget);
      expect(find.text('Issue Title *'), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
      expect(find.text('Campus Location *'), findsOneWidget);
      expect(find.text('Urgency Priority *'), findsOneWidget);
      expect(find.text('Detailed Description *'), findsOneWidget);
      expect(find.text('Submit Incident Report'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets(
      'validates required fields with character length restrictions',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: ReportIssueScreen())),
        );

        // Submit without entering data
        await tester.ensureVisible(find.text('Submit Incident Report'));
        await tester.tap(find.text('Submit Incident Report'));
        await tester.pump();

        expect(
          find.text('Title must be at least 5 characters.'),
          findsOneWidget,
        );
        expect(
          find.text('Location must be at least 3 characters.'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Description must provide at least 15 characters of detail.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'submits valid form and transitions to confirmed success view with reference code',
      (tester) async {
        final mockIssue = IssueModel(
          id: 'iss_created_77',
          referenceCode: 'CFX-7788',
          title: 'Ceiling projector lamp burnt out',
          description: 'The projector bulb does not power on during lectures.',
          category: 'Classroom Equipment',
          priority: 'HIGH',
          status: 'OPEN',
          location: 'Hall A101',
          createdAt: DateTime.now(),
          createdBy: const UserSummaryModel(id: 'u1', name: 'Student'),
        );

        final mockRepo = _MockIssueRepo(createResult: mockIssue);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [issueRepositoryProvider.overrideWithValue(mockRepo)],
            child: const MaterialApp(home: ReportIssueScreen()),
          ),
        );

        // Fill out valid data
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'e.g., Broken projector HDMI port',
          ),
          'Ceiling projector lamp burnt out',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'e.g., Science Block 302 or West Wing Restroom',
          ),
          'Hall A101',
        );
        await tester.tap(find.text('High'));
        await tester.pump();

        await tester.enterText(
          find.byWidgetPredicate(
            (w) => w is TextField && (w.maxLines ?? 0) > 2,
          ),
          'The projector bulb does not power on during lectures.',
        );

        // Submit form
        await tester.ensureVisible(find.text('Submit Incident Report'));
        await tester.tap(find.text('Submit Incident Report'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify request payload was mapped accurately
        expect(
          mockRepo.capturedRequest?.title,
          'Ceiling projector lamp burnt out',
        );
        expect(mockRepo.capturedRequest?.location, 'Hall A101');
        expect(mockRepo.capturedRequest?.priority, 'High');

        // Verify success view
        expect(find.text('Incident Reported Successfully'), findsOneWidget);
        expect(find.text('CFX-7788'), findsOneWidget);
        expect(find.text('View Incident Details'), findsOneWidget);
      },
    );

    testWidgets(
      'displays server validation error banner on submission failure',
      (tester) async {
        final mockRepo = _MockIssueRepo(
          createError: const ApiException(
            message: 'Facility sector is currently closed for maintenance.',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [issueRepositoryProvider.overrideWithValue(mockRepo)],
            child: const MaterialApp(home: ReportIssueScreen()),
          ),
        );

        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'e.g., Broken projector HDMI port',
          ),
          'Ceiling projector lamp burnt out',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'e.g., Science Block 302 or West Wing Restroom',
          ),
          'Hall A101',
        );
        await tester.enterText(
          find.byWidgetPredicate(
            (w) => w is TextField && (w.maxLines ?? 0) > 2,
          ),
          'The projector bulb does not power on during lectures.',
        );

        await tester.ensureVisible(find.text('Submit Incident Report'));
        await tester.tap(find.text('Submit Incident Report'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text('Facility sector is currently closed for maintenance.'),
          findsOneWidget,
        );
      },
    );
  });
}
