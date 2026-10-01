class ApiConstants {
  static const String igdbProxyUrl = 'https://lycoris-igdb-proxy.ytfl.workers.dev';
  static const String igdbBaseUrl = 'https://api.igdb.com/v4';
  static const String igdbGamesEndpoint = 'https://api.igdb.com/v4/games';

  // IGDB Image URL builders
  static String coverBigUrl(String imageId) =>
      'https://images.igdb.com/igdb/image/upload/t_cover_big/$imageId.jpg';

  static String cover720pUrl(String imageId) =>
      'https://images.igdb.com/igdb/image/upload/t_720p/$imageId.jpg';

  static String coverMicroUrl(String imageId) =>
      'https://images.igdb.com/igdb/image/upload/t_cover_small/$imageId.jpg';

  // Google Drive & OAuth (Injected at build time via --dart-define or --dart-define-from-file)
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String googleProjectId = String.fromEnvironment('GOOGLE_PROJECT_ID');
  static const String backupFolderName = 'Lycoris';
  static const String backupFileName = 'lycoris_vault_backup.json';
  static const int schemaVersion = 1;
}

