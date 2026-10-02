import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/rankings/domain/models/canonical_game.dart';
import 'package:lycoris/features/rankings/domain/models/ranking_comparison.dart';
import 'package:lycoris/features/rankings/presentation/widgets/help_me_choose_sheet.dart';
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

  testWidgets('HelpMeChooseSheet displays warning banner, metrics, and handles evaluation', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    RankingChoice? returnedChoice;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  returnedChoice = await HelpMeChooseSheet.show(
                    context,
                    gameA: gameA,
                    gameB: gameB,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 1. Verify warning banner text
    expect(
      find.text('Avoid picking Draw as much as possible for a more accurate ranking.'),
      findsOneWidget,
    );

    // 2. Verify metrics are rendered
    expect(find.text('Gameplay & Mechanics'), findsOneWidget);
    expect(find.text('Story & Narrative'), findsOneWidget);
    expect(find.text('Visuals & Art Style'), findsOneWidget);
    expect(find.text('Music & Audio'), findsOneWidget);
    expect(find.text('World & Atmosphere'), findsOneWidget);
    expect(find.text('Pacing & Game Flow'), findsOneWidget);
    expect(find.text('Emotional Impact & Memorability'), findsOneWidget);

    // 3. Verify initially evenly matched
    expect(find.text('Evenly matched (0 - 0)'), findsOneWidget);
    expect(find.text('Choose Draw'), findsOneWidget);

    // 4. Tap Elden Ring on Gameplay (the first 'Elden Ring' choice pill in the list)
    final eldenRingPills = find.widgetWithText(InkWell, 'Elden Ring');
    expect(eldenRingPills, findsWidgets);

    // Tap first pill (Gameplay for Elden Ring)
    await tester.tap(eldenRingPills.first);
    await tester.pumpAndSettle();

    // Now Elden Ring should take the lead!
    expect(find.text('Elden Ring takes the lead (1 to 0)'), findsOneWidget);
    expect(find.text('Choose Elden Ring'), findsOneWidget);

    // 5. Confirm choice and verify returned value
    await tester.tap(find.text('Choose Elden Ring'));
    await tester.pumpAndSettle();

    expect(returnedChoice, equals(RankingChoice.aWins));
  });

  testWidgets('HelpMeChooseSheet allows direct Skip to Draw', (tester) async {
    RankingChoice? returnedChoice;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  returnedChoice = await HelpMeChooseSheet.show(
                    context,
                    gameA: gameA,
                    gameB: gameB,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Skip to Draw'), findsOneWidget);
    await tester.tap(find.text('Skip to Draw'));
    await tester.pumpAndSettle();

    expect(returnedChoice, equals(RankingChoice.draw));
  });
}
