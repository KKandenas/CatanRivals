import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att grundspelskort bara går att slänga till en av grundspelets
/// draghögar, och Gulderan-kort bara till en av Gulderans egna (se
/// GameNotifier._checkStackMatchesCardOrigin) – oavsett vilken av de
/// fem vägarna en spelare försöker lägga kortet tillbaka på
/// (handjustering, kortbytesfasens gratisbyte/kika, Fejd, Brödrafejd).
void main() {
  ProviderContainer buildGoldContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfGold});
    notifier.rollProductionDie();
    return container;
  }

  // I det aktiva draghögs-upplägget (3 grundspel + 2 Gulderan) är
  // index 0-2 grundspelet, 3-4 Gulderan.
  const basicCard = BasicSetCards.storehouse; // vanligt id, inget suffix
  const goldCard = BasicSetCards.storehouse; // återanvänds nedan med suffix

  test('discardHandCard: grundspelskort avvisas mot en Gulderan-hög, går bra mot en grundspelshög', () {
    final container = buildGoldContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(
      handAdjustmentPhase: HandAdjustmentPhase.discarding,
      you: state.you.copyWith(hand: [...state.you.hand, basicCard]),
    );

    final wrongError = notifier.discardHandCard(basicCard, 3); // Gulderan-hög
    expect(wrongError, isNotNull);
    expect(container.read(gameProvider).you.hand.contains(basicCard), isTrue);

    final okError = notifier.discardHandCard(basicCard, 0); // grundspelshög
    expect(okError, isNull);
    expect(container.read(gameProvider).you.hand.contains(basicCard), isFalse);
  });

  test('discardHandCard: Gulderan-kort avvisas mot en grundspelshög, går bra mot en Gulderan-hög', () {
    final container = buildGoldContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final card = goldCard.copyWith(id: '${goldCard.id}-gold-draw-0');
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(
      handAdjustmentPhase: HandAdjustmentPhase.discarding,
      you: state.you.copyWith(hand: [...state.you.hand, card]),
    );

    final wrongError = notifier.discardHandCard(card, 0); // grundspelshög
    expect(wrongError, isNotNull);
    expect(container.read(gameProvider).you.hand.contains(card), isTrue);

    final okError = notifier.discardHandCard(card, 4); // Gulderan-hög
    expect(okError, isNull);
    expect(container.read(gameProvider).you.hand.contains(card), isFalse);
  });

  test('exchangeDiscard: samma matchning krävs som discardHandCard', () {
    final container = buildGoldContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(
      tradePhase: TradePhase.exchangeDiscard,
      you: state.you.copyWith(hand: [...state.you.hand, basicCard]),
    );

    expect(notifier.exchangeDiscard(basicCard, 4), isNotNull);
    expect(notifier.exchangeDiscard(basicCard, 0), isNull);
  });

  test('peekDiscardCard: samma matchning krävs som discardHandCard', () {
    final container = buildGoldContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(
      tradePhase: TradePhase.peekDiscard,
      you: state.you.copyWith(hand: [...state.you.hand, basicCard]),
    );

    expect(notifier.peekDiscardCard(basicCard, 3), isNotNull);
    expect(notifier.peekDiscardCard(basicCard, 1), isNull);
  });

  test('resolveFeudBuildingRemoval: byggnaden får bara läggas i en hög av samma set, och blir kvar på riket om fel hög väljs', () {
    final container = buildGoldContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    state.you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: basicCard));
    notifier.state = state.copyWith(
      feudBuildingPickActive: true,
      feudPickedBuilding: const RelocationSelection(
          kind: RelocationTargetKind.expansion,
          column: 0,
          row: BuildingRow.above,
          slotIndex: 0),
    );

    final wrongError = notifier.resolveFeudBuildingRemoval(3); // Gulderan-hög
    expect(wrongError, isNotNull);
    expect(
        container
            .read(gameProvider)
            .you
            .principality
            .settlementAt(0)!
            .aboveSites[0]
            ?.card
            .id,
        basicCard.id,
        reason: 'byggnaden ska ligga kvar tills rätt hög väljs');

    final okError = notifier.resolveFeudBuildingRemoval(0); // grundspelshög
    expect(okError, isNull);
    expect(
        container.read(gameProvider).you.principality.settlementAt(0)!.aboveSites[0],
        isNull);
  });

  test('pickFraternalFeudsCard: motståndarens handkort får bara läggas i en hög av samma set', () {
    final container = buildGoldContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(
      fraternalFeudsPicking: true,
      opponent: state.opponent.copyWith(hand: [...state.opponent.hand, basicCard]),
    );

    final wrongError = notifier.pickFraternalFeudsCard(basicCard, 4);
    expect(wrongError, isNotNull);
    expect(container.read(gameProvider).opponent.hand.contains(basicCard), isTrue);

    final okError = notifier.pickFraternalFeudsCard(basicCard, 0);
    expect(okError, isNull);
    expect(container.read(gameProvider).opponent.hand.contains(basicCard), isFalse);
  });
}
