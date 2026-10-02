import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lycoris/core/constants/api_constants.dart';
import 'package:lycoris/features/sync/data/settings_repository.dart';

void main() {
  group('SettingsRepository Tests', () {
    late Directory tempDir;
    late Box<dynamic> settingsBox;
    late SettingsRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_settings_repo_test_');
      Hive.init(tempDir.path);
      settingsBox = await Hive.openBox<dynamic>('test_settings_box');
      repo = SettingsRepository(settingsBox);
    });

    tearDown(() async {
      await settingsBox.close();
      await Hive.deleteBoxFromDisk('test_settings_box');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('workerProxyUrl defaults to ApiConstants.igdbProxyUrl and can be reset', () async {
      expect(repo.workerProxyUrl, equals(ApiConstants.igdbProxyUrl));

      await repo.setWorkerProxyUrl('https://my-custom-proxy.workers.dev');
      expect(repo.workerProxyUrl, equals('https://my-custom-proxy.workers.dev'));

      await repo.resetWorkerProxyUrl();
      expect(repo.workerProxyUrl, equals(ApiConstants.igdbProxyUrl));
    });

    test('twitchClientSecret is encrypted upon storage and decrypted when accessed', () async {
      expect(repo.hasTwitchClientSecret, isFalse);
      expect(repo.getDecryptedTwitchClientSecret(), isNull);

      const rawSecret = 'sec_twitch_live_99881122';
      await repo.setTwitchClientSecret(rawSecret);

      expect(repo.hasTwitchClientSecret, isTrue);

      // Verify the value stored in the raw box is encrypted (not plain text)
      final rawBoxValue = settingsBox.get(SettingsRepository.keyTwitchClientSecretEncrypted);
      expect(rawBoxValue, isNot(equals(rawSecret)));

      // Verify decrypted accessor recovers original secret
      expect(repo.getDecryptedTwitchClientSecret(), equals(rawSecret));

      // Clearing credentials removes secret
      await repo.clearTwitchCredentials();
      expect(repo.hasTwitchClientSecret, isFalse);
      expect(repo.getDecryptedTwitchClientSecret(), isNull);
    });
  });
}
