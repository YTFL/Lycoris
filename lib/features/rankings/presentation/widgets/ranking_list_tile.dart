import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../domain/models/ranking_tier.dart';
import '../controllers/rankings_state.dart';

class RankingListTile extends StatelessWidget {
  final RankedGameItem item;
  final VoidCallback onTap;

  const RankingListTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tier = RankingTier.forRank(item.rank);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withAlpha(40),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Rank Number Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tier != RankingTier.standard
                    ? tier.color.withAlpha(40)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tier != RankingTier.standard
                      ? tier.color.withAlpha(140)
                      : colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
              child: Center(
                child: Text(
                  '#${item.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: tier != RankingTier.standard
                        ? tier.color
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Cover Thumbnail
            Container(
              width: 40,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: colorScheme.surfaceContainerLowest,
              ),
              clipBehavior: Clip.antiAlias,
              child: item.game.coverUrl != null && item.game.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.game.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(Icons.sports_esports, size: 18),
                    )
                  : const Icon(Icons.sports_esports, size: 18),
            ),
            const SizedBox(width: 12),

            // Title & Playtime
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (item.game.totalMinutesPlayed > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      TimeNormalizer.format(item.game.totalMinutesPlayed),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
