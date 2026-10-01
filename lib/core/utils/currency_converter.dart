class CurrencyConverter {
  /// Standard exchange rates normalized to USD (1.0 base)
  /// e.g. 1 EUR = 1.08 USD, 1 INR = 0.012 USD
  static const Map<String, double> ratesToUsd = {
    'USD': 1.0,
    'EUR': 1.08,
    'GBP': 1.28,
    'INR': 0.012,
    'JPY': 0.0067,
    'CAD': 0.74,
    'AUD': 0.66,
  };

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'CAD': 'CA\$',
    'AUD': 'A\$',
  };

  static List<String> get supportedCurrencies => ratesToUsd.keys.toList();

  /// Returns the currency symbol or the code if symbol not found
  static String symbolFor(String currencyCode) {
    return currencySymbols[currencyCode.toUpperCase()] ?? currencyCode;
  }

  /// Converts an amount from one currency to another using the USD baseline
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();

    if (from == to) return amount;

    final fromRate = ratesToUsd[from] ?? 1.0;
    final toRate = ratesToUsd[to] ?? 1.0;

    // Convert from origin to USD, then from USD to target currency
    final inUsd = amount * fromRate;
    final converted = inUsd / toRate;

    return double.parse(converted.toStringAsFixed(2));
  }

  /// Formats an amount with its currency symbol
  static String format(double amount, String currencyCode) {
    final symbol = symbolFor(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
