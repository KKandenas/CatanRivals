import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Piratskepp (regelhäftet: "Motståndaren måste ta bort 1
/// valfritt handelsskepp från sitt rike och lägga det bland kasserade
/// kort") – se GameNotifier._maybeTriggerPirateShip/
/// resolvePirateShipDiscard. Precis som Fejd (se feud_test.dart) tar
/// den DRABBADE spelaren bort sitt EGET kort på sin EGEN klient, så
/// resolvePirateShipDiscard opererar alltid på state.you.principality
/// – här simulerat genom att ge "you" ett handelsskepp och tvinga fram
/// väntar-flaggan direkt, precis som feud_test.dart:s forceFeudCard.
void main() {
  ProviderContainer readyContainer() {
    final container = ProviderContainer();
    container.read(gameProvider.notifier).rollProductionDie();
    return container;
  }

  group('GameNotifier._maybeTriggerPirateShip (via dropExpansion)', () {
    test(
        'bygger man Piratskepp och motståndaren har ett handelsskepp sätts väntar-flaggan',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      before.you.hand.add(EraOfGoldCards.pirateShip);
      before.opponent.principality.placeExpansion(2, BuildingRow.below, 0,
          const PlacedCard(card: BasicSetCards.largeTradeShip));

      final error =
          notifier.dropExpansion(0, BuildingRow.above, 0, EraOfGoldCards.pirateShip);

      expect(error, isNull);
      expect(container.read(gameProvider).pirateShipDiscardPending, isTrue);
    });

    test(
        'bygger man Piratskepp och motståndaren saknar handelsskepp händer inget ("Om motståndaren inte har några handelsskepp så händer inget")',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      before.you.hand.add(EraOfGoldCards.pirateShip);

      final error =
          notifier.dropExpansion(0, BuildingRow.above, 0, EraOfGoldCards.pirateShip);

      expect(error, isNull);
      expect(container.read(gameProvider).pirateShipDiscardPending, isFalse);
    });

    test('bygger man ett annat kort än Piratskepp sätts ingen flagga', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      before.opponent.principality.placeExpansion(2, BuildingRow.below, 0,
          const PlacedCard(card: BasicSetCards.largeTradeShip));
      final storehouse =
          before.you.hand.firstWhere((c) => c.id == 'building-storehouse');

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, storehouse);

      expect(error, isNull);
      expect(container.read(gameProvider).pirateShipDiscardPending, isFalse);
    });
  });

  group('GameNotifier.resolvePirateShipDiscard', () {
    test('no-op utan väntande flagga', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.principality.placeExpansion(0,
          BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.largeTradeShip));

      final error = notifier.resolvePirateShipDiscard(0, BuildingRow.above, 0);

      expect(error, isNull);
      expect(
          container.read(gameProvider).you.principality
              .settlementAt(0)!
              .aboveSites[0],
          isNotNull,
          reason: 'kortet ska inte ha rörts');
    });

    test('avvisar ett kort som inte är ett handelsskepp', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.state =
          container.read(gameProvider).copyWith(pirateShipDiscardPending: true);
      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.abbey));

      final error = notifier.resolvePirateShipDiscard(0, BuildingRow.above, 0);

      expect(error, 'Piratskepp kräver att du väljer ett handelsskepp.');
      expect(container.read(gameProvider).pirateShipDiscardPending, isTrue);
      expect(
          container.read(gameProvider).you.principality
              .settlementAt(0)!
              .aboveSites[0],
          isNotNull);
    });

    test(
        'kastar det valda handelsskeppet i slänghögen och rensar flaggan',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.state = container
          .read(gameProvider)
          .copyWith(
              pirateShipDiscardPending: true,
              activeExpansions: {ExpansionSet.eraOfGold});
      container.read(gameProvider).you.principality.placeExpansion(0,
          BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.largeTradeShip));

      final error = notifier.resolvePirateShipDiscard(0, BuildingRow.above, 0);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.pirateShipDiscardPending, isFalse);
      expect(state.you.principality.settlementAt(0)!.aboveSites[0], isNull);
      expect(state.discardPile, hasLength(1));
      expect(state.discardPile.last.id, BasicSetCards.largeTradeShip.id);
    });
  });
}
