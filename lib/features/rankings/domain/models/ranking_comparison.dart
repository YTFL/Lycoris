import 'canonical_game.dart';

enum RankingChoice {
  aWins,
  bWins,
  draw,
}

/// Represents an active 1-on-1 comparison between two canonical games
class RankingComparison {
  final CanonicalGame gameA;
  final CanonicalGame gameB;

  const RankingComparison({
    required this.gameA,
    required this.gameB,
  });
}

/// Stores an immutable historical record of a comparison to support Undo
class ComparisonRecord {
  final String canonicalKeyA;
  final String canonicalKeyB;
  final RankingChoice result;
  final double deltaA;
  final double deltaB;
  final DateTime timestamp;

  const ComparisonRecord({
    required this.canonicalKeyA,
    required this.canonicalKeyB,
    required this.result,
    required this.deltaA,
    required this.deltaB,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'canonicalKeyA': canonicalKeyA,
    'canonicalKeyB': canonicalKeyB,
    'result': result.index,
    'deltaA': deltaA,
    'deltaB': deltaB,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ComparisonRecord.fromJson(Map<dynamic, dynamic> json) {
    return ComparisonRecord(
      canonicalKeyA: json['canonicalKeyA'] as String,
      canonicalKeyB: json['canonicalKeyB'] as String,
      result: RankingChoice.values[json['result'] as int? ?? 0],
      deltaA: (json['deltaA'] as num?)?.toDouble() ?? 0.0,
      deltaB: (json['deltaB'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
