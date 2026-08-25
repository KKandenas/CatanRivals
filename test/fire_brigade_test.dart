import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Brandkår (regelhäftet: "Brandkåren skyddar alla byggnader ...
/// i den stad där Brandkåren är placerad ... mot Pyromanen") – se
/// GameNotifier._cityHasFireBrigade/_attackCardCardQualifiesAt.
void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfTurmoil});
    notifier.state = container.read(gameProvider).copyWith(diceRolled: true);
    return container;
  }

  void giveHedgeTavern(ProviderContainer container) {
    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.hedgeTavern));
  }

  void giveTraitorlessArsonist(ProviderContainer container) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state = container
        .read(gameProvider)
        .copyWith(you: container.read(gameProvider).you.copyWith(
            hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.arsonist]));
  }

  test(
      'en byggnad i en stad med Brandkår kan inte väljas av Pyroman, ingen väntande flagga sätts om det är det enda målet',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveHedgeTavern(container);
    giveTraitorlessArsonist(container);
    final opponentBoard = container.read(gameProvider).opponent.principality;
    // Samma stad (kolumn 2): Brandkår ovanför, en vanlig byggnad nedanför
    // – Brandkåren ska skydda BÅDA (inklusive sig själv, men den räknas
    // ändå aldrig som ett giltigt Pyroman-mål eftersom den är en
    // stadsutbyggnad, inte ExpansionKind.building, se
    // _attackCardCardQualifiesAt-doc).
    opponentBoard.placeExpansion(
        2, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.fireBrigade));
    opponentBoard.placeExpansion(
        2, BuildingRow.below, 0, const PlacedCard(card: EraOfTurmoilCards.drillGround));

    expect(notifier.useArsonist(), isNull);
    expect(container.read(gameProvider).pendingAttackCard, isNull,
        reason: 'den enda byggnaden är skyddad av Brandkår, så inget mål finns');
  });

  test(
      'en byggnad i en ANNAN stad (utan Brandkår) kan fortfarande väljas',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveHedgeTavern(container);
    giveTraitorlessArsonist(container);
    final opponentBoard = container.read(gameProvider).opponent.principality;
    opponentBoard.placeExpansion(
        2, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.fireBrigade));
    opponentBoard.placeExpansion(
        2, BuildingRow.below, 0, const PlacedCard(card: EraOfTurmoilCards.drillGround));
    // Byggnad i en annan stad (kolumn 0), utan egen Brandkår.
    opponentBoard.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.abbey));

    expect(notifier.useArsonist(), isNull);
    expect(container.read(gameProvider).pendingAttackCard, AttackCardKind.arsonist);
  });

  test(
      'selectAttackCardUnit avvisar den skyddade byggnaden med ett tydligt fel',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveHedgeTavern(container);
    giveTraitorlessArsonist(container);
    final opponentBoard = container.read(gameProvider).opponent.principality;
    opponentBoard.placeExpansion(
        2, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.fireBrigade));
    opponentBoard.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.abbey));
    // "you" (den drabbade sidans egna klient, se attack_cards_test.dart-
    // kommentaren) har samma uppställning: skyddad byggnad i kolumn 2,
    // oskyddad i kolumn 0.
    final youBoard = container.read(gameProvider).you.principality;
    youBoard.placeExpansion(
        2, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.fireBrigade));
    youBoard.placeExpansion(
        2, BuildingRow.below, 0, const PlacedCard(card: EraOfTurmoilCards.drillGround));

    notifier.useArsonist();
    expect(container.read(gameProvider).pendingAttackCard, AttackCardKind.arsonist);

    final protectedError =
        notifier.selectAttackCardUnit(2, BuildingRow.below, 0);
    expect(protectedError, 'Den byggnaden är skyddad av en Brandkår.');
  });
}
