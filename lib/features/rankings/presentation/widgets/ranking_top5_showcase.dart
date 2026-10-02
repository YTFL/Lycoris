import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/models/ranking_tier.dart';
import '../controllers/rankings_state.dart';

class RankingTop5Showcase extends StatelessWidget {
  final List<RankedGameItem> topItems;
  final void Function(RankedGameItem item) onItemTap;

  const RankingTop5Showcase({
    super.key,
    required this.topItems,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (topItems.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Separate into Top 3 and Ranks 4-5
    final diamond = topItems.isNotEmpty ? topItems[0] : null;
    final platinum = topItems.length > 1 ? topItems[1] : null;
    final gold = topItems.length > 2 ? topItems[2] : null;
    final silver = topItems.length > 3 ? topItems[3] : null;
    final bronze = topItems.length > 4 ? topItems[4] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podium Row: #2 Platinum (left), #1 Diamond (center), #3 Gold (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // #2 Platinum
              Expanded(
                flex: 10,
                child: platinum != null
                    ? _buildPodiumSlot(
                        context,
                        item: platinum,
                        tier: RankingTier.platinum,
                        height: 180,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),

              // #1 Diamond (Center & Tallest)
              Expanded(
                flex: 11,
                child: diamond != null
                    ? _buildPodiumSlot(
                        context,
                        item: diamond,
                        tier: RankingTier.diamond,
                        height: 215,
                        isChampion: true,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),

              // #3 Gold
              Expanded(
                flex: 10,
                child: gold != null
                    ? _buildPodiumSlot(
                        context,
                        item: gold,
                        tier: RankingTier.gold,
                        height: 165,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),

          // Lower Tiers Row: #4 Silver & #5 Bronze
          if (silver != null || bronze != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (silver != null)
                  Expanded(
                    child: _buildSubTierCard(
                      context,
                      item: silver,
                      tier: RankingTier.silver,
                    ),
                  ),
                if (silver != null && bronze != null) const SizedBox(width: 10),
                if (bronze != null)
                  Expanded(
                    child: _buildSubTierCard(
                      context,
                      item: bronze,
                      tier: RankingTier.bronze,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPodiumSlot(
    BuildContext context, {
    required RankedGameItem item,
    required RankingTier tier,
    required double height,
    bool isChampion = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(14);
    final innerRadius = BorderRadius.circular(12);

    return InkWell(
      onTap: () => onItemTap(item),
      borderRadius: borderRadius,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: borderRadius,
          border: Border.all(
            color: tier.color.withAlpha(isChampion ? 200 : 140),
            width: isChampion ? 2.0 : 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: innerRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
            // Artwork
            if (item.game.coverUrl != null && item.game.coverUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: item.game.coverUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox(),
              ),

            // Scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(30),
                    Colors.black.withAlpha(120),
                    Colors.black.withAlpha(240),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Rank Badge Top
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: tier.color.withAlpha(220),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${item.rank}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Bottom Content
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                item.game.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSubTierCard(
    BuildContext context, {
    required RankedGameItem item,
    required RankingTier tier,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => onItemTap(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tier.color.withAlpha(90),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 34,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: colorScheme.surfaceContainerLowest,
              ),
              clipBehavior: Clip.antiAlias,
              child: item.game.coverUrl != null && item.game.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.game.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox(),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 8),

            // Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: tier.color.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${item.rank}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: tier.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
