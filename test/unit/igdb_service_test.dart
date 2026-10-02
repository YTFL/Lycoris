import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lycoris/features/search/data/igdb_cache_service.dart';
import 'package:lycoris/features/search/data/igdb_service.dart';

void main() {
  group('IGDBService & Caching Tests', () {
    late Directory tempDir;
    late Box<dynamic> testBox;
    late IGDBCacheService cacheService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_igdb_svc_test_');
      Hive.init(tempDir.path);
      testBox = await Hive.openBox<dynamic>('test_igdb_cache_svc');
      cacheService = IGDBCacheService(box: testBox);
    });

    tearDown(() async {
      await testBox.close();
      await Hive.deleteBoxFromDisk('test_igdb_cache_svc');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final cachedGame = IGDBSearchResult(
      id: 7346,
      title: 'The Legend of Zelda: Breath of the Wild',
      summary: 'Step into a world of discovery, exploration, and adventure.',
      coverBigUrl: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co3p2d.jpg',
      genres: ['Action', 'Adventure'],
      releaseDate: DateTime(2017, 3, 3),
    );

    test('searchGames returns immediately from cache when cached without hitting network', () async {
      await cacheService.cacheQueryResults('zelda', [cachedGame]);

      final service = IGDBService(
        cacheService: cacheService,
        // Intentionally invalid proxy URL to guarantee test fails if network is attempted
        workerProxyUrl: 'http://invalid-unreachable-proxy-host.domain',
      );

      final results = await service.searchGames('zelda');
      expect(results.length, equals(1));
      expect(results.first.id, equals(7346));
      expect(results.first.title, equals('The Legend of Zelda: Breath of the Wild'));
    });

    test('searchGames falls back to offline entity search when network fails', () async {
      // Pre-warm cache with game under a different query
      await cacheService.cacheQueryResults('nintendo', [cachedGame]);

      final service = IGDBService(
        cacheService: cacheService,
        // Invalid proxy URL causes network error
        workerProxyUrl: 'http://invalid-unreachable-proxy-host.domain',
      );

      // Searching for 'breath' is not cached as an exact query, but matches cached entity title
      final results = await service.searchGames('breath');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.title, contains('Breath of the Wild'));
    });

    test('hasDirectTwitchCredentials is true only when both clientId and clientSecret are provided', () {
      final serviceNone = IGDBService();
      expect(serviceNone.hasDirectTwitchCredentials, isFalse);

      final serviceIdOnly = IGDBService(twitchClientId: 'id_123');
      expect(serviceIdOnly.hasDirectTwitchCredentials, isFalse);

      final serviceSecretOnly = IGDBService(twitchClientSecret: 'secret_456');
      expect(serviceSecretOnly.hasDirectTwitchCredentials, isFalse);

      final serviceBoth = IGDBService(
        twitchClientId: 'id_123',
        twitchClientSecret: 'secret_456',
      );
      expect(serviceBoth.hasDirectTwitchCredentials, isTrue);
    });

    test('IGDBSearchResult fromCacheJson and toJson roundtrip', () {
      final json = cachedGame.toJson();
      final reconstructed = IGDBSearchResult.fromCacheJson(json);

      expect(reconstructed.id, equals(cachedGame.id));
      expect(reconstructed.title, equals(cachedGame.title));
      expect(reconstructed.summary, equals(cachedGame.summary));
      expect(reconstructed.coverBigUrl, equals(cachedGame.coverBigUrl));
      expect(reconstructed.genres, equals(cachedGame.genres));
      expect(reconstructed.releaseDate, equals(cachedGame.releaseDate));
    });
  });
}
