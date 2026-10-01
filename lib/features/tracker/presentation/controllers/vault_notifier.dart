import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../../../sync/data/settings_repository.dart';
import '../../data/game_repository.dart';
import '../../domain/models/additional_expense.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';
import 'vault_state.dart';

// Providers
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(HiveRegistrar.gamesBox);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(HiveRegistrar.settingsBox);
});

final vaultNotifierProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  final gameRepo = ref.watch(gameRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return VaultNotifier(gameRepo, settingsRepo);
});

class VaultNotifier extends StateNotifier<VaultState> {
  final GameRepository _gameRepo;
  final SettingsRepository _settingsRepo;

  VaultNotifier(this._gameRepo, this._settingsRepo)
      : super(VaultState(
          allGames: _gameRepo.getAll(),
          viewMode: _settingsRepo.shelfViewMode,
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

  void setSortOption(VaultSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void toggleViewMode() {
    final newMode = state.viewMode == 'grid' ? 'list' : 'grid';
    _settingsRepo.setShelfViewMode(newMode);
    state = state.copyWith(viewMode: newMode);
  }

  Future<void> saveGame(GameEntry game) async {
    await _gameRepo.save(game);
  }

  Future<void> deleteGame(String id) async {
    await _gameRepo.delete(id);
  }

  Future<void> updatePlaytime(String gameId, int newTotalMinutes) async {
    final game = _gameRepo.getById(gameId);
    if (game != null) {
      final updated = game.copyWith(
        totalMinutesPlayed: newTotalMinutes,
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
      final updatedList = List<AdditionalExpense>.from(game.additionalExpenses)..add(expense);
      final updated = game.copyWith(
        additionalExpenses: updatedList,
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
  }

  Future<void> removeExpense(String gameId, String expenseId) async {
    final game = _gameRepo.getById(gameId);
    if (game != null) {
      final updatedList = game.additionalExpenses.where((e) => e.id != expenseId).toList();
      final updated = game.copyWith(
        additionalExpenses: updatedList,
        updatedAt: DateTime.now(),
      );
      await _gameRepo.save(updated);
    }
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
