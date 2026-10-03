import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/text_field_helper.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/domain/models/game_status.dart';
import '../../../tracker/domain/models/storefront.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';
import '../../../tracker/presentation/widgets/help_me_rate_sheet.dart';
import '../../data/igdb_service.dart';

enum PlayTimeInputMode {
  hoursAndMinutes('Hours & Mins'),
  decimalHours('Decimal Hours'),
  pureMinutes('Total Minutes');

  final String label;
  const PlayTimeInputMode(this.label);
}

class GameIntakeScreen extends ConsumerStatefulWidget {
  final IGDBSearchResult game;

  const GameIntakeScreen({
    super.key,
    required this.game,
  });

  @override
  ConsumerState<GameIntakeScreen> createState() => _GameIntakeScreenState();
}

class _GameIntakeScreenState extends ConsumerState<GameIntakeScreen> {
  Storefront? _selectedStorefront;
  GameStatus? _selectedStatus;
  String _selectedCurrency = '';
  final _priceController = TextEditingController();
  bool _isFree = false;

  // Playtime Modes
  PlayTimeInputMode _timeMode = PlayTimeInputMode.hoursAndMinutes;
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _decimalHoursController = TextEditingController();
  final _pureMinutesController = TextEditingController();

  // Rating & Notes
  double _rating = 0.0;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _decimalHoursController.dispose();
    _pureMinutesController.dispose();
    _notesController.dispose();
    super.dispose();
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
    final messenger = ScaffoldMessenger.of(context);
    if (_selectedStorefront == null) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Storefront / Platform to continue')),
      );
      return;
    }

    if (_selectedStatus == null) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Play Status to continue')),
      );
      return;
    }

    final price = _isFree ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0);

    final entry = GameEntry(
      id: GameEntry.generateId(
        igdbId: widget.game.id,
        storefront: _selectedStorefront!,
      ),
      igdbId: widget.game.id,
      title: widget.game.title,
      coverUrl: widget.game.coverBigUrl,
      genres: widget.game.genres,
      storefront: _selectedStorefront!,
      status: _selectedStatus!,
      totalMinutesPlayed: _calculatedMinutes,
      basePrice: price,
      currency: _selectedCurrency,
      personalRating: _rating,
      notes: _notesController.text.trim(),
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(libraryNotifierProvider.notifier).saveGame(entry);

    final colorScheme = Theme.of(context).colorScheme;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    messenger.showSnackBar(
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

    final gameRepo = ref.read(gameRepositoryProvider);
    final existingEditions = gameRepo.findExisting(
      title: widget.game.title,
      igdbId: widget.game.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Game Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overview Header (Full game title without truncation)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 84,
                        child: widget.game.coverBigUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.game.coverBigUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.videogame_asset_outlined,
                                      size: 28, color: colorScheme.onSurfaceVariant),
                                ),
                              )
                            : Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(Icons.videogame_asset_outlined,
                                    size: 28, color: colorScheme.onSurfaceVariant),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Full Title & Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.game.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (widget.game.releaseDate != null) ...[
                            Text(
                              'Released ${widget.game.releaseDate!.year}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (widget.game.genres.isNotEmpty) ...[
                            Text(
                              widget.game.genres.join(' • '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Multi-Storefront Duplicate Warning Banner
              if (existingEditions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.secondary.withAlpha(120)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.secondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Already in Library on: ${existingEditions.map((e) => e.storefront.label).join(", ")}. Adding another storefront edition?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Storefront Dropdown (Selection required)
              DropdownButtonFormField<Storefront>(
                initialValue: _selectedStorefront,
                decoration: _inputDecoration('Storefront / Platform'),
                hint: const Text('Select Storefront / Platform'),
                dropdownColor: colorScheme.surfaceContainerHigh,
                items: Storefront.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.label),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedStorefront = val);
                },
              ),
              const SizedBox(height: 16),

              // 3. Play Status Dropdown (Selection required)
              DropdownButtonFormField<GameStatus>(
                initialValue: _selectedStatus,
                decoration: _inputDecoration('Play Status'),
                hint: const Text('Select Play Status'),
                dropdownColor: colorScheme.surfaceContainerHigh,
                items: GameStatus.values.map((st) {
                  return DropdownMenuItem(
                    value: st,
                    child: Text(st.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: 20),

              // 4. Acquisition & Base Price
              Text(
                'Purchase / Valuation',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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
                      onTap: () => TextFieldHelper.selectAll(_priceController),
                      enabled: !_isFree,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Base Price'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Free / Gift / Claimed', style: TextStyle(fontSize: 14)),
                value: _isFree,
                activeThumbColor: colorScheme.primary,
                onChanged: (val) {
                  setState(() {
                    _isFree = val;
                    if (val) _priceController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              // 5. Initial Playtime
              Text(
                'Playtime Input Mode',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PlayTimeInputMode>(
                segments: PlayTimeInputMode.values.map((mode) {
                  return ButtonSegment(
                    value: mode,
                    label: Text(mode.label, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                selected: {_timeMode},
                onSelectionChanged: (set) => setState(() => _timeMode = set.first),
              ),
              const SizedBox(height: 12),

              if (_timeMode == PlayTimeInputMode.hoursAndMinutes) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hoursController,
                        onTap: () => TextFieldHelper.selectAll(_hoursController),
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Hours', suffix: 'h'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minutesController,
                        onTap: () => TextFieldHelper.selectAll(_minutesController),
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
                  onTap: () => TextFieldHelper.selectAll(_decimalHoursController),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('Decimal Hours (e.g. 18.75)', suffix: 'hrs'),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                TextField(
                  controller: _pureMinutesController,
                  onTap: () => TextFieldHelper.selectAll(_pureMinutesController),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Total Minutes (e.g. 1125)', suffix: 'mins'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 10),

              // Playtime Preview (Clean base hrs+mins, no brackets)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Logged Playtime:',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text(
                      TimeNormalizer.format(_calculatedMinutes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6. Rating Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Personal Rating: ${_rating > 0 ? _rating.toStringAsFixed(1) : "Unrated"}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _rating > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: colorScheme.secondary,
                        size: 20,
                      ),
                    ],
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                    label: const Text('Help Me Rate'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: () async {
                      final score = await HelpMeRateSheet.show(
                        context,
                        gameTitle: widget.game.title,
                        coverUrl: widget.game.coverBigUrl,
                      );
                      if (score != null && score > 0) {
                        setState(() => _rating = score);
                      }
                    },
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
              const SizedBox(height: 12),

              // 7. Notes
              TextField(
                controller: _notesController,
                onTap: () => TextFieldHelper.selectAll(_notesController),
                maxLines: 3,
                decoration: _inputDecoration('Notes / Impressions log'),
              ),
              const SizedBox(height: 28),

              // 8. Submit Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.bookmark_add, size: 20),
                label: const Text(
                  'Add to Library',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                onPressed: _saveEntry,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffix}) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }
}
