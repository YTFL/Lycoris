import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/search/data/igdb_service.dart';
import 'package:lycoris/features/search/presentation/screens/game_intake_screen.dart';
import 'package:lycoris/features/search/presentation/screens/game_search_screen.dart';
import 'package:lycoris/features/search/presentation/widgets/game_metadata_preview_dialog.dart';
import 'package:lycoris/features/sync/presentation/controllers/settings_notifier.dart';
import 'package:lycoris/features/tracker/data/game_repository.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/presentation/controllers/library_notifier.dart';
import 'package:lycoris/features/tracker/presentation/controllers/library_state.dart';

// In-memory fake game repository for widget tests
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

  @override
  List<GameEntry> findExisting({required String title, int? igdbId}) {
    return games.where((g) => (igdbId != null && igdbId > 0 && g.igdbId == igdbId) || g.title.toLowerCase() == title.toLowerCase()).toList();
  }

  @override
  Future<void> clearAll() async {
    games.clear();
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
  Future<void> saveGame(GameEntry game) async {
    await repo.save(game);
    state = state.copyWith(allGames: repo.getAll());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsNotifier extends StateNotifier<SettingsState> implements SettingsNotifier {
  FakeSettingsNotifier()
      : super(const SettingsState(
          workerProxyUrl: '',
          twitchClientId: '',
          twitchBearerToken: '',
          primaryCurrency: 'USD',
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('GameMetadataPreviewDialog displays metadata and triggers onContinue', (WidgetTester tester) async {
    final testGame = IGDBSearchResult(
      id: 1234,
      title: 'Hollow Knight: Silksong',
      summary: 'Explore a vast, haunted kingdom in Hollow Knight: Silksong!',
      genres: ['Metroidvania', 'Platformer'],
      releaseDate: DateTime(2025, 12, 1),
    );

    bool continued = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameMetadataPreviewDialog(
            game: testGame,
            onContinue: () {
              continued = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Hollow Knight: Silksong'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('Metroidvania • Platformer'), findsOneWidget);
    expect(find.text('Explore a vast, haunted kingdom in Hollow Knight: Silksong!'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(continued, isTrue);
  });

  testWidgets('GameIntakeScreen renders full title, text-only chips, and adds game', (WidgetTester tester) async {
    final testGame = IGDBSearchResult(
      id: 5678,
      title: 'Elden Ring: Shadow of the Erdtree',
      genres: ['Action RPG'],
      releaseDate: DateTime(2024, 6, 21),
    );

    final fakeRepo = FakeGameRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(fakeRepo),
          libraryNotifierProvider.overrideWith((ref) => FakeLibraryNotifier(fakeRepo)),
          settingsNotifierProvider.overrideWith((ref) => FakeSettingsNotifier()),
        ],
        child: MaterialApp(
          home: GameIntakeScreen(game: testGame),
        ),
      ),
    );

    // Title should be visible and untruncated
    expect(find.text('Elden Ring: Shadow of the Erdtree'), findsOneWidget);
    expect(find.text('Released 2024'), findsOneWidget);

    // Storefront chips should show labels
    expect(find.text('Steam'), findsOneWidget);
    expect(find.text('PlayStation'), findsOneWidget);
    expect(find.text('Nintendo Switch'), findsOneWidget);

    // Status chips should show labels
    expect(find.text('Backlog'), findsOneWidget);
    expect(find.text('Playing'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // Scroll down to reveal and tap Add to Library button
    await tester.ensureVisible(find.text('Add to Library'));
    await tester.tap(find.text('Add to Library'));
    await tester.pump();

    // Verify game was saved into repo
    expect(fakeRepo.games.length, equals(1));
    expect(fakeRepo.games.first.title, equals('Elden Ring: Shadow of the Erdtree'));
  });

  testWidgets('GameSearchScreen renders search bar and manual button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith((ref) => FakeSettingsNotifier()),
        ],
        child: const MaterialApp(
          home: GameSearchScreen(),
        ),
      ),
    );

    expect(find.text('Add Game'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Search IGDB (e.g. Elden Ring, Hades)...'), findsOneWidget);
    expect(find.text('Search IGDB Database'), findsOneWidget);
  });
}
