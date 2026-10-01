import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../../core/utils/value_metric_evaluator.dart';
import '../../domain/models/game_entry.dart';
import 'roi_badge.dart';
import 'status_badge.dart';
import 'storefront_badge.dart';

class GameLedgerRow extends StatelessWidget {
  final GameEntry game;
  final VoidCallback onTap;

  const GameLedgerRow({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final metric = ValueMetricEvaluator.evaluate(
      totalSpent: game.totalSpent,
      totalMinutes: game.totalMinutesPlayed,
      currency: game.currency,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LycorisColors.slateCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: LycorisColors.slateBorder, width: 1),
        ),
        child: Row(
          children: [
            // Cover Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 64,
                child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: game.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LycorisColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StorefrontBadge(
                        storefront: game.storefront,
                        showLabel: true,
                      ),
                      StatusBadge(status: game.status),
                      if (game.personalRating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              game.personalRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Financial & Time Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RoiBadge(metric: metric, compact: true),
                const SizedBox(height: 5),
                Text(
                  TimeNormalizer.format(game.totalMinutesPlayed),
                  style: const TextStyle(
                    color: LycorisColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${game.currency} ${game.totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: LycorisColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: LycorisColors.slateDark,
      child: Center(
        child: Icon(
          game.storefront.fallbackIcon,
          size: 24,
          color: Colors.white24,
        ),
      ),
    );
  }
}
