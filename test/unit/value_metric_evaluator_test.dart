import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/core/utils/value_metric_evaluator.dart';

void main() {
  group('ValueMetricEvaluator Tests', () {
    test('Zero spend with playtime yields 0.00/hr rate', () {
      final metric = ValueMetricEvaluator.evaluate(
        totalSpent: 0.0,
        totalMinutes: 120,
        currency: 'USD',
      );
      expect(metric.tier, equals(ValueTier.free));
      expect(metric.label, equals('USD 0.00/hr'));
      expect(metric.costPerHour, equals(0.0));

      final unplayedMetric = ValueMetricEvaluator.evaluate(
        totalSpent: 0.0,
        totalMinutes: 0,
        currency: 'USD',
      );
      expect(unplayedMetric.tier, equals(ValueTier.free));
      expect(unplayedMetric.label, equals('USD 0.00/hr'));

      final highYieldMetric = ValueMetricEvaluator.evaluate(
        totalSpent: 0.0,
        totalMinutes: 35 * 60,
        currency: 'USD',
      );
      expect(highYieldMetric.tier, equals(ValueTier.free));
      expect(highYieldMetric.label, equals('USD 0.00/hr'));
    });

    test('Unplayed game yields unplayed tier', () {
      final metric = ValueMetricEvaluator.evaluate(
        totalSpent: 59.99,
        totalMinutes: 0,
        currency: 'USD',
      );
      expect(metric.tier, equals(ValueTier.unplayed));
      expect(metric.label, equals('Unplayed'));
      expect(metric.costPerHour, isNull);
    });

    test('High hours low cost yields greatValue tier (<= 1.00/hr)', () {
      // $30 for 40 hours -> $0.75/hr
      final metric = ValueMetricEvaluator.evaluate(
        totalSpent: 30.0,
        totalMinutes: 40 * 60,
        currency: 'USD',
      );
      expect(metric.tier, equals(ValueTier.greatValue));
      expect(metric.label, equals('USD 0.75/hr'));
    });

    test('Moderate hours yields fairValue tier (<= 3.50/hr)', () {
      // $60 for 25 hours -> $2.40/hr
      final metric = ValueMetricEvaluator.evaluate(
        totalSpent: 60.0,
        totalMinutes: 25 * 60,
        currency: 'USD',
      );
      expect(metric.tier, equals(ValueTier.fairValue));
      expect(metric.label, equals('USD 2.40/hr'));
    });

    test('Low hours high cost yields costly tier (> 3.50/hr)', () {
      // $70 for 5 hours -> $14.00/hr
      final metric = ValueMetricEvaluator.evaluate(
        totalSpent: 70.0,
        totalMinutes: 5 * 60,
        currency: 'USD',
      );
      expect(metric.tier, equals(ValueTier.costly));
      expect(metric.label, equals('USD 14.00/hr'));
    });
  });
}
