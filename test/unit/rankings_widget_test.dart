import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/rankings/domain/models/canonical_game.dart';
import 'package:lycoris/features/rankings/domain/models/game_ranking_data.dart';
import 'package:lycoris/features/rankings/domain/models/ranking_comparison.dart';
import 'package:lycoris/features/rankings/presentation/controllers/rankings_state.dart';
import 'package:lycoris/features/rankings/presentation/widgets/ranking_comparison_view.dart';
import 'package:lycoris/features/rankings/presentation/widgets/ranking_list_tile.dart';
import 'package:lycoris/features/rankings/presentation/widgets/ranking_top5_showcase.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';

void main() {
  final gameA = CanonicalGame(
    canonicalKey: 'igdb_1',
    title: 'Elden Ring',
    coverUrl: null,
    highestStatus: GameStatus.mastered,
    totalMinutesPlayed: 6000,
    storefronts: [Storefront.steam],
    gameEntryIds: ['g1'],
    primaryEntryId: 'g1',
    genres: ['Action RPG'],
    personalRating: 10.0,
  );

  final gameB = CanonicalGame(
    canonicalKey: 'igdb_2',
    title: 'Hollow Knight',
    coverUrl: null,
    highestStatus: GameStatus.completed,
    totalMinutesPlayed: 2400,
    storefronts: [Storefront.steam],
    gameEntryIds: ['g2'],
    primaryEntryId: 'g2',
    genres: ['Metroidvania'],
    personalRating: 9.5,
  );

  testWidgets('RankingComparisonView renders Pick one, banners, and clean Draw button', (tester) async {
    RankingChoice? selectedResult;

    final comparison = RankingComparison(gameA: gameA, gameB: gameB);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RankingComparisonView(
            comparison: comparison,
            currentComparisonIndex: 1,
            totalComparisonsInSession: 10,
            canUndo: false,
            isReliable: false,
            onChoose: (result) => selectedResult = result,
            onUndo: () {},
            onSkip: () {},
            onFinishEarly: () {},
            onExit: () {},
          ),
        ),
      ),
    );

    // Verify Header
    expect(find.text('Pick one'), findsOneWidget);
    expect(find.text('Comparison 1 of 10'), findsOneWidget);

    // Verify Game Titles on banners
    expect(find.text('Elden Ring'), findsOneWidget);
    expect(find.text('Hollow Knight'), findsOneWidget);

    // Verify Finish Early button is disabled when isReliable is false
    final finishEarlyButton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Finish Early'));
    expect(finishEarlyButton.onPressed, isNull);

    // Verify Help Me Choose button
    expect(find.text('Help Me Choose'), findsOneWidget);

    // Tap Help Me Choose and skip to draw
    await tester.tap(find.text('Help Me Choose'));
    await tester.pumpAndSettle();
    expect(find.text('Avoid picking Draw as much as possible for a more accurate ranking.'), findsOneWidget);
    await tester.tap(find.text('Skip to Draw'));
    await tester.pumpAndSettle();
    expect(selectedResult, equals(RankingChoice.draw));

    // Tap Game A Banner
    await tester.tap(find.text('Elden Ring'));
    await tester.pump();
    expect(selectedResult, equals(RankingChoice.aWins));

    // Tap Game B Banner
    await tester.tap(find.text('Hollow Knight'));
    await tester.pump();
    expect(selectedResult, equals(RankingChoice.bWins));
  });

  testWidgets('RankingTop5Showcase renders clean rank badges without tier names or points', (tester) async {
    final topItems = [
      RankedGameItem(
        rank: 1,
        game: gameA,
        data: const GameRankingData(canonicalKey: 'igdb_1', eloRating: 1420),
      ),
      RankedGameItem(
        rank: 2,
        game: gameB,
        data: const GameRankingData(canonicalKey: 'igdb_2', eloRating: 1350),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RankingTop5Showcase(
              topItems: topItems,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Top Tier Rankings'), findsNothing);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('Diamond'), findsNothing);
    expect(find.text('Platinum'), findsNothing);
    expect(find.text('1420 pts'), findsNothing);
  });

  testWidgets('RankingListTile displays rank, title, record without points or status badge', (tester) async {
    bool tapped = false;
    final item = RankedGameItem(
      rank: 6,
      game: gameA,
      data: const GameRankingData(
        canonicalKey: 'igdb_1',
        eloRating: 1285.4,
        wins: 4,
        losses: 2,
        draws: 1,
        comparisonCount: 7,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RankingListTile(
            item: item,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('#6'), findsOneWidget);
    expect(find.text('Elden Ring'), findsOneWidget);
    expect(find.text('1285 pts'), findsNothing);
    expect(find.text('4W - 2L - 1D'), findsNothing);

    await tester.tap(find.text('Elden Ring'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
