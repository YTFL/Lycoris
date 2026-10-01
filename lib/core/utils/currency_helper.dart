import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/exchange_rate_service.dart';

class CurrencyOption {
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;
  final double symbolScale;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalDigits,
    this.symbolScale = 1.0,
  });

  /// Returns the optimal font size for this currency's symbol given a base font size.
  /// Automatically scales multi-character symbols (e.g. CA$, A$) so they fit containers seamlessly.
  double fontSizeFor(double baseFontSize) {
    if (symbolScale != 1.0) return baseFontSize * symbolScale;
    if (symbol.length >= 3) return baseFontSize * 0.70;
    if (symbol.length == 2) return baseFontSize * 0.85;
    return baseFontSize;
  }
}

class CurrencyHelper {
  /// Standard default game currency
  static const String defaultCurrency = 'USD';

  static const List<CurrencyOption> supportedCurrencies = [
    CurrencyOption(
      code: 'USD',
      symbol: r'$',
      name: 'US Dollar (USD)',
      decimalDigits: 2,
      symbolScale: 1.0,
    ),
    CurrencyOption(
      code: 'EUR',
      symbol: '€',
      name: 'Euro (EUR)',
      decimalDigits: 2,
      symbolScale: 1.0,
    ),
    CurrencyOption(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound (GBP)',
      decimalDigits: 2,
      symbolScale: 1.0,
    ),
    CurrencyOption(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee (INR)',
      decimalDigits: 2,
      symbolScale: 1.0,
    ),
    CurrencyOption(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen (JPY)',
      decimalDigits: 0,
      symbolScale: 1.0,
    ),
    CurrencyOption(
      code: 'CAD',
      symbol: r'CA$',
      name: 'Canadian Dollar (CAD)',
      decimalDigits: 2,
      symbolScale: 0.70,
    ),
    CurrencyOption(
      code: 'AUD',
      symbol: r'A$',
      name: 'Australian Dollar (AUD)',
      decimalDigits: 2,
      symbolScale: 0.80,
    ),
  ];

  static CurrencyOption getOption(String? code) {
    if (code == null || code.isEmpty) {
      return supportedCurrencies.firstWhere((c) => c.code == 'USD');
    }
    final upper = code.toUpperCase().trim();
    return supportedCurrencies.firstWhere(
      (c) =>
          c.code == upper ||
          (upper == 'YEN' && c.code == 'JPY') ||
          (upper == 'POUND' && c.code == 'GBP') ||
          (upper == 'EURO' && c.code == 'EUR') ||
          (upper == 'RUPEE' && c.code == 'INR'),
      orElse: () => supportedCurrencies.firstWhere((c) => c.code == 'USD'),
    );
  }

  static String getSymbol(String? code) {
    return getOption(code).symbol;
  }

  static double getSymbolFontSize(String? code, double baseSize) {
    return getOption(code).fontSizeFor(baseSize);
  }

