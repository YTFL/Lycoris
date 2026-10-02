import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../../core/utils/value_metric_evaluator.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../domain/models/additional_expense.dart';
import '../../domain/models/game_entry.dart';
import '../../domain/models/game_status.dart';
import '../controllers/library_notifier.dart';
import '../widgets/edit_game_modal.dart';
import '../widgets/playtime_editor_dialog.dart';
import '../widgets/roi_badge.dart';
import '../widgets/status_badge.dart';
import '../widgets/storefront_badge.dart';

class DossierScreen extends ConsumerStatefulWidget {
  final String gameId;

  const DossierScreen({
    super.key,
    required this.gameId,
  });

  @override
  ConsumerState<DossierScreen> createState() => _DossierScreenState();
}

class _DossierScreenState extends ConsumerState<DossierScreen> {
  late String _currentGameId;

  @override
  void initState() {
    super.initState();
    _currentGameId = widget.gameId;
  }

  GameEntry? _getGame() {
    final allGames = ref.watch(libraryNotifierProvider).allGames;
    final index = allGames.indexWhere((g) => g.id == _currentGameId);
    return index != -1 ? allGames[index] : null;
  }

  void _showAddExpenseDialog(BuildContext context, GameEntry game) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
        ),
        title: Text(
          'Add Additional Expense / DLC',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Description',
                hintText: 'e.g. Season Pass, Deluxe DLC, Skin',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (${game.currency})',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (title.isNotEmpty && amount > 0) {
                final expense = AdditionalExpense(
                  id: const Uuid().v4(),
                  title: title,
                  amount: amount,
                  date: DateTime.now(),
                );
                ref.read(libraryNotifierProvider.notifier).addExpense(game.id, expense);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  void _showNotesEditor(BuildContext context, GameEntry game) {
    final notesController = TextEditingController(text: game.notes);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
        ),
        title: Text(
          'Edit Notes & Impressions',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: notesController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Write your thoughts, completion milestones, or review...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(libraryNotifierProvider.notifier).updateNotes(game.id, notesController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save Notes'),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context, GameEntry game) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Change Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ...GameStatus.values.map((status) {
                  final isCurrent = status == game.status;
                  return ListTile(
                    leading: Icon(
                      status.icon,
                      color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      status.displayName,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                        color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    trailing: isCurrent ? Icon(Icons.check_rounded, color: colorScheme.primary) : null,
                    onTap: () {
                      ref.read(libraryNotifierProvider.notifier).updateStatus(game.id, status);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context, GameEntry game) {
    double currentRating = game.personalRating;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
            ),
            title: Text(
              'Personal Rating',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentRating > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: colorScheme.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentRating > 0 ? currentRating.toStringAsFixed(1) : 'Unrated',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: currentRating,
                  min: 0.0,
                  max: 10.0,
                  divisions: 20,
                  activeColor: colorScheme.primary,
                  onChanged: (val) {
                    setDialogState(() => currentRating = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(libraryNotifierProvider.notifier).updateRating(game.id, currentRating);
                  Navigator.pop(ctx);
                },
                child: const Text('Save Score'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = _getGame();
    if (game == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Game entry not found.'),
        ),
      );
    }

    final primaryCurrency = ref.watch(settingsNotifierProvider).primaryCurrency;
    final exchangeRates = ref.watch(exchangeRatesNotifierProvider);
    final metric = ValueMetricEvaluator.evaluate(
      totalSpent: game.totalSpent,
      totalMinutes: game.totalMinutesPlayed,
      currency: game.currency,
    );

    // Primary currency normalized conversion using live exchange rates
    final convertedTotal = CurrencyHelper.convert(
      amount: game.totalSpent,
      fromCurrency: game.currency,
      toCurrency: primaryCurrency,
      rates: exchangeRates,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero App Bar with Cover Art
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: colorScheme.surfaceContainerLow,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Edit Game Details Button
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit Game Details',
                onPressed: () async {
                  final newId = await showDialog<String>(
                    context: context,
                    builder: (ctx) => EditGameModal(
                      game: game,
                      onGameUpdated: (id) {
                        setState(() => _currentGameId = id);
                      },
                    ),
                  );
                  if (newId != null && mounted) {
                    setState(() => _currentGameId = newId);
                  }
                },
              ),

              // Delete Game Button
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                tooltip: 'Remove Game',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      title: const Text('Remove Game?'),
                      content: Text(
                        'Are you sure you want to remove "${game.title}" (${game.storefront.label})?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await ref.read(libraryNotifierProvider.notifier).deleteGame(game.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred Background Backdrop
                  if (game.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: game.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: colorScheme.surfaceContainerHighest),

                  // Dark Vignette Gradients
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(160),
                          Colors.black.withAlpha(100),
                          Colors.black.withAlpha(220),
                          colorScheme.surface,
                        ],
                        stops: const [0.0, 0.4, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // Game Header Metadata
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cover Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 80,
                            height: 110,
                            child: game.coverUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: game.coverUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: colorScheme.surfaceContainerHigh,
                                    child: Icon(game.storefront.fallbackIcon, size: 36, color: colorScheme.onSurfaceVariant),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title & Badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                game.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  StorefrontBadge(storefront: game.storefront),
                                  // Interactive Status Badge
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _showStatusPicker(context, game),
                                    child: StatusBadge(status: game.status),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Financial & ROI Bento Grid
                  _buildFinancialRoiCard(context, game, metric, primaryCurrency, convertedTotal),
                  const SizedBox(height: 16),

                  // 2. Playtime & Progression
                  _buildPlaytimeCard(context, game),
                  const SizedBox(height: 16),

                  // 3. Itemized Expenses / DLC Table
                  _buildExpensesCard(context, game),
                  const SizedBox(height: 16),

                  // 4. Personal Rating & Journal Notes
                  _buildJournalCard(context, game),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRoiCard(
    BuildContext context,
    GameEntry game,
    ValueMetric metric,
    String primaryCurrency,
    double convertedTotal,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INVESTMENT & RETURN (ROI)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              RoiBadge(metric: metric),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  'Base Price',
                  CurrencyHelper.format(game.basePrice, currencyCode: game.currency),
                  Icons.receipt_long,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context,
                  'DLC / Extras',
                  CurrencyHelper.format(game.totalSpent - game.basePrice, currencyCode: game.currency),
                  Icons.extension_outlined,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context,
                  'Total Spent',
                  CurrencyHelper.format(game.totalSpent, currencyCode: game.currency),
                  Icons.account_balance_wallet_outlined,
                  highlight: true,
                ),
              ),
            ],
          ),
          if (game.currency != primaryCurrency) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
              ),
              child: Row(
                children: [
                  CurrencySymbolBox(
                    currencyCode: primaryCurrency,
                    size: 22,
                    baseFontSize: 11,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '≈ ${CurrencyHelper.format(convertedTotal, currencyCode: primaryCurrency)} in Primary Currency ($primaryCurrency)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, IconData icon, {bool highlight = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: highlight ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaytimeCard(BuildContext context, GameEntry game) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL PLAYTIME',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                TimeNormalizer.format(game.totalMinutesPlayed),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${game.totalMinutesPlayed} canonical minutes logged',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(180),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          FilledButton.icon(
            icon: const Icon(Icons.timer_outlined, size: 16),
            label: const Text('Log Time'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => PlaytimeEditorDialog(
                  initialMinutes: game.totalMinutesPlayed,
                  gameTitle: game.title,
                  onSave: (newMinutes) {
                    ref.read(libraryNotifierProvider.notifier).updatePlaytime(game.id, newMinutes);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesCard(BuildContext context, GameEntry game) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DLC & EXPENSES ITEMIZATION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add DLC', style: TextStyle(fontSize: 12)),
                onPressed: () => _showAddExpenseDialog(context, game),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (game.additionalExpenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No additional DLC, battle passes, or microtransactions recorded.',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: game.additionalExpenses.length,
              separatorBuilder: (_, _) => Divider(color: colorScheme.outlineVariant.withAlpha(30), height: 12),
              itemBuilder: (context, index) {
                final expense = game.additionalExpenses[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            DateFormat.yMMMd().format(expense.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyHelper.format(expense.amount, currencyCode: game.currency),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: colorScheme.onSurfaceVariant,
                      onPressed: () {
                        ref.read(libraryNotifierProvider.notifier).removeExpense(game.id, expense.id);
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, GameEntry game) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RATING & JOURNAL',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                color: colorScheme.primary,
                onPressed: () => _showNotesEditor(context, game),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Interactive Rating Row
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showRatingDialog(context, game),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    game.personalRating > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: colorScheme.secondary,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    game.personalRating > 0 ? '${game.personalRating.toStringAsFixed(1)} / 10.0' : 'Tap to rate (Unrated)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            game.notes.isNotEmpty ? game.notes : 'No personal notes or impressions written yet. Tap edit to journal.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: game.notes.isNotEmpty ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withAlpha(160),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
