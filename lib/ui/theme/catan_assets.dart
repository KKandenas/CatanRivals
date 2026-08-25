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
  static const String _dice = 'assets/images/dice';

  static const String lobbyBackground = '$_ui/lobby_background.webp';
  static const String boardBackground = '$_ui/board_background.webp';

  /// Händelsetärningens sex sidor (se [EventDieFace]) – de fem
  /// symbolerna från regelhäftets referenskort.
  static const String eventDieBrigandAttack =
      '$_dice/event_brigand_attack.jpg';
  static const String eventDieTrade = '$_dice/event_trade.jpg';
  static const String eventDieCelebration = '$_dice/event_celebration.jpg';
  static const String eventDiePlentifulHarvest =
      '$_dice/event_plentiful_harvest.jpg';
  static const String eventDieEventCard = '$_dice/event_card.jpg';

  /// Landskapsfoto för en resurstyp, t.ex. ResourceType.wool -> wool.webp.
  static String resourcePhoto(ResourceType type) =>
      '$_resources/${type.name}.webp';

  static const String road = '$_locations/road_forest_path.webp';
  static const String settlement = '$_locations/settlement_village.webp';
  static const String city = '$_locations/city_walled_river.webp';

  static const String backSettlements = '$_backs/settlements.webp';
  static const String backCities = '$_backs/cities.webp';
  static const String backRegions = '$_backs/regions.webp';
  static const String backEvent = '$_backs/event.webp';

  /// Draghögarnas kortbaksidor, EN källa till sanning som används både
  /// i själva spelet (se [CenterStacksStrip]) och som omslagsbild för
  /// temavalet i lobbyn (se [LobbyScreen]) – exakt samma bild på båda
  /// ställena, så att lobbyns val syns igen i den faktiska draghögen.
  static const String backBasicSet = '$_backs/basic_set.webp';
  static const String backEraGold = '$_backs/era_gold.webp';
  static const String backEraTurmoil = '$_backs/era_turmoil.webp';
  static const String backEraProgress = '$_backs/era_progress.webp';

  /// Liten kostnadsikon (hexagon) för en resurstyp – för att visa
  /// byggkostnad kompakt på hand-/stapelkort.
  static String resourceCostIcon(ResourceType type) =>
      '$_icons/icon_${type.name}.webp';

  static const String pointStrength = '$_icons/icon_strength.webp';
  static const String pointCommerce = '$_icons/icon_commerce.webp';
  static const String pointSkill = '$_icons/icon_skill.webp';
  static const String pointProgress = '$_icons/icon_progress.webp';
  static const String pointVictory = '$_icons/icon_victory.webp';

  /// Symboliserar "Hero Token"/"Trade Token" – de fysiska brickorna som
  /// visar vem som just nu har flest styrke- respektive handelspoäng
  /// (minst 3, och fler än motståndaren, se
  /// [GameNotifier.recomputeTokenHolders]). Ligger inte hos någon
  /// ("banken") när ingen uppfyller kravet.
  static const String heroToken = '$_icons/icon_hero_token.webp';
  static const String tradeToken = '$_icons/icon_trade_token.webp';

  /// Rätt bild för ett kort oavsett kategori. Regionkort och by/stad/
  /// väg-korten visas med en annan bild än [GameCard.imageAsset] (som
  /// är kvarlevor från innan den riktiga bildmappningen fanns) – den
  /// här metoden är den enda källan till sanning för vilken bild som
  /// faktiskt hör till ett kort, så att alla vyer (bräde, detaljruta,
  /// bekräftelseruta) visar exakt samma bild.
  static String resolveCardImage(GameCard card) {
    switch (card.category) {
      case CardCategory.region:
        return resourcePhoto(card.resource);
      case CardCategory.settlement:
        return settlement;
      case CardCategory.city:
        return city;
      case CardCategory.road:
        return road;
      default:
        return card.imageAsset;
    }
  }
}
