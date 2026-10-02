import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum ValueTier {
  free,
  unplayed,
  greatValue,
  fairValue,
  costly;

  Color themeColor(ColorScheme colorScheme) {
    switch (this) {
      case ValueTier.free:
      case ValueTier.greatValue:
        return colorScheme.primary;
      case ValueTier.fairValue:
        return colorScheme.secondary;
      case ValueTier.unplayed:
      case ValueTier.costly:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color get color {
    switch (this) {
      case ValueTier.free:
        return LycorisColors.primaryCrimson;
      case ValueTier.unplayed:
        return LycorisColors.tierUnplayed;
      case ValueTier.greatValue:
        return LycorisColors.primaryCrimson;
      case ValueTier.fairValue:
        return LycorisColors.crimsonLight;
      case ValueTier.costly:
        return LycorisColors.textSecondary;
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
    final hours = totalMinutes / 60.0;

    // 1. Unplayed games
    if (totalMinutes <= 0) {
      if (totalSpent <= 0.0) {
        return ValueMetric(
          label: '$currency 0.00/hr',
          secondaryText: '',
          tier: ValueTier.free,
          costPerHour: 0.0,
        );
      }
      return ValueMetric(
        label: 'Unplayed',
        secondaryText: '',
        tier: ValueTier.unplayed,
        costPerHour: null,
      );
    }

    // 2. Active playtime calculations (both free and paid)
    final costPerHour = totalSpent <= 0.0 ? 0.0 : totalSpent / hours;
    final formatted = '$currency ${costPerHour.toStringAsFixed(2)}/hr';

    if (totalSpent <= 0.0 || costPerHour <= 1.00) {
      return ValueMetric(
        label: formatted,
        secondaryText: '',
        tier: totalSpent <= 0.0 ? ValueTier.free : ValueTier.greatValue,
        costPerHour: costPerHour,
      );
    } else if (costPerHour <= 3.50) {
      return ValueMetric(
        label: formatted,
        secondaryText: '',
        tier: ValueTier.fairValue,
        costPerHour: costPerHour,
      );
    } else {
      return ValueMetric(
        label: formatted,
        secondaryText: '',
        tier: ValueTier.costly,
        costPerHour: costPerHour,
      );
    }
  }
}
