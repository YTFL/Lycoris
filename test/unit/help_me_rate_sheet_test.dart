import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/rankings/domain/models/comparison_metric.dart';
import 'package:lycoris/features/tracker/presentation/widgets/help_me_rate_sheet.dart';

void main() {
  group('HelpMeRateSheet Widget & Rounding Tests', () {
    testWidgets('Renders header, live ticker, all 9 metrics, and 10 stars each', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpMeRateSheet(
              gameTitle: 'Chrono Trigger',
            ),
          ),
        ),
      );

      // Verify title & initial unrated state
      expect(find.text('Help Me Rate'), findsOneWidget);
      expect(find.text('Chrono Trigger'), findsOneWidget);
      expect(find.text('Unrated'), findsOneWidget);
      expect(find.text('Rate dimensions below from 1 to 10 stars'), findsOneWidget);

      // Verify all 9 comparison dimensions are present
      for (final metric in ComparisonMetric.values) {
        expect(find.text(metric.title), findsOneWidget);
      }

      // Verify Apply button is disabled initially
      final applyButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Rate dimensions to calculate'),
      );
      expect(applyButton.onPressed, isNull);
    });

    testWidgets('Tapping stars updates metric score and dynamically calculates rounded rating', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      double? resultingRating;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultingRating = await HelpMeRateSheet.show(
                    context,
                    gameTitle: 'Elden Ring',
                  );
                },
                child: const Text('Open Help Me Rate'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Help Me Rate'));
      await tester.pumpAndSettle();

      // Tap the 9th star of Gameplay & Mechanics using its key
      await tester.tap(find.byKey(const Key('star_gameplay_9')));
      await tester.pumpAndSettle();

      // Ticker should update to 9.0 / 10.0 with 1 dimension rated
      expect(find.text('9.0 / 10.0'), findsOneWidget);
      expect(find.text('1 of 9 dimensions rated (rounded to nearest 0.5)'), findsOneWidget);

      // Apply button should now be enabled and say 'Apply Rating (9.0 / 10)'
      final applyFinder = find.widgetWithText(FilledButton, 'Apply Rating (9.0 / 10)');
      expect(applyFinder, findsOneWidget);

      await tester.tap(applyFinder);
      await tester.pumpAndSettle();

      expect(resultingRating, equals(9.0));
    });

    test('Nearest 0.5 rounding calculation behaves accurately', () {
      // 8.33 -> 8.5
      const avg1 = (8 + 8 + 9) / 3.0; // 8.333333333333334
      final rounded1 = (avg1 * 2).round() / 2.0;
      expect(rounded1, equals(8.5));

      // 8.77 -> 9.0
      const avg2 = (9 + 9 + 8 + 9) / 4.0; // 8.75 -> 9.0 or 8.77 -> 9.0
      final rounded2 = (avg2 * 2).round() / 2.0;
      expect(rounded2, equals(9.0));

      // 8.11 -> 8.0
      const avg3 = (8 + 8 + 8 + 8 + 9) / 5.0; // 8.2 -> 8.0
      final rounded3 = (avg3 * 2).round() / 2.0;
      expect(rounded3, equals(8.0));

      // 7.4 -> 7.5
      const avg4 = 7.4;
      final rounded4 = (avg4 * 2).round() / 2.0;
      expect(rounded4, equals(7.5));
    });
  });
}
