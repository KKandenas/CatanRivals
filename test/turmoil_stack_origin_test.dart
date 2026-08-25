import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Motsvarigheten till gold_stack_origin_test.dart, för Oroligheternas
/// tid – bekräftar att GameNotifier._checkStackMatchesCardOrigin (se
/// _isThemeCard/_isThemeStackIndex) känner igen "-turmoil-draw-"-
/// suffixet lika väl som "-gold-draw-", och inte längre (felaktigt)
/// avvisar ett Oroligheternas tid-kort mot sina EGNA högar (rapporterad
/// bugg under utvecklingen: den gamla, Gulderan-hårdkodade koden trodde
/// index 3/4 alltid var Gulderans högar, oavsett vilket tema som
/// faktiskt var aktivt).
void main() {
  ProviderContainer buildTurmoilContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfTurmoil});
    notifier.rollProductionDie();
    return container;
  }

  // I det aktiva draghögs-upplägget (3 grundspel + 2 Oroligheternas tid)
  // är index 0-2 grundspelet, 3-4 Oroligheternas tid.
  const basicCard = BasicSetCards.storehouse;

  test(
      'discardHandCard: grundspelskort avvisas mot en Oroligheternas tid-hög, går bra mot en grundspelshög',
      () {
    final container = buildTurmoilContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(
      handAdjustmentPhase: HandAdjustmentPhase.discarding,
      you: state.you.copyWith(hand: [...state.you.hand, basicCard]),
    );

    final wrongError =
        notifier.discardHandCard(basicCard, 3); // Oroligheternas tid-hög
    expect(wrongError, isNotNull);
    expect(wrongError, contains('grundspelets högar'));
    expect(container.read(gameProvider).you.hand.contains(basicCard), isTrue);

    final okError = notifier.discardHandCard(basicCard, 0); // grundspelshög
    expect(okError, isNull);
    expect(container.read(gameProvider).you.hand.contains(basicCard), isFalse);
  });

  test(
      'discardHandCard: Oroligheternas tid-kort avvisas mot en grundspelshög, går bra mot en Oroligheternas tid-hög',
      () {
    final container = buildTurmoilContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final card = basicCard.copyWith(id: '${basicCard.id}-turmoil-draw-0');
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(
      handAdjustmentPhase: HandAdjustmentPhase.discarding,
      you: state.you.copyWith(hand: [...state.you.hand, card]),
    );

    final wrongError = notifier.discardHandCard(card, 0); // grundspelshög
    expect(wrongError, isNotNull);
    expect(wrongError, contains('Oroligheternas tids högar'));
    expect(container.read(gameProvider).you.hand.contains(card), isTrue);

    final okError =
        notifier.discardHandCard(card, 4); // Oroligheternas tid-hög
    expect(okError, isNull);
    expect(container.read(gameProvider).you.hand.contains(card), isFalse);
  });

  test('exchangeDiscard: samma matchning krävs som discardHandCard', () {
    final container = buildTurmoilContainer();
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
}
