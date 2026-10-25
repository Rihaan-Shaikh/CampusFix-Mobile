import 'package:campusfix/core/widgets/campus_empty_state.dart';
import 'package:campusfix/core/widgets/campus_status_chip.dart';
import 'package:campusfix/features/issues/presentation/issues_notifier.dart';
import 'package:campusfix/features/issues/presentation/issues_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIssuesNotifier extends IssuesNotifier {
  _FakeIssuesNotifier(this._initialState);
  final IssuesState _initialState;

  @override
  IssuesState build() => _initialState;

  @override
  Future<void> loadInitial() async {}
}

void main() {
  group('IssuesScreen product behavior & layout', () {
    testWidgets(
      'renders real search bar, filter chips, and honest empty state without fake records',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              issuesNotifierProvider.overrideWith(
                () => _FakeIssuesNotifier(const IssuesState()),
              ),
            ],
            child: const MaterialApp(home: IssuesScreen()),
          ),
        );

        // Verify search bar and empty state
        expect(
          find.text('Search by title, location or ref code...'),
          findsOneWidget,
        );
        expect(find.byType(CampusEmptyState), findsOneWidget);
        expect(find.text('No Matching Incidents Found'), findsOneWidget);

        // Ensure no demo/fabricated cards are presented as live issues
        expect(
          find.text('Broken projector in Science Lecture Hall 301'),
          findsNothing,
        );
        expect(
          find.text('Water fountain pressure issue and low flow'),
          findsNothing,
        );
        expect(
          find.text('Air conditioning malfunction in Dormitory Block B'),
          findsNothing,
        );
        expect(
          find.text('Elevator door sensor calibrated and serviced'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders responsive horizontal filter row with interactive chips',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              issuesNotifierProvider.overrideWith(
                () => _FakeIssuesNotifier(const IssuesState()),
              ),
            ],
            child: const MaterialApp(home: IssuesScreen()),
          ),
        );

        // Verify filter chips exist
        expect(find.text('All'), findsOneWidget);
        expect(find.text(IssueStatus.open.label), findsOneWidget);
        expect(find.text(IssueStatus.inProgress.label), findsOneWidget);
        expect(find.text(IssueStatus.resolved.label), findsOneWidget);

        // Tap on 'Open' filter chip
        await tester.tap(find.text(IssueStatus.open.label));
        await tester.pump();

        expect(tester.takeException(), isNull);

        // Tap on 'All' filter chip
        await tester.tap(find.text('All'));
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders correctly on narrow viewport widths without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              issuesNotifierProvider.overrideWith(
                () => _FakeIssuesNotifier(const IssuesState()),
              ),
            ],
            child: const MaterialApp(home: IssuesScreen()),
          ),
        );

        expect(find.byType(CampusEmptyState), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
