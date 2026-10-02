import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';
import '../../../home/presentation/controllers/home_nav_provider.dart';
import '../controllers/library_notifier.dart';
import '../controllers/library_state.dart';
import '../widgets/game_cover_card.dart';
import '../widgets/game_list_row.dart';
import 'dossier_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

// Backward compatibility alias during transition
typedef VaultScreen = LibraryScreen;

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  final _searchController = SearchController();
  late final TabController _tabController;

  static const List<GameStatus?> _tabStatuses = [
    null, // All
    GameStatus.playing,
    GameStatus.backlog,
    GameStatus.completed,
    GameStatus.mastered,
    GameStatus.abandoned,
    GameStatus.wishlist,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabStatuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showPlatformFilterSheet(BuildContext context, LibraryState libraryState, LibraryNotifier notifier) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Platform',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (libraryState.storefrontFilter != null)
                        TextButton(
                          onPressed: () {
                            notifier.setStorefrontFilter(null);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset'),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.devices_other_rounded,
                    color: libraryState.storefrontFilter == null ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'All Platforms',
                    style: TextStyle(
                      fontWeight: libraryState.storefrontFilter == null ? FontWeight.w800 : FontWeight.w500,
                      color: libraryState.storefrontFilter == null ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  trailing: Text('(${libraryState.allGames.length})'),
                  onTap: () {
                    notifier.setStorefrontFilter(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...Storefront.values.map((s) {
                  final isSelected = libraryState.storefrontFilter == s;
                  final count = libraryState.allGames.where((g) => g.storefront == s).length;
                  return ListTile(
                    leading: Icon(
                      s.fallbackIcon,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      s.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    trailing: Text('($count)'),
                    onTap: () {
                      notifier.setStorefrontFilter(isSelected ? null : s);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final libraryState = ref.watch(libraryNotifierProvider);
    final notifier = ref.read(libraryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_esports, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Library',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // 1. View Mode Switcher (Cycles: 2 cols -> 3 cols -> 4 cols -> list -> 2 cols)
          IconButton(
            tooltip: libraryState.viewMode.label,
            icon: Icon(libraryState.viewMode.icon),
            onPressed: () => notifier.cycleViewMode(),
          ),

          // 2. Sort Menu
          PopupMenuButton<LibrarySortOption>(
            tooltip: 'Sort games',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (option) => notifier.setSortOption(option),
            itemBuilder: (ctx) => LibrarySortOption.values.map((opt) {
              final isSelected = libraryState.sortOption == opt;
              return PopupMenuItem(
                value: opt,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 16,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      opt.label,
                      style: TextStyle(
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // 3. Quick Header Navigation to Analytics
          IconButton(
            tooltip: 'Analytics',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => ref.read(homeNavIndexProvider.notifier).state = 1,
          ),

          // 4. Quick Header Navigation to Settings
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => ref.read(homeNavIndexProvider.notifier).state = 2,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            children: [
              // SearchBar with leading platform filter button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search title, genres, notes...',
                  leading: IconButton(
                    icon: Badge(
                      isLabelVisible: libraryState.storefrontFilter != null,
                      backgroundColor: colorScheme.primary,
                      smallSize: 8,
                      child: Icon(
                        libraryState.storefrontFilter != null
                            ? libraryState.storefrontFilter!.fallbackIcon
                            : Icons.filter_list_rounded,
                        color: libraryState.storefrontFilter != null
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    tooltip: 'Filter by Platform',
                    onPressed: () => _showPlatformFilterSheet(context, libraryState, notifier),
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                          setState(() {});
                        },
                      ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
                  onChanged: (val) {
                    notifier.setSearchQuery(val);
                    setState(() {});
                  },
                ),
              ),

              // TabBar for Statuses (Synced with TabBarView for swiping)
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: _tabStatuses.map((st) {
                  if (st == null) {
                    return Tab(text: 'All (${libraryState.allGames.length})');
                  }
                  final count = libraryState.allGames.where((g) => g.status == st).length;
                  return Tab(text: '${st.displayName} ($count)');
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      // Swipeable TabBarView across all tabs
      body: TabBarView(
        controller: _tabController,
        children: _tabStatuses.map((st) {
          return _buildGameListForStatus(context, st, libraryState);
        }).toList(),
      ),
    );
  }

  Widget _buildGameListForStatus(BuildContext context, GameStatus? status, LibraryState libraryState) {
    // Filter games by tab status, search query, and storefront filter
    var games = List<GameEntry>.from(libraryState.allGames);

    if (status != null) {
      games = games.where((g) => g.status == status).toList();
    }

    if (libraryState.storefrontFilter != null) {
      games = games.where((g) => g.storefront == libraryState.storefrontFilter).toList();
    }

    if (libraryState.searchQuery.trim().isNotEmpty) {
      final query = libraryState.searchQuery.trim().toLowerCase();
      games = games.where((g) {
        return g.title.toLowerCase().contains(query) ||
            g.genres.any((genre) => genre.toLowerCase().contains(query)) ||
            g.notes.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    switch (libraryState.sortOption) {
      case LibrarySortOption.lastUpdated:
        games.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case LibrarySortOption.playtimeDesc:
        games.sort((a, b) => b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed));
        break;
      case LibrarySortOption.costPerHourAsc:
        games.sort((a, b) {
          final costA = a.costPerHour ?? double.infinity;
          final costB = b.costPerHour ?? double.infinity;
          return costA.compareTo(costB);
        });
        break;
      case LibrarySortOption.ratingDesc:
        games.sort((a, b) => b.personalRating.compareTo(a.personalRating));
        break;
      case LibrarySortOption.priceDesc:
        games.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case LibrarySortOption.titleAsc:
        games.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    if (games.isEmpty) {
      return _buildEmptyState(context, libraryState.allGames.isEmpty);
    }

    // List view
    if (libraryState.viewMode == LibraryViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return GameListRow(
            game: game,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DossierScreen(gameId: game.id),
                ),
              );
            },
          );
        },
      );
    }

    // Grid view (2, 3, or 4 columns)
    final cols = libraryState.viewMode.columns;
    final double childAspect = cols == 4 ? (3 / 4.8) : (cols == 3 ? (3 / 4.6) : (3 / 4.4));
    final double spacing = cols == 4 ? 8.0 : (cols == 3 ? 10.0 : 14.0);

    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: childAspect,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return GameCoverCard(
          game: game,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DossierScreen(gameId: game.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isLibraryEmpty) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLibraryEmpty ? Icons.sports_esports_outlined : Icons.search_off_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isLibraryEmpty ? 'Your Library is Empty' : 'No Matching Titles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLibraryEmpty
                  ? 'Track games across multiple storefronts with real-time ROI.\nTap the "+ Add Game" button below to add your first title.'
                  : 'Try clearing your search query or choosing another platform tab.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
