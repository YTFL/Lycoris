import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency_converter.dart';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final games = ref.watch(vaultNotifierProvider).allGames;
    final primaryCurrency = ref.watch(settingsNotifierProvider).primaryCurrency;

    // Aggregations converted into primary display currency
    double totalInvested = 0.0;
    int totalMinutes = 0;
    int playedMinutes = 0;
    double playedSpend = 0.0;
    double backlogInvested = 0.0;

    final storefrontSpendMap = <Storefront, double>{};
    final statusCountMap = <GameStatus, int>{};
    final tierCountMap = <ValueTier, int>{};

    for (final game in games) {
      final convertedSpend = CurrencyConverter.convert(
        amount: game.totalSpent,
        fromCurrency: game.currency,
        toCurrency: primaryCurrency,
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

      // Storefront spend
      storefrontSpendMap[game.storefront] =
          (storefrontSpendMap[game.storefront] ?? 0.0) + convertedSpend;

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

    // Leaderboards
    final playedGames = games.where((g) => g.totalMinutesPlayed > 0 && g.totalSpent > 0).toList();
    playedGames.sort((a, b) => (a.costPerHour ?? 9999).compareTo(b.costPerHour ?? 9999));
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
          // M3 Currency Selector
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              tooltip: 'Change Display Currency',
              color: colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payments_outlined, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$primaryCurrency ${CurrencyConverter.symbolFor(primaryCurrency)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant, size: 18),
                  ],
                ),
              ),
              onSelected: (currency) {
                ref.read(settingsNotifierProvider.notifier).updatePrimaryCurrency(currency);
              },
              itemBuilder: (ctx) => CurrencyConverter.supportedCurrencies.map((c) {
                final isSelected = c == primaryCurrency;
                return PopupMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 16,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$c (${CurrencyConverter.symbolFor(c)})',
                        style: TextStyle(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
                      'Add games to your library to unlock ROI analytics, playtime tracking, and spend breakdowns.',
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
                // 1. KPI Overview Bento Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        context: context,
                        title: 'Total Invested',
                        value: CurrencyConverter.format(totalInvested, primaryCurrency),
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
                        color: LycorisColors.crimsonGlow,
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
                            ? '${CurrencyConverter.symbolFor(primaryCurrency)}${avgCostPerHour.toStringAsFixed(2)}/hr'
                            : 'N/A',
                        subtitle: 'Active played games',
                        icon: Icons.trending_up_rounded,
                        color: LycorisColors.tierGreatValue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        context: context,
                        title: 'Backlog Capital',
                        value: CurrencyConverter.format(backlogInvested, primaryCurrency),
                        subtitle: 'Unplayed investment',
                        icon: Icons.inventory_2_outlined,
                        color: LycorisColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Spend by Storefront Chart
                _buildStorefrontChartCard(
                  context: context,
                  spendMap: storefrontSpendMap,
                  totalInvested: totalInvested,
                  currency: primaryCurrency,
                ),

                const SizedBox(height: 16),

                // 3. Best ROI Champions
                _buildLeaderboardCard(
                  context: context,
                  title: 'Best Value Champions (Lowest Cost/Hr)',
                  items: bestRoiGames,
                  metricGetter: (g) =>
                      '${CurrencyConverter.symbolFor(primaryCurrency)}${g.costPerHour?.toStringAsFixed(2) ?? "0"}/hr',
                  currency: primaryCurrency,
                  icon: Icons.stars_rounded,
                  accentColor: LycorisColors.tierGreatValue,
                ),

                const SizedBox(height: 16),

                // 4. Most Played Time Sinks
                _buildLeaderboardCard(
                  context: context,
                  title: 'Top Time Sinks (Most Played)',
                  items: topTimeSinks,
                  metricGetter: (g) => TimeNormalizer.format(g.totalMinutesPlayed),
                  currency: primaryCurrency,
                  icon: Icons.military_tech_rounded,
                  accentColor: LycorisColors.crimsonLight,
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

  Widget _buildStorefrontChartCard({
    required BuildContext context,
    required Map<Storefront, double> spendMap,
    required double totalInvested,
    required String currency,
  }) {
    if (spendMap.isEmpty || totalInvested <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = spendMap.entries.toList();

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
                  'Spend by Storefront',
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
                            _touchedSectionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: List.generate(entries.length, (i) {
                        final isTouched = i == _touchedSectionIndex;
                        final storefront = entries[i].key;
                        final spend = entries[i].value;
                        final percentage = (spend / totalInvested) * 100;

                        return PieChartSectionData(
                          color: storefront.brandColor,
                          value: spend,
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
                    children: entries.map((e) {
                      final percentage = ((e.value / totalInvested) * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: e.key.brandColor,
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
                              '$percentage% (${CurrencyConverter.symbolFor(currency)}${e.value.toStringAsFixed(0)})',
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
                          color: accentColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withAlpha(90)),
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
