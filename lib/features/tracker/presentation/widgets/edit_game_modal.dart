import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/storefront.dart';
import '../controllers/library_notifier.dart';

class EditGameModal extends ConsumerStatefulWidget {
  final GameEntry game;
  final ValueChanged<String>? onGameUpdated;

  const EditGameModal({
    super.key,
    required this.game,
    this.onGameUpdated,
  });

  @override
  ConsumerState<EditGameModal> createState() => _EditGameModalState();
}

class _EditGameModalState extends ConsumerState<EditGameModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;

  late Storefront _selectedStorefront;
  late GameStatus _selectedStatus;
  late String _selectedCurrency;
  late bool _isFree;
  late double _rating;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game.title);
    _priceController = TextEditingController(
      text: widget.game.basePrice > 0 ? widget.game.basePrice.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: widget.game.notes);

    _selectedStorefront = widget.game.storefront;
    _selectedStatus = widget.game.status;
    _selectedCurrency = widget.game.currency;
    _isFree = widget.game.basePrice <= 0;
    _rating = widget.game.personalRating;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final price = _isFree ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0);

    final newId = widget.game.igdbId > 0
        ? GameEntry.generateId(igdbId: widget.game.igdbId, storefront: _selectedStorefront)
        : (widget.game.id.startsWith('custom_') && widget.game.id.split('_').length >= 3)
            ? 'custom_${widget.game.id.split('_')[1]}_${_selectedStorefront.name}'
            : GameEntry.generateId(igdbId: 0, storefront: _selectedStorefront);

    await ref.read(libraryNotifierProvider.notifier).updateGameDetails(
      originalGame: widget.game,
      newTitle: title,
      newStorefront: _selectedStorefront,
      newStatus: _selectedStatus,
      newBasePrice: price,
      newCurrency: _selectedCurrency,
      newPersonalRating: _rating,
      newNotes: _notesController.text.trim(),
    );

    widget.onGameUpdated?.call(newId);

    if (mounted) {
      Navigator.pop(context, newId);
    }
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
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Game Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Title Input
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Game Title',
                    prefixIcon: const Icon(Icons.videogame_asset_outlined),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Storefront Dropdown
                DropdownButtonFormField<Storefront>(
                  initialValue: _selectedStorefront,
                  decoration: InputDecoration(
                    labelText: 'Storefront / Platform',
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                    ),
                  ),
                  dropdownColor: colorScheme.surfaceContainerHigh,
                  items: Storefront.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStorefront = val);
                  },
                ),
                const SizedBox(height: 14),

                // 3. Play Status Dropdown
                DropdownButtonFormField<GameStatus>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
                    ),
                  ),
                  dropdownColor: colorScheme.surfaceContainerHigh,
                  items: GameStatus.values.map((st) {
                    return DropdownMenuItem(
                      value: st,
                      child: Text(st.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 14),

                // 4. Free toggle & Pricing
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Free / Gift / Claimed', style: TextStyle(fontSize: 14)),
                  value: _isFree,
                  activeThumbColor: colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      _isFree = val;
                      if (val) _priceController.text = '0.00';
                    });
                  },
                ),
                if (!_isFree) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Currency Selector
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCurrency,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surfaceContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          dropdownColor: colorScheme.surfaceContainerHigh,
                          items: CurrencyHelper.supportedCurrencies.map((c) {
                            return DropdownMenuItem(
                              value: c.code,
                              child: Text(c.code),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCurrency = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Price field
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Base Price',
                            filled: true,
                            fillColor: colorScheme.surfaceContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // 5. Personal Rating Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Personal Rating',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        Icon(
                          _rating > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 18,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _rating > 0 ? _rating.toStringAsFixed(1) : 'Unrated',
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: _rating,
                  min: 0.0,
                  max: 10.0,
                  divisions: 20,
                  activeColor: colorScheme.primary,
                  inactiveColor: colorScheme.outlineVariant.withAlpha(80),
                  onChanged: (val) => setState(() => _rating = val),
                ),
                const SizedBox(height: 10),

                // 6. Notes
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes / Thoughts',
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _onSave,
                        child: const Text('Save Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
