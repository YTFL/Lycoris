import 'package:flutter/material.dart';

enum Storefront {
  steam('Steam', 'assets/icons/steam.svg', Color(0xFF1B2838), Icons.sports_esports),
  epicGames('Epic Games', 'assets/icons/epic.svg', Color(0xFF2A2A2A), Icons.gamepad),
  gog('GOG', 'assets/icons/gog.svg', Color(0xFF7825BC), Icons.auto_awesome),
  itchIo('itch.io', 'assets/icons/itch.svg', Color(0xFFFA5C5C), Icons.favorite),
  playstation('PlayStation', 'assets/icons/ps.svg', Color(0xFF00439C), Icons.games),
  nintendoSwitch('Nintendo Switch', 'assets/icons/switch.svg', Color(0xFFE60012), Icons.videogame_asset),
  xbox('Xbox', 'assets/icons/xbox.svg', Color(0xFF107C10), Icons.gamepad_outlined),
  physical('Physical', 'assets/icons/disc.svg', Color(0xFF2563EB), Icons.album),
  other('Other', 'assets/icons/gamepad.svg', Color(0xFF4B5563), Icons.devices_other);

  final String label;
  final String iconAsset;
  final Color brandColor;
  final IconData fallbackIcon;

  const Storefront(
    this.label,
    this.iconAsset,
    this.brandColor,
    this.fallbackIcon,
  );
}
