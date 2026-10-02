import 'package:hive_flutter/hive_flutter.dart';
import '../../features/tracker/domain/models/additional_expense.dart';
import '../../features/tracker/domain/models/game_entry.dart';
import '../../features/tracker/domain/models/game_status.dart';
import '../../features/tracker/domain/models/storefront.dart';
import 'hive_adapters.dart';

class HiveRegistrar {
  static const String gamesBoxName = 'games_vault';
  static const String settingsBoxName = 'app_settings';
  static const String metadataCacheBoxName = 'igdb_cache';
  static const String rankingsBoxName = 'game_rankings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register TypeAdapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter<Storefront>(StorefrontAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter<GameStatus>(GameStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter<AdditionalExpense>(AdditionalExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter<GameEntry>(GameEntryAdapter());
    }

    // Open persistent boxes
    await Hive.openBox<GameEntry>(gamesBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<dynamic>(metadataCacheBoxName);
    await Hive.openBox<dynamic>(rankingsBoxName);
  }

  static Box<GameEntry> get gamesBox => Hive.box<GameEntry>(gamesBoxName);
  static Box<dynamic> get settingsBox => Hive.box<dynamic>(settingsBoxName);
  static Box<dynamic> get metadataCacheBox => Hive.box<dynamic>(metadataCacheBoxName);
  static Box<dynamic> get rankingsBox => Hive.box<dynamic>(rankingsBoxName);
}
