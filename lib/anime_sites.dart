import 'package:flutter/material.dart';

class AnimeSite {
  final String name;
  final String url;
  final String description;
  final Color primaryColor;
  final Color backgroundColor;
  final IconData icon;

  const AnimeSite({
    required this.name,
    required this.url,
    required this.description,
    required this.primaryColor,
    required this.backgroundColor,
    required this.icon,
  });
}

class AnimeSites {
  static const hianime = AnimeSite(
    name: 'HiAnime',
    url: 'https://hianime.to/',
    description: 'Watch anime online in high quality with English subtitles and dubbing. Features a clean interface and vast library of titles.',
    primaryColor: Color(0xFF4186F5),
    backgroundColor: Color(0xFF16181D),
    icon: Icons.play_circle_filled,
  );

  static const miruro = AnimeSite(
    name: 'Miruro',
    url: 'https://www.miruro.tv/',
    description: 'Free anime streaming site with a vast library of content. Enjoy anime without interruptions in HD quality.',
    primaryColor: Color(0xFFF42A5D),
    backgroundColor: Color(0xFF1A1A1A),
    icon: Icons.live_tv,
  );

  static const List<AnimeSite> allSites = [
    hianime,
    miruro,
  ];
} 