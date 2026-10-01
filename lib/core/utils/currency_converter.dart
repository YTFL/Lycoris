import '../services/exchange_rate_service.dart';
import 'currency_helper.dart';

class CurrencyConverter {
  /// Standard exchange rates normalized to USD (1.0 base).
  /// Rates represent how much 1 unit of the given currency is worth in USD.
  /// (e.g. 1 EUR = 1.08 USD, 1 INR = 0.012 USD).
  static Map<String, double> get ratesToUsd => {
        'USD': 1.0,
        'EUR': 1.08,
        'GBP': 1.28,
        'INR': 0.012,
        'JPY': 0.0067,
        'CAD': 0.74,
        'AUD': 0.66,
      };

  static Map<String, String> get currencySymbols => {
        for (final opt in CurrencyHelper.supportedCurrencies) opt.code: opt.symbol,
      };

  static List<String> get supportedCurrencies =>
      CurrencyHelper.supportedCurrencies.map((c) => c.code).toList();

  /// Returns the currency symbol or the code if symbol not found
  static String symbolFor(String currencyCode) {
    return CurrencyHelper.getSymbol(currencyCode);
  }

  /// Converts an amount from one currency to another using the USD baseline or live [rates]
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    ExchangeRates? rates,
  }) {
    return CurrencyHelper.convert(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      rates: rates,
    );
  }

  /// Formats an amount with its currency symbol
  static String format(double amount, String currencyCode) {
    final symbol = symbolFor(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
