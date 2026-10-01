import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../../core/utils/value_metric_evaluator.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../../tracker/domain/models/game_entry.dart';
import '../../../tracker/domain/models/game_status.dart';
import '../../../tracker/domain/models/storefront.dart';
import '../../../tracker/presentation/controllers/vault_notifier.dart';

class AnalyticsDashboard extends ConsumerStatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  ConsumerState<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends ConsumerState<AnalyticsDashboard> {
  int _touchedSectionIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exchangeRatesNotifierProvider.notifier).checkAndAutoFetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final games = ref.watch(vaultNotifierProvider).allGames;
    final primaryCurrency = ref.watch(settingsNotifierProvider).primaryCurrency;
    final exchangeRates = ref.watch(exchangeRatesNotifierProvider);

    // Aggregations converted into primary display currency
    double totalInvested = 0.0;
    int totalMinutes = 0;
    int playedMinutes = 0;
    double playedSpend = 0.0;
    double backlogInvested = 0.0;

    final storefrontCountMap = <Storefront, int>{};
    final statusCountMap = <GameStatus, int>{};
    final tierCountMap = <ValueTier, int>{};

    for (final game in games) {
      final convertedSpend = CurrencyHelper.convert(
        amount: game.totalSpent,
        fromCurrency: game.currency,
        toCurrency: primaryCurrency,
        rates: exchangeRates,
      );

      totalInvested += convertedSpend;
      totalMinutes += game.totalMinutesPlayed;

      if (game.totalMinutesPlayed > 0) {
        playedMinutes += game.totalMinutesPlayed;
        playedSpend += convertedSpend;
      }

      if (game.status == GameStatus.backlog || (game.totalMinutesPlayed == 0 && game.totalSpent > 0)) {
        backlogInvested += convertedSpend;
      }

      // Storefront games owned count
      storefrontCountMap[game.storefront] = (storefrontCountMap[game.storefront] ?? 0) + 1;

      // Status count
      statusCountMap[game.status] = (statusCountMap[game.status] ?? 0) + 1;

      // Tier count
      final metric = ValueMetricEvaluator.evaluate(
        totalSpent: game.totalSpent,
        totalMinutes: game.totalMinutesPlayed,
        currency: game.currency,
      );
      tierCountMap[metric.tier] = (tierCountMap[metric.tier] ?? 0) + 1;
    }

    final totalHours = totalMinutes / 60.0;
    final avgCostPerHour = playedMinutes > 0 ? (playedSpend / (playedMinutes / 60.0)) : 0.0;

    // Leaderboards normalized to primary currency
    double normalizedCostPerHour(GameEntry g) {
      if (g.costPerHour == null) return 999999.0;
      return CurrencyHelper.convert(
        amount: g.costPerHour!,
        fromCurrency: g.currency,
        toCurrency: primaryCurrency,
        rates: exchangeRates,
      );
    }

    final playedGames = games.where((g) => g.totalMinutesPlayed > 0 && g.totalSpent > 0).toList();
    playedGames.sort((a, b) => normalizedCostPerHour(a).compareTo(normalizedCostPerHour(b)));
    final bestRoiGames = playedGames.take(5).toList();

    final mostPlayedGames = List<GameEntry>.from(games);
    mostPlayedGames.sort((a, b) => b.totalMinutesPlayed.compareTo(a.totalMinutesPlayed));
    final topTimeSinks = mostPlayedGames.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Currency Selector Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => CurrencyHelper.showCurrencyPicker(
                context,
                currentCurrency: primaryCurrency,
                onSelected: (currency) {
                  ref.read(settingsNotifierProvider.notifier).updatePrimaryCurrency(currency);
                },
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencySymbolBox(
                      currencyCode: primaryCurrency,
                      size: 20,
                      baseFontSize: 10,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      primaryCurrency,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: games.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.insights_rounded, size: 48, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Games in Library Yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add games to your library to unlock playtime tracking, ownership distribution, and value metrics.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. KPI Overview Bento Cards (Normalized to M3 Primary & Secondary tones)
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        context: context,
                        title: 'Total Invested',
                        value: CurrencyHelper.format(totalInvested, currencyCode: primaryCurrency),
                        subtitle: 'Across ${games.length} titles',
                        icon: Icons.account_balance_wallet_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        context: context,
                        title: 'Total Playtime',
                        value: '${totalHours.toStringAsFixed(1)} hrs',
                        subtitle: '${(totalHours / 24).toStringAsFixed(1)} full days',
                        icon: Icons.schedule_rounded,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        context: context,
                        title: 'Avg Cost / Hour',
                        value: avgCostPerHour > 0
                            ? '${CurrencyHelper.format(avgCostPerHour, currencyCode: primaryCurrency)}/hr'
                            : 'N/A',
                        subtitle: 'Active played games',
                        icon: Icons.trending_up_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        context: context,
                        title: 'Backlog Capital',
                        value: CurrencyHelper.format(backlogInvested, currencyCode: primaryCurrency),
                        subtitle: 'Unplayed investment',
                        icon: Icons.inventory_2_outlined,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Games Owned by Platform Chart (Replaces Spend by Storefront)
                _buildStorefrontOwnershipCard(
                  context: context,
                  countMap: storefrontCountMap,
                  totalGames: games.length,
                ),

                const SizedBox(height: 16),

                // 3. Best Value Champions Leaderboard (Normalized to colorScheme.primary)
                _buildLeaderboardCard(
                  context: context,
                  title: 'Best Value Champions (Lowest Cost/Hr)',
                  items: bestRoiGames,
                  metricGetter: (g) =>
                      '${CurrencyHelper.format(normalizedCostPerHour(g), currencyCode: primaryCurrency)}/hr',
                  currency: primaryCurrency,
                  icon: Icons.stars_rounded,
                  accentColor: colorScheme.primary,
                ),

                const SizedBox(height: 16),

                // 4. Most Played Time Sinks Leaderboard (Normalized to colorScheme.secondary)
                _buildLeaderboardCard(
                  context: context,
                  title: 'Top Time Sinks (Most Played)',
                  items: topTimeSinks,
                  metricGetter: (g) => TimeNormalizer.format(g.totalMinutesPlayed),
                  currency: primaryCurrency,
                  icon: Icons.military_tech_rounded,
                  accentColor: colorScheme.secondary,
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorefrontOwnershipCard({
    required BuildContext context,
    required Map<Storefront, int> countMap,
    required int totalGames,
  }) {
    if (countMap.isEmpty || totalGames <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = countMap.entries.toList();

    // Harmonious M3 tonal palette for chart sections (no neon rainbow)
    final chartPalette = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.primary.withAlpha(190),
      colorScheme.secondary.withAlpha(190),
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiary,
    ];

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.pie_chart_outline_rounded, size: 16, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Games Owned by Platform',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedSectionIndex = -1;
                              return;
                            }
                            _touchedSectionIndex =
                                pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      sections: List.generate(entries.length, (i) {
                        final isTouched = i == _touchedSectionIndex;
                        final count = entries[i].value;
                        final percentage = (count / totalGames) * 100;
                        final sliceColor = chartPalette[i % chartPalette.length];

                        return PieChartSectionData(
                          color: sliceColor,
                          value: count.toDouble(),
                          title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
                          radius: isTouched ? 32 : 26,
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.asMap().entries.map((item) {
                      final i = item.key;
                      final e = item.value;
                      final percentage = ((e.value / totalGames) * 100).toStringAsFixed(1);
                      final sliceColor = chartPalette[i % chartPalette.length];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: sliceColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${e.value} ($percentage%)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard({
    required BuildContext context,
    required String title,
    required List<GameEntry> items,
    required String Function(GameEntry) metricGetter,
    required String currency,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No games recorded with playtime yet.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => Divider(color: colorScheme.outlineVariant.withAlpha(50), height: 16),
                itemBuilder: (context, index) {
                  final game = items[index];
                  return Row(
                    children: [
                      Text(
                        '#${index + 1}',
                        style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${game.storefront.label} • ${TimeNormalizer.format(game.totalMinutesPlayed)}',
                              style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withAlpha(80)),
                        ),
                        child: Text(
                          metricGetter(game),
                          style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
