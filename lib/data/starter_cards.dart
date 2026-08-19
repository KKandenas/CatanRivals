import '../models/models.dart';
import 'basic_set_cards.dart';

/// Startuppställningen ur regelhäftets introduktionsspel
/// ("The First Catanians", s. 2–5): 6 regioner, 2 byar och 1 väg som
/// bildar spelarens rike vid start.
///
/// Korttyperna kommer från [BasicSetCards]. Varje fysiskt regionkort har
/// ett eget tärningstal tryckt på kortet, så startregionerna görs till
/// egna instanser här (via `copyWith`) med de tal regelhäftet kräver:
/// "each number (1-6) is on exactly one of your 6 regions" (s. 6).
class StarterCards {
  StarterCards._();

  /// Bygger startuppställningen: 2 byar (kolumn 0 och 2) förbundna av
  /// 1 väg (kolumn 1), med de 6 regionerna fördelade på knutpunkterna
  /// -1, 1 och 3 (ovanför/nedanför) och en distinkt siffra 1–6 var.
  static RealmBoard buildStartingPrincipality(String ownerId) {
    final board = RealmBoard(ownerId: ownerId);

    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.placeSettlement(2, const PlacedCard(card: BasicSetCards.settlement));
    board.placeRoad(1, const PlacedCard(card: BasicSetCards.road));

    board.placeRegion(
      -1,
      BuildingRow.above,
      PlacedCard(card: BasicSetCards.forest.copyWith(id: 'region-forest-start', productionNumber: 3)),
    );
    board.placeRegion(
      -1,
      BuildingRow.below,
      PlacedCard(card: BasicSetCards.pasture.copyWith(id: 'region-pasture-start', productionNumber: 5)),
    );
    board.placeRegion(
      1,
      BuildingRow.above,
      PlacedCard(card: BasicSetCards.goldField.copyWith(id: 'region-gold-field-start', productionNumber: 1)),
    );
    board.placeRegion(
      1,
      BuildingRow.below,
      PlacedCard(card: BasicSetCards.hills.copyWith(id: 'region-hills-start', productionNumber: 4)),
    );
    board.placeRegion(
      3,
      BuildingRow.above,
      PlacedCard(card: BasicSetCards.fields.copyWith(id: 'region-fields-start', productionNumber: 6)),
    );
    board.placeRegion(
      3,
      BuildingRow.below,
      PlacedCard(
          card: BasicSetCards.mountains.copyWith(id: 'region-mountains-start', productionNumber: 2)),
    );

    return board;
  }
}
