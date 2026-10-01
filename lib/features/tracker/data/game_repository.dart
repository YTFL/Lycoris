import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/game_entry.dart';

class GameRepository {
  final Box<GameEntry> _box;

  GameRepository(this._box);

  List<GameEntry> getAll() {
    return _box.values.toList();
  }

  ValueListenable<Box<GameEntry>> listenable() {
    return _box.listenable();
  }

  GameEntry? getById(String id) {
    return _box.get(id);
  }

  Future<void> save(GameEntry game) async {
    final entryToSave = game.copyWith(
      updatedAt: DateTime.now(),
    );
    await _box.put(entryToSave.id, entryToSave);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Checks if a title or IGDB ID is already owned on any storefront
  List<GameEntry> findExisting({required String title, int? igdbId}) {
    final lowerTitle = title.trim().toLowerCase();
    return _box.values.where((game) {
      if (igdbId != null && igdbId > 0 && game.igdbId == igdbId) {
        return true;
      }
      return game.title.trim().toLowerCase() == lowerTitle;
    }).toList();
  }
}
