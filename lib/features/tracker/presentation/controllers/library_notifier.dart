import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../../../sync/data/settings_repository.dart';
import '../../data/game_repository.dart';
import '../../domain/models/additional_expense.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';
import 'library_state.dart';

// Providers
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(HiveRegistrar.gamesBox);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(HiveRegistrar.settingsBox);
});

final libraryNotifierProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final gameRepo = ref.watch(gameRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return LibraryNotifier(gameRepo, settingsRepo);
});

// Backward compatibility alias during transition
final vaultNotifierProvider = libraryNotifierProvider;

class LibraryNotifier extends StateNotifier<LibraryState> {
  final GameRepository _gameRepo;
  final SettingsRepository _settingsRepo;

  LibraryNotifier(this._gameRepo, this._settingsRepo)
      : super(LibraryState(
          allGames: _gameRepo.getAll(),
          viewMode: LibraryViewMode.fromString(_settingsRepo.shelfViewMode),
        )) {
    // Listen to Hive box mutations to automatically refresh UI
    _gameRepo.listenable().addListener(_onHiveChanged);
  }

  void _onHiveChanged() {
    state = state.copyWith(allGames: _gameRepo.getAll());
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(GameStatus? status) {
    state = state.copyWith(statusFilter: () => status);
  }

  void setStorefrontFilter(Storefront? storefront) {
    state = state.copyWith(storefrontFilter: () => storefront);
  }

  void setSortOption(LibrarySortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void cycleViewMode() {
    final nextMode = state.viewMode.next;
    _settingsRepo.setShelfViewMode(nextMode.name);
    state = state.copyWith(viewMode: nextMode);
  }

  void toggleViewMode() => cycleViewMode();

  Future<void> updateStatus(String gameId, GameStatus status) async {
    final game = _gameRepo.getById(gameId);
    if (game != null) {
      final updated = game.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
  }

  Future<void> updateGameDetails({
    required GameEntry originalGame,
    required String newTitle,
    required Storefront newStorefront,
    required GameStatus newStatus,
    required double newBasePrice,
    required String newCurrency,
    required double newPersonalRating,
    required String newNotes,
  }) async {
    final hasStorefrontChanged = originalGame.storefront != newStorefront;

    if (hasStorefrontChanged) {
      final newId = GameEntry.generateId(
        igdbId: originalGame.igdbId,
        storefront: newStorefront,
        customUuid: originalGame.isCustomEntry ? originalGame.id : null,
      );

      final migratedGame = originalGame.copyWith(
        id: newId,
        title: newTitle,
        storefront: newStorefront,
        status: newStatus,
        basePrice: newBasePrice,
        currency: newCurrency,
        personalRating: newPersonalRating,
        notes: newNotes,
        updatedAt: DateTime.now(),
      );

      await _gameRepo.delete(originalGame.id);
      await _gameRepo.save(migratedGame);
    } else {
      final updated = originalGame.copyWith(
        title: newTitle,
        status: newStatus,
        basePrice: newBasePrice,
        currency: newCurrency,
        personalRating: newPersonalRating,
        notes: newNotes,
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
  }

  Future<void> updateRating(String gameId, double rating) async {
    final game = _gameRepo.getById(gameId);
    if (game != null) {
      final updated = game.copyWith(
        personalRating: rating,
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
  }

  Future<void> updatePlaytime(String gameId, int totalMinutes) async {
    final game = _gameRepo.getById(gameId);
    if (game != null) {
      final updated = game.copyWith(
        totalMinutesPlayed: totalMinutes,
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
  }

  Future<void> updateNotes(String gameId, String notes) async {
    final game = _gameRepo.getById(gameId);
    if (game != null) {
      final updated = game.copyWith(
        notes: notes,
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
  }

  Future<void> addExpense(String gameId, AdditionalExpense expense) async {
    final game = _gameRepo.getById(gameId);
    if (game != null) {
      final updated = game.copyWith(
        additionalExpenses: [...game.additionalExpenses, expense],
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
  }

  Future<void> removeExpense(String gameId, String expenseId) async {
    final game = _gameRepo.getById(gameId);
    if (game != null) {
      final updated = game.copyWith(
        additionalExpenses: game.additionalExpenses.where((e) => e.id != expenseId).toList(),
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
  }

  Future<void> saveGame(GameEntry game) async {
    await _gameRepo.save(game);
  }

  Future<void> deleteGame(String gameId) async {
    await _gameRepo.delete(gameId);
  }

  Future<void> clearAll() async {
    await _gameRepo.clearAll();
  }

  @override
  void dispose() {
    _gameRepo.listenable().removeListener(_onHiveChanged);
    super.dispose();
  }
}

// Backward compatibility alias during transition
typedef VaultNotifier = LibraryNotifier;
