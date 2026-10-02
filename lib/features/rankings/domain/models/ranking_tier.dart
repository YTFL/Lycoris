import 'package:flutter/material.dart';

/// Visual tier representation for the Top 5 and overall rankings
enum RankingTier {
  diamond(
    'Diamond',
    Color(0xFF00E5FF),
  ),
  platinum(
    'Platinum',
    Color(0xFFE2E8F0),
  ),
  gold(
    'Gold',
    Color(0xFFF59E0B),
  ),
  silver(
    'Silver',
    Color(0xFF94A3B8),
  ),
  bronze(
    'Bronze',
    Color(0xFFD97706),
  ),
  standard(
    'Ranked',
    Color(0xFF64748B),
  );

  final String displayName;
  final Color color;

  const RankingTier(this.displayName, this.color);

  /// Determine the tier for a 1-based rank position
  static RankingTier forRank(int rank) {
    switch (rank) {
      case 1:
        return RankingTier.diamond;
      case 2:
        return RankingTier.platinum;
      case 3:
        return RankingTier.gold;
      case 4:
        return RankingTier.silver;
      case 5:
        return RankingTier.bronze;
      default:
        return RankingTier.standard;
    }
  }
}
