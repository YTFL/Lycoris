import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/core/services/exchange_rate_service.dart';
import 'package:lycoris/core/utils/currency_helper.dart';

void main() {
  group('CurrencyHelper Tests', () {
    test('Supported currencies list contains 7 core currencies', () {
      final codes = CurrencyHelper.supportedCurrencies.map((c) => c.code).toList();
      expect(codes, containsAll(['USD', 'EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD']));
    });

    test('getOption resolves codes and aliases case-insensitively', () {
      expect(CurrencyHelper.getOption('usd').code, equals('USD'));
      expect(CurrencyHelper.getOption('JPY').code, equals('JPY'));
      expect(CurrencyHelper.getOption('yen').code, equals('JPY'));
      expect(CurrencyHelper.getOption('pound').code, equals('GBP'));
      expect(CurrencyHelper.getOption('euro').code, equals('EUR'));
      expect(CurrencyHelper.getOption('rupee').code, equals('INR'));
      expect(CurrencyHelper.getOption(null).code, equals('USD'));
      expect(CurrencyHelper.getOption('UNKNOWN').code, equals('USD'));
    });

    test('getSymbol returns correct symbols', () {
      expect(CurrencyHelper.getSymbol('USD'), equals(r'$'));
      expect(CurrencyHelper.getSymbol('EUR'), equals('€'));
      expect(CurrencyHelper.getSymbol('GBP'), equals('£'));
      expect(CurrencyHelper.getSymbol('INR'), equals('₹'));
      expect(CurrencyHelper.getSymbol('JPY'), equals('¥'));
      expect(CurrencyHelper.getSymbol('CAD'), equals(r'CA$'));
      expect(CurrencyHelper.getSymbol('AUD'), equals(r'A$'));
    });

    test('format respects decimal rules and locales', () {
      // JPY has no fractional subunit
      final jpyFormatted = CurrencyHelper.format(1500.0, currencyCode: 'JPY');
      expect(jpyFormatted, contains('¥'));
      expect(jpyFormatted, contains('1,500'));
      expect(jpyFormatted, isNot(contains('.00')));

      // USD has 2 decimals
      final usdFormatted = CurrencyHelper.format(49.99, currencyCode: 'USD');
      expect(usdFormatted, contains(r'$'));
      expect(usdFormatted, contains('49.99'));

      // INR formatting
      final inrFormatted = CurrencyHelper.format(1499.0, currencyCode: 'INR');
      expect(inrFormatted, contains('₹'));
      expect(inrFormatted, contains('1,499'));
    });

    test('CurrencyOption fontSizeFor scales multi-char symbols', () {
      final cadOption = CurrencyHelper.getOption('CAD');
      final usdOption = CurrencyHelper.getOption('USD');
      expect(cadOption.fontSizeFor(20), equals(14.0)); // 20 * 0.70
      expect(usdOption.fontSizeFor(20), equals(20.0)); // 20 * 1.0
    });

    test('detectCurrency identifies symbol or code in raw strings', () {
      expect(CurrencyHelper.detectCurrency(r'CA$49.99'), equals('CAD'));
      expect(CurrencyHelper.detectCurrency('£24.50'), equals('GBP'));
      expect(CurrencyHelper.detectCurrency('€69.99'), equals('EUR'));
      expect(CurrencyHelper.detectCurrency('₹2,499'), equals('INR'));
      expect(CurrencyHelper.detectCurrency('¥7,800'), equals('JPY'));
      expect(CurrencyHelper.detectCurrency(r'A$89.00'), equals('AUD'));
      expect(CurrencyHelper.detectCurrency(r'$59.99'), equals('USD'));
      expect(CurrencyHelper.detectCurrency(null), isNull);
    });

    test('parsePrice sanitizes symbols, letters, and commas', () {
      expect(CurrencyHelper.parsePrice(r'$59.99'), equals(59.99));
      expect(CurrencyHelper.parsePrice(r'CA$79.50'), equals(79.50));
      expect(CurrencyHelper.parsePrice('₹1,499.00'), equals(1499.00));
      expect(CurrencyHelper.parsePrice('¥7,800'), equals(7800.0));
      expect(CurrencyHelper.parsePrice(45.5), equals(45.5));
      expect(CurrencyHelper.parsePrice(''), equals(0.0));
      expect(CurrencyHelper.parsePrice(null), equals(0.0));
    });
  });

  group('ExchangeRates & Service Tests', () {
    test('Seed rates have baseline 1 USD = 1.0', () {
      final seed = ExchangeRates.seed();
      expect(seed.baseCurrency, equals('USD'));
      expect(seed.rates['USD'], equals(1.0));
      expect(seed.isSeed, isTrue);
    });

    test('Convert same currency returns identical value', () {
      final seed = ExchangeRates.seed();
      expect(seed.convert(amount: 59.99, from: 'USD', to: 'USD'), equals(59.99));
      expect(seed.convert(amount: 1500.0, from: 'JPY', to: 'JPY'), equals(1500.0));
    });

    test('Convert cross-currency via custom rates', () {
      final rates = ExchangeRates(
        baseCurrency: 'USD',
        rates: const {
          'USD': 1.0,
          'EUR': 0.90, // 1 USD = 0.90 EUR
          'INR': 90.0, // 1 USD = 90.00 INR
        },
        lastUpdated: DateTime.now(),
      );

      // 100 USD to EUR = 90.00 EUR
      expect(rates.convert(amount: 100.0, from: 'USD', to: 'EUR'), equals(90.00));
      // 90 EUR to USD = 100.00 USD
      expect(rates.convert(amount: 90.0, from: 'EUR', to: 'USD'), equals(100.00));
      // 10 EUR to INR = (10 / 0.90) * 90 = 1000.00 INR
      expect(rates.convert(amount: 10.0, from: 'EUR', to: 'INR'), equals(1000.00));
    });

    test('ExchangeRates toMap and fromMap serialization roundtrip', () {
      final original = ExchangeRates(
        baseCurrency: 'USD',
        rates: const {
          'USD': 1.0,
          'CAD': 1.35,
          'INR': 86.0,
          'EUR': 0.88,
        },
        lastUpdated: DateTime.utc(2026, 10, 1, 12, 0),
      );

      final map = original.toMap();
      final restored = ExchangeRates.fromMap(map);

      expect(restored.baseCurrency, equals('USD'));
      expect(restored.rates['CAD'], equals(1.35));
      expect(restored.rates['INR'], equals(86.0));
      expect(restored.rates['EUR'], equals(0.88));
      expect(restored.lastUpdated.toIso8601String(), equals(original.lastUpdated.toIso8601String()));
    });

    test('ExchangeRateService cooldown helper methods format correctly', () {
      expect(ExchangeRateService.formatCooldownRemaining(Duration.zero), equals('Available now'));
      expect(ExchangeRateService.formatCooldownRemaining(const Duration(hours: 4, minutes: 12)), equals('4h'));
      expect(ExchangeRateService.formatCooldownRemaining(const Duration(minutes: 35)), equals('35m'));
      expect(ExchangeRateService.formatCooldownRemaining(const Duration(seconds: 40)), equals('<1m'));
    });
  });
}
