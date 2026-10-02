import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lycoris/features/rankings/data/rankings_repository.dart';
import 'package:lycoris/features/rankings/domain/models/canonical_game.dart';
import 'package:lycoris/features/rankings/domain/models/game_ranking_data.dart';
import 'package:lycoris/features/rankings/domain/models/ranking_comparison.dart';
import 'package:lycoris/features/rankings/domain/models/ranking_tier.dart';
import 'package:lycoris/features/rankings/presentation/controllers/rankings_notifier.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> testBox;
  late RankingsRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lycoris_rankings_test_');
    Hive.init(tempDir.path);
    testBox = await Hive.openBox<dynamic>('test_game_rankings');
    repo = RankingsRepository(testBox);
  });

  tearDown(() async {
    await testBox.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CanonicalGame Eligibility & Deduplication Tests', () {
    test('Eligibility rules: completed, mastered, and abandoned with playtime are eligible', () {
      final completed = GameEntry(
        id: '1',
        igdbId: 10,
        title: 'Game 1',
        genres: [],
        storefront: Storefront.steam,
        status: GameStatus.completed,
        totalMinutesPlayed: 0,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final mastered = GameEntry(
        id: '2',
        igdbId: 20,
        title: 'Game 2',
        genres: [],
        storefront: Storefront.playstation,
        status: GameStatus.mastered,
        totalMinutesPlayed: 100,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final abandonedWithPlaytime = GameEntry(
        id: '3',
        igdbId: 30,
        title: 'Game 3',
        genres: [],
        storefront: Storefront.gog,
        status: GameStatus.abandoned,
        totalMinutesPlayed: 45,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final abandonedNoPlaytime = GameEntry(
        id: '4',
        igdbId: 40,
        title: 'Game 4',
        genres: [],
        storefront: Storefront.epicGames,
        status: GameStatus.abandoned,
        totalMinutesPlayed: 0,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final playing = GameEntry(
        id: '5',
        igdbId: 50,
        title: 'Game 5',
        genres: [],
        storefront: Storefront.steam,
        status: GameStatus.playing,
        totalMinutesPlayed: 600,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final backlog = GameEntry(
        id: '6',
        igdbId: 60,
        title: 'Game 6',
        genres: [],
        storefront: Storefront.steam,
        status: GameStatus.backlog,
        totalMinutesPlayed: 0,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(CanonicalGame.isEligible(completed), isTrue);
      expect(CanonicalGame.isEligible(mastered), isTrue);
      expect(CanonicalGame.isEligible(abandonedWithPlaytime), isTrue);
      expect(CanonicalGame.isEligible(abandonedNoPlaytime), isFalse);
      expect(CanonicalGame.isEligible(playing), isFalse);
      expect(CanonicalGame.isEligible(backlog), isFalse);
    });

    test('Deduplicates cross-storefront copies into one CanonicalGame with aggregate playtime', () {
      final steamCopy = GameEntry(
        id: 'igdb_100_steam',
        igdbId: 100,
        title: 'The Witcher 3',
        coverUrl: 'https://image.com/cover.jpg',
        genres: ['RPG'],
        storefront: Storefront.steam,
        status: GameStatus.completed,
        totalMinutesPlayed: 3000, // 50h
        addedAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final gogCopy = GameEntry(
        id: 'igdb_100_gog',
        igdbId: 100,
        title: 'The Witcher 3: Wild Hunt',
        genres: ['Action', 'RPG'],
        storefront: Storefront.gog,
        status: GameStatus.mastered, // Higher status
        totalMinutesPlayed: 1200, // 20h
        addedAt: DateTime(2025, 2, 1),
        updatedAt: DateTime(2025, 2, 1),
      );

      final canonical = CanonicalGame.fromGameEntries([steamCopy, gogCopy]);

      expect(canonical.length, equals(1));
      final game = canonical.first;
      expect(game.canonicalKey, equals('igdb_100'));
      expect(game.totalMinutesPlayed, equals(4200)); // 3000 + 1200 = 70h
      expect(game.hoursPlayed, equals(70.0));
      expect(game.highestStatus, equals(GameStatus.mastered));
      expect(game.storefronts.contains(Storefront.steam), isTrue);
      expect(game.storefronts.contains(Storefront.gog), isTrue);
    });

    test('Custom manual entries without igdbId group by trimmed lowercase title', () {
      final custom1 = GameEntry(
        id: 'custom_1_steam',
        igdbId: 0,
        title: 'Indie Gem ',
        genres: [],
        storefront: Storefront.steam,
        status: GameStatus.completed,
        totalMinutesPlayed: 60,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final custom2 = GameEntry(
        id: 'custom_2_itch',
        igdbId: 0,
        title: '  indie gem',
        genres: [],
        storefront: Storefront.itchIo,
        status: GameStatus.completed,
        totalMinutesPlayed: 120,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final canonical = CanonicalGame.fromGameEntries([custom1, custom2]);
      expect(canonical.length, equals(1));
      expect(canonical.first.canonicalKey, equals('title_indie gem'));
      expect(canonical.first.totalMinutesPlayed, equals(180));
    });
  });

  group('RankingTier Tests', () {
    test('Top 5 ranks match Diamond, Platinum, Gold, Silver, Bronze', () {
      expect(RankingTier.forRank(1), equals(RankingTier.diamond));
      expect(RankingTier.forRank(2), equals(RankingTier.platinum));
      expect(RankingTier.forRank(3), equals(RankingTier.gold));
      expect(RankingTier.forRank(4), equals(RankingTier.silver));
      expect(RankingTier.forRank(5), equals(RankingTier.bronze));
      expect(RankingTier.forRank(6), equals(RankingTier.standard));
      expect(RankingTier.forRank(10), equals(RankingTier.standard));
    });
  });

  group('Elo Algorithm & Matchmaking Notifier Tests', () {
    test('calculateTargetComparisons caps at N * log2(N)', () {
      final notifier = RankingsNotifier(repo, [], null);
      expect(notifier.calculateTargetComparisons(2), equals(2));
      expect(notifier.calculateTargetComparisons(4), equals(8));
      // 10 * log2(10) = 10 * 3.3219 = 33.22 -> ceil = 34
      expect(notifier.calculateTargetComparisons(10), equals(34));
    });

    test('Game A win increases A rating and decreases B rating', () async {
      final games = [
        GameEntry(
          id: 'g1',
          igdbId: 1,
          title: 'Game A',
          genres: [],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 100,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        GameEntry(
          id: 'g2',
          igdbId: 2,
          title: 'Game B',
          genres: [],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 100,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final notifier = RankingsNotifier(repo, games, null);
      notifier.startInitialRanking();

      expect(notifier.state.isComparisonActive, isTrue);
      expect(notifier.state.currentComparison, isNotNull);

      final leftKey = notifier.state.currentComparison!.gameA.canonicalKey;
      final rightKey = notifier.state.currentComparison!.gameB.canonicalKey;

      // Record Left game win
      await notifier.recordChoice(RankingChoice.aWins);

      final rWinner = notifier.state.rankingDataMap[leftKey]!;
      final rLoser = notifier.state.rankingDataMap[rightKey]!;

      expect(rWinner.eloRating, greaterThan(1200.0));
      expect(rLoser.eloRating, lessThan(1200.0));
      expect(rWinner.wins, equals(1));
      expect(rLoser.losses, equals(1));
      expect(rWinner.comparisonCount, equals(1));
      expect(rLoser.comparisonCount, equals(1));
    });

    test('Draw between equal ratings yields zero rating change', () async {
      final games = [
        GameEntry(
          id: 'g1',
          igdbId: 1,
          title: 'Game A',
          genres: [],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 100,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        GameEntry(
          id: 'g2',
          igdbId: 2,
          title: 'Game B',
          genres: [],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 100,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final notifier = RankingsNotifier(repo, games, null);
      notifier.startInitialRanking();

      // Record Draw
      await notifier.recordChoice(RankingChoice.draw);

      final rA = notifier.state.rankingDataMap['igdb_1']!;
      final rB = notifier.state.rankingDataMap['igdb_2']!;

      // 1200 + 32 * (0.5 - 0.5) = 1200
      expect(rA.eloRating, closeTo(1200.0, 0.001));
      expect(rB.eloRating, closeTo(1200.0, 0.001));
      expect(rA.draws, equals(1));
      expect(rB.draws, equals(1));
      // In a 2-game pool, after the only pair is compared, session finishes early without repeating
      expect(notifier.state.isComparisonActive, isFalse);
      expect(notifier.state.currentComparison, isNull);
    });

    test('Never repeats already-compared pairs and finishes session early', () async {
      final games = [
        GameEntry(
          id: 'g1',
          igdbId: 1,
          title: 'Game A',
          genres: [],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 100,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        GameEntry(
          id: 'g2',
          igdbId: 2,
          title: 'Game B',
          genres: [],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 100,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final notifier = RankingsNotifier(repo, games, null);
      notifier.startInitialRanking();
      expect(notifier.state.isComparisonActive, isTrue);

      await notifier.recordChoice(RankingChoice.aWins);

      // Session finishes early instead of asking Game A vs Game B again
      expect(notifier.state.isComparisonActive, isFalse);
      expect(notifier.state.currentComparison, isNull);
    });

    test('Undo restores exact previous Elo ratings and match stats', () async {
      final games = [
        GameEntry(
          id: 'g1',
          igdbId: 1,
          title: 'Game A',
          genres: [],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 100,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        GameEntry(
          id: 'g2',
          igdbId: 2,
          title: 'Game B',
          genres: [],
          storefront: Storefront.steam,
          status: GameStatus.completed,
          totalMinutesPlayed: 100,
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final notifier = RankingsNotifier(repo, games, null);
      notifier.startInitialRanking();

      final winnerKey = notifier.state.currentComparison!.gameA.canonicalKey;
      final loserKey = notifier.state.currentComparison!.gameB.canonicalKey;

      await notifier.recordChoice(RankingChoice.aWins);
      expect(notifier.state.rankingDataMap[winnerKey]!.eloRating, greaterThan(1200.0));
      expect(notifier.state.rankingDataMap[loserKey]!.eloRating, lessThan(1200.0));

      // Undo
      await notifier.undoLastChoice();
      final rA = notifier.state.rankingDataMap['igdb_1']!;
      final rB = notifier.state.rankingDataMap['igdb_2']!;

      expect(rA.eloRating, closeTo(1200.0, 0.001));
      expect(rB.eloRating, closeTo(1200.0, 0.001));
      expect(rA.wins, equals(0));
      expect(rA.comparisonCount, equals(0));
    });

    test('Rankings persistence roundtrip via repository', () async {
      final data = GameRankingData(
        canonicalKey: 'igdb_99',
        eloRating: 1354.5,
        wins: 4,
        losses: 1,
        draws: 2,
        comparisonCount: 7,
        lastRankedAt: DateTime(2026, 10, 2),
      );

      await repo.saveRanking(data);

      final retrieved = repo.getRanking('igdb_99');
      expect(retrieved.canonicalKey, equals('igdb_99'));
      expect(retrieved.eloRating, equals(1354.5));
      expect(retrieved.wins, equals(4));
      expect(retrieved.losses, equals(1));
      expect(retrieved.draws, equals(2));
      expect(retrieved.comparisonCount, equals(7));
      expect(retrieved.isCalibrated, isTrue);
    });
  });
}
