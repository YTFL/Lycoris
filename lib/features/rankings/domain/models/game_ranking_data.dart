/// Persistent statistics and Elo rating for a canonical game
class GameRankingData {
  final String canonicalKey;
  final double eloRating;
  final int wins;
  final int losses;
  final int draws;
  final int comparisonCount;
  final DateTime? lastRankedAt;

  const GameRankingData({
    required this.canonicalKey,
    this.eloRating = 1200.0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.comparisonCount = 0,
    this.lastRankedAt,
  });

  /// A game is considered calibrated once it has participated in at least 3 comparisons
  bool get isCalibrated => comparisonCount >= 3;

  double get winRate {
    if (comparisonCount <= 0) return 0.0;
    return (wins + (draws * 0.5)) / comparisonCount;
  }

  GameRankingData copyWith({
    String? canonicalKey,
    double? eloRating,
    int? wins,
    int? losses,
    int? draws,
    int? comparisonCount,
    DateTime? lastRankedAt,
  }) {
    return GameRankingData(
      canonicalKey: canonicalKey ?? this.canonicalKey,
      eloRating: eloRating ?? this.eloRating,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      comparisonCount: comparisonCount ?? this.comparisonCount,
      lastRankedAt: lastRankedAt ?? this.lastRankedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'canonicalKey': canonicalKey,
    'eloRating': eloRating,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'comparisonCount': comparisonCount,
    'lastRankedAt': lastRankedAt?.toIso8601String(),
  };

  factory GameRankingData.fromJson(Map<dynamic, dynamic> json) {
    return GameRankingData(
      canonicalKey: json['canonicalKey'] as String,
      eloRating: (json['eloRating'] as num?)?.toDouble() ?? 1200.0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      comparisonCount: json['comparisonCount'] as int? ?? 0,
      lastRankedAt: json['lastRankedAt'] != null
          ? DateTime.tryParse(json['lastRankedAt'] as String)
          : null,
    );
  }
}
