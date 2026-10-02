import 'package:flutter/material.dart';
import 'ranking_comparison.dart';

/// The 9 core evaluation dimensions for breaking down game comparisons
enum ComparisonMetric {
  gameplay(
    key: 'gameplay',
    title: 'Gameplay & Mechanics',
    description: 'Controls, combat, responsiveness, core loop, and game feel',
    icon: Icons.sports_esports_rounded,
  ),
  story(
    key: 'story',
    title: 'Story & Narrative',
    description: 'Plot, character development, lore, writing, and dialogue',
    icon: Icons.auto_stories_rounded,
  ),
  visuals(
    key: 'visuals',
    title: 'Visuals & Art Style',
    description: 'Art direction, aesthetic coherence, graphics fidelity, and animations',
    icon: Icons.palette_rounded,
  ),
  audio(
    key: 'audio',
    title: 'Music & Audio',
    description: 'Original soundtrack, ambient sound design, and voice acting',
    icon: Icons.music_note_rounded,
  ),
  world(
    key: 'world',
    title: 'World & Atmosphere',
    description: 'Immersion, level design, environment, and world-building',
    icon: Icons.public_rounded,
  ),
  pacing(
    key: 'pacing',
    title: 'Pacing & Game Flow',
    description: 'Progression momentum, lack of bloat/filler, and respect for player time',
    icon: Icons.speed_rounded,
  ),
  impact(
    key: 'impact',
    title: 'Emotional Impact & Memorability',
    description: 'Climax, emotional resonance, and how long the game sticks with you',
    icon: Icons.favorite_rounded,
  ),
  replayability(
    key: 'replayability',
    title: 'Replay Value & Depth',
    description: 'Build variety, post-game/endgame depth, secrets, and reasons to return',
    icon: Icons.replay_rounded,
  ),
  polish(
    key: 'polish',
    title: 'Polish & Quality of Life',
    description: 'Performance smoothness, UI/UX clarity, responsiveness, and bug-free execution',
    icon: Icons.verified_rounded,
  );

  final String key;
  final String title;
  final String description;
  final IconData icon;

  const ComparisonMetric({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// The user's preference choice for an individual metric
enum MetricPreference {
  gameA,
  draw,
  gameB,
}

/// The computed outcome of multi-criteria decision evaluation
class MetricEvaluationResult {
  final double scoreA;
  final double scoreB;
  final int picksA;
  final int picksB;
  final int picksDraw;
  final RankingChoice choice;

  const MetricEvaluationResult({
    required this.scoreA,
    required this.scoreB,
    required this.picksA,
    required this.picksB,
    required this.picksDraw,
    required this.choice,
  });

  bool get isDraw => choice == RankingChoice.draw;
  bool get isAWins => choice == RankingChoice.aWins;
  bool get isBWins => choice == RankingChoice.bWins;

  /// Evaluates a map of metric preferences into a decisive winner or verified draw.
  /// 
  /// Each metric:
  /// - [MetricPreference.gameA]: +1.0 to Game A
  /// - [MetricPreference.draw]: +0.5 to Game A, +0.5 to Game B
  /// - [MetricPreference.gameB]: +1.0 to Game B
  /// 
  /// If unselected, defaults to neutral 0.5 / 0.5.
  static MetricEvaluationResult evaluate(Map<ComparisonMetric, MetricPreference> preferences) {
    double scoreA = 0.0;
    double scoreB = 0.0;
    int picksA = 0;
    int picksB = 0;
    int picksDraw = 0;

    for (final metric in ComparisonMetric.values) {
      final pref = preferences[metric] ?? MetricPreference.draw;
      switch (pref) {
        case MetricPreference.gameA:
          scoreA += 1.0;
          picksA += 1;
          break;
        case MetricPreference.gameB:
          scoreB += 1.0;
          picksB += 1;
          break;
        case MetricPreference.draw:
          scoreA += 0.5;
          scoreB += 0.5;
          picksDraw += 1;
          break;
      }
    }

    final RankingChoice choice;
    if (scoreA > scoreB) {
      choice = RankingChoice.aWins;
    } else if (scoreB > scoreA) {
      choice = RankingChoice.bWins;
    } else {
      choice = RankingChoice.draw;
    }

    return MetricEvaluationResult(
      scoreA: scoreA,
      scoreB: scoreB,
      picksA: picksA,
      picksB: picksB,
      picksDraw: picksDraw,
      choice: choice,
    );
  }
}
