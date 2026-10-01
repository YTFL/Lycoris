import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/core/utils/time_normalizer.dart';

void main() {
  group('TimeNormalizer Tests', () {
    test('fromHoursAndMinutes converts properly', () {
      expect(TimeNormalizer.fromHoursAndMinutes(18, 45), equals(1125));
      expect(TimeNormalizer.fromHoursAndMinutes(0, 30), equals(30));
      expect(TimeNormalizer.fromHoursAndMinutes(2, 0), equals(120));
      expect(TimeNormalizer.fromHoursAndMinutes(-5, -10), equals(0));
    });

    test('fromDecimalHours converts properly', () {
      expect(TimeNormalizer.fromDecimalHours(14.5), equals(870));
      expect(TimeNormalizer.fromDecimalHours(0.5), equals(30));
      expect(TimeNormalizer.fromDecimalHours(0.0), equals(0));
      expect(TimeNormalizer.fromDecimalHours(-2.5), equals(0));
    });

    test('fromRawMinutes rounds appropriately', () {
      expect(TimeNormalizer.fromRawMinutes(870), equals(870));
      expect(TimeNormalizer.fromRawMinutes(45.4), equals(45));
      expect(TimeNormalizer.fromRawMinutes(45.6), equals(46));
      expect(TimeNormalizer.fromRawMinutes(-10), equals(0));
    });

    test('format returns clean human readable string', () {
      expect(TimeNormalizer.format(1125), equals('18h 45m'));
      expect(TimeNormalizer.format(45), equals('45m'));
      expect(TimeNormalizer.format(120), equals('2h'));
      expect(TimeNormalizer.format(0), equals('0m'));
      expect(TimeNormalizer.format(-10), equals('0m'));
    });

    test('toDecimalHours converts correctly', () {
      expect(TimeNormalizer.toDecimalHours(90), equals(1.5));
      expect(TimeNormalizer.toDecimalHours(60), equals(1.0));
      expect(TimeNormalizer.toDecimalHours(0), equals(0.0));
    });
  });
}
