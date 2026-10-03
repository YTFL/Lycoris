import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../rankings/domain/models/comparison_metric.dart';

/// Modal bottom sheet that helps the user compute a balanced, multidimensional
/// game rating out of 10.0 using the 9 core evaluation metrics.
///
/// Each metric is rated with whole-number stars (1 to 10). The final rating
/// is calculated as the average across rated dimensions, rounded cleanly
/// to the nearest 0.5 (e.g., 8.33 -> 8.5, 8.77 -> 9.0).
class HelpMeRateSheet extends StatefulWidget {
  final String gameTitle;
  final String? coverUrl;

  const HelpMeRateSheet({
    super.key,
    required this.gameTitle,
    this.coverUrl,
  });

  /// Static helper to display the sheet as a modal bottom sheet.
  /// Returns the computed rating rounded to the nearest 0.5, or null if dismissed.
  static Future<double?> show(
    BuildContext context, {
    required String gameTitle,
    String? coverUrl,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HelpMeRateSheet(
        gameTitle: gameTitle,
        coverUrl: coverUrl,
      ),
    );
  }

  @override
  State<HelpMeRateSheet> createState() => _HelpMeRateSheetState();
}

class _HelpMeRateSheetState extends State<HelpMeRateSheet> {
  /// Whole-number score for each metric (0 = unrated, 1..10 = rated)
  final Map<ComparisonMetric, int> _scores = {};

  int get _ratedCount => _scores.values.where((s) => s > 0).length;

  /// Arithmetic mean across all rated metrics, rounded to the nearest 0.5
  double get roundedRating {
    final rated = _scores.values.where((s) => s > 0).toList();
    if (rated.isEmpty) return 0.0;
    final rawAvg = rated.reduce((a, b) => a + b) / rated.length;
    return (rawAvg * 2).round() / 2.0;
  }

  void _setScore(ComparisonMetric metric, int score) {
    setState(() {
      if (_scores[metric] == score && score == 1) {
        // Toggle off if clicking 1 again
        _scores.remove(metric);
      } else {
        _scores[metric] = score;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalMetrics = ComparisonMetric.values.length;
    final currentScore = roundedRating;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withAlpha(120),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.coverUrl != null && widget.coverUrl!.isNotEmpty) ...[
                  Container(
                    width: 36,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: colorScheme.surfaceContainerLowest,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: widget.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(Icons.sports_esports, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help Me Rate',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.gameTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Live Overall Score Ticker
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: currentScore > 0
                    ? colorScheme.secondary.withAlpha(120)
                    : colorScheme.outlineVariant.withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentScore > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: currentScore > 0 ? colorScheme.secondary : colorScheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentScore > 0
                            ? '${currentScore.toStringAsFixed(1)} / 10.0'
                            : 'Unrated',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: currentScore > 0 ? colorScheme.secondary : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _ratedCount > 0
                            ? '$_ratedCount of $totalMetrics dimensions rated (rounded to nearest 0.5)'
                            : 'Rate dimensions below from 1 to 10 stars',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Scrollable List of 9 Metrics
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: totalMetrics,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final metric = ComparisonMetric.values[index];
                final score = _scores[metric] ?? 0;
                return _buildMetricCard(context, metric: metric, score: score);
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(40),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: currentScore > 0
                        ? () => Navigator.pop(context, currentScore)
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      currentScore > 0
                          ? 'Apply Rating (${currentScore.toStringAsFixed(1)} / 10)'
                          : 'Rate dimensions to calculate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required ComparisonMetric metric,
    required int score,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRated = score > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRated
              ? colorScheme.secondary.withAlpha(80)
              : colorScheme.outlineVariant.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon, Title, Description, and Score Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isRated
                      ? colorScheme.secondary.withAlpha(40)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  metric.icon,
                  size: 16,
                  color: isRated ? colorScheme.secondary : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isRated
                      ? colorScheme.secondary.withAlpha(220)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isRated ? '$score / 10' : '—',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isRated ? Colors.black87 : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 10 Interactive Stars Row (Whole Numbers 1 to 10)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (idx) {
                final starNumber = idx + 1;
                final isFilled = starNumber <= score;

                return InkWell(
                  key: Key('star_${metric.key}_$starNumber'),
                  onTap: () => _setScore(metric, starNumber),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 26,
                      color: isFilled
                          ? colorScheme.secondary
                          : colorScheme.outlineVariant.withAlpha(120),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
