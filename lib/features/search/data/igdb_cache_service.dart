import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../core/storage/hive_registrar.dart';
import 'igdb_service.dart';

/// Permanent client-side cache for IGDB search queries and game metadata entities.
///
/// Operates on two tiers:
/// - L1 In-Memory: Ultra-fast synchronous access during active app sessions (< 1ms).
/// - L2 Hive Box ('igdb_cache'): Permanent disk-persisted cache across app restarts.
///
/// Features:
/// - Indefinite retention: No arbitrary TTL expirations because game metadata rarely changes.
/// - Offline & Rate-Limit Fallback: Matches local cached entities by title if offline or 429 occurs.
/// - Disk Management: Real-time on-disk byte measurement and compaction upon clearing.
class IGDBCacheService {
  final Box<dynamic>? _customBox;

  // L1 In-Memory Caches
  final Map<String, List<IGDBSearchResult>> _memoryQueryCache = {};
  final Map<int, IGDBSearchResult> _memoryEntityCache = {};

  IGDBCacheService({Box<dynamic>? box}) : _customBox = box;

  Box<dynamic> get _box => _customBox ?? HiveRegistrar.metadataCacheBox;

  /// Retrieves cached results for a search query.
  /// Checks L1 memory first, then L2 Hive storage. Returns null if not cached.
  List<IGDBSearchResult>? getCachedQuery(String query) {
    final key = _normalizeQuery(query);
    if (key.isEmpty) return null;

    // 1. L1 Memory Cache Check
    if (_memoryQueryCache.containsKey(key)) {
      return _memoryQueryCache[key];
    }

    // 2. L2 Hive Disk Cache Check
    try {
      if (_box.isOpen) {
        final raw = _box.get('query_$key');
        if (raw is List) {
          final results = <IGDBSearchResult>[];
          for (final item in raw) {
            if (item is Map) {
              final game = IGDBSearchResult.fromCacheJson(item);
              results.add(game);
              // Warm entity memory cache
              _memoryEntityCache[game.id] = game;
            }
          }
          _memoryQueryCache[key] = results;
          return results;
        }
      }
    } catch (e) {
      debugPrint('[IGDBCacheService] Error reading cached query: $e');
    }

    return null;
  }

  /// Permanently saves search query results and individual game entities into L1 and L2 cache.
  Future<void> cacheQueryResults(String query, List<IGDBSearchResult> results) async {
    final key = _normalizeQuery(query);
    if (key.isEmpty || results.isEmpty) return;

    // 1. Save to L1 Memory
    _memoryQueryCache[key] = results;
    for (final game in results) {
      _memoryEntityCache[game.id] = game;
    }

    // 2. Save to L2 Hive Storage
    try {
      if (_box.isOpen) {
        final serializedList = results.map((g) => g.toJson()).toList();
        await _box.put('query_$key', serializedList);

        for (final game in results) {
          await _box.put('game_${game.id}', game.toJson());
        }
      }
    } catch (e) {
      debugPrint('[IGDBCacheService] Error saving query results to cache: $e');
    }
  }

  /// Fallback search that scans locally cached game entities by title substring match.
  /// Useful when offline or when IGDB returns HTTP 429 Too Many Requests.
  List<IGDBSearchResult> searchLocalEntities(String query, {int limit = 15}) {
    final lowerQuery = query.trim().toLowerCase();
    if (lowerQuery.isEmpty) return [];

    // Ensure memory entity cache has all persisted entities from Hive
    _warmAllEntitiesFromDisk();

    final matches = _memoryEntityCache.values.where((game) {
      return game.title.toLowerCase().contains(lowerQuery);
    }).take(limit).toList();

    return matches;
  }

  /// Total count of unique game entities stored in local cache.
  int get cachedGamesCount {
    if (!_box.isOpen) return _memoryEntityCache.length;
    var count = 0;
    for (final key in _box.keys) {
      if (key is String && key.startsWith('game_')) {
        count++;
      }
    }
    return count > 0 ? count : _memoryEntityCache.length;
  }

  /// Total count of unique search queries stored in local cache.
  int get cachedQueriesCount {
    if (!_box.isOpen) return _memoryQueryCache.length;
    var count = 0;
    for (final key in _box.keys) {
      if (key is String && key.startsWith('query_')) {
        count++;
      }
    }
    return count > 0 ? count : _memoryQueryCache.length;
  }

  /// Calculates the approximate on-disk file size of the Hive cache in bytes.
  Future<int> getSizeBytes() async {
    if (kIsWeb) return 0;
    try {
      if (_box.isOpen) {
        final path = _box.path;
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) {
            return await file.length();
          }
        }
      }
    } catch (e) {
      debugPrint('[IGDBCacheService] Error getting cache file size: $e');
    }
    return 0;
  }

  /// Formats byte count into human-readable representation (e.g. '420.5 KB' or '2.10 MB').
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Flushes all cached queries and game entities from both L1 memory and L2 Hive storage,
  /// and compacts the Hive box file to immediately reclaim disk space.
  Future<void> clearCache() async {
    _memoryQueryCache.clear();
    _memoryEntityCache.clear();

    try {
      if (_box.isOpen) {
        await _box.clear();
        await _box.compact();
      }
    } catch (e) {
      debugPrint('[IGDBCacheService] Error clearing cache: $e');
    }
  }

  void _warmAllEntitiesFromDisk() {
    try {
      if (_box.isOpen) {
        for (final key in _box.keys) {
          if (key is String && key.startsWith('game_')) {
            final raw = _box.get(key);
            if (raw is Map) {
              final game = IGDBSearchResult.fromCacheJson(raw);
              _memoryEntityCache[game.id] = game;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[IGDBCacheService] Error warming entities from disk: $e');
    }
  }

  String _normalizeQuery(String query) => query.trim().toLowerCase();
}
