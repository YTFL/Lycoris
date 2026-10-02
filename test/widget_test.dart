import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/core/utils/value_metric_evaluator.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';
import 'package:lycoris/features/tracker/presentation/controllers/library_state.dart';
import 'package:lycoris/features/tracker/presentation/widgets/game_cover_card.dart';
import 'package:lycoris/features/tracker/presentation/widgets/game_list_row.dart';
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

  testWidgets('GameListRow displays minimal title, playtime, and rating', (WidgetTester tester) async {
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
          body: GameListRow(
            game: game,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Hollow Knight'), findsOneWidget);
    expect(find.text('30h'), findsOneWidget);
    expect(find.text('9.5'), findsOneWidget);
  });

  testWidgets('GameCoverCard displays minimal title, playtime, and rating', (WidgetTester tester) async {
    final game = GameEntry(
      id: 'test_game_card',
      igdbId: 102,
      title: 'Elden Ring',
      genres: ['Action RPG'],
      storefront: Storefront.steam,
      status: GameStatus.playing,
      basePrice: 59.99,
      currency: 'USD',
      totalMinutesPlayed: 7200, // 120 hours
      personalRating: 10.0,
      addedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 250,
            child: GameCoverCard(
              game: game,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Elden Ring'), findsOneWidget);
    expect(find.text('120h'), findsOneWidget);
    expect(find.text('10.0'), findsOneWidget);
  });

  test('LibraryViewMode cycles sequentially through 4 modes', () {
    expect(LibraryViewMode.grid2.next, equals(LibraryViewMode.grid3));
    expect(LibraryViewMode.grid3.next, equals(LibraryViewMode.grid4));
    expect(LibraryViewMode.grid4.next, equals(LibraryViewMode.list));
    expect(LibraryViewMode.list.next, equals(LibraryViewMode.grid2));
  });
}
