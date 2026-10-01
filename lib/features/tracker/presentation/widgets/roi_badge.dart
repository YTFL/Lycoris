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
    final tierColor = metric.tier.color;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: tierColor.withAlpha(45),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: tierColor.withAlpha(120), width: 1),
        ),
        child: Text(
          metric.label,
          style: TextStyle(
            color: tierColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tierColor.withAlpha(35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tierColor.withAlpha(140), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: tierColor.withAlpha(30),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metric.label,
            style: TextStyle(
              color: tierColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            metric.secondaryText,
            style: TextStyle(
              color: tierColor.withAlpha(200),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
