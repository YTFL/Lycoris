import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/core/utils/value_metric_evaluator.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';
import 'package:lycoris/features/tracker/presentation/widgets/game_ledger_row.dart';
import 'package:lycoris/features/tracker/presentation/widgets/roi_badge.dart';
import 'package:lycoris/features/tracker/presentation/widgets/status_badge.dart';
import 'package:lycoris/features/tracker/presentation/widgets/storefront_badge.dart';

void main() {
  testWidgets('RoiBadge renders label and secondary text', (WidgetTester tester) async {
    const metric = ValueMetric(
      label: 'USD 0.75/hr',
      secondaryText: 'Incredible ROI',
      tier: ValueTier.greatValue,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoiBadge(metric: metric),
        ),
      ),
    );

    expect(find.text('USD 0.75/hr'), findsOneWidget);
    expect(find.text('Incredible ROI'), findsOneWidget);
  });

  testWidgets('StorefrontBadge renders label and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StorefrontBadge(storefront: Storefront.steam),
        ),
      ),
    );

    expect(find.text('Steam'), findsOneWidget);
  });

  testWidgets('StatusBadge renders game progression status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: GameStatus.mastered),
        ),
      ),
    );

    expect(find.text('Mastered (100%)'), findsOneWidget);
  });

  testWidgets('GameLedgerRow displays title and metrics properly', (WidgetTester tester) async {
    final game = GameEntry(
      id: 'test_game',
      igdbId: 101,
      title: 'Hollow Knight',
      genres: ['Metroidvania'],
      storefront: Storefront.steam,
      status: GameStatus.completed,
      basePrice: 14.99,
      currency: 'USD',
      totalMinutesPlayed: 1800, // 30 hours
      personalRating: 9.5,
      addedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameLedgerRow(
            game: game,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Hollow Knight'), findsOneWidget);
    expect(find.text('Steam'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('30h'), findsOneWidget);
    expect(find.text('USD 14.99'), findsOneWidget);
    expect(find.text('9.5'), findsOneWidget);
  });
}
