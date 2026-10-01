import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/core/utils/currency_converter.dart';

void main() {
  group('CurrencyConverter Tests', () {
    test('Same currency conversion returns exact amount', () {
      final converted = CurrencyConverter.convert(
        amount: 59.99,
        fromCurrency: 'USD',
        toCurrency: 'USD',
      );
      expect(converted, equals(59.99));
    });

    test('Converts USD to EUR correctly', () {
      // 100 USD at 1.08 rate = ~92.59 EUR
      final converted = CurrencyConverter.convert(
        amount: 100.0,
        fromCurrency: 'USD',
        toCurrency: 'EUR',
      );
      expect(converted, closeTo(92.59, 0.05));
    });

    test('Converts INR to USD correctly', () {
      // 1000 INR at 0.012 rate = 12.00 USD
      final converted = CurrencyConverter.convert(
        amount: 1000.0,
        fromCurrency: 'INR',
        toCurrency: 'USD',
      );
      expect(converted, equals(12.00));
    });

    test('Converts USD to INR correctly', () {
      // 100 USD = 100 / 0.012 = ~8333.33 INR
      final converted = CurrencyConverter.convert(
        amount: 100.0,
        fromCurrency: 'USD',
        toCurrency: 'INR',
      );
      expect(converted, closeTo(8333.33, 0.5));
    });

    test('Symbol lookup works for common currencies', () {
      expect(CurrencyConverter.symbolFor('USD'), equals('\$'));
      expect(CurrencyConverter.symbolFor('EUR'), equals('€'));
      expect(CurrencyConverter.symbolFor('GBP'), equals('£'));
      expect(CurrencyConverter.symbolFor('INR'), equals('₹'));
      expect(CurrencyConverter.symbolFor('JPY'), equals('¥'));
    });

    test('Formatting outputs clean string', () {
      expect(CurrencyConverter.format(49.99, 'USD'), equals('\$49.99'));
      expect(CurrencyConverter.format(1499.00, 'INR'), equals('₹1499.00'));
    });
  });
}
