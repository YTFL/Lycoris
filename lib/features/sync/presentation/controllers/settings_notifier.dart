import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../../../search/data/igdb_service.dart';
import '../../../tracker/presentation/controllers/vault_notifier.dart';
import '../../data/drive_vault_service.dart';
import '../../data/settings_repository.dart';
export 'exchange_rates_notifier.dart';

final igdbServiceProvider = Provider<IGDBService>((ref) {
  return IGDBService();
});

final driveVaultServiceProvider = Provider<DriveVaultService>((ref) {
  return DriveVaultService();
});

class SettingsState {
  final String workerProxyUrl;
  final String twitchClientId;
  final String twitchBearerToken;
  final String primaryCurrency;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final String? syncStatusMessage;

  const SettingsState({
    required this.workerProxyUrl,
    required this.twitchClientId,
    required this.twitchBearerToken,
    required this.primaryCurrency,
    this.lastSyncedAt,
    this.isSyncing = false,
    this.syncStatusMessage,
  });

  SettingsState copyWith({
    String? workerProxyUrl,
    String? twitchClientId,
    String? twitchBearerToken,
    String? primaryCurrency,
    DateTime? lastSyncedAt,
    bool? isSyncing,
    String? syncStatusMessage,
  }) {
    return SettingsState(
      workerProxyUrl: workerProxyUrl ?? this.workerProxyUrl,
      twitchClientId: twitchClientId ?? this.twitchClientId,
      twitchBearerToken: twitchBearerToken ?? this.twitchBearerToken,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncing: isSyncing ?? this.isSyncing,
      syncStatusMessage: syncStatusMessage,
    );
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final driveService = ref.watch(driveVaultServiceProvider);
  return SettingsNotifier(settingsRepo, driveService);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _settingsRepo;
  final DriveVaultService _driveService;

  SettingsNotifier(this._settingsRepo, this._driveService)
      : super(SettingsState(
          workerProxyUrl: _settingsRepo.workerProxyUrl,
          twitchClientId: _settingsRepo.twitchClientId,
          twitchBearerToken: _settingsRepo.twitchBearerToken,
          primaryCurrency: _settingsRepo.primaryCurrency,
          lastSyncedAt: _settingsRepo.lastSyncedAt,
        ));

  Future<void> updateWorkerProxyUrl(String url) async {
    await _settingsRepo.setWorkerProxyUrl(url);
    state = state.copyWith(workerProxyUrl: url);
  }

  Future<void> updateTwitchCredentials({
    required String clientId,
    required String bearerToken,
  }) async {
    await _settingsRepo.setTwitchClientId(clientId);
    await _settingsRepo.setTwitchBearerToken(bearerToken);
    state = state.copyWith(
      twitchClientId: clientId,
      twitchBearerToken: bearerToken,
    );
  }

  Future<void> updatePrimaryCurrency(String currency) async {
    await _settingsRepo.setPrimaryCurrency(currency);
    state = state.copyWith(primaryCurrency: currency);
  }

  Future<bool> backupToDrive() async {
    state = state.copyWith(isSyncing: true, syncStatusMessage: 'Backing up to Google Drive AppData...');
    final success = await _driveService.backupToDrive(HiveRegistrar.gamesBox);
    final now = DateTime.now();
    if (success) {
      await _settingsRepo.setLastSyncedAt(now);
      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: now,
        syncStatusMessage: 'Backup completed successfully!',
      );
    } else {
      state = state.copyWith(
        isSyncing: false,
        syncStatusMessage: 'Google Drive backup failed. Sign-in canceled or offline.',
      );
    }
    return success;
  }

  Future<int> restoreFromDrive() async {
    state = state.copyWith(isSyncing: true, syncStatusMessage: 'Restoring from Google Drive AppData...');
    final restoredCount = await _driveService.restoreFromDrive(HiveRegistrar.gamesBox);
    final now = DateTime.now();
    await _settingsRepo.setLastSyncedAt(now);
    state = state.copyWith(
      isSyncing: false,
      lastSyncedAt: now,
      syncStatusMessage: 'Restored $restoredCount entries via LWW merge.',
    );
    return restoredCount;
  }

  String exportToJson() {
    return _driveService.createBackupPayload(HiveRegistrar.gamesBox);
  }

  Future<int> importFromJson(String jsonString) async {
    state = state.copyWith(isSyncing: true, syncStatusMessage: 'Importing JSON payload...');
    final count = await _driveService.mergeBackupPayload(jsonString, HiveRegistrar.gamesBox);
    state = state.copyWith(
      isSyncing: false,
      syncStatusMessage: 'Imported $count entries via LWW merge.',
    );
    return count;
  }
}
