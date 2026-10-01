import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../domain/models/game_entry.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            // 1. Cover Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 58,
                child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: game.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(
                          color: colorScheme.surfaceContainerHigh,
                        ),
                        errorWidget: (c, u, e) => _buildPlaceholder(colorScheme),
                      )
                    : _buildPlaceholder(colorScheme),
              ),
            ),
            const SizedBox(width: 14),

            // 2. Info Column: Title and Subtitle Row (Time Played & Rating)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Time Played
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TimeNormalizer.format(game.totalMinutesPlayed),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withAlpha(120),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      // Rating
                      Icon(
                        game.personalRating > 0
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        game.personalRating > 0
                            ? game.personalRating.toStringAsFixed(1)
                            : '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant.withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.sports_esports_outlined,
          size: 20,
          color: colorScheme.onSurfaceVariant.withAlpha(80),
        ),
      ),
    );
  }
}
