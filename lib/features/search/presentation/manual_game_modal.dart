import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency_converter.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../tracker/domain/models/game_entry.dart';
import '../../tracker/domain/models/game_status.dart';
import '../../tracker/domain/models/storefront.dart';

class ManualGameModal extends StatefulWidget {
  final ValueChanged<GameEntry> onSave;

  const ManualGameModal({
    super.key,
    required this.onSave,
  });

  @override
  State<ManualGameModal> createState() => _ManualGameModalState();
}

class _ManualGameModalState extends State<ManualGameModal> {
  final _titleController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _genresController = TextEditingController();
  final _priceController = TextEditingController(text: '0.00');
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _notesController = TextEditingController();

  Storefront _selectedStorefront = Storefront.steam;
  GameStatus _selectedStatus = GameStatus.backlog;
  String _selectedCurrency = 'USD';
  bool _isFree = false;
  double _rating = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _coverUrlController.dispose();
    _genresController.dispose();
    _priceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _calculatedMinutes {
    final h = int.tryParse(_hoursController.text.trim()) ?? 0;
    final m = int.tryParse(_minutesController.text.trim()) ?? 0;
    return TimeNormalizer.fromHoursAndMinutes(h, m);
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a game title'),
          backgroundColor: LycorisColors.error,
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
        storefront: _selectedStorefront,
        customUuid: customUuid,
      ),
      igdbId: 0,
      title: title,
      coverUrl: _coverUrlController.text.trim().isNotEmpty
          ? _coverUrlController.text.trim()
          : null,
      genres: genres.isNotEmpty ? genres : ['Custom / Indie'],
      storefront: _selectedStorefront,
      status: _selectedStatus,
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
    return Dialog(
      backgroundColor: LycorisColors.slateCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LycorisColors.slateBorder),
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
                  const Text(
                    'Manual Game Entry',
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

              // Scrollable Form
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Game Title *', hint: 'e.g. Pokemon Radical Red'),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _coverUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Cover Artwork URL (Optional)', hint: 'https://.../cover.jpg'),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _genresController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Genres (Comma separated)', hint: 'RPG, ROM Hack, Indie'),
                    ),
                    const SizedBox(height: 16),

                    // Storefront Selector
                    const Text(
                      'Storefront / Platform',
                      style: TextStyle(color: LycorisColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
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
                      style: TextStyle(color: LycorisColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
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

                    // Pricing
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

                    // Playtime
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
                    const SizedBox(height: 14),

                    // Rating Slider
                    Text(
                      'Personal Rating: ${_rating.toStringAsFixed(1)} / 10.0',
                      style: const TextStyle(color: LycorisColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
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
                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Personal Notes / Impressions'),
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
                    child: const Text('Cancel', style: TextStyle(color: LycorisColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: LycorisColors.primaryCrimson,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
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

  InputDecoration _inputDecoration(String label, {String? hint, String? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      labelStyle: const TextStyle(color: LycorisColors.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: LycorisColors.textMuted, fontSize: 12),
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
