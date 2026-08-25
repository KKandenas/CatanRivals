import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Utvecklingens tid-uppställningen: 3 grundspels-draghögar à
/// 12 + 2 Utvecklingens tid-draghögar à 12 (i stället för 4 à 9 utan
/// tema), samt ansikte-upp-kortet Universitet – exakt samma mönster
/// som Gulderan/Oroligheternas tid (se era_of_gold_setup_test.dart/
/// era_of_turmoil_setup_test.dart), fast med Universitet i stället för
/// Köpmansgille/Värdshus (se [Player.faceUpExpansionCard]-doc). VARJE
/// spelare har sin EGEN, separata plats med som mest 1 eget kort, inte
/// en delad hög båda kan bygga från. De tre temaseten kombineras
/// aldrig i samma match (se LobbyScreen).
void main() {
  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
  }

  group('uppställning (playLocally)', () {
    test(
        'med Utvecklingens tid: 5 draghögar (3x12, 2x12) och varsitt eget Universitet',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      container
          .read(gameProvider.notifier)
          .playLocally(expansions: {ExpansionSet.eraOfProgress});

      final state = container.read(gameProvider);
      expect(state.you.faceUpExpansionCard?.baseId,
          EraOfProgressCards.university.id);
      expect(state.opponent.faceUpExpansionCard?.baseId,
          EraOfProgressCards.university.id);
      // Två SKILDA fysiska kopior, inte samma kort visat två gånger.
      expect(state.you.faceUpExpansionCard!.id,
          isNot(state.opponent.faceUpExpansionCard!.id));
      expect(state.victoryPointTarget, 12);
      // Starthänderna dras från hög 1/2 (12 vardera), så 12-3=9.
      expect(state.centerStacks['draw1'], 9);
      expect(state.centerStacks['draw2'], 9);
      expect(state.centerStacks['draw3'], 12);
      expect(state.centerStacks['draw4'], 12);
      expect(state.centerStacks['draw5'], 12);
      expect(state.initialDrawStackSizes, [12, 12, 12, 12, 12]);
    });

    test(
        'Utvecklingens tid-kort hamnar bara i de två sista högarna (3-4), aldrig i grundspelets (0-2)',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.playLocally(expansions: {ExpansionSet.eraOfProgress});

      bool isProgressCard(GameCard c) => c.id.contains('-progress-draw-');
      for (var i = 0; i < 3; i++) {
        expect(notifier.drawStack(i).any(isProgressCard), isFalse,
            reason: 'hög $i är en grundspelshög');
      }
      for (var i = 3; i < 5; i++) {
        expect(notifier.drawStack(i).every(isProgressCard), isTrue,
            reason: 'hög $i är en Utvecklingens tid-hög');
      }
    });

    test(
        'händelsekortsstapeln innehåller Utvecklingens tids 5 extra händelsekort',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);

      notifier.playLocally();
      final baseLength = notifier.eventDeck.length;

      notifier.playLocally(expansions: {ExpansionSet.eraOfProgress});
      expect(notifier.eventDeck.length, baseLength + 5);
      final plagueCount = notifier.eventDeck
          .where((c) => c.baseId == EraOfProgressCards.plague.id)
          .length;
      expect(plagueCount, 3);
    });
  });

  group('buyFaceUpExpansion (Universitet)', () {
    late ProviderContainer container;
    late GameNotifier notifier;

    setUp(() {
      container = buildContainer();
      notifier = container.read(gameProvider.notifier);
      notifier.playLocally(expansions: {ExpansionSet.eraOfProgress});
      notifier.rollProductionDie();
      // Universitet kräver en stad (cityExpansion, se
      // build_requirements.dart) OCH Kloster eller Bibliotek utplacerat.
      container.read(gameProvider).you.principality
          .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));
    });
    tearDown(() => container.dispose());

    test('bygger DITT EGET Universitet, motståndarens eget kort påverkas inte',
        () {
      final before = container.read(gameProvider);
      final card = before.you.faceUpExpansionCard!;
      final opponentCard = before.opponent.faceUpExpansionCard;

      final error = notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, card);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.you.faceUpExpansionCard, isNull);
      expect(state.opponent.faceUpExpansionCard, opponentCard,
          reason: 'motståndarens separata kort ska inte påverkas alls');
      expect(state.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          card.id);
    });

    test(
        'byts ett byggt Universitet ut mot ett annat kort hamnar det INTE i slänghögen utan tillbaka på din egen ansikte-upp-plats',
        () {
      final card = container.read(gameProvider).you.faceUpExpansionCard!;
      expect(notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, card), isNull);
      expect(container.read(gameProvider).you.faceUpExpansionCard, isNull);

      const replacement = BasicSetCards.storehouse;
      final hand = List<GameCard>.of(container.read(gameProvider).you.hand)
        ..add(replacement);
      notifier.state = container.read(gameProvider).copyWith(
          you: container.read(gameProvider).you.copyWith(hand: hand));
      final error =
          notifier.dropExpansion(0, BuildingRow.above, 0, replacement);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.discardPile, isEmpty,
          reason: 'Universitet ska tillbaka till ansikte-upp-platsen, inte slänghögen');
      expect(state.you.faceUpExpansionCard?.id, card.id);
    });
  });
}
