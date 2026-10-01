import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';

enum VaultSortOption {
  lastUpdated('Recently Updated'),
  playtimeDesc('Most Played (Hours)'),
  costPerHourAsc('Best ROI (Cost/Hr)'),
  ratingDesc('Highest Rated'),
  priceDesc('Highest Spend'),
  titleAsc('Alphabetical (A-Z)');

  final String label;
  const VaultSortOption(this.label);
}

class VaultState {
  final List<GameEntry> allGames;
  final GameStatus? statusFilter;
  final Storefront? storefrontFilter;
  final String searchQuery;
  final VaultSortOption sortOption;
  final String viewMode; // 'grid' or 'list'

  const VaultState({
    this.allGames = const [],
    this.statusFilter,
    this.storefrontFilter,
    this.searchQuery = '',
    this.sortOption = VaultSortOption.lastUpdated,
    this.viewMode = 'grid',
  });

  VaultState copyWith({
    List<GameEntry>? allGames,
    GameStatus? Function()? statusFilter,
    Storefront? Function()? storefrontFilter,
    String? searchQuery,
    VaultSortOption? sortOption,
    String? viewMode,
  }) {
    return VaultState(
      allGames: allGames ?? this.allGames,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      storefrontFilter: storefrontFilter != null ? storefrontFilter() : this.storefrontFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  /// Evaluates filters and sorts games into the final displayed list
  List<GameEntry> get filteredGames {
    var result = List<GameEntry>.from(allGames);

    // 1. Status Filter
    if (statusFilter != null) {
      result = result.where((g) => g.status == statusFilter).toList();
    }

    // 2. Storefront Filter
    if (storefrontFilter != null) {
      result = result.where((g) => g.storefront == storefrontFilter).toList();
    }

    // 3. Search Query
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((g) {
        return g.title.toLowerCase().contains(query) ||
            g.genres.any((genre) => genre.toLowerCase().contains(query)) ||
            g.notes.toLowerCase().contains(query);
      }).toList();
    }

    // 4. Sorting
    switch (sortOption) {
      case VaultSortOption.lastUpdated:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case VaultSortOption.playtimeDesc:
        result.sort((a, b) => b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed));
        break;
      case VaultSortOption.costPerHourAsc:
        result.sort((a, b) {
          final cpa = a.costPerHour ?? 999999.0;
          final cpb = b.costPerHour ?? 999999.0;
          return cpa.compareTo(cpb);
        });
        break;
      case VaultSortOption.ratingDesc:
        result.sort((a, b) => b.personalRating.compareTo(a.personalRating));
        break;
      case VaultSortOption.priceDesc:
        result.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case VaultSortOption.titleAsc:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return result;
  }
}
