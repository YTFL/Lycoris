import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum ValueTier {
  free,
  unplayed,
  greatValue,
  fairValue,
  costly;

  Color get color {
    switch (this) {
      case ValueTier.free:
        return LycorisColors.tierFree;
      case ValueTier.unplayed:
        return LycorisColors.tierUnplayed;
      case ValueTier.greatValue:
        return LycorisColors.tierGreatValue;
      case ValueTier.fairValue:
        return LycorisColors.tierFairValue;
      case ValueTier.costly:
        return LycorisColors.tierCostly;
    }
  }

  String get displayName {
    switch (this) {
      case ValueTier.free:
        return 'Free / Claimed';
      case ValueTier.unplayed:
        return 'Unplayed';
      case ValueTier.greatValue:
        return 'Great Value';
      case ValueTier.fairValue:
        return 'Fair Value';
      case ValueTier.costly:
        return 'Costly';
    }
  }
}

class ValueMetric {
  final String label;
  final String secondaryText;
  final ValueTier tier;
  final double? costPerHour;

  const ValueMetric({
    required this.label,
    required this.secondaryText,
    required this.tier,
    this.costPerHour,
  });
}

class ValueMetricEvaluator {
  /// Evaluates financial investment and elapsed playtime to produce a ValueMetric
  static ValueMetric evaluate({
    required double totalSpent,
    required int totalMinutes,
    required String currency,
  }) {
    // 1. Zero or negative cost
    if (totalSpent <= 0.0) {
      return const ValueMetric(
        label: 'Free / Gift',
        secondaryText: 'Zero spend recorded',
        tier: ValueTier.free,
        costPerHour: 0.0,
      );
    }

    // 2. Purchased but unplayed
    if (totalMinutes <= 0) {
      return ValueMetric(
        label: 'Unplayed',
        secondaryText: '$currency ${totalSpent.toStringAsFixed(2)} invested',
        tier: ValueTier.unplayed,
        costPerHour: null,
      );
    }

    // 3. Active playtime calculations
    final hours = totalMinutes / 60.0;
    final costPerHour = totalSpent / hours;
    final formatted = '$currency ${costPerHour.toStringAsFixed(2)}/hr';

    if (costPerHour <= 1.00) {
      return ValueMetric(
        label: formatted,
        secondaryText: 'Incredible ROI',
        tier: ValueTier.greatValue,
        costPerHour: costPerHour,
      );
    } else if (costPerHour <= 3.50) {
      return ValueMetric(
        label: formatted,
        secondaryText: 'Good return',
        tier: ValueTier.fairValue,
        costPerHour: costPerHour,
      );
    } else {
      return ValueMetric(
        label: formatted,
        secondaryText: 'High cost per hour',
        tier: ValueTier.costly,
        costPerHour: costPerHour,
      );
    }
  }
}
