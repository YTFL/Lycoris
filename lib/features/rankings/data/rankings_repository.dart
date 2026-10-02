import 'package:hive/hive.dart';
import '../domain/models/game_ranking_data.dart';
import '../domain/models/ranking_comparison.dart';

class RankingsRepository {
  final Box<dynamic> _box;
  static const String _prefix = 'ranking_';
  static const String _historyKey = '__history__';

  RankingsRepository(this._box);

  GameRankingData getRanking(String canonicalKey) {
    final raw = _box.get('$_prefix$canonicalKey');
    if (raw != null && raw is Map) {
      return GameRankingData.fromJson(raw);
    }
    return GameRankingData(canonicalKey: canonicalKey);
  }

  Map<String, GameRankingData> getAllRankings() {
    final result = <String, GameRankingData>{};
    for (final key in _box.keys) {
      if (key is String && key.startsWith(_prefix)) {
        final canonicalKey = key.substring(_prefix.length);
        final raw = _box.get(key);
        if (raw != null && raw is Map) {
          result[canonicalKey] = GameRankingData.fromJson(raw);
        }
      }
    }
    return result;
  }

  Future<void> saveRanking(GameRankingData data) async {
    await _box.put('$_prefix${data.canonicalKey}', data.toJson());
  }

  Future<void> saveRankingsBatch(List<GameRankingData> list) async {
    final map = <String, dynamic>{};
    for (final item in list) {
      map['$_prefix${item.canonicalKey}'] = item.toJson();
    }
    await _box.putAll(map);
  }

  List<ComparisonRecord> getHistory() {
    final raw = _box.get(_historyKey);
    if (raw != null && raw is List) {
      return raw.map((e) => ComparisonRecord.fromJson(e as Map)).toList();
    }
    return [];
  }

  Future<void> saveHistory(List<ComparisonRecord> history) async {
    final list = history.map((e) => e.toJson()).toList();
    await _box.put(_historyKey, list);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
