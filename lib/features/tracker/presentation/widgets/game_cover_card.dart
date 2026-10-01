import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../domain/models/game_entry.dart';

class GameCoverCard extends StatelessWidget {
  final GameEntry game;
  final VoidCallback onTap;

  const GameCoverCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isCompact = cardWidth < 125;
        final isVeryCompact = cardWidth < 95;

        final titleFontSize = isVeryCompact ? 10.0 : (isCompact ? 11.5 : 13.0);
        final metaFontSize = isVeryCompact ? 8.5 : (isCompact ? 10.0 : 11.0);
        final iconSize = isVeryCompact ? 9.0 : (isCompact ? 11.0 : 12.0);
        final paddingAmount = isVeryCompact ? 5.0 : (isCompact ? 6.0 : 8.0);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(50),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 3 / 4.4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Cover Artwork
                  if (game.coverUrl != null && game.coverUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: game.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainerHigh,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildPlaceholder(colorScheme),
                    )
                  else
                    _buildPlaceholder(colorScheme),

                  // 2. High-Readability Bottom Gradient Scrim
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 0.70, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withAlpha(160),
                          Colors.black.withAlpha(245),
                        ],
                      ),
                    ),
                  ),

                  // 3. Bottom Information Panel: Title, Playtime & Rating only
                  Positioned(
                    bottom: paddingAmount,
                    left: paddingAmount,
                    right: paddingAmount,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          game.title,
                          maxLines: isCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                        SizedBox(height: isVeryCompact ? 2 : 4),

                        // Subtitle Row: Playtime and Rating
                        Row(
                          children: [
                            // Playtime indicator
                            Icon(
                              Icons.schedule_rounded,
                              size: iconSize,
                              color: colorScheme.onSurfaceVariant.withAlpha(220),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                TimeNormalizer.format(game.totalMinutesPlayed),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withAlpha(220),
                                  fontSize: metaFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Rating indicator (normalized to theme secondary color)
                            Icon(
                              game.personalRating > 0
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: iconSize,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              game.personalRating > 0
                                  ? game.personalRating.toStringAsFixed(1)
                                  : '—',
                              style: TextStyle(
                                color: colorScheme.secondary,
                                fontSize: metaFontSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_outlined,
          size: 36,
          color: colorScheme.onSurfaceVariant.withAlpha(80),
        ),
      ),
    );
  }
}
