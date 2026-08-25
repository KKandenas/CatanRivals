import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Vakttorn ("När motståndaren spelar Bågskytt, Pyroman eller
/// Förrädare, slå tärningen. Slår du 1 eller 2 har kortet ingen
/// effekt") och Heinrich väktaren ("Har du även ett Vakttorn ... är du
/// skyddad när 1, 2, 3, 4 eller 5 slås ... Bara Heinrich har ingen
/// påverkan") – se GameNotifier.rollLookoutTowerDefense/
/// pendingDefenseRollCard-doc. Tärningsslaget är slumpat, så testerna
/// kör flera varv i stället för att bero på ett enda utfall.
void main() {
  const heroUnit = EraOfTurmoilCards.carlForkbeard;

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

  void giveArcher(ProviderContainer container) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state = container
        .read(gameProvider)
        .copyWith(you: container.read(gameProvider).you.copyWith(
            hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.archer]));
  }

  test(
      'motståndaren har Vakttorn: Bågskytt gatas bakom ett försvarsslag i stället för att verka direkt',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveHedgeTavern(container);
    giveArcher(container);
    final opponentBoard = container.read(gameProvider).opponent.principality;
    opponentBoard.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.lookoutTower));
    opponentBoard.placeExpansion(2, BuildingRow.above, 0, const PlacedCard(card: heroUnit));

    expect(notifier.useArcher(), isNull);
    final state = container.read(gameProvider);
    expect(state.pendingDefenseRollCard, EraOfTurmoilCards.archer.id);
    expect(state.pendingAttackCard, isNull,
        reason: 'väntar på försvarsslaget innan attacken verkar');
  });

  test(
      'motståndaren SAKNAR Vakttorn: Bågskytt verkar direkt precis som förut',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveHedgeTavern(container);
    giveArcher(container);
    container.read(gameProvider).opponent.principality.placeExpansion(
        2, BuildingRow.above, 0, const PlacedCard(card: heroUnit));

    expect(notifier.useArcher(), isNull);
    final state = container.read(gameProvider);
    expect(state.pendingDefenseRollCard, isNull);
    expect(state.pendingAttackCard, AttackCardKind.archer);
  });

  test('rollLookoutTowerDefense är no-op utan ett väntande försvarsslag', () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    expect(notifier.rollLookoutTowerDefense(), isNull);
  });

  test(
      'bara Vakttorn: slaget avgör om Bågskytt aktiveras eller inte – aldrig något annat utfall',
      () {
    // Kör flera varv (slumpat tärningsslag): varje gång ska EXAKT ETT av
    // de två utfallen (skyddad ELLER pendingAttackCard aktiverad) ha
    // inträffat, aldrig något tredje.
    for (var i = 0; i < 30; i++) {
      final container = buildContainer();
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      giveArcher(container);
      final opponentBoard = container.read(gameProvider).opponent.principality;
      opponentBoard.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.lookoutTower));
      opponentBoard.placeExpansion(2, BuildingRow.above, 0, const PlacedCard(card: heroUnit));
      notifier.useArcher();

      final message = notifier.rollLookoutTowerDefense();
      expect(message, isNotNull);
      final state = container.read(gameProvider);
      expect(state.pendingDefenseRollCard, isNull,
          reason: 'försvarsslaget ska alltid rensas efter slaget');
      final protected = state.pendingAttackCard == null;
      expect(message!.contains('Inte skyddad'), !protected,
          reason: 'meddelandet ska stämma överens med det faktiska utfallet');

      container.dispose();
    }
  });

  test(
      'Vakttorn + Heinrich: bara en 6 tar sig igenom (kör många varv för att se båda utfallen)',
      () {
    var sawProtected = false;
    var sawThrough = false;
    for (var i = 0; i < 60 && !(sawProtected && sawThrough); i++) {
      final container = buildContainer();
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      giveArcher(container);
      final opponentBoard = container.read(gameProvider).opponent.principality;
      opponentBoard.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.lookoutTower));
      opponentBoard.placeExpansion(
          0, BuildingRow.below, 0,
          const PlacedCard(card: EraOfTurmoilCards.heinrichTheSentinel));
      opponentBoard.placeExpansion(2, BuildingRow.above, 0, const PlacedCard(card: heroUnit));
      notifier.useArcher();

      notifier.rollLookoutTowerDefense();
      final protectedNow = container.read(gameProvider).pendingAttackCard == null;
      if (protectedNow) {
        sawProtected = true;
      } else {
        sawThrough = true;
      }
      container.dispose();
    }
    expect(sawProtected, isTrue,
        reason: 'med Heinrich ska 1-5 nästan alltid ge skydd inom 60 varv');
    expect(sawThrough, isTrue,
        reason: 'en 6 ska fortfarande kunna ta sig igenom inom 60 varv');
  });

  test(
      'bara Heinrich (utan Vakttorn) har ingen påverkan: Bågskytt verkar direkt',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveHedgeTavern(container);
    giveArcher(container);
    final opponentBoard = container.read(gameProvider).opponent.principality;
    opponentBoard.placeExpansion(
        0, BuildingRow.above, 0,
        const PlacedCard(card: EraOfTurmoilCards.heinrichTheSentinel));
    opponentBoard.placeExpansion(2, BuildingRow.above, 0, const PlacedCard(card: heroUnit));

    expect(notifier.useArcher(), isNull);
    final state = container.read(gameProvider);
    expect(state.pendingDefenseRollCard, isNull);
    expect(state.pendingAttackCard, AttackCardKind.archer);
  });

  test(
      'Förrädare gatas också bakom Vakttorn (traitorPicking aktiveras bara om slaget inte skyddar)',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveHedgeTavern(container);
    final notifierState = container.read(gameProvider);
    notifier.state = notifierState.copyWith(
        you: notifierState.you
            .copyWith(hand: [...notifierState.you.hand, EraOfTurmoilCards.traitor]));
    final opponentBoard = container.read(gameProvider).opponent.principality;
    opponentBoard.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.lookoutTower));

    expect(notifier.useTraitor(), isNull);
    var state = container.read(gameProvider);
    expect(state.pendingDefenseRollCard, EraOfTurmoilCards.traitor.id);
    expect(state.traitorPicking, isFalse);

    notifier.rollLookoutTowerDefense();
    state = container.read(gameProvider);
    expect(state.pendingDefenseRollCard, isNull,
        reason: 'försvarsslaget ska alltid rensas efter slaget');
  });

  test('_checkCanBuild blockerar inte bygge bara för att ett försvarsslag väntar (det är motståndaren som väntar, inte du)', () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveHedgeTavern(container);
    giveArcher(container);
    final opponentBoard = container.read(gameProvider).opponent.principality;
    opponentBoard.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.lookoutTower));
    opponentBoard.placeExpansion(2, BuildingRow.above, 0, const PlacedCard(card: heroUnit));
    notifier.useArcher();
    expect(container.read(gameProvider).pendingDefenseRollCard, isNotNull);

    final error = notifier.discardActionCard(BasicSetCards.merchantCaravan);
    expect(error, isNull);
  });
}
