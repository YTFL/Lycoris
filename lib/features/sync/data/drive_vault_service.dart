import 'dart:convert';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive/hive.dart';
import '../../../core/constants/api_constants.dart';
import '../../tracker/domain/models/game_entry.dart';

class DriveVaultService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: ApiConstants.googleClientId.isNotEmpty ? ApiConstants.googleClientId : null,
    scopes: [drive.DriveApi.driveFileScope],
  );

  /// Authenticate and retrieve Drive client
  Future<drive.DriveApi?> _getDriveClient() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) return null;
    return drive.DriveApi(httpClient);
  }

  /// Locates existing 'Lycoris' folder or creates one at Drive root
  Future<String?> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    final folderList = await driveApi.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and name = '${ApiConstants.backupFolderName}' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id;
    }

    // Create Lycoris folder if it doesn't exist
    final folderMetadata = drive.File()
      ..name = ApiConstants.backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(
      folderMetadata,
      $fields: 'id',
    );
    return createdFolder.id;
  }

  /// Exports local Hive entries to standard Lycoris JSON payload string
  String createBackupPayload(Box<GameEntry> box) {
    final entries = box.values.map((e) => e.toJson()).toList();
    return jsonEncode({
      'app': 'Lycoris',
      'schemaVersion': ApiConstants.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'games': entries,
    });
  }

  /// Applies Last-Write-Wins (LWW) merge from raw JSON payload into the local Hive box
  Future<int> mergeBackupPayload(String rawJson, Box<GameEntry> box) async {
    final Map<String, dynamic> decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final gamesList = decoded['games'] as List<dynamic>? ?? [];

    int mergedCount = 0;
    for (final raw in gamesList) {
      final remoteGame = GameEntry.fromJson(raw as Map<String, dynamic>);
      final localGame = box.get(remoteGame.id);

      // Last-Write-Wins: Apply if local doesn't exist or remote is newer
      if (localGame == null || remoteGame.updatedAt.isAfter(localGame.updatedAt)) {
        await box.put(remoteGame.id, remoteGame);
        mergedCount++;
      }
    }
    return mergedCount;
  }

  /// Uploads backup payload to the user visible Google Drive 'Lycoris' folder
  Future<bool> backupToDrive(Box<GameEntry> box) async {
    try {
      final driveApi = await _getDriveClient();
      if (driveApi == null) return false;

      final folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) return false;

      final payload = createBackupPayload(box);
      final fileContent = utf8.encode(payload);
      final media = drive.Media(
        Stream.value(fileContent),
        fileContent.length,
        contentType: 'application/json',
      );

      // Query for existing file in the Lycoris folder
      final fileList = await driveApi.files.list(
        spaces: 'drive',
        q: "'$folderId' in parents and name = '${ApiConstants.backupFileName}' and trashed = false",
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingFileId = fileList.files!.first.id!;
        final fileUpdate = drive.File()..name = ApiConstants.backupFileName;
        await driveApi.files.update(fileUpdate, existingFileId, uploadMedia: media);
      } else {
        final newFile = drive.File()
          ..name = ApiConstants.backupFileName
          ..parents = [folderId];
        await driveApi.files.create(newFile, uploadMedia: media);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Restores backup from Google Drive 'Lycoris' folder with LWW delta merge
  Future<int> restoreFromDrive(Box<GameEntry> box) async {
    try {
      final driveApi = await _getDriveClient();
      if (driveApi == null) return 0;

      final folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) return 0;

      final fileList = await driveApi.files.list(
        spaces: 'drive',
        q: "'$folderId' in parents and name = '${ApiConstants.backupFileName}' and trashed = false",
        $fields: 'files(id, name)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) return 0;
      final fileId = fileList.files!.first.id!;

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (final chunk in media.stream) {
        dataStore.addAll(chunk);
      }

      final rawJson = utf8.decode(dataStore);
      return await mergeBackupPayload(rawJson, box);
    } catch (_) {
      return 0;
    }
  }
}
