import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';
import '../../data/rankings_repository.dart';
import '../../domain/models/canonical_game.dart';
import '../../domain/models/game_ranking_data.dart';
import '../../domain/models/ranking_comparison.dart';
import 'rankings_state.dart';

final rankingsRepositoryProvider = Provider<RankingsRepository>((ref) {
  return RankingsRepository(HiveRegistrar.rankingsBox);
});

final rankingsNotifierProvider = StateNotifierProvider<RankingsNotifier, RankingsState>((ref) {
  final repository = ref.watch(rankingsRepositoryProvider);
  final libraryNotifier = ref.watch(libraryNotifierProvider.notifier);
  final libraryGames = ref.watch(libraryNotifierProvider).allGames;
  return RankingsNotifier(repository, libraryGames, libraryNotifier);
});

class RankingsNotifier extends StateNotifier<RankingsState> {
  final RankingsRepository _repository;
  final Random _rng = Random();

  RankingsNotifier(
    this._repository,
    List<dynamic> initialLibraryGames,
    dynamic libraryNotifier,
  ) : super(const RankingsState()) {
    _syncWithLibrary(initialLibraryGames.cast());
  }

  void updateLibraryGames(List<dynamic> rawGames) {
    _syncWithLibrary(rawGames.cast());
  }

  void _syncWithLibrary(List<dynamic> rawGames) {
    final entries = rawGames.whereType().toList();
    final canonical = CanonicalGame.fromGameEntries(entries.cast());
    final storedRatings = _repository.getAllRankings();
    final history = _repository.getHistory();

    final ratingMap = <String, GameRankingData>{};
    for (final game in canonical) {
      ratingMap[game.canonicalKey] = storedRatings[game.canonicalKey] ??
          GameRankingData(canonicalKey: game.canonicalKey);
    }

    final newUnranked = canonical.where((g) {
      final data = ratingMap[g.canonicalKey];
      return data == null || data.comparisonCount == 0;
    }).toList();

    state = state.copyWith(
      canonicalGames: canonical,
      rankingDataMap: ratingMap,
      newUnrankedGames: newUnranked,
      comparisonHistory: history,
    );
  }

  /// Calculates N * log2(N) comparison limit
  int calculateTargetComparisons(int n) {
    if (n < 2) return 0;
    if (n == 2) return 2;
    final log2N = log(n) / ln2;
    return max(5, (n * log2N).ceil());
  }

  /// Start a full ranking session across all eligible canonical games
  void startInitialRanking() {
    if (state.canonicalGames.length < 2) return;

    final target = calculateTargetComparisons(state.canonicalGames.length);
    final firstPair = _findNextPair(onlyNewGames: false);
    if (firstPair == null) return;

    state = state.copyWith(
      currentComparison: () => firstPair,
      currentComparisonIndex: 1,
      totalComparisonsInSession: target,
      isComparisonActive: true,
      isRankingOnlyNewGames: false,
    );
  }

  /// Start ranking only newly added/uncalibrated games against the existing list
  void startRankNewGames() {
    if (state.canonicalGames.length < 2) return;
    if (state.newUnrankedGames.isEmpty) return;

    final n = state.canonicalGames.length;
    final log2N = log(max(2, n)) / ln2;
    final perGameComparisons = max(3, (log2N * 2).ceil());
    final totalPlanned = perGameComparisons * state.newUnrankedGames.length;

    final firstPair = _findNextPair(onlyNewGames: true);
    if (firstPair == null) return;

    state = state.copyWith(
      currentComparison: () => firstPair,
      currentComparisonIndex: 1,
      totalComparisonsInSession: totalPlanned,
      isComparisonActive: true,
      isRankingOnlyNewGames: true,
    );
  }

  /// Reset all rankings and start a brand new ranking session from scratch
  Future<void> startRerankAll() async {
    await _repository.clearAll();

    final resetMap = <String, GameRankingData>{};
    for (final game in state.canonicalGames) {
      resetMap[game.canonicalKey] = GameRankingData(canonicalKey: game.canonicalKey);
    }

    state = state.copyWith(
      rankingDataMap: resetMap,
      comparisonHistory: [],
      newUnrankedGames: List.from(state.canonicalGames),
    );

    startInitialRanking();
  }

