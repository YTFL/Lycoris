import 'package:flutter/material.dart';
import '../../../../core/utils/value_metric_evaluator.dart';

class RoiBadge extends StatelessWidget {
  final ValueMetric metric;
  final bool compact;

  const RoiBadge({
    super.key,
    required this.metric,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary;

    return Text(
      metric.label,
      style: TextStyle(
        color: color,
        fontSize: compact ? 11 : 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
