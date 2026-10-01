import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../../core/utils/value_metric_evaluator.dart';
import '../../domain/models/game_entry.dart';
import 'roi_badge.dart';
import 'status_badge.dart';
import 'storefront_badge.dart';

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
    final metric = ValueMetricEvaluator.evaluate(
      totalSpent: game.totalSpent,
      totalMinutes: game.totalMinutesPlayed,
      currency: game.currency,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: LycorisColors.slateCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LycorisColors.slateBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Cover Artwork
              if (game.coverUrl != null && game.coverUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: game.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: LycorisColors.slateDark,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: LycorisColors.primaryCrimson,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),

              // 2. Gradient Overlays for Readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.25, 0.55, 1.0],
                    colors: [
                      Colors.black.withAlpha(190),
                      Colors.transparent,
                      Colors.black.withAlpha(120),
                      Colors.black.withAlpha(240),
                    ],
                  ),
                ),
              ),

              // 3. Top Badges (Storefront & Status)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: StorefrontBadge(
                        storefront: game.storefront,
                        showLabel: false,
                      ),
                    ),
                    const SizedBox(width: 4),
                    StatusBadge(status: game.status),
                  ],
                ),
              ),

              // 4. Bottom Information Panel
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Playtime indicator
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: LycorisColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              TimeNormalizer.format(game.totalMinutesPlayed),
                              style: const TextStyle(
                                color: LycorisColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // ROI Badge
                        RoiBadge(
                          metric: metric,
                          compact: true,
                        ),
                      ],
                    ),

                    // Personal Rating Row if available
                    if (game.personalRating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 3),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            game.storefront.brandColor.withAlpha(80),
            LycorisColors.slateDark,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          game.storefront.fallbackIcon,
          size: 48,
          color: Colors.white.withAlpha(40),
        ),
      ),
    );
  }
}
