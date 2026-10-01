import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency_converter.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../search/data/igdb_service.dart';
import '../../../search/presentation/manual_game_modal.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';
import '../controllers/vault_notifier.dart';
import 'playtime_editor_dialog.dart';

class IntakeModal extends ConsumerStatefulWidget {
  const IntakeModal({super.key});

  @override
  ConsumerState<IntakeModal> createState() => _IntakeModalState();
}

class _IntakeModalState extends ConsumerState<IntakeModal> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<IGDBSearchResult> _searchResults = [];
  bool _isSearching = false;
  IGDBSearchResult? _selectedGame;

  // Form Fields
  Storefront _selectedStorefront = Storefront.steam;
  GameStatus _selectedStatus = GameStatus.playing;
  String _selectedCurrency = 'USD';
  final _priceController = TextEditingController(text: '0.00');
  bool _isFree = false;

  PlayTimeInputMode _timeMode = PlayTimeInputMode.hoursAndMinutes;
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _decimalHoursController = TextEditingController();
  final _pureMinutesController = TextEditingController();

  double _rating = 0.0;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
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
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final igdbService = ref.read(igdbServiceProvider);
    final results = await igdbService.searchGames(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  int get _calculatedMinutes {
    switch (_timeMode) {
      case PlayTimeInputMode.hoursAndMinutes:
        final h = int.tryParse(_hoursController.text.trim()) ?? 0;
        final m = int.tryParse(_minutesController.text.trim()) ?? 0;
        return TimeNormalizer.fromHoursAndMinutes(h, m);
      case PlayTimeInputMode.decimalHours:
        final dec = double.tryParse(_decimalHoursController.text.trim()) ?? 0.0;
        return TimeNormalizer.fromDecimalHours(dec);
      case PlayTimeInputMode.pureMinutes:
        final raw = int.tryParse(_pureMinutesController.text.trim()) ?? 0;
        return TimeNormalizer.fromRawMinutes(raw);
    }
  }

  void _saveEntry() {
    if (_selectedGame == null) return;

    final price = _isFree ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0);
    final compositeId = GameEntry.generateId(
      igdbId: _selectedGame!.id,
      storefront: _selectedStorefront,
    );

    final entry = GameEntry(
      id: compositeId,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${entry.title}" (${entry.storefront.label}) to Library!'),
        backgroundColor: LycorisColors.primaryCrimson,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultCurrency = ref.watch(settingsNotifierProvider).primaryCurrency;
    if (_selectedCurrency.isEmpty) {
      _selectedCurrency = defaultCurrency;
    }

    return Dialog(
      backgroundColor: LycorisColors.slateCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LycorisColors.slateBorder),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Close
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add Game',
              style: TextStyle(
                color: LycorisColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: LycorisColors.textMuted),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Input
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search IGDB for title (e.g. Elden Ring, Hades)...',
            hintStyle: const TextStyle(color: LycorisColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: LycorisColors.primaryCrimson),
            filled: true,
            fillColor: LycorisColors.slateDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: LycorisColors.slateBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: LycorisColors.primaryCrimson),
            ),
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 8),

        // Manual Entry Fallback Button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.edit_note, size: 16, color: LycorisColors.crimsonGlow),
            label: const Text(
              "Can't find it? Add manually",
              style: TextStyle(color: LycorisColors.crimsonGlow, fontSize: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => ManualGameModal(
                  onSave: (game) {
                    ref.read(vaultNotifierProvider.notifier).saveGame(game);
                  },
                ),
              );
            },
          ),
        ),

        const Divider(color: LycorisColors.slateDivider, height: 16),

        // Results List
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(
                    color: LycorisColors.primaryCrimson,
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 48, color: Colors.white.withAlpha(50)),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Type a title above to search the IGDB database'
                                : 'No matching titles found on IGDB',
                            style: const TextStyle(color: LycorisColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Or tap "Add manually" to add non-IGDB games'
                                : 'You can add this title as a custom entry',
                            style: const TextStyle(color: LycorisColors.textMuted, fontSize: 11.5),
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
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGame = item;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LycorisColors.slateDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: LycorisColors.slateBorder),
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
                        errorWidget: (_, _, _) => Container(color: LycorisColors.slateCard),
                      )
                    : Container(color: LycorisColors.slateCard),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.genres.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LycorisColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: LycorisColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildIntakeForm() {
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
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _selectedGame = null),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADD TO LIBRARY',
                    style: const TextStyle(
                      color: LycorisColors.primaryCrimson,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    _selectedGame!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
              color: LycorisColors.warning.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LycorisColors.warning.withAlpha(150)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: LycorisColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Already in Library on: ${existingEditions.map((e) => e.storefront.label).join(", ")}. Adding another storefront purchase?',
                    style: const TextStyle(
                      color: LycorisColors.warning,
                      fontSize: 11.5,
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
              const Text(
                'Storefront / Platform',
                style: TextStyle(color: LycorisColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Storefront.values.map((s) {
                  final isSelected = _selectedStorefront == s;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: isSelected,
                    selectedColor: s.brandColor,
                    backgroundColor: LycorisColors.slateDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : LycorisColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedStorefront = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Play Status
              const Text(
                'Play Status',
                style: TextStyle(color: LycorisColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GameStatus.values.map((st) {
                  final isSelected = _selectedStatus == st;
                  return ChoiceChip(
                    label: Text(st.displayName),
                    selected: isSelected,
                    selectedColor: st.color.withAlpha(200),
                    backgroundColor: LycorisColors.slateDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : LycorisColors.textSecondary,
                      fontSize: 12,
                    ),
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
                      dropdownColor: LycorisColors.slateDark,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration('Currency'),
                      items: CurrencyConverter.supportedCurrencies.map((c) {
                        return DropdownMenuItem(value: c, child: Text('$c (${CurrencyConverter.symbolFor(c)})'));
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
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Base Price'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Free / Gift / Claimed (\$0.00)', style: TextStyle(color: LycorisColors.textSecondary, fontSize: 13)),
                value: _isFree,
                activeTrackColor: LycorisColors.primaryCrimson,
                onChanged: (val) => setState(() => _isFree = val),
              ),
              const SizedBox(height: 14),

              // Time Tracking Mode Tabs
              const Text(
                'Playtime Input Mode',
                style: TextStyle(color: LycorisColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SegmentedButton<PlayTimeInputMode>(
                segments: PlayTimeInputMode.values.map((mode) {
                  return ButtonSegment(value: mode, label: Text(mode.label, style: const TextStyle(fontSize: 11)));
                }).toList(),
                selected: {_timeMode},
                onSelectionChanged: (set) => setState(() => _timeMode = set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return LycorisColors.primaryCrimson;
                    return LycorisColors.slateDark;
                  }),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                ),
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
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Hours', suffix: 'h'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Decimal Hours (e.g. 18.75)', suffix: 'hrs'),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                TextField(
                  controller: _pureMinutesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Total Minutes (e.g. 1125)', suffix: 'mins'),
                  onChanged: (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 8),

              // Canonical Preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: LycorisColors.slateDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LycorisColors.slateBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Normalized Playtime:', style: TextStyle(color: LycorisColors.textSecondary, fontSize: 12)),
                    Text(
                      '${TimeNormalizer.format(_calculatedMinutes)} ($_calculatedMinutes normalized minutes)',
                      style: const TextStyle(color: LycorisColors.crimsonGlow, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Rating Slider
              Text(
                'Personal Rating: ${_rating.toStringAsFixed(1)} / 10.0',
                style: const TextStyle(color: LycorisColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Slider(
                value: _rating,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                activeColor: LycorisColors.primaryCrimson,
                inactiveColor: LycorisColors.slateBorder,
                label: _rating.toStringAsFixed(1),
                onChanged: (val) => setState(() => _rating = val),
              ),

              const SizedBox(height: 10),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
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
              child: const Text('Cancel', style: TextStyle(color: LycorisColors.textSecondary)),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              icon: const Icon(Icons.bookmark_add, size: 18),
              label: const Text('Save Game'),
              style: FilledButton.styleFrom(
                backgroundColor: LycorisColors.primaryCrimson,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: _saveEntry,
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      labelStyle: const TextStyle(color: LycorisColors.textSecondary, fontSize: 13),
      suffixStyle: const TextStyle(color: LycorisColors.textMuted),
      filled: true,
      fillColor: LycorisColors.slateDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LycorisColors.slateBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LycorisColors.primaryCrimson),
      ),
    );
  }
}
