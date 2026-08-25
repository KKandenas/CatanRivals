import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
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

  test('vanliga byggkort utan särskilt krav godkänns alltid', () {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));

    final reason = buildRequirementBlockedReason(
        BasicSetCards.storehouse, board, 0, BuildingRow.above);

    expect(reason, isNull);
  });
}
