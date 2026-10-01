import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

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
}

class IGDBService {
  final Dio _dio;
  String _workerProxyUrl;

  IGDBService({Dio? dio, String? workerProxyUrl})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )),
        _workerProxyUrl = workerProxyUrl ?? ApiConstants.igdbProxyUrl;

  void configure({
    String? workerProxyUrl,
    String? clientId,
    String? bearerToken,
  }) {
    if (workerProxyUrl != null && workerProxyUrl.trim().isNotEmpty) {
      _workerProxyUrl = workerProxyUrl.trim();
    }
  }

  bool get isConfigured => true;

  /// Tests connectivity with the configured proxy or direct IGDB endpoint
  Future<bool> testConnection() async {
    try {
      final results = await searchGames('Zelda', limit: 1);
      return results.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Searches IGDB for games matching query using APICalypse syntax
  Future<List<IGDBSearchResult>> searchGames(String query, {int limit = 15}) async {
    final sanitizedQuery = query.replaceAll('"', '').trim();
    if (sanitizedQuery.isEmpty) return [];

    final apicalypseQuery = '''
fields name, summary, cover.image_id, genres.name, first_release_date;
search "$sanitizedQuery";
limit $limit;
''';

    try {
      var targetUrl = _workerProxyUrl;
      if (!targetUrl.endsWith('/games') && !targetUrl.endsWith('/v4/games')) {
        targetUrl = targetUrl.endsWith('/') ? '${targetUrl}games' : '$targetUrl/games';
      }

      final response = await _dio.post(
        targetUrl,
        data: apicalypseQuery,
        options: Options(
          headers: {'Content-Type': 'text/plain'},
        ),
      );

      final rawList = response.data as List<dynamic>;
      return rawList
          .map((item) => IGDBSearchResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
