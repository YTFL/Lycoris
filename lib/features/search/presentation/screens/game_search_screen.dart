import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';
import '../../data/igdb_service.dart';
import '../manual_game_modal.dart';
import '../widgets/game_metadata_preview_dialog.dart';
import 'game_intake_screen.dart';

class GameSearchScreen extends ConsumerStatefulWidget {
  const GameSearchScreen({super.key});

  @override
  ConsumerState<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends ConsumerState<GameSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isSearching = false;
  List<IGDBSearchResult> _searchResults = [];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      try {
        final igdbService = ref.read(igdbServiceProvider);
        final results = await igdbService.searchGames(query.trim());
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _openManualModal() {
    final defaultCurrency = ref.read(settingsNotifierProvider).primaryCurrency;
    showDialog(
      context: context,
      builder: (ctx) => ManualGameModal(
        defaultCurrency: defaultCurrency,
        onSave: (game) {
          ref.read(libraryNotifierProvider.notifier).saveGame(game);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  void _navigateToIntake(IGDBSearchResult item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameIntakeScreen(game: item),
      ),
    );
  }

  void _showMetadataPreview(IGDBSearchResult item) {
    showDialog(
      context: context,
      builder: (ctx) => GameMetadataPreviewDialog(
        game: item,
        onContinue: () => _navigateToIntake(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Game'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit_note, size: 20),
            label: const Text('Manual'),
            onPressed: _openManualModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search IGDB (e.g. Elden Ring, Hades)...',
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Icons.search, size: 20),
                ),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                ],
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
                onChanged: _onSearchChanged,
              ),
            ),

            // Hint Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap to preview overview • Tap & hold to directly configure details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(180),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Results / Loading / Empty State
            Expanded(
              child: _isSearching
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
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
                                    _searchController.text.isEmpty
                                        ? Icons.search_rounded
                                        : Icons.search_off_rounded,
                                    size: 44,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Search IGDB Database'
                                      : 'No Matching Games Found',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Type any game title above to search cover art, overview, and metadata.'
                                      : 'Cannot find what you are looking for? Tap "Manual" in the top bar to add a custom entry.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  FilledButton.tonalIcon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Manually'),
                                    onPressed: _openManualModal,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return _buildSearchResultTile(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(IGDBSearchResult item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final year = item.releaseDate != null ? '${item.releaseDate!.year}' : null;

    return InkWell(
      onTap: () => _showMetadataPreview(item),
      onLongPress: () => _navigateToIntake(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
        ),
        child: Row(
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 68,
                child: item.coverBigUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.coverBigUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.videogame_asset_outlined,
                              size: 24, color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.videogame_asset_outlined,
                            size: 24, color: colorScheme.onSurfaceVariant),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Metadata & Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (year != null) ...[
                        Text(
                          year,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.genres.isNotEmpty)
                          Text(
                            ' • ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                      if (item.genres.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.genres.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
