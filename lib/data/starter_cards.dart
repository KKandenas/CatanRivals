import '../models/models.dart';

/// De kortdefinitioner och den startuppställning som beskrivs i
/// regelhäftets introduktionsspel ("The First Catanians", s. 2–5):
/// 6 regioner, 2 byar och 1 väg som bildar spelarens rike vid start.
///
/// Detta är exempeldata för att visa hur [GameCard] och [RealmBoard]
/// används tillsammans – inte den fullständiga kortkatalogen (180 kort).
class StarterCards {
  StarterCards._();

  static const forest = GameCard(
    id: 'region-forest',
    name: 'Skog',
    category: CardCategory.region,
    resource: ResourceType.lumber,
    imageAsset: 'assets/images/cards/region_forest.png',
  );

  static const pasture = GameCard(
    id: 'region-pasture',
    name: 'Betesmark',
    category: CardCategory.region,
    resource: ResourceType.wool,
    imageAsset: 'assets/images/cards/region_pasture.png',
  );

  static const fields = GameCard(
    id: 'region-fields',
    name: 'Åker',
    category: CardCategory.region,
    resource: ResourceType.grain,
    imageAsset: 'assets/images/cards/region_fields.png',
  );

  static const hills = GameCard(
    id: 'region-hills',
    name: 'Kulle',
    category: CardCategory.region,
    resource: ResourceType.brick,
    imageAsset: 'assets/images/cards/region_hills.png',
  );

  static const mountains = GameCard(
    id: 'region-mountains',
    name: 'Berg',
    category: CardCategory.region,
    resource: ResourceType.ore,
    imageAsset: 'assets/images/cards/region_mountains.png',
  );

  static const goldField = GameCard(
    id: 'region-gold-field',
    name: 'Guldfält',
    category: CardCategory.region,
    resource: ResourceType.gold,
    imageAsset: 'assets/images/cards/region_gold_field.png',
  );

  static const settlement = GameCard(
    id: 'settlement',
    name: 'By',
    category: CardCategory.settlement,
    victoryPoints: 1,
    imageAsset: 'assets/images/cards/settlement.png',
  );

  static const city = GameCard(
    id: 'city',
    name: 'Stad',
    category: CardCategory.city,
    victoryPoints: 2,
    buildingCost: {ResourceType.ore: 3, ResourceType.grain: 2},
    imageAsset: 'assets/images/cards/city.png',
  );

  static const road = GameCard(
    id: 'road',
    name: 'Väg',
    category: CardCategory.road,
    buildingCost: {ResourceType.brick: 2, ResourceType.lumber: 1},
    imageAsset: 'assets/images/cards/road.png',
  );

  /// Bygger startuppställningen ur regelhäftet: 2 byar (kolumn 0 och 2)
  /// förbundna av 1 väg (kolumn 1), med de 6 regionerna fördelade på
  /// knutpunkterna -1, 1 och 3 (ovanför/nedanför).
  static RealmBoard buildStartingPrincipality(String ownerId) {
    final board = RealmBoard(ownerId: ownerId);

    board.placeSettlement(0, const PlacedCard(card: settlement));
    board.placeSettlement(2, const PlacedCard(card: settlement));
    board.placeRoad(1, const PlacedCard(card: road));

    board.placeRegion(-1, BuildingRow.above, const PlacedCard(card: forest));
    board.placeRegion(-1, BuildingRow.below, const PlacedCard(card: pasture));
    board.placeRegion(1, BuildingRow.above, const PlacedCard(card: goldField));
    board.placeRegion(1, BuildingRow.below, const PlacedCard(card: hills));
    board.placeRegion(3, BuildingRow.above, const PlacedCard(card: fields));
    board.placeRegion(3, BuildingRow.below, const PlacedCard(card: mountains));

    return board;
  }
}
