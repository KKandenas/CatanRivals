import '../../models/models.dart';

/// Sökvägar till den grafik som används i UI:t – landskapsfoton per
/// resurstyp, kortbaks-/stapelikoner för center-korten, och foton för
/// väg/by/stad. Separat från [CatanColors] eftersom det här är
/// bildtillgångar, inte färger.
class CatanAssets {
  CatanAssets._();

  static const String _resources = 'assets/images/cards/resources';
  static const String _backs = 'assets/images/cards/backs';
  static const String _locations = 'assets/images/cards/locations';
  static const String _icons = 'assets/images/cards/icons';
  static const String _ui = 'assets/images/ui';

  static const String lobbyBackground = '$_ui/lobby_background.png';
  static const String boardBackground = '$_ui/board_background.png';

  /// Landskapsfoto för en resurstyp, t.ex. ResourceType.wool -> wool.png.
  static String resourcePhoto(ResourceType type) => '$_resources/${type.name}.png';

  static const String road = '$_locations/road_forest_path.png';
  static const String settlement = '$_locations/settlement_village.png';
  static const String city = '$_locations/city_walled_river.png';

  static const String backSettlements = '$_backs/settlements.png';
  static const String backCities = '$_backs/cities.png';
  static const String backRegions = '$_backs/regions.png';
  static const String backEvent = '$_backs/event.png';
  static const String backBasicSet = '$_backs/basic_set.png';
  static const String backEraGold = '$_backs/era_gold.png';
  static const String backEraTurmoil = '$_backs/era_turmoil.png';
  static const String backEraProgress = '$_backs/era_progress.png';

  /// Liten kostnadsikon (hexagon) för en resurstyp – för att visa
  /// byggkostnad kompakt på hand-/stapelkort.
  static String resourceCostIcon(ResourceType type) => '$_icons/icon_${type.name}.png';

  static const String pointStrength = '$_icons/icon_strength.png';
  static const String pointCommerce = '$_icons/icon_commerce.png';
  static const String pointSkill = '$_icons/icon_skill.png';
  static const String pointProgress = '$_icons/icon_progress.png';
}
