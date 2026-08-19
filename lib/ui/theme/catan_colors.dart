import 'package:flutter/material.dart';

import '../../models/models.dart';

/// Färgpalett för Catan Duellen-brädet. Håller resurs-/pergamentfärger
/// på ett ställe så att widgets inte hårdkodar hex-koder var för sig.
class CatanColors {
  CatanColors._();

  static const parchment = Color(0xFFEFE3C8);
  static const parchmentDark = Color(0xFFDFCFA6);
  static const woodFrame = Color(0xFF6B4A30);
  static const woodFrameDark = Color(0xFF4A3220);
  static const ink = Color(0xFF3B2E22);
  static const inkSoft = Color(0xFF6B5C47);

  static const buildingSiteBorder = Color(0xFFB3A27C);

  static const Map<ResourceType, Color> resource = {
    ResourceType.lumber: Color(0xFF4F6F45),
    ResourceType.brick: Color(0xFFA84A2A),
    ResourceType.ore: Color(0xFF6E7378),
    ResourceType.grain: Color(0xFFD3A038),
    ResourceType.wool: Color(0xFF8FBF7A),
    ResourceType.gold: Color(0xFFC79A3D),
    ResourceType.none: Color(0xFF9B8F78),
  };

  static const Map<ResourceType, IconData> resourceIcon = {
    ResourceType.lumber: Icons.park,
    ResourceType.brick: Icons.landscape,
    ResourceType.ore: Icons.terrain,
    ResourceType.grain: Icons.grass,
    ResourceType.wool: Icons.cloud,
    ResourceType.gold: Icons.circle,
    ResourceType.none: Icons.help_outline,
  };

  static Color resourceColor(ResourceType type) => resource[type] ?? inkSoft;

  static IconData iconFor(ResourceType type) => resourceIcon[type] ?? Icons.help_outline;
}
