import 'dart:math';
import '../../domain/models/canonical_game.dart';
import '../../domain/models/game_ranking_data.dart';
import '../../domain/models/ranking_comparison.dart';

class RankedGameItem {
  final int rank;
  final CanonicalGame game;
  final GameRankingData data;

  const RankedGameItem({
    required this.rank,
    required this.game,
    required this.data,
  });
}

class RankingsState {
  final List<CanonicalGame> canonicalGames;
  final Map<String, GameRankingData> rankingDataMap;
  final RankingComparison? currentComparison;
  final int currentComparisonIndex;
  final int totalComparisonsInSession;
  final bool isComparisonActive;
  final bool isRankingOnlyNewGames;
  final List<CanonicalGame> newUnrankedGames;
  final List<ComparisonRecord> comparisonHistory;

  const RankingsState({
    this.canonicalGames = const [],
    this.rankingDataMap = const {},
    this.currentComparison,
    this.currentComparisonIndex = 0,
    this.totalComparisonsInSession = 0,
    this.isComparisonActive = false,
    this.isRankingOnlyNewGames = false,
    this.newUnrankedGames = const [],
    this.comparisonHistory = const [],
  });

  bool get canUndo => comparisonHistory.isNotEmpty;

  /// True if at least one comparison has been recorded
  bool get hasRankings => rankingDataMap.values.any((d) => d.comparisonCount > 0);

  /// True when all canonical games have completed sufficient comparisons for baseline stability
  bool get isReliable {
    if (canonicalGames.isEmpty) return false;
    final minRequired = min(3, max(1, canonicalGames.length - 1));
    if (isRankingOnlyNewGames) {
      if (newUnrankedGames.isEmpty) return true;
      return newUnrankedGames.every(
        (g) => (rankingDataMap[g.canonicalKey]?.comparisonCount ?? 0) >= minRequired,
      );
    }
    return canonicalGames.every(
      (g) => (rankingDataMap[g.canonicalKey]?.comparisonCount ?? 0) >= minRequired,
    );
  }

  /// Sorted list of games by Elo rating descending
  List<RankedGameItem> get rankedList {
    final list = canonicalGames.map((g) {
      final data = rankingDataMap[g.canonicalKey] ?? GameRankingData(canonicalKey: g.canonicalKey);
      return MapEntry(g, data);
    }).toList();

    list.sort((a, b) {
      // 1. Prioritize games with at least 1 comparison
      final aActive = a.value.comparisonCount > 0 ? 1 : 0;
      final bActive = b.value.comparisonCount > 0 ? 1 : 0;
      if (aActive != bActive) return bActive.compareTo(aActive);

      // 2. Sort by Elo rating descending
      final cmpElo = b.value.eloRating.compareTo(a.value.eloRating);
      if (cmpElo != 0) return cmpElo;

      // 3. Tie-break by win rate
      final cmpWinRate = b.value.winRate.compareTo(a.value.winRate);
      if (cmpWinRate != 0) return cmpWinRate;

      // 4. Tie-break by total playtime
      return b.key.totalMinutesPlayed.compareTo(a.key.totalMinutesPlayed);
    });

    final ranked = <RankedGameItem>[];
    for (int i = 0; i < list.length; i++) {
      ranked.add(
        RankedGameItem(
          rank: i + 1,
          game: list[i].key,
          data: list[i].value,
        ),
      );
    }
    return ranked;
  }

  RankingsState copyWith({
    List<CanonicalGame>? canonicalGames,
    Map<String, GameRankingData>? rankingDataMap,
    RankingComparison? Function()? currentComparison,
    int? currentComparisonIndex,
    int? totalComparisonsInSession,
    bool? isComparisonActive,
    bool? isRankingOnlyNewGames,
    List<CanonicalGame>? newUnrankedGames,
    List<ComparisonRecord>? comparisonHistory,
  }) {
    return RankingsState(
      canonicalGames: canonicalGames ?? this.canonicalGames,
      rankingDataMap: rankingDataMap ?? this.rankingDataMap,
      currentComparison: currentComparison != null ? currentComparison() : this.currentComparison,
      currentComparisonIndex: currentComparisonIndex ?? this.currentComparisonIndex,
      totalComparisonsInSession: totalComparisonsInSession ?? this.totalComparisonsInSession,
      isComparisonActive: isComparisonActive ?? this.isComparisonActive,
      isRankingOnlyNewGames: isRankingOnlyNewGames ?? this.isRankingOnlyNewGames,
      newUnrankedGames: newUnrankedGames ?? this.newUnrankedGames,
      comparisonHistory: comparisonHistory ?? this.comparisonHistory,
    );
  }
}
