import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/models/canonical_game.dart';
import '../../domain/models/comparison_metric.dart';
import '../../domain/models/ranking_comparison.dart';

class HelpMeChooseSheet extends StatefulWidget {
  final CanonicalGame gameA;
  final CanonicalGame gameB;

  const HelpMeChooseSheet({
    super.key,
    required this.gameA,
    required this.gameB,
  });

  /// Static helper to show the sheet as a modal bottom sheet
  static Future<RankingChoice?> show(
    BuildContext context, {
    required CanonicalGame gameA,
    required CanonicalGame gameB,
  }) {
    return showModalBottomSheet<RankingChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HelpMeChooseSheet(
        gameA: gameA,
        gameB: gameB,
      ),
    );
  }

  @override
  State<HelpMeChooseSheet> createState() => _HelpMeChooseSheetState();
}

class _HelpMeChooseSheetState extends State<HelpMeChooseSheet> {
  final Map<ComparisonMetric, MetricPreference> _preferences = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = MetricEvaluationResult.evaluate(_preferences);

    final titleA = widget.gameA.title;
    final titleB = widget.gameB.title;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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

          // Header: Help Me Choose Title & Matchup
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help Me Choose',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Break down the matchup factor by factor',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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

          // Matchup Mini-Bar: Game A vs Game B
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildMiniCover(widget.gameA),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titleA,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      titleB,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildMiniCover(widget.gameB),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Warning Notice on Draws
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.error.withAlpha(80),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Avoid picking Draw as much as possible for a more accurate ranking.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable Metric Dimensions List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: ComparisonMetric.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final metric = ComparisonMetric.values[index];
                final currentPref = _preferences[metric];

                return _buildMetricCard(
                  context,
                  metric: metric,
                  currentPref: currentPref,
                  titleA: titleA,
                  titleB: titleB,
                );
              },
            ),
          ),

          // Bottom Bar: Live Decision & Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Outcome summary
                  _buildOutcomeTicker(context, result, titleA, titleB),
                  const SizedBox(height: 10),

                  // Confirm Decision Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, result.choice);
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _getConfirmButtonLabel(result, titleA, titleB),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Direct Draw option
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, RankingChoice.draw);
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Skip to Draw',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCover(CanonicalGame game) {
    return Container(
      width: 24,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: game.coverUrl != null && game.coverUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: game.coverUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const Icon(Icons.sports_esports, size: 14),
            )
          : const Icon(Icons.sports_esports, size: 14),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required ComparisonMetric metric,
    required MetricPreference? currentPref,
    required String titleA,
    required String titleB,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              Icon(
                metric.icon,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                metric.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            metric.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),

          // 3-way Segmented Buttons
          Row(
            children: [
              // Game A Button
              Expanded(
                flex: 5,
                child: _buildChoicePill(
                  context,
                  label: titleA,
                  isSelected: currentPref == MetricPreference.gameA,
                  isLeft: true,
                  onTap: () {
                    setState(() {
                      _preferences[metric] = MetricPreference.gameA;
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),

              // Draw Button
              Expanded(
                flex: 3,
                child: _buildChoicePill(
                  context,
                  label: 'Draw',
                  isSelected: currentPref == MetricPreference.draw,
                  isDraw: true,
                  onTap: () {
                    setState(() {
                      _preferences[metric] = MetricPreference.draw;
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),

              // Game B Button
              Expanded(
                flex: 5,
                child: _buildChoicePill(
                  context,
                  label: titleB,
                  isSelected: currentPref == MetricPreference.gameB,
                  isLeft: false,
                  onTap: () {
                    setState(() {
                      _preferences[metric] = MetricPreference.gameB;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoicePill(
    BuildContext context, {
    required String label,
    required bool isSelected,
    bool isLeft = true,
    bool isDraw = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bg;
    Color border;
    Color fg;

    if (isSelected) {
      if (isDraw) {
        bg = colorScheme.outlineVariant.withAlpha(120);
        border = colorScheme.outline;
        fg = colorScheme.onSurface;
      } else {
        bg = colorScheme.primaryContainer;
        border = colorScheme.primary;
        fg = colorScheme.onPrimaryContainer;
      }
    } else {
      bg = colorScheme.surfaceContainerHighest.withAlpha(70);
      border = colorScheme.outlineVariant.withAlpha(50);
      fg = colorScheme.onSurfaceVariant;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: isSelected ? 1.5 : 1.0),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutcomeTicker(
    BuildContext context,
    MetricEvaluationResult result,
    String titleA,
    String titleB,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String statusText;
    Color statusColor;

    if (result.isAWins) {
      statusText = '$titleA takes the lead (${result.picksA} to ${result.picksB})';
      statusColor = colorScheme.primary;
    } else if (result.isBWins) {
      statusText = '$titleB takes the lead (${result.picksB} to ${result.picksA})';
      statusColor = colorScheme.primary;
    } else {
      statusText = 'Evenly matched (${result.picksA} - ${result.picksB})';
      statusColor = colorScheme.onSurfaceVariant;
    }

    return Center(
      child: Text(
        statusText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: statusColor,
        ),
      ),
    );
  }

  String _getConfirmButtonLabel(MetricEvaluationResult result, String titleA, String titleB) {
    if (result.isAWins) {
      return 'Choose $titleA';
    } else if (result.isBWins) {
      return 'Choose $titleB';
    } else {
      return 'Choose Draw';
    }
  }
}