  /// Formats currency with canonical locale rules:
  /// - INR: Indian numbering grouping (e.g. ₹1,23,456.00 or ₹499.00)
  /// - JPY: 0 decimals (¥1,500)
  /// - EUR/GBP/CAD/AUD/USD: locale standard decimals and symbols
  static String format(double amount, {String? currencyCode, bool compact = false}) {
    final option = getOption(currencyCode);

    if (option.code == 'INR') {
      final format = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
      );
      return format.format(amount);
    } else if (option.code == 'JPY') {
      final format = NumberFormat.currency(
        locale: 'ja_JP',
        symbol: '¥',
        decimalDigits: 0,
      );
      return format.format(amount.roundToDouble());
    } else if (option.code == 'EUR') {
      final format = NumberFormat.currency(
        locale: 'de_DE',
        symbol: '€',
        decimalDigits: 2,
      );
      return format.format(amount);
    } else if (option.code == 'GBP') {
      final format = NumberFormat.currency(
        locale: 'en_GB',
        symbol: '£',
        decimalDigits: 2,
      );
      return format.format(amount);
    } else if (option.code == 'CAD') {
      final format = NumberFormat.currency(
        locale: 'en_CA',
        symbol: r'CA$',
        decimalDigits: 2,
      );
      return format.format(amount);
    } else if (option.code == 'AUD') {
      final format = NumberFormat.currency(
        locale: 'en_AU',
        symbol: r'A$',
        decimalDigits: 2,
      );
      return format.format(amount);
    } else {
      final format = NumberFormat.currency(
        locale: 'en_US',
        symbol: r'$',
        decimalDigits: 2,
      );
      return format.format(amount);
    }
  }

  /// Converts amount from [fromCurrency] to [toCurrency] using active exchange rates.
  /// If [rates] is null, loads cached rates from storage or falls back to baseline seed.
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    ExchangeRates? rates,
  }) {
    final activeRates = rates ?? ExchangeRateService.loadFromStorage();
    return activeRates.convert(amount: amount, from: fromCurrency, to: toCurrency);
  }

  static String? detectCurrency(dynamic input) {
    if (input == null) return null;
    final str = input.toString().trim();
    if (str.contains(r'CA$') || str.contains('CAD')) return 'CAD';
    if (str.contains(r'A$') || str.contains('AUD')) return 'AUD';
    if (str.contains('£') || str.contains('GBP')) return 'GBP';
    if (str.contains('€') || str.contains('EUR')) return 'EUR';
    if (str.contains('₹') || str.contains('INR') || str.contains('Rs')) return 'INR';
    if (str.contains('¥') || str.contains('JPY') || str.contains('YEN')) return 'JPY';
    if (str.contains(r'$') || str.contains('USD')) return 'USD';
    return null;
  }

  static double parsePrice(dynamic input) {
    if (input == null) return 0.0;
    if (input is num) return input.toDouble();

    String str = input.toString().trim();
    if (str.isEmpty) return 0.0;

    str = str
        .replaceAll(r'CA$', '')
        .replaceAll(r'CAD', '')
        .replaceAll(r'A$', '')
        .replaceAll(r'AUD', '')
        .replaceAll(r'USD', '')
        .replaceAll(r'EUR', '')
        .replaceAll(r'GBP', '')
        .replaceAll(r'INR', '')
        .replaceAll(r'JPY', '')
        .replaceAll(r'YEN', '')
        .replaceAll(r'$', '')
        .replaceAll('€', '')
        .replaceAll('£', '')
        .replaceAll('₹', '')
        .replaceAll('¥', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .trim();

    str = str.replaceAll(',', '').trim();
    return double.tryParse(str) ?? 0.0;
  }

  /// Interactive Modal Bottom Sheet to choose a global display currency
  static Future<void> showCurrencyPicker(
    BuildContext context, {
    required String currentCurrency,
    required ValueChanged<String> onSelected,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Display Currency',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: supportedCurrencies.length,
                      itemBuilder: (context, index) {
                        final opt = supportedCurrencies[index];
                        final isSelected = opt.code == currentCurrency;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withAlpha(35)
                                : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant.withAlpha(60),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            leading: CurrencySymbolBox(
                              currencyCode: opt.code,
                              isSelected: isSelected,
                            ),
                            title: Text(
                              opt.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                                : null,
                            onTap: () {
                              onSelected(opt.code);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('Display currency updated to ${opt.name}!'),
                                    backgroundColor: colorScheme.primary,
                                  ),
                                );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A standardized reusable avatar/badge for displaying currency symbols throughout the app
class CurrencySymbolBox extends StatelessWidget {
  final String currencyCode;
  final double size;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? textColor;
  final double? baseFontSize;
  final BorderRadius? borderRadius;

  const CurrencySymbolBox({
    super.key,
    required this.currencyCode,
    this.size = 40,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    this.baseFontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final option = CurrencyHelper.getOption(currencyCode);
    final effectiveBaseFontSize = baseFontSize ?? (size * 0.44);
    final scaledFontSize = option.fontSizeFor(effectiveBaseFontSize);

    final defaultBg = isSelected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;
    final defaultTextColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.08),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withAlpha(80),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          option.symbol,
          style: TextStyle(
            fontSize: scaledFontSize,
            fontWeight: FontWeight.w800,
            color: textColor ?? defaultTextColor,
          ),
        ),
      ),
    );
  }
}

/// A standardized text widget for currency symbols (used in input prefixes, inline badges, etc.)
class CurrencySymbolText extends StatelessWidget {
  final String currencyCode;
  final double baseFontSize;
  final FontWeight fontWeight;
  final Color? color;

  const CurrencySymbolText({
    super.key,
    required this.currencyCode,
    this.baseFontSize = 15,
    this.fontWeight = FontWeight.w700,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final option = CurrencyHelper.getOption(currencyCode);
    final effectiveFontSize = option.fontSizeFor(baseFontSize);

    return Text(
      option.symbol,
      style: TextStyle(
        fontSize: effectiveFontSize,
        fontWeight: fontWeight,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// A standardized DropdownFormField for currency selection that matches InputDecoration height and styling
class CurrencyDropdownField extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final InputDecoration? decoration;

  const CurrencyDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: colorScheme.surfaceContainerHigh,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: decoration ??
          InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
            ),
          ),
      icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
      items: CurrencyHelper.supportedCurrencies.map((c) {
        return DropdownMenuItem<String>(
          value: c.code,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.symbol,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  c.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