  /// Record user choice (A wins, B wins, or Draw)
  Future<void> recordChoice(RankingChoice result) async {
    final comparison = state.currentComparison;
    if (comparison == null) return;

    final keyA = comparison.gameA.canonicalKey;
    final keyB = comparison.gameB.canonicalKey;

    final dataA = state.rankingDataMap[keyA] ?? GameRankingData(canonicalKey: keyA);
    final dataB = state.rankingDataMap[keyB] ?? GameRankingData(canonicalKey: keyB);

    final rA = dataA.eloRating;
    final rB = dataB.eloRating;

    // Expected scores based on Elo logistic curve
    final eA = 1.0 / (1.0 + pow(10.0, (rB - rA) / 400.0));
    final eB = 1.0 - eA;

    // Dynamic K-factor (higher for new games for rapid calibration)
    final kA = dataA.comparisonCount < 6 ? 32.0 : 20.0;
    final kB = dataB.comparisonCount < 6 ? 32.0 : 20.0;

    double sA;
    double sB;
    int aWins = dataA.wins;
    int aLosses = dataA.losses;
    int aDraws = dataA.draws;
    int bWins = dataB.wins;
    int bLosses = dataB.losses;
    int bDraws = dataB.draws;

    switch (result) {
      case RankingChoice.aWins:
        sA = 1.0;
        sB = 0.0;
        aWins++;
        bLosses++;
        break;
      case RankingChoice.bWins:
        sA = 0.0;
        sB = 1.0;
        bWins++;
        aLosses++;
        break;
      case RankingChoice.draw:
        sA = 0.5;
        sB = 0.5;
        aDraws++;
        bDraws++;
        break;
    }

    final deltaA = kA * (sA - eA);
    final deltaB = kB * (sB - eB);

    final updatedDataA = dataA.copyWith(
      eloRating: rA + deltaA,
      wins: aWins,
      losses: aLosses,
      draws: aDraws,
      comparisonCount: dataA.comparisonCount + 1,
      lastRankedAt: DateTime.now(),
    );

    final updatedDataB = dataB.copyWith(
      eloRating: rB + deltaB,
      wins: bWins,
      losses: bLosses,
      draws: bDraws,
      comparisonCount: dataB.comparisonCount + 1,
      lastRankedAt: DateTime.now(),
    );

    await _repository.saveRanking(updatedDataA);
    await _repository.saveRanking(updatedDataB);

    final record = ComparisonRecord(
      canonicalKeyA: keyA,
      canonicalKeyB: keyB,
      result: result,
      deltaA: deltaA,
      deltaB: deltaB,
      timestamp: DateTime.now(),
    );

    final updatedHistory = [record, ...state.comparisonHistory];
    await _repository.saveHistory(updatedHistory);

    final updatedMap = Map<String, GameRankingData>.from(state.rankingDataMap);
    updatedMap[keyA] = updatedDataA;
    updatedMap[keyB] = updatedDataB;

    final nextIndex = state.currentComparisonIndex + 1;
    final isDone = nextIndex > state.totalComparisonsInSession;

    final nextPair = isDone
        ? null
        : _findNextPair(
            onlyNewGames: state.isRankingOnlyNewGames,
            excludeA: keyA,
            excludeB: keyB,
            history: updatedHistory,
          );

    if (nextPair == null) {
      // Finish early if total comparisons reached or no more valid uncompared pairs exist
      state = state.copyWith(
        rankingDataMap: updatedMap,
        comparisonHistory: updatedHistory,
        currentComparison: () => null,
        isComparisonActive: false,
        isRankingOnlyNewGames: false,
        newUnrankedGames: state.canonicalGames.where((g) {
          final d = updatedMap[g.canonicalKey];
          return d == null || d.comparisonCount == 0;
        }).toList(),
      );
    } else {
      state = state.copyWith(
        rankingDataMap: updatedMap,
        comparisonHistory: updatedHistory,
        currentComparison: () => nextPair,
        currentComparisonIndex: nextIndex,
        newUnrankedGames: state.canonicalGames.where((g) {
          final d = updatedMap[g.canonicalKey];
          return d == null || d.comparisonCount == 0;
        }).toList(),
      );
    }
  }

