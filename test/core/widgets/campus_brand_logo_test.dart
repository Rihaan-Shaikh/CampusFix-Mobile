import 'package:campusfix/core/widgets/campus_brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CampusBrandLogo', () {
    testWidgets('renders approved image logo with specified dimensions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: CampusBrandLogo(size: 40))),
        ),
      );

      expect(find.byType(CampusBrandLogo), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      final sizedBoxFinder = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 40 && w.height == 40,
      );
      expect(sizedBoxFinder, findsOneWidget);
    });

    testWidgets('renders vector fallback painter when requested', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusBrandLogo(size: 40, useVectorFallback: true),
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CampusBrandLogo),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders wordmark RichText when showWordmark is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CampusBrandLogo(size: 32, showWordmark: true)),
          ),
        ),
      );

      expect(find.byType(CampusBrandLogo), findsOneWidget);
      expect(find.byType(RichText), findsOneWidget);
    });
  });
}
