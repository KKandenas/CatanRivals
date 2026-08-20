import '../models/models.dart';
import 'basic_set_cards.dart';

/// Startuppställningen ur regelhäftets introduktionsspel
/// ("The First Catanians", s. 2–5): 6 regioner, 2 byar och 1 väg som
/// bildar spelarens rike vid start.
///
/// De två spelarna använder samma sex regiontyper i samma layout, men
/// med olika tärningstal (regelhäftet s. 4: "the numbers on the regions
/// are distributed differently") – det finns alltså en uppsättning
/// starttal för den röda spelaren (s. 2) och en annan för den blå
/// (s. 4), avlästa direkt från regelhäftets diagram.
///
/// Layouten (samma för båda spelarna): vänster knutpunkt (kolumn -1) =
/// Forest ovanför / Hills nedanför, mittenknutpunkten (kolumn 1, vid
/// vägen) = Gold Field ovanför / Pasture nedanför, höger knutpunkt
/// (kolumn 3) = Fields ovanför / Mountains nedanför.
class StarterCards {
  StarterCards._();

  static const Map<String, int> _redNumbers = {
    'forest': 2,
    'hills': 3,
    'goldField': 1,
    'pasture': 4,
    'fields': 6,
    'mountains': 5,
  };

  static const Map<String, int> _blueNumbers = {
    'forest': 3,
    'hills': 2,
    'goldField': 4,
    'pasture': 1,
    'fields': 5,
    'mountains': 6,
  };

  /// Bygger startuppställningen: 2 byar (kolumn 0 och 2) förbundna av
  /// 1 väg (kolumn 1), med de 6 regionerna fördelade på knutpunkterna
  /// -1, 1 och 3 (ovanför/nedanför). [isRed] väljer vilken spelares
  /// tärningstal som används – regelhäftets röda respektive blå
  /// startkort har samma regiontyper men olika tal.
  static RealmBoard buildStartingPrincipality(String ownerId, {bool isRed = true}) {
    final numbers = isRed ? _redNumbers : _blueNumbers;
    final board = RealmBoard(ownerId: ownerId);

    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.placeSettlement(2, const PlacedCard(card: BasicSetCards.settlement));
    board.placeRoad(1, const PlacedCard(card: BasicSetCards.road));

    // Regelhäftet s. 3: vid start har varje region – utom guldfältet –
    // exakt 1 resurs lagrad (guldfältet börjar tomt, du börjar aldrig
    // med guld).
    board.placeRegion(
      -1,
      BuildingRow.above,
      PlacedCard(
        card: BasicSetCards.forest.copyWith(id: 'region-forest-start', productionNumber: numbers['forest']),
        storedResources: 1,
      ),
    );
    board.placeRegion(
      -1,
      BuildingRow.below,
      PlacedCard(
        card: BasicSetCards.hills.copyWith(id: 'region-hills-start', productionNumber: numbers['hills']),
        storedResources: 1,
      ),
    );
    board.placeRegion(
      1,
      BuildingRow.above,
      PlacedCard(
        card: BasicSetCards.goldField.copyWith(id: 'region-gold-field-start', productionNumber: numbers['goldField']),
      ),
    );
    board.placeRegion(
      1,
      BuildingRow.below,
      PlacedCard(
        card: BasicSetCards.pasture.copyWith(id: 'region-pasture-start', productionNumber: numbers['pasture']),
        storedResources: 1,
      ),
    );
    board.placeRegion(
      3,
      BuildingRow.above,
      PlacedCard(
        card: BasicSetCards.fields.copyWith(id: 'region-fields-start', productionNumber: numbers['fields']),
        storedResources: 1,
      ),
    );
    board.placeRegion(
      3,
      BuildingRow.below,
      PlacedCard(
        card: BasicSetCards.mountains.copyWith(id: 'region-mountains-start', productionNumber: numbers['mountains']),
        storedResources: 1,
      ),
    );

    return board;
  }
}
