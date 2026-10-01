import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency_converter.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../../core/utils/value_metric_evaluator.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../domain/models/additional_expense.dart';
import '../../domain/models/game_entry.dart';
import '../controllers/vault_notifier.dart';
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
  GameEntry? _getGame() {
    final allGames = ref.watch(vaultNotifierProvider).allGames;
    final index = allGames.indexWhere((g) => g.id == widget.gameId);
    return index != -1 ? allGames[index] : null;
  }

  void _showAddExpenseDialog(BuildContext context, GameEntry game) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LycorisColors.slateCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: LycorisColors.slateBorder),
        ),
        title: const Text('Add Additional Expense / DLC', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title / Description',
                hintText: 'e.g. Season Pass, Deluxe DLC, Skin',
                labelStyle: TextStyle(color: LycorisColors.textSecondary),
                hintStyle: TextStyle(color: LycorisColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (${game.currency})',
                labelStyle: const TextStyle(color: LycorisColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: LycorisColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LycorisColors.primaryCrimson),
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
                ref.read(vaultNotifierProvider.notifier).addExpense(game.id, expense);
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LycorisColors.slateCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: LycorisColors.slateBorder),
        ),
        title: const Text('Edit Notes & Impressions', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: notesController,
          maxLines: 6,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Write your thoughts, completion milestones, or review...',
            hintStyle: TextStyle(color: LycorisColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: LycorisColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LycorisColors.primaryCrimson),
            onPressed: () {
              ref.read(vaultNotifierProvider.notifier).updateNotes(game.id, notesController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save Notes'),
          ),
        ],
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
          child: Text('Game entry not found.', style: TextStyle(color: LycorisColors.textSecondary)),
        ),
      );
    }

    final primaryCurrency = ref.watch(settingsNotifierProvider).primaryCurrency;
    final metric = ValueMetricEvaluator.evaluate(
      totalSpent: game.totalSpent,
      totalMinutes: game.totalMinutesPlayed,
      currency: game.currency,
    );

    // Primary currency normalized conversion
    final convertedTotal = CurrencyConverter.convert(
      amount: game.totalSpent,
      fromCurrency: game.currency,
      toCurrency: primaryCurrency,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

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
              IconButton(
                icon: const Icon(Icons.delete_outline, color: LycorisColors.error),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: LycorisColors.slateCard,
                      title: const Text('Remove Game?', style: TextStyle(color: Colors.white)),
                      content: Text(
                        'Are you sure you want to remove "${game.title}" (${game.storefront.label})?',
                        style: const TextStyle(color: LycorisColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: LycorisColors.textSecondary)),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: LycorisColors.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await ref.read(vaultNotifierProvider.notifier).deleteGame(game.id);
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
                    Container(color: game.storefront.brandColor.withAlpha(60)),

                  // Dark Vignette Gradients
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(160),
                          Colors.black.withAlpha(220),
                          scaffoldBg,
                        ],
                      ),
                    ),
                  ),

                  // Foreground Hero Details
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Floating 3:4 Box Art
                        Container(
                          width: 110,
                          height: 146,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: LycorisColors.slateBorder, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 16, offset: const Offset(0, 8)),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: game.coverUrl != null
                              ? CachedNetworkImage(imageUrl: game.coverUrl!, fit: BoxFit.cover)
                              : Container(
                                  color: LycorisColors.slateDark,
                                  child: Icon(game.storefront.fallbackIcon, size: 40, color: Colors.white24),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  StorefrontBadge(storefront: game.storefront),
                                  StatusBadge(status: game.status),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Financial & ROI Bento Grid
                  _buildFinancialRoiCard(game, metric, primaryCurrency, convertedTotal),
                  const SizedBox(height: 20),

                  // 2. Playtime & Progression
                  _buildPlaytimeCard(game),
                  const SizedBox(height: 20),

                  // 3. Itemized Expenses / DLC Table
                  _buildExpensesCard(game),
                  const SizedBox(height: 20),

                  // 4. Personal Rating & Journal Notes
                  _buildJournalCard(game),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRoiCard(
    GameEntry game,
    ValueMetric metric,
    String primaryCurrency,
    double convertedTotal,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LycorisColors.slateCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LycorisColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INVESTMENT & RETURN (ROI)',
                style: TextStyle(
                  color: LycorisColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              RoiBadge(metric: metric),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Base Price',
                  '${game.currency} ${game.basePrice.toStringAsFixed(2)}',
                  Icons.receipt_long,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'DLC / Extras',
                  '${game.currency} ${(game.totalSpent - game.basePrice).toStringAsFixed(2)}',
                  Icons.extension_outlined,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Total Spent',
                  '${game.currency} ${game.totalSpent.toStringAsFixed(2)}',
                  Icons.account_balance_wallet_outlined,
                  highlight: true,
                ),
              ),
            ],
          ),
          if (game.currency != primaryCurrency) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: LycorisColors.slateDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '≈ ${CurrencyConverter.symbolFor(primaryCurrency)}${convertedTotal.toStringAsFixed(2)} in Primary Currency ($primaryCurrency)',
                style: const TextStyle(color: LycorisColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: LycorisColors.textMuted),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: LycorisColors.textSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? LycorisColors.crimsonGlow : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaytimeCard(GameEntry game) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LycorisColors.slateCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LycorisColors.slateBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL PLAYTIME',
                style: TextStyle(
                  color: LycorisColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                TimeNormalizer.format(game.totalMinutesPlayed),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${game.totalMinutesPlayed} canonical minutes logged',
                style: const TextStyle(color: LycorisColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          FilledButton.icon(
            icon: const Icon(Icons.timer_outlined, size: 16),
            label: const Text('Log Time'),
            style: FilledButton.styleFrom(
              backgroundColor: LycorisColors.primaryCrimson,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => PlaytimeEditorDialog(
                  initialMinutes: game.totalMinutesPlayed,
                  gameTitle: game.title,
                  onSave: (newMinutes) {
                    ref.read(vaultNotifierProvider.notifier).updatePlaytime(game.id, newMinutes);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesCard(GameEntry game) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LycorisColors.slateCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LycorisColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DLC & EXPENSES ITEMIZATION',
                style: TextStyle(
                  color: LycorisColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: LycorisColors.crimsonGlow),
                label: const Text('Add DLC', style: TextStyle(color: LycorisColors.crimsonGlow, fontSize: 12)),
                onPressed: () => _showAddExpenseDialog(context, game),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (game.additionalExpenses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No additional DLC, battle passes, or microtransactions recorded.',
                style: TextStyle(color: LycorisColors.textMuted, fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: game.additionalExpenses.length,
              separatorBuilder: (_, _) => const Divider(color: LycorisColors.slateDivider, height: 12),
              itemBuilder: (context, index) {
                final expense = game.additionalExpenses[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(DateFormat.yMMMd().format(expense.date), style: const TextStyle(color: LycorisColors.textMuted, fontSize: 10.5)),
                        ],
                      ),
                    ),
                    Text(
                      '${game.currency} ${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: LycorisColors.crimsonLight, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: LycorisColors.textMuted),
                      onPressed: () {
                        ref.read(vaultNotifierProvider.notifier).removeExpense(game.id, expense.id);
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

  Widget _buildJournalCard(GameEntry game) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LycorisColors.slateCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LycorisColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RATING & JOURNAL',
                style: TextStyle(
                  color: LycorisColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: LycorisColors.crimsonGlow),
                onPressed: () => _showNotesEditor(context, game),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 22),
              const SizedBox(width: 6),
              Text(
                game.personalRating > 0 ? '${game.personalRating.toStringAsFixed(1)} / 10.0' : 'Unrated',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            game.notes.isNotEmpty ? game.notes : 'No personal notes or impressions written yet. Tap edit to journal.',
            style: TextStyle(
              color: game.notes.isNotEmpty ? LycorisColors.textPrimary : LycorisColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
