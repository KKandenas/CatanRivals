import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/build_requirements.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar den delade, rena kravkontrollen `buildRequirementBlockedReason`
/// (se lib/state/build_requirements.dart) – kollas både i UI:t
/// (PrincipalityGrid/BuildConfirmCard) och som ett sista skydd i
/// GameNotifier.dropExpansion/dropRegionExpansion.
void main() {
  test('cityExpansion på en vanlig by avvisas', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));

    final reason = buildRequirementBlockedReason(
        EraOfGoldCards.merchantGuild, board, 0, BuildingRow.above);

    expect(reason, 'Köpmansgille kräver en stad, inte bara en by.');
  });

  test('cityExpansion på en stad godkänns', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));

    final reason = buildRequirementBlockedReason(
        EraOfGoldCards.merchantGuild, board, 0, BuildingRow.above);

    expect(reason, isNull);
  });

  test('cityExpansion på en plats utan by/stad avvisas', () {
    final board = RealmBoard(ownerId: 'you');

    final reason = buildRequirementBlockedReason(
        EraOfGoldCards.merchantGuild, board, 5, BuildingRow.above);

    expect(reason, 'Köpmansgille kräver en stad, inte bara en by.');
  });

  test('Guldgömma utan utplacerad hjälte avvisas', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeRegion(
        1, BuildingRow.above, const PlacedCard(card: BasicSetCards.goldField));

    final reason = buildRequirementBlockedReason(
        EraOfGoldCards.goldCache, board, 1, BuildingRow.above);

    expect(reason,
        'Guldgömma kräver att du spelat ut en hjälte med minst 1 styrkepoäng.');
  });

  test('Guldgömma med en utplacerad hjälte (strengthPoints > 0) godkänns', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeRegion(
        1, BuildingRow.above, const PlacedCard(card: BasicSetCards.goldField));
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.harald));

    final reason = buildRequirementBlockedReason(
        EraOfGoldCards.goldCache, board, 1, BuildingRow.above);

    expect(reason, isNull);
  });

  test('en hjälte med 0 styrkepoäng räcker inte för Guldgömma', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeRegion(
        1, BuildingRow.above, const PlacedCard(card: BasicSetCards.goldField));
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.placeExpansion(0, BuildingRow.above, 0,
        PlacedCard(card: BasicSetCards.harald.copyWith(strengthPoints: 0)));

    final reason = buildRequirementBlockedReason(
        EraOfGoldCards.goldCache, board, 1, BuildingRow.above);

    expect(reason, isNotNull);
  });

  test('Stapelhus utan Köpmansgille avvisas', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));

    final reason = buildRequirementBlockedReason(
        EraOfGoldCards.stapleHouse, board, 0, BuildingRow.above);

    expect(reason, 'Stapelhus kräver Köpmansgille i ditt rike.');
  });

  test('Stapelhus med Köpmansgille utplacerat godkänns', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfGoldCards.merchantGuild));

    final reason = buildRequirementBlockedReason(
        EraOfGoldCards.stapleHouse, board, 0, BuildingRow.above);

    expect(reason, isNull);
  });

  test('Universitet utan Kloster eller Bibliotek avvisas', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.university, board, 0, BuildingRow.above);

    expect(reason, 'Universitet kräver Kloster eller Bibliotek i ditt rike.');
  });

  test('Universitet med Kloster utplacerat godkänns', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(
        0, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.university, board, 0, BuildingRow.above);

    expect(reason, isNull);
  });

  test('Universitet med Bibliotek utplacerat godkänns', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(0, BuildingRow.below, 0,
        const PlacedCard(card: EraOfProgressCards.library));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.university, board, 0, BuildingRow.above);

    expect(reason, isNull);
  });

  test('Kanonmästare utan Universitet avvisas', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.chiefCannoneer, board, 0, BuildingRow.above);

    expect(reason, 'Kanonmästare kräver Universitet i ditt rike.');
  });

  test('Kanonmästare med Universitet utplacerat godkänns', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(0, BuildingRow.above, 0,
        const PlacedCard(card: EraOfProgressCards.university));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.chiefCannoneer, board, 0, BuildingRow.below);

    expect(reason, isNull);
  });

  test('Byggkran utan Universitet avvisas', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.buildingCrane, board, 0, BuildingRow.above);

    expect(reason, 'Byggkran kräver Universitet i ditt rike.');
  });

  test('Parlament kräver minst 2 framstegspoäng: avvisas utan det', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(
        0,
        BuildingRow.above,
        0,
        PlacedCard(card: BasicSetCards.storehouse.copyWith(progressPoints: 1)));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.parliament, board, 0, BuildingRow.below);

    expect(reason, 'Parlament kräver minst 2 framstegspoäng i ditt rike.');
  });

  test('Parlament med 2 framstegspoäng godkänns', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
    board.placeSettlement(2, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(
        0,
        BuildingRow.above,
        0,
        PlacedCard(card: BasicSetCards.storehouse.copyWith(progressPoints: 1)));
    board.placeExpansion(
        2,
        BuildingRow.above,
        0,
        PlacedCard(card: BasicSetCards.abbey.copyWith(progressPoints: 1)));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.parliament, board, 0, BuildingRow.below);

    expect(reason, isNull);
  });

  test('Rådhus på en tom plats avvisas, även om Församlingshus finns i riket',
      () {
    // Rapporterad bugg: Rådhus gick tidigare att bygga på VILKEN SOM
    // HELST plats i riket bara Församlingshus fanns någonstans – inte
    // bara direkt ovanpå det, som regelhäftet/korttexten kräver.
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(0, BuildingRow.above, 0,
        const PlacedCard(card: BasicSetCards.parishHall));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.townHall, board, 0, BuildingRow.below);

    expect(reason, 'Rådhus måste läggas ovanpå ditt Församlingshus.');
  });

  test(
      'Rådhus ovanpå ett annat kort (inte Församlingshus) avvisas, även om Församlingshus finns i riket',
      () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(0, BuildingRow.above, 0,
        const PlacedCard(card: BasicSetCards.parishHall));
    board.placeExpansion(
        0, BuildingRow.above, 1, const PlacedCard(card: BasicSetCards.abbey));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.townHall, board, 0, BuildingRow.above, 1);

    expect(reason, 'Rådhus måste läggas ovanpå ditt Församlingshus.');
  });

  test('Rådhus utan Församlingshus alls i riket avvisas', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.townHall, board, 0, BuildingRow.above);

    expect(reason, 'Rådhus måste läggas ovanpå ditt Församlingshus.');
  });

  test('Rådhus direkt ovanpå Församlingshus (rätt plats) godkänns', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(0, BuildingRow.above, 0,
        const PlacedCard(card: BasicSetCards.parishHall));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.townHall, board, 0, BuildingRow.above);

    expect(reason, isNull);
  });

  test(
      'Rådhus direkt ovanpå Församlingshus på den andra stadsplatsen (slotIndex 1) godkänns',
      () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    board.placeExpansion(0, BuildingRow.above, 1,
        const PlacedCard(card: BasicSetCards.parishHall));

    final reason = buildRequirementBlockedReason(
        EraOfProgressCards.townHall, board, 0, BuildingRow.above, 1);

    expect(reason, isNull);
  });

  test('vanliga byggkort utan särskilt krav godkänns alltid', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));

    final reason = buildRequirementBlockedReason(
        BasicSetCards.storehouse, board, 0, BuildingRow.above);

    expect(reason, isNull);
  });
}
