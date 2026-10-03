import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/utils/text_field_helper.dart';
import '../../../core/utils/time_normalizer.dart';
import '../../tracker/domain/models/game_entry.dart';
import '../../tracker/domain/models/game_status.dart';
import '../../tracker/domain/models/storefront.dart';
import '../../tracker/presentation/widgets/help_me_rate_sheet.dart';

class ManualGameModal extends StatefulWidget {
  final String defaultCurrency;
  final ValueChanged<GameEntry> onSave;

  const ManualGameModal({
    super.key,
    required this.defaultCurrency,
    required this.onSave,
  });

  @override
  State<ManualGameModal> createState() => _ManualGameModalState();
}

class _ManualGameModalState extends State<ManualGameModal> {
  final _titleController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _genresController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  Storefront? _selectedStorefront;
  GameStatus? _selectedStatus;
  late String _selectedCurrency;
  bool _isFree = false;
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.defaultCurrency;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _coverUrlController.dispose();
    _genresController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  int get _calculatedMinutes {
    final h = int.tryParse(_hoursController.text.trim()) ?? 0;
    final m = int.tryParse(_minutesController.text.trim()) ?? 0;
    return TimeNormalizer.fromHoursAndMinutes(h, m);
  }

  void _submit() {
    final title = _titleController.text.trim();
    final colorScheme = Theme.of(context).colorScheme;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a game title'),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedStorefront == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a Storefront / Platform'),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a Play Status'),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    final price = _isFree ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0);
    final genres = _genresController.text
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    final customUuid = const Uuid().v4();
    final game = GameEntry(
      id: GameEntry.generateId(
        igdbId: 0,
        storefront: _selectedStorefront!,
        customUuid: customUuid,
      ),
      igdbId: 0,
      title: title,
      coverUrl: _coverUrlController.text.trim().isNotEmpty
          ? _coverUrlController.text.trim()
          : null,
      genres: genres.isNotEmpty ? genres : ['Custom / Indie'],
      storefront: _selectedStorefront!,
      status: _selectedStatus!,
      totalMinutesPlayed: _calculatedMinutes,
      basePrice: price,
      currency: _selectedCurrency,
      personalRating: _rating,
      notes: _notesController.text.trim(),
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCustomEntry: true,
    );

    widget.onSave(game);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manual Game Entry',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scrollable Form
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _titleController,
                      onTap: () => TextFieldHelper.selectAll(_titleController),
                      decoration: _inputDecoration(context, 'Game Title *', hint: 'e.g. Pokemon Radical Red'),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _coverUrlController,
                      onTap: () => TextFieldHelper.selectAll(_coverUrlController),
                      decoration: _inputDecoration(context, 'Cover Artwork URL (Optional)', hint: 'https://.../cover.jpg'),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _genresController,
                      onTap: () => TextFieldHelper.selectAll(_genresController),
                      decoration: _inputDecoration(context, 'Genres (Comma separated)', hint: 'RPG, ROM Hack, Indie'),
                    ),
                    const SizedBox(height: 16),

                    // Storefront Selector Dropdown
                    DropdownButtonFormField<Storefront>(
                      initialValue: _selectedStorefront,
                      decoration: _inputDecoration(context, 'Storefront / Platform'),
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

                    // Play Status Selector Dropdown
                    DropdownButtonFormField<GameStatus>(
                      initialValue: _selectedStatus,
                      decoration: _inputDecoration(context, 'Play Status'),
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
                    const SizedBox(height: 16),

                    // Pricing
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCurrency,
                            dropdownColor: colorScheme.surfaceContainerHigh,
                            decoration: _inputDecoration(context, 'Currency'),
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
                            decoration: _inputDecoration(context, 'Base Price'),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Free / Gift / Claimed', style: TextStyle(fontSize: 13)),
                      value: _isFree,
                      activeThumbColor: colorScheme.primary,
                      onChanged: (val) {
                        setState(() {
                          _isFree = val;
                          if (val) _priceController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Playtime
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _hoursController,
                            onTap: () => TextFieldHelper.selectAll(_hoursController),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(context, 'Hours', suffix: 'h'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _minutesController,
                            onTap: () => TextFieldHelper.selectAll(_minutesController),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(context, 'Minutes', suffix: 'm'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Rating Slider (using colorScheme.secondary)
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
                              size: 18,
                              color: colorScheme.secondary,
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
                            final title = _titleController.text.trim();
                            final score = await HelpMeRateSheet.show(
                              context,
                              gameTitle: title.isNotEmpty ? title : 'New Game',
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
                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: _notesController,
                      onTap: () => TextFieldHelper.selectAll(_notesController),
                      maxLines: 3,
                      decoration: _inputDecoration(context, 'Personal Notes / Impressions'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Save Game'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label, {String? hint, String? suffix}) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: colorScheme.surfaceContainer,
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
