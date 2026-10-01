import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/time_normalizer.dart';

enum PlayTimeInputMode {
  hoursAndMinutes('Hours + Mins'),
  decimalHours('Decimal Hours'),
  pureMinutes('Total Minutes');

  final String label;
  const PlayTimeInputMode(this.label);
}

class PlaytimeEditorDialog extends StatefulWidget {
  final int initialMinutes;
  final String gameTitle;
  final ValueChanged<int> onSave;

  const PlaytimeEditorDialog({
    super.key,
    required this.initialMinutes,
    required this.gameTitle,
    required this.onSave,
  });

  @override
  State<PlaytimeEditorDialog> createState() => _PlaytimeEditorDialogState();
}

class _PlaytimeEditorDialogState extends State<PlaytimeEditorDialog> {
  PlayTimeInputMode _mode = PlayTimeInputMode.hoursAndMinutes;
  bool _isAdditionMode = false;

  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _decimalController;
  late final TextEditingController _pureMinutesController;

  @override
  void initState() {
    super.initState();
    final initHours = widget.initialMinutes ~/ 60;
    final initMins = widget.initialMinutes % 60;
    final initDecimal = (widget.initialMinutes / 60.0).toStringAsFixed(1);

    _hoursController = TextEditingController(text: initHours > 0 ? initHours.toString() : '');
    _minutesController = TextEditingController(text: initMins > 0 ? initMins.toString() : '');
    _decimalController = TextEditingController(text: initDecimal != '0.0' ? initDecimal : '');
    _pureMinutesController = TextEditingController(
      text: widget.initialMinutes > 0 ? widget.initialMinutes.toString() : '',
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _decimalController.dispose();
    _pureMinutesController.dispose();
    super.dispose();
  }

  int _calculateInputMinutes() {
    switch (_mode) {
      case PlayTimeInputMode.hoursAndMinutes:
        final h = int.tryParse(_hoursController.text.trim()) ?? 0;
        final m = int.tryParse(_minutesController.text.trim()) ?? 0;
        return TimeNormalizer.fromHoursAndMinutes(h, m);
      case PlayTimeInputMode.decimalHours:
        final dec = double.tryParse(_decimalController.text.trim()) ?? 0.0;
        return TimeNormalizer.fromDecimalHours(dec);
      case PlayTimeInputMode.pureMinutes:
        final raw = int.tryParse(_pureMinutesController.text.trim()) ?? 0;
        return TimeNormalizer.fromRawMinutes(raw);
    }
  }

  int get _finalMinutes {
    final input = _calculateInputMinutes();
    return _isAdditionMode ? (widget.initialMinutes + input) : input;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LycorisColors.slateCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LycorisColors.slateBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Log Playtime',
                style: const TextStyle(
                  color: LycorisColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.gameTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LycorisColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Mode Tabs
              SegmentedButton<PlayTimeInputMode>(
                segments: PlayTimeInputMode.values.map((mode) {
                  return ButtonSegment<PlayTimeInputMode>(
                    value: mode,
                    label: Text(
                      mode.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
                selected: {_mode},
                onSelectionChanged: (newSet) {
                  setState(() {
                    _mode = newSet.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return LycorisColors.primaryCrimson;
                    }
                    return LycorisColors.slateDark;
                  }),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Inputs based on mode
              if (_mode == PlayTimeInputMode.hoursAndMinutes) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: _inputDecoration('Hours', suffix: 'h'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: _inputDecoration('Minutes', suffix: 'm'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ] else if (_mode == PlayTimeInputMode.decimalHours) ...[
                TextField(
                  controller: _decimalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: _inputDecoration('Decimal Hours (e.g. 18.5)', suffix: 'hrs'),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                TextField(
                  controller: _pureMinutesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: _inputDecoration('Total Minutes (e.g. 1125)', suffix: 'mins'),
                  onChanged: (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 14),

              // Add vs Replace Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _isAdditionMode ? 'Add to current playtime' : 'Set as new total',
                  style: const TextStyle(color: LycorisColors.textSecondary, fontSize: 13),
                ),
                subtitle: Text(
                  'Current: ${TimeNormalizer.format(widget.initialMinutes)}',
                  style: const TextStyle(color: LycorisColors.textMuted, fontSize: 11),
                ),
                value: _isAdditionMode,
                activeTrackColor: LycorisColors.primaryCrimson,
                onChanged: (val) {
                  setState(() {
                    _isAdditionMode = val;
                  });
                },
              ),

              const SizedBox(height: 8),

              // Normalized Preview Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LycorisColors.slateDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: LycorisColors.slateBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Resulting Playtime:',
                      style: TextStyle(
                        color: LycorisColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${TimeNormalizer.format(_finalMinutes)} ($_finalMinutes mins)',
                      style: const TextStyle(
                        color: LycorisColors.crimsonGlow,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: LycorisColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: LycorisColors.primaryCrimson,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      widget.onSave(_finalMinutes);
                      Navigator.pop(context);
                    },
                    child: const Text('Save Playtime'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
