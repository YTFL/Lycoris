import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/tracker/data/game_repository.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';
import 'package:lycoris/features/tracker/presentation/controllers/library_notifier.dart';
import 'package:lycoris/features/tracker/presentation/controllers/library_state.dart';
import 'package:lycoris/features/tracker/presentation/widgets/edit_game_modal.dart';

class FakeGameRepository extends Fake implements GameRepository {
  final List<GameEntry> games = [];

  @override
  List<GameEntry> getAll() => List.unmodifiable(games);

  @override
  Future<void> save(GameEntry game) async {
    final idx = games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) {
      games[idx] = game;
    } else {
      games.add(game);
    }
  }

  @override
  Future<void> delete(String id) async {
    games.removeWhere((g) => g.id == id);
  }

  @override
  GameEntry? getById(String id) {
    try {
      return games.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}

class FakeLibraryNotifier extends StateNotifier<LibraryState> implements LibraryNotifier {
  final FakeGameRepository repo;

  FakeLibraryNotifier(this.repo)
      : super(LibraryState(
          allGames: repo.getAll(),
          viewMode: LibraryViewMode.grid2,
        ));

  @override
  Future<void> updateGameDetails({
    required GameEntry originalGame,
    required String newTitle,
    required Storefront newStorefront,
    required GameStatus newStatus,
    required double newBasePrice,
    required String newCurrency,
    double? newPersonalRating,
    String? newNotes,
  }) async {
    final updated = originalGame.copyWith(
      title: newTitle,
      storefront: newStorefront,
      status: newStatus,
      basePrice: newBasePrice,
      currency: newCurrency,
      personalRating: newPersonalRating ?? originalGame.personalRating,
      notes: newNotes ?? originalGame.notes,
      updatedAt: DateTime.now(),
    );
    await repo.save(updated);
    state = state.copyWith(allGames: repo.getAll());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('EditGameModal does not display Personal Rating slider or Notes field, preserves them on save', (WidgetTester tester) async {
    final testGame = GameEntry(
      id: 'igdb_9999_steam',
      igdbId: 9999,
      title: 'Hades II',
      genres: ['Roguelike'],
      storefront: Storefront.steam,
      status: GameStatus.playing,
      totalMinutesPlayed: 1200,
      basePrice: 29.99,
      currency: 'USD',
      personalRating: 9.5,
      notes: 'Superb combat and art design!',
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final fakeRepo = FakeGameRepository();
    fakeRepo.games.add(testGame);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(fakeRepo),
          libraryNotifierProvider.overrideWith((ref) => FakeLibraryNotifier(fakeRepo)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EditGameModal(game: testGame),
          ),
        ),
      ),
    );

    // Verify modal header and metadata inputs
    expect(find.text('Edit Game Details'), findsOneWidget);
    expect(find.text('Game Title'), findsOneWidget);
    expect(find.text('Storefront / Platform'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);

    // Verify Personal Rating slider and Notes are completely removed
    expect(find.text('Personal Rating'), findsNothing);
    expect(find.text('Notes / Thoughts'), findsNothing);
    expect(find.byType(Slider), findsNothing);

    // Tap Save Details
    await tester.tap(find.text('Save Details'));
    await tester.pumpAndSettle();

    // Verify the saved game in repository retained original rating and notes
    expect(fakeRepo.games.length, equals(1));
    final savedGame = fakeRepo.games.first;
    expect(savedGame.personalRating, equals(9.5));
    expect(savedGame.notes, equals('Superb combat and art design!'));
  });
}
