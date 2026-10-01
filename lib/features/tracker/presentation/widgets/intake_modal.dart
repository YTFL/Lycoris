import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../search/data/igdb_service.dart';
import '../../../search/presentation/manual_game_modal.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';
import '../controllers/vault_notifier.dart';

enum PlayTimeInputMode {
  hoursAndMinutes('Hours & Mins'),
  decimalHours('Decimal Hours'),
  pureMinutes('Total Minutes');

  final String label;
  const PlayTimeInputMode(this.label);
}

class IntakeModal extends ConsumerStatefulWidget {
  const IntakeModal({super.key});

  @override
  ConsumerState<IntakeModal> createState() => _IntakeModalState();
}

class _IntakeModalState extends ConsumerState<IntakeModal> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isSearching = false;
  List<IGDBSearchResult> _searchResults = [];
  IGDBSearchResult? _selectedGame;

  // Form Fields
  Storefront _selectedStorefront = Storefront.steam;
  GameStatus _selectedStatus = GameStatus.backlog;
  String _selectedCurrency = '';
  final _priceController = TextEditingController(text: '0.00');
  bool _isFree = false;

  // Playtime Modes
  PlayTimeInputMode _timeMode = PlayTimeInputMode.hoursAndMinutes;
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _decimalHoursController = TextEditingController(text: '0.0');
  final _pureMinutesController = TextEditingController(text: '0');

  // Rating & Notes
  double _rating = 0.0;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _priceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _decimalHoursController.dispose();
    _pureMinutesController.dispose();
    _notesController.dispose();
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

  int get _calculatedMinutes {
    switch (_timeMode) {
      case PlayTimeInputMode.hoursAndMinutes:
        final h = int.tryParse(_hoursController.text.trim()) ?? 0;
        final m = int.tryParse(_minutesController.text.trim()) ?? 0;
        return TimeNormalizer.fromHoursAndMinutes(h, m);
      case PlayTimeInputMode.decimalHours:
        final d = double.tryParse(_decimalHoursController.text.trim()) ?? 0.0;
        return TimeNormalizer.fromDecimalHours(d);
      case PlayTimeInputMode.pureMinutes:
        final raw = int.tryParse(_pureMinutesController.text.trim()) ?? 0;
        return TimeNormalizer.fromRawMinutes(raw);
    }
  }

  void _saveEntry() {
    if (_selectedGame == null) return;

    final price = _isFree ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0);

    final entry = GameEntry(
      id: GameEntry.generateId(
        igdbId: _selectedGame!.id,
        storefront: _selectedStorefront,
      ),
      igdbId: _selectedGame!.id,
      title: _selectedGame!.title,
      coverUrl: _selectedGame!.coverBigUrl,
      genres: _selectedGame!.genres,
      storefront: _selectedStorefront,
      status: _selectedStatus,
      totalMinutesPlayed: _calculatedMinutes,
      basePrice: price,
      currency: _selectedCurrency,
      personalRating: _rating,
      notes: _notesController.text.trim(),
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(vaultNotifierProvider.notifier).saveGame(entry);
    Navigator.pop(context);

    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${entry.title}" (${entry.storefront.label}) to Library!'),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultCurrency = ref.watch(settingsNotifierProvider).primaryCurrency;
    if (_selectedCurrency.isEmpty) {
      _selectedCurrency = defaultCurrency;
    }

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _selectedGame == null ? _buildSearchStage() : _buildIntakeForm(),
        ),
      ),
    );
  }

  Widget _buildSearchStage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Close
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Game',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Input
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search IGDB for title (e.g. Elden Ring, Hades)...',
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 8),

        // Manual Entry Fallback Button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: Icon(Icons.edit_note, size: 16, color: colorScheme.primary),
            label: Text(
              "Can't find it? Add manually",
              style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => ManualGameModal(
                  defaultCurrency: _selectedCurrency,
                  onSave: (game) {
                    ref.read(vaultNotifierProvider.notifier).saveGame(game);
                  },
                ),
              );
            },
          ),
        ),

        Divider(color: colorScheme.outlineVariant.withAlpha(40), height: 16),

        // Results List
        Expanded(
          child: _isSearching
              ? Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 48, color: colorScheme.onSurfaceVariant.withAlpha(80)),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Type a title above to search the IGDB database'
                                : 'No matching titles found on IGDB',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Or tap "Add manually" to add non-IGDB games'
                                : 'You can add this title as a custom entry',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return _buildSearchResultTile(item);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchResultTile(IGDBSearchResult item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGame = item;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 42,
                height: 56,
                child: item.coverBigUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.coverBigUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(color: colorScheme.surfaceContainerHigh),
                      )
                    : Container(color: colorScheme.surfaceContainerHigh),
              ),
            ),
            const SizedBox(width: 12),

            // Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.genres.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildIntakeForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gameRepo = ref.read(gameRepositoryProvider);
    final existingEditions = gameRepo.findExisting(
      title: _selectedGame!.title,
      igdbId: _selectedGame!.id,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with Back button
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => setState(() => _selectedGame = null),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADD TO LIBRARY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    _selectedGame!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Multi-Storefront Duplicate Warning Banner
        if (existingEditions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.secondary.withAlpha(120)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Already in Library on: ${existingEditions.map((e) => e.storefront.label).join(", ")}. Adding another storefront purchase?',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Scrollable Fields
        Expanded(
          child: ListView(
            children: [
              // Storefront
              Text(
                'Storefront / Platform',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Storefront.values.map((s) {
                  final isSelected = _selectedStorefront == s;
                  return ChoiceChip(
                    avatar: Icon(s.fallbackIcon, size: 14),
                    label: Text(s.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStorefront = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Play Status
              Text(
                'Play Status',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GameStatus.values.map((st) {
                  final isSelected = _selectedStatus == st;
                  return ChoiceChip(
                    avatar: Icon(st.icon, size: 14),
                    label: Text(st.displayName),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStatus = st),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Acquisition & Base Price
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      dropdownColor: colorScheme.surfaceContainerHigh,
                      decoration: _inputDecoration('Currency'),
                      items: CurrencyHelper.supportedCurrencies.map((c) {
                        return DropdownMenuItem(
                          value: c.code,
                          child: Text('${c.code} (${c.symbol})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCurrency = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _priceController,
                      enabled: !_isFree,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Base Price'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Free / Gift / Claimed (\$0.00)', style: TextStyle(fontSize: 13)),
                value: _isFree,
                activeThumbColor: colorScheme.primary,
                onChanged: (val) => setState(() => _isFree = val),
              ),
              const SizedBox(height: 14),

              // Time Tracking Mode Tabs
              Text(
                'Playtime Input Mode',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<PlayTimeInputMode>(
                segments: PlayTimeInputMode.values.map((mode) {
                  return ButtonSegment(value: mode, label: Text(mode.label, style: const TextStyle(fontSize: 11)));
                }).toList(),
                selected: {_timeMode},
                onSelectionChanged: (set) => setState(() => _timeMode = set.first),
              ),
              const SizedBox(height: 10),

              // Mode Inputs
              if (_timeMode == PlayTimeInputMode.hoursAndMinutes) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Hours', suffix: 'h'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Minutes', suffix: 'm'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ] else if (_timeMode == PlayTimeInputMode.decimalHours) ...[
                TextField(
                  controller: _decimalHoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('Decimal Hours (e.g. 18.75)', suffix: 'hrs'),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                TextField(
                  controller: _pureMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Total Minutes (e.g. 1125)', suffix: 'mins'),
                  onChanged: (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 8),

              // Canonical Preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Normalized Playtime:', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text(
                      '${TimeNormalizer.format(_calculatedMinutes)} ($_calculatedMinutes normalized minutes)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Rating Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Personal Rating: ${_rating > 0 ? _rating.toStringAsFixed(1) : "Unrated"}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    _rating > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: colorScheme.secondary,
                    size: 18,
                  ),
                ],
              ),
              Slider(
                value: _rating,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                activeColor: colorScheme.primary,
                label: _rating.toStringAsFixed(1),
                onChanged: (val) => setState(() => _rating = val),
              ),

              const SizedBox(height: 10),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: _inputDecoration('Notes / Impressions log'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              icon: const Icon(Icons.bookmark_add, size: 18),
              label: const Text('Save Game'),
              onPressed: _saveEntry,
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffix}) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      filled: true,
      fillColor: colorScheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}