  /// Undo the most recent comparison result
  Future<void> undoLastChoice() async {
    if (state.comparisonHistory.isEmpty) return;

    final lastRecord = state.comparisonHistory.first;
    final updatedHistory = state.comparisonHistory.sublist(1);
    await _repository.saveHistory(updatedHistory);

    final keyA = lastRecord.canonicalKeyA;
    final keyB = lastRecord.canonicalKeyB;

    final dataA = state.rankingDataMap[keyA];
    final dataB = state.rankingDataMap[keyB];

    if (dataA != null && dataB != null) {
      int aWins = dataA.wins;
      int aLosses = dataA.losses;
      int aDraws = dataA.draws;
      int bWins = dataB.wins;
      int bLosses = dataB.losses;
      int bDraws = dataB.draws;

      switch (lastRecord.result) {
        case RankingChoice.aWins:
          aWins = max(0, aWins - 1);
          bLosses = max(0, bLosses - 1);
          break;
        case RankingChoice.bWins:
          bWins = max(0, bWins - 1);
          aLosses = max(0, aLosses - 1);
          break;
        case RankingChoice.draw:
          aDraws = max(0, aDraws - 1);
          bDraws = max(0, bDraws - 1);
          break;
      }

      final revertedDataA = dataA.copyWith(
        eloRating: dataA.eloRating - lastRecord.deltaA,
        wins: aWins,
        losses: aLosses,
        draws: aDraws,
        comparisonCount: max(0, dataA.comparisonCount - 1),
      );

      final revertedDataB = dataB.copyWith(
        eloRating: dataB.eloRating - lastRecord.deltaB,
        wins: bWins,
        losses: bLosses,
        draws: bDraws,
        comparisonCount: max(0, dataB.comparisonCount - 1),
      );

      await _repository.saveRanking(revertedDataA);
      await _repository.saveRanking(revertedDataB);

      final updatedMap = Map<String, GameRankingData>.from(state.rankingDataMap);
      updatedMap[keyA] = revertedDataA;
      updatedMap[keyB] = revertedDataB;

      // Re-load game instances for active comparison
      final gameA = state.canonicalGames.firstWhere((g) => g.canonicalKey == keyA, orElse: () => state.canonicalGames.first);
      final gameB = state.canonicalGames.firstWhere((g) => g.canonicalKey == keyB, orElse: () => state.canonicalGames.last);

      state = state.copyWith(
        rankingDataMap: updatedMap,
        comparisonHistory: updatedHistory,
        currentComparison: () => RankingComparison(gameA: gameA, gameB: gameB),
        currentComparisonIndex: max(1, state.currentComparisonIndex - 1),
        isComparisonActive: true,
      );
    }
  }

  /// Skip the current pair and pick a different match
  void skipComparison() {
    final nextPair = _findNextPair(
      onlyNewGames: state.isRankingOnlyNewGames,
      avoidSameAsCurrent: true,
    );
    if (nextPair != null) {
      state = state.copyWith(
        currentComparison: () => nextPair,
      );
    } else {
      finishSessionEarly();
    }
  }

  /// Conclude active session early and return to rankings view
  void finishSessionEarly() {
    state = state.copyWith(
      isComparisonActive: false,
      isRankingOnlyNewGames: false,
      currentComparison: () => null,
    );
  }

