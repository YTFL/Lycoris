import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/controllers/home_nav_provider.dart';
import '../../../tracker/presentation/screens/dossier_screen.dart';
import '../controllers/rankings_notifier.dart';
import '../controllers/rankings_state.dart';
import '../widgets/ranking_comparison_view.dart';
import '../widgets/ranking_list_tile.dart';
import '../widgets/ranking_top5_showcase.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(rankingsNotifierProvider);
    final notifier = ref.read(rankingsNotifierProvider.notifier);

    // 1. Not enough games state (< 2 eligible unique canonical games)
    if (state.canonicalGames.length < 2) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.leaderboard_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Rankings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.leaderboard_outlined,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Not Enough Games to Rank',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rankings require at least 2 unique completed, mastered, or abandoned (with playtime) games in your library.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () {
                    ref.read(homeNavIndexProvider.notifier).state = 0;
                  },
                  icon: const Icon(Icons.sports_esports_rounded),
                  label: const Text('View Library'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Active comparison session view
    if (state.isComparisonActive && state.currentComparison != null) {
      return Scaffold(
        body: RankingComparisonView(
          comparison: state.currentComparison!,
          currentComparisonIndex: state.currentComparisonIndex,
          totalComparisonsInSession: state.totalComparisonsInSession,
          canUndo: state.canUndo,
          isReliable: state.isReliable,
          onChoose: (result) => notifier.recordChoice(result),
          onUndo: () => notifier.undoLastChoice(),
          onSkip: () => notifier.skipComparison(),
          onFinishEarly: () => notifier.finishSessionEarly(),
          onExit: () => notifier.finishSessionEarly(),
        ),
      );
    }

    // 3. Ranked Leaderboard & Showcase View
    final rankedList = state.rankedList;
    final top5 = rankedList.take(5).toList();
    final remaining = rankedList.skip(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.leaderboard_outlined, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Rankings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (state.hasRankings)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'rank_more') {
                  notifier.startInitialRanking();
                } else if (value == 'rerank_all') {
                  _showRerankConfirmation(context, notifier);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'rank_more',
                  child: Row(
                    children: [
                      Icon(Icons.compare_arrows_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Rank More Comparisons'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rerank_all',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Re-rank All from Scratch'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: !state.hasRankings
          ? _buildUnrankedWelcome(context, notifier, state.canonicalGames.length)
          : CustomScrollView(
              slivers: [
                // New Games Ready to Rank Notification Banner
                if (state.newUnrankedGames.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.primary.withAlpha(120),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.newUnrankedGames.length} new game${state.newUnrankedGames.length > 1 ? 's' : ''} ready to rank',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rank newly finished titles to slot them into your list.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => notifier.startRankNewGames(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Rank Now'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top 5 Showcase
                SliverToBoxAdapter(
                  child: RankingTop5Showcase(
                    topItems: top5,
                    onItemTap: (item) => _openDossier(context, item),
                  ),
                ),

                // Remaining ranks
                if (remaining.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 4),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = remaining[index];
                        return RankingListTile(
                          item: item,
                          onTap: () => _openDossier(context, item),
                        );
                      },
                      childCount: remaining.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
      floatingActionButton: state.hasRankings
          ? FloatingActionButton.extended(
              onPressed: () => notifier.startInitialRanking(),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text(
                'Rank More',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildUnrankedWelcome(BuildContext context, RankingsNotifier notifier, int eligibleCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withAlpha(100),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 44,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Your Game Ranking',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Compare your $eligibleCount completed and played games head-to-head to determine your personal hall of fame.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => notifier.startInitialRanking(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Create a Ranking',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRerankConfirmation(BuildContext context, RankingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-rank All from Scratch?'),
        content: const Text(
          'This will reset your current game ranking scores and begin a fresh comparison session for all eligible games in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.startRerankAll();
            },
            child: const Text('Re-rank All'),
          ),
        ],
      ),
    );
  }

  void _openDossier(BuildContext context, RankedGameItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DossierScreen(gameId: item.game.primaryEntryId),
      ),
    );
  }
}
