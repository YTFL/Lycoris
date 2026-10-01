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

    // 1. Zero or negative cost (Free / Gifted / Claimed Games)
    if (totalSpent <= 0.0) {
      if (totalMinutes <= 0) {
        return const ValueMetric(
          label: 'Free • Unplayed',
          secondaryText: 'Zero spend recorded',
          tier: ValueTier.unplayed,
          costPerHour: 0.0,
        );
      } else if (hours < 3.0) {
        return ValueMetric(
          label: '${hours.toStringAsFixed(1)}h • Tried',
          secondaryText: 'Early impressions',
          tier: ValueTier.fairValue,
          costPerHour: 0.0,
        );
      } else if (hours < 10.0) {
        return ValueMetric(
          label: '${hours.toStringAsFixed(1)}h • Good Return',
          secondaryText: 'Solid engagement',
          tier: ValueTier.greatValue,
          costPerHour: 0.0,
        );
      } else if (hours < 30.0) {
        return ValueMetric(
          label: '${hours.toStringAsFixed(1)}h • High Value',
          secondaryText: 'Deep immersion',
          tier: ValueTier.greatValue,
          costPerHour: 0.0,
        );
      } else {
        return ValueMetric(
          label: '${hours.toStringAsFixed(1)}h • Legendary Yield',
          secondaryText: 'Phenomenal free ROI',
          tier: ValueTier.greatValue,
          costPerHour: 0.0,
        );
      }
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

    // 3. Active playtime calculations for paid titles
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
