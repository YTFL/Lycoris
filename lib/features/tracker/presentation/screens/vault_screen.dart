import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';
import '../controllers/vault_notifier.dart';
import '../controllers/vault_state.dart';
import '../widgets/game_cover_card.dart';
import '../widgets/game_ledger_row.dart';
import 'dossier_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> with SingleTickerProviderStateMixin {
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
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final selectedStatus = _tabStatuses[_tabController.index];
    ref.read(vaultNotifierProvider.notifier).setStatusFilter(selectedStatus);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vaultState = ref.watch(vaultNotifierProvider);
    final notifier = ref.read(vaultNotifierProvider.notifier);
    final displayedGames = vaultState.filteredGames;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_esports, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Lycoris',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // View Mode Switcher (Grid vs List)
          IconButton(
            tooltip: vaultState.viewMode == 'grid' ? 'Switch to Ledger List' : 'Switch to Cover Grid',
            icon: Icon(
              vaultState.viewMode == 'grid' ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => notifier.toggleViewMode(),
          ),

          // Sort Menu
          PopupMenuButton<VaultSortOption>(
            tooltip: 'Sort games',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (option) => notifier.setSortOption(option),
            itemBuilder: (ctx) => VaultSortOption.values.map((opt) {
              final isSelected = vaultState.sortOption == opt;
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
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            children: [
              // 1. Material You SearchBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search library by title, genres, notes...',
                  leading: const Icon(Icons.search),
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

              // 2. Material You TabBar for Statuses
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
                    return Tab(text: 'All (${vaultState.allGames.length})');
                  }
                  final count = vaultState.allGames.where((g) => g.status == st).length;
                  return Tab(text: '${st.displayName} ($count)');
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Storefront Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All Platforms'),
                    selected: vaultState.storefrontFilter == null,
                    onSelected: (_) => notifier.setStorefrontFilter(null),
                  ),
                ),
                ...Storefront.values.map((s) {
                  final isSelected = vaultState.storefrontFilter == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(s.fallbackIcon, size: 14),
                      label: Text(s.label),
                      selected: isSelected,
                      onSelected: (_) => notifier.setStorefrontFilter(isSelected ? null : s),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Main View (Grid or List)
          Expanded(
            child: displayedGames.isEmpty
                ? _buildEmptyState(context, vaultState.allGames.isEmpty)
                : vaultState.viewMode == 'grid'
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 195,
                          childAspectRatio: 3 / 4.4,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: displayedGames.length,
                        itemBuilder: (context, index) {
                          final game = displayedGames[index];
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: displayedGames.length,
                        itemBuilder: (context, index) {
                          final game = displayedGames[index];
                          return GameLedgerRow(
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
                      ),
          ),
        ],
      ),
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
