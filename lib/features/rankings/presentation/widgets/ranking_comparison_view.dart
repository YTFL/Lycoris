import 'package:flutter/material.dart';
import '../../domain/models/ranking_comparison.dart';
import 'help_me_choose_sheet.dart';
import 'ranking_game_banner.dart';

class RankingComparisonView extends StatelessWidget {
  final RankingComparison comparison;
  final int currentComparisonIndex;
  final int totalComparisonsInSession;
  final bool canUndo;
  final bool isReliable;
  final ValueChanged<RankingChoice> onChoose;
  final VoidCallback onUndo;
  final VoidCallback onSkip;
  final VoidCallback onFinishEarly;
  final VoidCallback onExit;

  const RankingComparisonView({
    super.key,
    required this.comparison,
    required this.currentComparisonIndex,
    required this.totalComparisonsInSession,
    required this.canUndo,
    required this.isReliable,
    required this.onChoose,
    required this.onUndo,
    required this.onSkip,
    required this.onFinishEarly,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = totalComparisonsInSession > 0
        ? (currentComparisonIndex / totalComparisonsInSession).clamp(0.0, 1.0)
        : 0.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Top Bar: Exit button, progress & step counter
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Exit to Rankings',
                  onPressed: onExit,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Comparison $currentComparisonIndex of $totalComparisonsInSession',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Balancing spacer
              ],
            ),
            const SizedBox(height: 12),

            // Header title
            Text(
              'Pick one',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),

            // Two Clickable Game Banners
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isPortrait = constraints.maxHeight > constraints.maxWidth * 1.1;

                  if (!isPortrait) {
                    // Landscape or Wide Screen: Side-by-side
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: RankingGameBanner(
                            game: comparison.gameA,
                            onTap: () => onChoose(RankingChoice.aWins),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: _buildVsBadge(colorScheme),
                          ),
                        ),
                        Expanded(
                          child: RankingGameBanner(
                            game: comparison.gameB,
                            onTap: () => onChoose(RankingChoice.bWins),
                          ),
                        ),
                      ],
                    );
                  }

                  // Portrait Mobile Screen: Side-by-side with nice vertical aspect
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: RankingGameBanner(
                          game: comparison.gameA,
                          onTap: () => onChoose(RankingChoice.aWins),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RankingGameBanner(
                          game: comparison.gameB,
                          onTap: () => onChoose(RankingChoice.bWins),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Center "Help Me Choose" Button
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _openHelpMeChoose(context),
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Text(
                  'Help Me Choose',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withAlpha(160),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Navigation & Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: canUndo ? onUndo : null,
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Undo'),
                ),
                TextButton(
                  onPressed: isReliable ? onFinishEarly : null,
                  child: const Text('Finish Early'),
                ),
                TextButton.icon(
                  onPressed: onSkip,
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVsBadge(ColorScheme colorScheme) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          'VS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _openHelpMeChoose(BuildContext context) async {
    final choice = await HelpMeChooseSheet.show(
      context,
      gameA: comparison.gameA,
      gameB: comparison.gameB,
    );
    if (choice != null) {
      onChoose(choice);
    }
  }
}
