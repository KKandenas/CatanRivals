import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Hero Token ("Strongest Force")/Trade Token ("Greatest
/// Trader"): 1 extra VP till den som har minst 3 styrke- respektive
/// handelspoäng och fler än motståndaren. Oavgjort ändrar ingenting
/// (den som redan har bricken behåller den) – se
/// [GameNotifier.recomputeTokenHolders].
///
/// Testerna placerar kort direkt på [RealmBoard] (i stället för via
/// [GameNotifier.dropExpansion], som bara kan spela kort ur din egen
/// hand) för att kunna ge båda spelarna godtyckliga poängsummor, och
/// anropar sedan [GameNotifier.recomputeTokenHolders] – exakt samma
/// omräkning som sker automatiskt efter varje riktigt drag.
void main() {
  group('Hero Token / Trade Token', () {
    test('ingen har bricken innan någon når 3 poäng', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);

      state.you.principality
          .placeExpansion(0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.austin)); // styrka 1
      state.opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.harald)); // styrka 2
      notifier.recomputeTokenHolders();

      expect(container.read(gameProvider).heroTokenHolder, isNull);
    });

    test('banken ger bricken till den som först når minst 3 och mer än motståndaren', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);

      state.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.candamir)); // styrka 4
      notifier.recomputeTokenHolders();

      expect(container.read(gameProvider).heroTokenHolder, 'you');
    });

    test('oavgjort ändrar ingenting – innehavaren behåller bricken', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);

      state.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.candamir)); // styrka 4
      notifier.recomputeTokenHolders();
      expect(container.read(gameProvider).heroTokenHolder, 'you');

      // Motståndaren hinner ikapp till exakt samma summa (4-4).
      state.opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.candamir));
      notifier.recomputeTokenHolders();

      expect(container.read(gameProvider).heroTokenHolder, 'you');
    });

    test('går om av motståndaren och bricken byter ägare', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);

      state.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.candamir)); // styrka 4
      notifier.recomputeTokenHolders();
      expect(container.read(gameProvider).heroTokenHolder, 'you');

      state.opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.candamir)); // styrka 4
      state.opponent.principality.placeExpansion(
          0, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.harald)); // +2 = 6
      notifier.recomputeTokenHolders();

      expect(container.read(gameProvider).heroTokenHolder, 'opponent');
    });

    test('Trade Token räknas oberoende av Hero Token, med handelspoäng', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);

      // 3 handelspoäng på dig (1 vardera), 0 styrkepoäng alls.
      state.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.marketplace));
      state.you.principality.placeExpansion(
          0, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.tollBridge));
      state.you.principality.placeExpansion(
          2, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.largeTradeShip));
      notifier.recomputeTokenHolders();

      final result = container.read(gameProvider);
      expect(result.tradeTokenHolder, 'you');
      expect(result.heroTokenHolder, isNull);
    });

    test('totalVictoryPointsFor lägger till 1 VP per bricka spelaren har', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      final baseline = state.totalVictoryPointsFor(state.you);

      state.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.candamir));
      notifier.recomputeTokenHolders();

      final after = container.read(gameProvider);
      expect(after.heroTokenHolder, 'you');
      expect(after.totalVictoryPointsFor(after.you), baseline + 1);
    });
  });
}
