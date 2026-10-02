import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import 'igdb_cache_service.dart';

class IGDBSearchResult {
  final int id;
  final String title;
  final String? summary;
  final String? coverBigUrl;
  final String? cover720pUrl;
  final List<String> genres;
  final DateTime? releaseDate;

  const IGDBSearchResult({
    required this.id,
    required this.title,
    this.summary,
    this.coverBigUrl,
    this.cover720pUrl,
    required this.genres,
    this.releaseDate,
  });

  factory IGDBSearchResult.fromJson(Map<String, dynamic> json) {
    // If deserializing from local cache
    if (json.containsKey('title') && !json.containsKey('name')) {
      return IGDBSearchResult.fromCacheJson(json);
    }

    final coverData = json['cover'] as Map<String, dynamic>?;
    final imageId = coverData?['image_id'] as String?;

    final genresList = (json['genres'] as List<dynamic>?)
            ?.map((g) => (g as Map<String, dynamic>)['name'] as String)
            .toList() ??
        <String>[];

    DateTime? releaseDate;
    if (json['first_release_date'] != null) {
      final timestamp = json['first_release_date'] as int;
      releaseDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }

    return IGDBSearchResult(
      id: json['id'] as int,
      title: json['name'] as String,
      summary: json['summary'] as String?,
      coverBigUrl: imageId != null ? ApiConstants.coverBigUrl(imageId) : null,
      cover720pUrl: imageId != null ? ApiConstants.cover720pUrl(imageId) : null,
      genres: genresList,
      releaseDate: releaseDate,
    );
  }

