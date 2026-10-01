import 'package:flutter/material.dart';

enum GameStatus {
  backlog('Backlog', Color(0xFF6B7280), Icons.hourglass_empty_rounded),
  playing('Playing', Color(0xFF3B82F6), Icons.play_arrow_rounded),
  completed('Completed', Color(0xFF10B981), Icons.check_circle_outline_rounded),
  mastered('Mastered (100%)', Color(0xFFF59E0B), Icons.military_tech_rounded),
  abandoned('Abandoned', Color(0xFFEF4444), Icons.cancel_outlined),
  wishlist('Wishlist', Color(0xFF8B5CF6), Icons.bookmark_outline_rounded);

  final String displayName;
  final Color color;
  final IconData icon;

  const GameStatus(
    this.displayName,
    this.color,
    this.icon,
  );
}
