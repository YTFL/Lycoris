import 'package:flutter/material.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';

enum LibraryViewMode {
  grid2(2, Icons.grid_view_rounded, '2-Column Grid'),
  grid3(3, Icons.view_module_rounded, '3-Column Grid'),
  grid4(4, Icons.view_comfy_rounded, '4-Column Grid'),
  list(1, Icons.view_list_rounded, 'List View');

  final int columns;
  final IconData icon;
  final String label;
  const LibraryViewMode(this.columns, this.icon, this.label);

  LibraryViewMode get next {
    switch (this) {
      case LibraryViewMode.grid2:
        return LibraryViewMode.grid3;
      case LibraryViewMode.grid3:
        return LibraryViewMode.grid4;
      case LibraryViewMode.grid4:
        return LibraryViewMode.list;
      case LibraryViewMode.list:
        return LibraryViewMode.grid2;
    }
  }

  static LibraryViewMode fromString(String? val) {
    switch (val) {
      case 'grid3':
        return LibraryViewMode.grid3;
      case 'grid4':
        return LibraryViewMode.grid4;
      case 'list':
        return LibraryViewMode.list;
      case 'grid':
      case 'grid2':
      default:
        return LibraryViewMode.grid2;
    }
  }
}

enum LibrarySortOption {
  lastUpdated('Recently Updated'),
  playtimeDesc('Most Played (Hours)'),
  costPerHourAsc('Best ROI (Cost/Hr)'),
  ratingDesc('Highest Rated'),
  priceDesc('Highest Spend'),
  titleAsc('Alphabetical (A-Z)');

  final String label;
  const LibrarySortOption(this.label);
}

// Backward compatibility alias during refactor
typedef VaultSortOption = LibrarySortOption;

class LibraryState {
  final List<GameEntry> allGames;
  final GameStatus? statusFilter;
  final Storefront? storefrontFilter;
  final String searchQuery;
  final LibrarySortOption sortOption;
  final LibraryViewMode viewMode;

  const LibraryState({
    this.allGames = const [],
    this.statusFilter,
    this.storefrontFilter,
    this.searchQuery = '',
    this.sortOption = LibrarySortOption.lastUpdated,
    this.viewMode = LibraryViewMode.grid2,
  });

  LibraryState copyWith({
    List<GameEntry>? allGames,
    GameStatus? Function()? statusFilter,
    Storefront? Function()? storefrontFilter,
    String? searchQuery,
    LibrarySortOption? sortOption,
    LibraryViewMode? viewMode,
  }) {
    return LibraryState(
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
      case LibrarySortOption.lastUpdated:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case LibrarySortOption.playtimeDesc:
        result.sort((a, b) => b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed));
        break;
      case LibrarySortOption.costPerHourAsc:
        result.sort((a, b) {
          final cpa = a.costPerHour ?? 999999.0;
          final cpb = b.costPerHour ?? 999999.0;
          return cpa.compareTo(cpb);
        });
        break;
      case LibrarySortOption.ratingDesc:
        result.sort((a, b) => b.personalRating.compareTo(a.personalRating));
        break;
      case LibrarySortOption.priceDesc:
        result.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case LibrarySortOption.titleAsc:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return result;
  }
}

// Backward compatibility alias during refactor
typedef VaultState = LibraryState;
