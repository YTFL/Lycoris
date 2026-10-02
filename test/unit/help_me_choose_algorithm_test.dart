import 'package:flutter_test/flutter_test.dart';
import 'package:lycoris/features/rankings/domain/models/comparison_metric.dart';
import 'package:lycoris/features/rankings/domain/models/ranking_comparison.dart';

void main() {
  group('Help Me Choose: MetricBreakdown & Algorithm Tests', () {
    test('All 9 Game A picks results in decisive Game A win', () {
      final preferences = {
        for (final m in ComparisonMetric.values) m: MetricPreference.gameA,
      };

      final result = MetricEvaluationResult.evaluate(preferences);

      expect(result.scoreA, equals(9.0));
      expect(result.scoreB, equals(0.0));
      expect(result.picksA, equals(9));
      expect(result.picksB, equals(0));
      expect(result.picksDraw, equals(0));
      expect(result.choice, equals(RankingChoice.aWins));
      expect(result.isAWins, isTrue);
    });

    test('5-4 split produces decisive winner with no draws', () {
      final preferences = {
        ComparisonMetric.gameplay: MetricPreference.gameA,
        ComparisonMetric.story: MetricPreference.gameA,
        ComparisonMetric.visuals: MetricPreference.gameA,
        ComparisonMetric.audio: MetricPreference.gameA,
        ComparisonMetric.world: MetricPreference.gameA,
        ComparisonMetric.pacing: MetricPreference.gameB,
        ComparisonMetric.impact: MetricPreference.gameB,
        ComparisonMetric.replayability: MetricPreference.gameB,
        ComparisonMetric.polish: MetricPreference.gameB,
      };

      final result = MetricEvaluationResult.evaluate(preferences);

      expect(result.scoreA, equals(5.0));
      expect(result.scoreB, equals(4.0));
      expect(result.picksA, equals(5));
      expect(result.picksB, equals(4));
      expect(result.choice, equals(RankingChoice.aWins));
    });

    test('Game B dominates with 7 picks and 2 draws', () {
      final preferences = {
        ComparisonMetric.gameplay: MetricPreference.gameB,
        ComparisonMetric.story: MetricPreference.gameB,
        ComparisonMetric.visuals: MetricPreference.draw,
        ComparisonMetric.audio: MetricPreference.gameB,
        ComparisonMetric.world: MetricPreference.gameB,
        ComparisonMetric.pacing: MetricPreference.gameB,
        ComparisonMetric.impact: MetricPreference.draw,
        ComparisonMetric.replayability: MetricPreference.gameB,
        ComparisonMetric.polish: MetricPreference.gameB,
      };

      final result = MetricEvaluationResult.evaluate(preferences);

      // Score: B gets 7 * 1.0 + 2 * 0.5 = 8.0; A gets 1.0
      expect(result.scoreA, equals(1.0));
      expect(result.scoreB, equals(8.0));
      expect(result.picksB, equals(7));
      expect(result.picksDraw, equals(2));
      expect(result.choice, equals(RankingChoice.bWins));
      expect(result.isBWins, isTrue);
    });

    test('Balanced draws (4 for A, 4 for B, 1 Draw) yields verified draw', () {
      final preferences = {
        ComparisonMetric.gameplay: MetricPreference.gameA,
        ComparisonMetric.story: MetricPreference.gameA,
        ComparisonMetric.visuals: MetricPreference.gameA,
        ComparisonMetric.audio: MetricPreference.gameA,
        ComparisonMetric.world: MetricPreference.draw,
        ComparisonMetric.pacing: MetricPreference.gameB,
        ComparisonMetric.impact: MetricPreference.gameB,
        ComparisonMetric.replayability: MetricPreference.gameB,
        ComparisonMetric.polish: MetricPreference.gameB,
      };

      final result = MetricEvaluationResult.evaluate(preferences);

      expect(result.scoreA, equals(4.5));
      expect(result.scoreB, equals(4.5));
      expect(result.picksA, equals(4));
      expect(result.picksB, equals(4));
      expect(result.picksDraw, equals(1));
      expect(result.choice, equals(RankingChoice.draw));
      expect(result.isDraw, isTrue);
    });

    test('All draw picks results in 4.5 - 4.5 verified draw', () {
      final preferences = {
        for (final m in ComparisonMetric.values) m: MetricPreference.draw,
      };

      final result = MetricEvaluationResult.evaluate(preferences);

      expect(result.scoreA, equals(4.5));
      expect(result.scoreB, equals(4.5));
      expect(result.picksDraw, equals(9));
      expect(result.choice, equals(RankingChoice.draw));
    });

    test('Empty preferences default cleanly to neutral draw across all 9 metrics', () {
      final preferences = <ComparisonMetric, MetricPreference>{};

      final result = MetricEvaluationResult.evaluate(preferences);

      expect(result.scoreA, equals(4.5));
      expect(result.scoreB, equals(4.5));
      expect(result.choice, equals(RankingChoice.draw));
    });
  });
}