  factory IGDBSearchResult.fromCacheJson(Map<dynamic, dynamic> map) {
    return IGDBSearchResult(
      id: map['id'] as int,
      title: map['title'] as String,
      summary: map['summary'] as String?,
      coverBigUrl: map['coverBigUrl'] as String?,
      cover720pUrl: map['cover720pUrl'] as String?,
      genres: (map['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      releaseDate: map['releaseDate'] != null
          ? DateTime.tryParse(map['releaseDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'coverBigUrl': coverBigUrl,
        'cover720pUrl': cover720pUrl,
        'genres': genres,
        'releaseDate': releaseDate?.toIso8601String(),
      };
}

class IGDBService {
  final Dio _dio;
  String _workerProxyUrl;
  String? _twitchClientId;
  String? _twitchClientSecret;
  IGDBCacheService? _cacheService;

  String? _cachedAppToken;
  DateTime? _tokenExpiresAt;

  IGDBService({
    Dio? dio,
    String? workerProxyUrl,
    String? twitchClientId,
    String? twitchClientSecret,
    IGDBCacheService? cacheService,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )),
        _workerProxyUrl = workerProxyUrl ?? ApiConstants.igdbProxyUrl,
        // ignore: prefer_initializing_formals
        _twitchClientId = twitchClientId,
        // ignore: prefer_initializing_formals
        _twitchClientSecret = twitchClientSecret,
        // ignore: prefer_initializing_formals
        _cacheService = cacheService;

  void configure({
    String? workerProxyUrl,
    String? clientId,
    String? clientSecret,
    IGDBCacheService? cacheService,
  }) {
    if (workerProxyUrl != null && workerProxyUrl.trim().isNotEmpty) {
      _workerProxyUrl = workerProxyUrl.trim();
    }
    if (clientId != null) {
      _twitchClientId = clientId.trim().isEmpty ? null : clientId.trim();
    }
    if (clientSecret != null) {
      _twitchClientSecret = clientSecret.trim().isEmpty ? null : clientSecret.trim();
    }
    if (cacheService != null) {
      _cacheService = cacheService;
    }
  }

  bool get hasDirectTwitchCredentials =>
      _twitchClientId != null &&
      _twitchClientId!.isNotEmpty &&
      _twitchClientSecret != null &&
      _twitchClientSecret!.isNotEmpty;

  bool get isConfigured => true;

  Future<String?> _getTwitchAppToken() async {
    if (!hasDirectTwitchCredentials) return null;

    final now = DateTime.now();
    if (_cachedAppToken != null && _tokenExpiresAt != null && _tokenExpiresAt!.isAfter(now)) {
      return _cachedAppToken;
    }

    try {
      final tokenUrl =
          'https://id.twitch.tv/oauth2/token?client_id=${_twitchClientId!}&client_secret=${_twitchClientSecret!}&grant_type=client_credentials';
      final response = await _dio.post<dynamic>(tokenUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _cachedAppToken = token;
        _tokenExpiresAt = now.add(Duration(seconds: max(60, expiresIn - 300)));
        return token;
      }
    } catch (e) {
      debugPrint('[IGDBService] Direct Twitch OAuth token fetch failed: $e');
    }
    return null;
  }

  /// Tests connectivity with the configured proxy or direct IGDB endpoint
  Future<bool> testConnection() async {
    try {
      final results = await searchGames('Zelda', limit: 1, bypassCache: true);
      return results.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Searches IGDB for games matching query using APICalypse syntax.
  /// Checks client-side cache first unless [bypassCache] is true.
  /// Falls back to local cached entities on network error or HTTP 429 rate limit.
  Future<List<IGDBSearchResult>> searchGames(
    String query, {
    int limit = 15,
    bool bypassCache = false,
  }) async {
    final sanitizedQuery = query.replaceAll('"', '').trim();
    if (sanitizedQuery.isEmpty) return [];

    // 1. Client-Side Cache Lookup
    if (!bypassCache && _cacheService != null) {
      final cached = _cacheService!.getCachedQuery(sanitizedQuery);
      if (cached != null && cached.isNotEmpty) {
        return cached.take(limit).toList();
      }
    }

    final apicalypseQuery = '''
fields name, summary, cover.image_id, genres.name, first_release_date;
search "$sanitizedQuery";
limit $limit;
''';

    try {
      final Response<dynamic> response;

      // 2. Direct Twitch Developer Mode vs Worker Proxy Mode
      if (hasDirectTwitchCredentials) {
        final token = await _getTwitchAppToken();
        if (token == null) {
          throw Exception('Unable to obtain Twitch App Access Token with provided credentials.');
        }

        response = await _dio.post<dynamic>(
          ApiConstants.igdbGamesEndpoint,
          data: apicalypseQuery,
          options: Options(
            headers: {
              'Client-ID': _twitchClientId!,
              'Authorization': 'Bearer $token',
              'Content-Type': 'text/plain',
            },
          ),
        );
      } else {
        var targetUrl = _workerProxyUrl;
        if (!targetUrl.endsWith('/games') && !targetUrl.endsWith('/v4/games')) {
          targetUrl = targetUrl.endsWith('/') ? '${targetUrl}games' : '$targetUrl/games';
        }

        response = await _dio.post<dynamic>(
          targetUrl,
          data: apicalypseQuery,
          options: Options(
            headers: {'Content-Type': 'text/plain'},
          ),
        );
      }

      final rawList = response.data as List<dynamic>;
      final results = rawList
          .map((item) => IGDBSearchResult.fromJson(item as Map<String, dynamic>))
          .toList();

      // 3. Persist fresh results to local cache permanently
      if (_cacheService != null && results.isNotEmpty) {
        await _cacheService!.cacheQueryResults(sanitizedQuery, results);
      }

      return results;
    } catch (e) {
      debugPrint('[IGDBService] Network search failed ($e), checking offline entity cache...');
      // 4. Fallback to local cached entities on network error or HTTP 429 rate limit
      if (_cacheService != null) {
        final localMatches = _cacheService!.searchLocalEntities(sanitizedQuery, limit: limit);
        if (localMatches.isNotEmpty) {
          return localMatches;
        }
      }
      return [];
    }
  }
}
