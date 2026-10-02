import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/domain/models/game_status.dart';
import '../../../tracker/domain/models/storefront.dart';

/// Represents a deduplicated canonical game across one or more storefronts,
/// filtered strictly for completed, mastered, or abandoned (with playtime) games.
class CanonicalGame {
  final String canonicalKey;
  final String title;
  final String? coverUrl;
  final String? customCoverPath;
  final GameStatus highestStatus;
  final int totalMinutesPlayed;
  final List<Storefront> storefronts;
  final List<String> gameEntryIds;
  final String primaryEntryId;
  final List<String> genres;
  final double personalRating;

  const CanonicalGame({
    required this.canonicalKey,
    required this.title,
    this.coverUrl,
    this.customCoverPath,
    required this.highestStatus,
    required this.totalMinutesPlayed,
    required this.storefronts,
    required this.gameEntryIds,
    required this.primaryEntryId,
    required this.genres,
    required this.personalRating,
  });

  double get hoursPlayed => totalMinutesPlayed / 60.0;

  /// Check if an individual GameEntry qualifies for ranking eligibility
  static bool isEligible(GameEntry game) {
    if (game.status == GameStatus.completed || game.status == GameStatus.mastered) {
      return true;
    }
    if (game.status == GameStatus.abandoned && game.totalMinutesPlayed > 0) {
      return true;
    }
    return false;
  }

  /// Generate a unique canonical key for deduplication across storefronts
  static String getCanonicalKey(GameEntry game) {
    if (game.igdbId > 0) {
      return 'igdb_${game.igdbId}';
    }
    return 'title_${game.title.trim().toLowerCase()}';
  }

  /// Groups raw library entries into unique, deduplicated canonical games
  static List<CanonicalGame> fromGameEntries(List<GameEntry> entries) {
    final eligible = entries.where(isEligible).toList();
    final grouped = <String, List<GameEntry>>{};

    for (final entry in eligible) {
      final key = getCanonicalKey(entry);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final canonicalList = <CanonicalGame>[];

    for (final entry in grouped.entries) {
      final key = entry.key;
      final group = entry.value;

      // Primary entry: sort by most playtime, then latest update
      group.sort((a, b) {
        final cmpPlaytime = b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed);
        if (cmpPlaytime != 0) return cmpPlaytime;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      final primary = group.first;

      // Aggregate playtime across storefronts
      final aggregateMinutes = group.fold<int>(0, (sum, g) => sum + g.totalMinutesPlayed);

      // Collect all distinct storefronts
      final storefronts = group.map((g) => g.storefront).toSet().toList();

      // Determine highest completion status: mastered > completed > abandoned
      GameStatus highestStatus = GameStatus.abandoned;
      for (final g in group) {
        if (g.status == GameStatus.mastered) {
          highestStatus = GameStatus.mastered;
          break;
        } else if (g.status == GameStatus.completed && highestStatus != GameStatus.mastered) {
          highestStatus = GameStatus.completed;
        }
      }

      // Max personal rating
      final maxRating = group.fold<double>(0.0, (max, g) => g.personalRating > max ? g.personalRating : max);

      // All genres combined
      final allGenres = <String>{};
      for (final g in group) {
        allGenres.addAll(g.genres);
      }

      canonicalList.add(
        CanonicalGame(
          canonicalKey: key,
          title: primary.title,
          coverUrl: primary.coverUrl,
          customCoverPath: primary.customCoverPath,
          highestStatus: highestStatus,
          totalMinutesPlayed: aggregateMinutes,
          storefronts: storefronts,
          gameEntryIds: group.map((g) => g.id).toList(),
          primaryEntryId: primary.id,
          genres: allGenres.toList(),
          personalRating: maxRating,
        ),
      );
    }

    return canonicalList;
  }
}
