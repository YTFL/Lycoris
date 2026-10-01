import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/tracker/domain/models/additional_expense.dart';
import 'package:lycoris/features/tracker/domain/models/game_entry.dart';
import 'package:lycoris/features/tracker/domain/models/game_status.dart';
import 'package:lycoris/features/tracker/domain/models/storefront.dart';

void main() {
  group('GameEntry & Sync Tests', () {
    test('Composite key generation formats uniquely by storefront', () {
      final steamKey = GameEntry.generateId(
        igdbId: 1942,
        storefront: Storefront.steam,
      );
      final epicKey = GameEntry.generateId(
        igdbId: 1942,
        storefront: Storefront.epicGames,
      );
      final customKey = GameEntry.generateId(
        igdbId: 0,
        storefront: Storefront.other,
        customUuid: 'retro_zelda_hack',
      );

      expect(steamKey, equals('igdb_1942_steam'));
      expect(epicKey, equals('igdb_1942_epicGames'));
      expect(customKey, equals('custom_retro_zelda_hack_other'));
      expect(steamKey, isNot(equals(epicKey)));
    });

    test('Total spent and cost per hour compute accurately with DLC itemization', () {
      final game = GameEntry(
        id: 'igdb_1942_steam',
        igdbId: 1942,
        title: 'NieR:Automata',
        genres: ['Action', 'RPG'],
        storefront: Storefront.steam,
        status: GameStatus.playing,
        basePrice: 39.99,
        currency: 'USD',
        totalMinutesPlayed: 1125, // 18h 45m = 18.75 hours
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        additionalExpenses: [
          AdditionalExpense(
            id: 'dlc_1',
            title: '3C3C1D119440927',
            amount: 13.99,
            date: DateTime(2026, 1, 5),
          ),
        ],
      );

      // Total spent = 39.99 + 13.99 = 53.98
      expect(game.totalSpent, closeTo(53.98, 0.001));

      // Hours = 1125 / 60 = 18.75 hrs
      expect(game.hoursPlayed, equals(18.75));

      // Cost per hour = 53.98 / 18.75 = ~2.8789
      expect(game.costPerHour, closeTo(2.879, 0.01));
    });

    test('JSON serialization roundtrip preserves all fields and LWW updatedAt', () {
      final original = GameEntry(
        id: 'igdb_1234_playstation',
        igdbId: 1234,
        title: 'Bloodborne',
        coverUrl: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co1r7f.jpg',
        genres: ['Action', 'Souls-like'],
        storefront: Storefront.playstation,
        status: GameStatus.completed,
        basePrice: 19.99,
        currency: 'USD',
        totalMinutesPlayed: 2400,
        personalRating: 10.0,
        notes: 'Masterpiece hunt.',
        addedAt: DateTime(2026, 2, 10, 12, 0, 0),
        completedAt: DateTime(2026, 2, 25, 20, 0, 0),
        updatedAt: DateTime(2026, 2, 26, 15, 30, 0),
        isCustomEntry: false,
      );

      final json = original.toJson();
      final restored = GameEntry.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.igdbId, equals(original.igdbId));
      expect(restored.title, equals(original.title));
      expect(restored.coverUrl, equals(original.coverUrl));
      expect(restored.storefront, equals(original.storefront));
      expect(restored.status, equals(original.status));
      expect(restored.basePrice, equals(original.basePrice));
      expect(restored.totalMinutesPlayed, equals(original.totalMinutesPlayed));
      expect(restored.personalRating, equals(original.personalRating));
      expect(restored.notes, equals(original.notes));
      expect(restored.updatedAt, equals(original.updatedAt));
    });

    test('LWW delta merge rule prefers remote if remote.updatedAt is newer', () {
      final localGame = GameEntry(
        id: 'igdb_100_steam',
        igdbId: 100,
        title: 'Hades',
        genres: ['Roguelike'],
        storefront: Storefront.steam,
        status: GameStatus.playing,
        basePrice: 24.99,
        totalMinutesPlayed: 600,
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 10, 10, 0, 0),
      );

      final newerRemoteGame = GameEntry(
        id: 'igdb_100_steam',
        igdbId: 100,
        title: 'Hades',
        genres: ['Roguelike'],
        storefront: Storefront.steam,
        status: GameStatus.completed,
        basePrice: 24.99,
        totalMinutesPlayed: 1800,
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 15, 12, 0, 0), // Newer!
      );

      final olderRemoteGame = GameEntry(
        id: 'igdb_100_steam',
        igdbId: 100,
        title: 'Hades',
        genres: ['Roguelike'],
        storefront: Storefront.steam,
        status: GameStatus.playing,
        basePrice: 24.99,
        totalMinutesPlayed: 300,
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 5, 8, 0, 0), // Older!
      );

      // LWW decision function:
      bool shouldApplyRemote(GameEntry local, GameEntry remote) {
        return remote.updatedAt.isAfter(local.updatedAt);
      }

      expect(shouldApplyRemote(localGame, newerRemoteGame), isTrue);
      expect(shouldApplyRemote(localGame, olderRemoteGame), isFalse);
    });
  });
}