  /// Matchmaking algorithm: selects the pair offering maximal rating information
  /// Never repeats a pair that has already been compared.
  /// If no uncompared, reasonably ranked pairs remain, returns null to finish early.
  RankingComparison? _findNextPair({
    required bool onlyNewGames,
    String? excludeA,
    String? excludeB,
    bool avoidSameAsCurrent = false,
    List<ComparisonRecord>? history,
  }) {
    final games = state.canonicalGames;
    if (games.length < 2) return null;

    final compHistory = history ?? state.comparisonHistory;
    final currentA = state.currentComparison?.gameA.canonicalKey;
    final currentB = state.currentComparison?.gameB.canonicalKey;

    final candidates = <_PairCandidate>[];

    for (int i = 0; i < games.length; i++) {
      for (int j = i + 1; j < games.length; j++) {
        final gA = games[i];
        final gB = games[j];

        // 1. NEVER REPEAT: Disqualify any pair that has already been compared
        final alreadyCompared = compHistory.any((rec) =>
            (rec.canonicalKeyA == gA.canonicalKey && rec.canonicalKeyB == gB.canonicalKey) ||
            (rec.canonicalKeyA == gB.canonicalKey && rec.canonicalKeyB == gA.canonicalKey));
        if (alreadyCompared) continue;

        // 2. Skip if it is the current comparison and avoidSameAsCurrent is requested
        if (avoidSameAsCurrent &&
            ((gA.canonicalKey == currentA && gB.canonicalKey == currentB) ||
             (gA.canonicalKey == currentB && gB.canonicalKey == currentA))) {
          continue;
        }

        // 3. Skip if matches excludeA / excludeB
        if ((gA.canonicalKey == excludeA && gB.canonicalKey == excludeB) ||
            (gA.canonicalKey == excludeB && gB.canonicalKey == excludeA)) {
          continue;
        }

        final dataA = state.rankingDataMap[gA.canonicalKey] ?? GameRankingData(canonicalKey: gA.canonicalKey);
        final dataB = state.rankingDataMap[gB.canonicalKey] ?? GameRankingData(canonicalKey: gB.canonicalKey);

        // 4. If ranking only new games, at least one game MUST be uncalibrated (< 3 comparisons)
        if (onlyNewGames) {
          final isAUncalibrated = dataA.comparisonCount < 3;
          final isBUncalibrated = dataB.comparisonCount < 3;
          if (!isAUncalibrated && !isBUncalibrated) continue;
        }

        final ratingDist = (dataA.eloRating - dataB.eloRating).abs();

        // 5. Must be reasonably ranked:
        // If both games have had at least 2 comparisons, their rating distance must be reasonable (<= 400.0)
        // If the gap exceeds 400.0 (>91% expected win probability), pairing them gives minimal rating information
        final isBothCalibrated = dataA.comparisonCount >= 2 && dataB.comparisonCount >= 2;
        if (isBothCalibrated && ratingDist > 400.0) {
          continue;
        }

        // Calculate matchup score (lower is better):
        // Closer ratings give higher information entropy
        // Games with fewer comparisons get higher priority
        final uncalibratedScore = (10 - min(10, dataA.comparisonCount)) + (10 - min(10, dataB.comparisonCount));
        final jitter = _rng.nextDouble() * 20.0;

        final score = ratingDist - (uncalibratedScore * 40.0) + jitter;
        candidates.add(_PairCandidate(gameA: gA, gameB: gB, score: score));
      }
    }

    if (candidates.isEmpty) {
      // No more uncompared, reasonably ranked pairs exist!
      // Return null so the session finishes early cleanly.
      return null;
    }

    candidates.sort((a, b) => a.score.compareTo(b.score));
    final chosen = candidates.first;

    // Randomize left vs right orientation
    if (_rng.nextBool()) {
      return RankingComparison(gameA: chosen.gameA, gameB: chosen.gameB);
    } else {
      return RankingComparison(gameA: chosen.gameB, gameB: chosen.gameA);
    }
  }
}

class _PairCandidate {
  final CanonicalGame gameA;
  final CanonicalGame gameB;
  final double score;

  _PairCandidate({
    required this.gameA,
    required this.gameB,
    required this.score,
  });
}
