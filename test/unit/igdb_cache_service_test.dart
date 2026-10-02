import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lycoris/features/search/data/igdb_cache_service.dart';
import 'package:lycoris/features/search/data/igdb_service.dart';

void main() {
  group('IGDBCacheService Tests', () {
    late Directory tempDir;
    late Box<dynamic> testBox;
    late IGDBCacheService cacheService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_igdb_test_');
      Hive.init(tempDir.path);
      testBox = await Hive.openBox<dynamic>('test_igdb_cache');
      cacheService = IGDBCacheService(box: testBox);
    });

    tearDown(() async {
      await testBox.close();
      await Hive.deleteBoxFromDisk('test_igdb_cache');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final sampleResults = [
      IGDBSearchResult(
        id: 119133,
        title: 'Elden Ring',
        summary: 'A vast fantasy action-RPG.',
        coverBigUrl: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co4jni.jpg',
        cover720pUrl: 'https://images.igdb.com/igdb/image/upload/t_720p/co4jni.jpg',
        genres: ['Role-playing (RPG)', 'Adventure'],
        releaseDate: DateTime(2022, 2, 25),
      ),
      IGDBSearchResult(
        id: 112875,
        title: 'Hades',
        summary: 'A god-like rogue-like dungeon crawler.',
        coverBigUrl: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co1r7f.jpg',
        cover720pUrl: 'https://images.igdb.com/igdb/image/upload/t_720p/co1r7f.jpg',
        genres: ['Indie', 'Action', 'Hack and slash'],
        releaseDate: DateTime(2020, 9, 17),
      ),
    ];

    test('cacheQueryResults stores queries permanently and getCachedQuery retrieves them', () async {
      expect(cacheService.getCachedQuery('Elden Ring'), isNull);

      await cacheService.cacheQueryResults('Elden Ring', sampleResults);

      // Verify immediate L1 and L2 retrieval
      final cached = cacheService.getCachedQuery('elden ring');
      expect(cached, isNotNull);
      expect(cached!.length, equals(2));
      expect(cached.first.title, equals('Elden Ring'));
      expect(cached.first.genres, contains('Role-playing (RPG)'));
      expect(cached.last.title, equals('Hades'));

      // Permanent retention: subsequent read still returns data
      final cachedAgain = cacheService.getCachedQuery('ELDEN RING  ');
      expect(cachedAgain, isNotNull);
      expect(cachedAgain!.length, equals(2));
    });

    test('Individual entities are cached and searchable via searchLocalEntities for offline fallback', () async {
      await cacheService.cacheQueryResults('rpg', sampleResults);

      // Search by partial substring matching
      final matches = cacheService.searchLocalEntities('hade');
      expect(matches.length, equals(1));
      expect(matches.first.title, equals('Hades'));
      expect(matches.first.id, equals(112875));

      final eldenMatches = cacheService.searchLocalEntities('elden');
      expect(eldenMatches.length, equals(1));
      expect(eldenMatches.first.title, equals('Elden Ring'));

      final nonExistent = cacheService.searchLocalEntities('Cyberpunk');
      expect(nonExistent, isEmpty);
    });

    test('cachedGamesCount and cachedQueriesCount accurately report stored entries', () async {
      expect(cacheService.cachedGamesCount, equals(0));
      expect(cacheService.cachedQueriesCount, equals(0));

      await cacheService.cacheQueryResults('elden', sampleResults);

      expect(cacheService.cachedQueriesCount, equals(1));
      expect(cacheService.cachedGamesCount, equals(2));
    });

    test('formatBytes properly converts byte counts to human-readable units', () {
      expect(IGDBCacheService.formatBytes(0), equals('0 B'));
      expect(IGDBCacheService.formatBytes(512), equals('512 B'));
      expect(IGDBCacheService.formatBytes(1024), equals('1.0 KB'));
      expect(IGDBCacheService.formatBytes(1536), equals('1.5 KB'));
      expect(IGDBCacheService.formatBytes(1048576), equals('1.00 MB'));
      expect(IGDBCacheService.formatBytes(2621440), equals('2.50 MB'));
    });

    test('clearCache flushes memory, clears Hive box, and resets counts to zero', () async {
      await cacheService.cacheQueryResults('rpg', sampleResults);
      expect(cacheService.cachedGamesCount, equals(2));

      await cacheService.clearCache();

      expect(cacheService.cachedGamesCount, equals(0));
      expect(cacheService.cachedQueriesCount, equals(0));
      expect(cacheService.getCachedQuery('rpg'), isNull);
      expect(cacheService.searchLocalEntities('elden'), isEmpty);
    });
  });
}
