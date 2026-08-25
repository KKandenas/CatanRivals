import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar GameNotifier-integrationen av "Duel of the Princes"-läget
/// (alla tre temaseten samtidigt, se DuelOfThePrincesSetup-klassdoc):
/// segervillkoret, de 6 draghögarna, avsaknaden av ansikte-upp-kort, och
/// att kort bara går att lägga tillbaka i RÄTT temasets egen hög (se
/// GameNotifier._checkStackMatchesCardOrigin) – samma sorts kontroll
/// som gold_stack_origin_test.dart, men nu med tre samtidiga teman i
/// stället för ett.
void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {
      ExpansionSet.eraOfGold,
      ExpansionSet.eraOfTurmoil,
      ExpansionSet.eraOfProgress,
    });
    notifier.rollProductionDie();
    return container;
  }

  test('victoryPointTarget är 13, inte 12', () {
    final container = buildContainer();
    addTearDown(container.dispose);

    expect(container.read(gameProvider).victoryPointTarget, 13);
  });

  test('6 draghögar: 3 grundspel (12 vardera) + Gulderan (12) + Oroligheternas tid (12) + Utvecklingens tid (14)',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    expect(notifier.drawStack(0), hasLength(lessThanOrEqualTo(12)));
    for (var i = 0; i < 3; i++) {
      expect(container.read(gameProvider).initialDrawStackSizes[i], 12);
    }
    expect(container.read(gameProvider).initialDrawStackSizes,
        [12, 12, 12, 12, 12, 14]);
    // Starthänderna dras redan (3 kort vardera) från hög 0/1.
    expect(container.read(gameProvider).centerStacks['draw1'], 9);
    expect(container.read(gameProvider).centerStacks['draw2'], 9);
    expect(container.read(gameProvider).centerStacks['draw3'], 12);
    expect(container.read(gameProvider).centerStacks['draw4'], 12,
        reason: 'Gulderans egen hög');
    expect(container.read(gameProvider).centerStacks['draw5'], 12,
        reason: 'Oroligheternas tids egen hög');
    expect(container.read(gameProvider).centerStacks['draw6'], 14,
        reason: 'Utvecklingens tids egen hög');
  });

  test('inga ansikte-upp-kort – varken Köpmansgille, Värdshus eller Universitet',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);

    final state = container.read(gameProvider);
    expect(state.you.faceUpExpansionCard, isNull);
    expect(state.opponent.faceUpExpansionCard, isNull);
  });

  test('händelsekortsstapeln har 12 kort (11 + Jul)', () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    expect(notifier.eventDeck.length, 12);
  });

  group('_checkStackMatchesCardOrigin: varje temaset har sin EGEN hög (3/4/5)', () {
    const basicCard = BasicSetCards.storehouse;

    test('grundspelskort avvisas mot alla tre temahögar, går bra mot en grundspelshög', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      notifier.state = state.copyWith(
        handAdjustmentPhase: HandAdjustmentPhase.discarding,
        you: state.you.copyWith(hand: [...state.you.hand, basicCard]),
      );

      expect(notifier.discardHandCard(basicCard, 3), isNotNull);
      expect(notifier.discardHandCard(basicCard, 4), isNotNull);
      expect(notifier.discardHandCard(basicCard, 5), isNotNull);
      expect(container.read(gameProvider).you.hand.contains(basicCard), isTrue);

      expect(notifier.discardHandCard(basicCard, 1), isNull);
      expect(container.read(gameProvider).you.hand.contains(basicCard), isFalse);
    });

    test('ett Gulderan-kort går bara till hög 3, inte 4/5 eller en grundspelshög', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final card = basicCard.copyWith(id: '${basicCard.id}-gold-draw-0');
      final state = container.read(gameProvider);
      notifier.state = state.copyWith(
        handAdjustmentPhase: HandAdjustmentPhase.discarding,
        you: state.you.copyWith(hand: [...state.you.hand, card]),
      );

      expect(notifier.discardHandCard(card, 0), isNotNull);
      expect(notifier.discardHandCard(card, 4), isNotNull);
      expect(notifier.discardHandCard(card, 5), isNotNull);
      expect(container.read(gameProvider).you.hand.contains(card), isTrue);

      expect(notifier.discardHandCard(card, 3), isNull);
      expect(container.read(gameProvider).you.hand.contains(card), isFalse);
    });

    test('ett Oroligheternas tid-kort går bara till hög 4, inte 3/5 eller en grundspelshög', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final card = basicCard.copyWith(id: '${basicCard.id}-turmoil-draw-0');
      final state = container.read(gameProvider);
      notifier.state = state.copyWith(
        handAdjustmentPhase: HandAdjustmentPhase.discarding,
        you: state.you.copyWith(hand: [...state.you.hand, card]),
      );

      expect(notifier.discardHandCard(card, 2), isNotNull);
      expect(notifier.discardHandCard(card, 3), isNotNull);
      expect(notifier.discardHandCard(card, 5), isNotNull);
      expect(container.read(gameProvider).you.hand.contains(card), isTrue);

      expect(notifier.discardHandCard(card, 4), isNull);
      expect(container.read(gameProvider).you.hand.contains(card), isFalse);
    });

    test('ett Utvecklingens tid-kort går bara till hög 5, inte 3/4 eller en grundspelshög', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final card = basicCard.copyWith(id: '${basicCard.id}-progress-draw-0');
      final state = container.read(gameProvider);
      notifier.state = state.copyWith(
        handAdjustmentPhase: HandAdjustmentPhase.discarding,
        you: state.you.copyWith(hand: [...state.you.hand, card]),
      );

      expect(notifier.discardHandCard(card, 0), isNotNull);
      expect(notifier.discardHandCard(card, 3), isNotNull);
      expect(notifier.discardHandCard(card, 4), isNotNull);
      expect(container.read(gameProvider).you.hand.contains(card), isTrue);

      expect(notifier.discardHandCard(card, 5), isNull);
      expect(container.read(gameProvider).you.hand.contains(card), isFalse);
    });
  });
}
