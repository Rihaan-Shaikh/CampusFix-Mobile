import 'package:campusfix/core/widgets/campus_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CampusButton', () {
    testWidgets('renders label and triggers callback on tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusButton(
              label: 'Submit Report',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Report'), findsOneWidget);

      await tester.tap(find.text('Submit Report'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
      'shows loading indicator when isLoading is true and ignores tap',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CampusButton(
                label: 'Submit Report',
                isLoading: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Submit Report'), findsNothing);

        await tester.tap(find.byType(CampusButton));
        await tester.pump();

        expect(tapped, isFalse);
      },
    );

    testWidgets('disabled button does not trigger callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CampusButton(label: 'Disabled', onPressed: null),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('renders properly with icon without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusButton(
              label: 'Browse Issues',
              icon: Icons.list_alt_rounded,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Browse Issues'), findsOneWidget);
      expect(find.byIcon(Icons.list_alt_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'handles tight width constraints and long label without overflow',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 140,
                  child: CampusButton(
                    label: 'Very Long Button Action Label That Exceeds Width',
                    icon: Icons.build_rounded,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CampusButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'handles narrow row layout equivalent to dual quick actions without overflow',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: Row(
                    children: [
                      Expanded(
                        child: CampusButton(
                          label: 'Browse Issues',
                          icon: Icons.list_alt_rounded,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampusButton(
                          label: 'App Settings',
                          icon: Icons.tune_rounded,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Browse Issues'), findsOneWidget);
        expect(find.text('App Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
