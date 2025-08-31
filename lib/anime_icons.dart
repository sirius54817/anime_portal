import 'package:flutter/widgets.dart';

/// Custom icons for the anime portal app
class AnimeIcons {
  static const IconData anime = IconData(
    0xe800,
    fontFamily: 'AnimeIcons',
  );
  
  static const IconData stream = IconData(
    0xe801,
    fontFamily: 'AnimeIcons',
  );
  
  // Alternative icon if custom font isn't available
  static const IconData animeFallback = IconData(0xf008, fontFamily: 'MaterialIcons');
  static const IconData streamFallback = IconData(0xf04b, fontFamily: 'MaterialIcons');
} 