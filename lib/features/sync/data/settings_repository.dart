import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  final Box<dynamic> _box;

  static const String keyWorkerProxyUrl = 'worker_proxy_url';
  static const String keyTwitchClientId = 'twitch_client_id';
  static const String keyTwitchBearerToken = 'twitch_bearer_token';
  static const String keyPrimaryCurrency = 'primary_currency';
  static const String keyLastSyncedAt = 'last_synced_at';
  static const String keyShelfViewMode = 'shelf_view_mode';

  SettingsRepository(this._box);

  ValueListenable<Box<dynamic>> listenable() => _box.listenable();

  String get workerProxyUrl => _box.get(keyWorkerProxyUrl, defaultValue: '') as String;
  Future<void> setWorkerProxyUrl(String value) => _box.put(keyWorkerProxyUrl, value);

  String get twitchClientId => _box.get(keyTwitchClientId, defaultValue: '') as String;
  Future<void> setTwitchClientId(String value) => _box.put(keyTwitchClientId, value);

  String get twitchBearerToken => _box.get(keyTwitchBearerToken, defaultValue: '') as String;
  Future<void> setTwitchBearerToken(String value) => _box.put(keyTwitchBearerToken, value);

  String get primaryCurrency => _box.get(keyPrimaryCurrency, defaultValue: 'USD') as String;
  Future<void> setPrimaryCurrency(String value) => _box.put(keyPrimaryCurrency, value);

  DateTime? get lastSyncedAt {
    final millis = _box.get(keyLastSyncedAt);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis as int) : null;
  }

  Future<void> setLastSyncedAt(DateTime date) =>
      _box.put(keyLastSyncedAt, date.millisecondsSinceEpoch);

  String get shelfViewMode => _box.get(keyShelfViewMode, defaultValue: 'grid') as String;
  Future<void> setShelfViewMode(String mode) => _box.put(keyShelfViewMode, mode);
}
