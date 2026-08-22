import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Spejare (regelhäftet: "Play this card when building a
/// settlement. Take 2 cards of your choice from the region card
/// stack. Reshuffle the region card stack.") – frågan väcks
/// automatiskt av [GameNotifier.dropSettlement] i stället för ett
/// handkortstryck, se hand_dock.dart. Mock-handen (MockGame.buildYou)
/// har redan kortet, så inget extra setup krävs för att väcka frågan.
void main() {
  group('Spejare', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).rollProductionDie();
    });

    void buildBeyondFrontier() {
      final notifier = container.read(gameProvider.notifier);
      notifier.dropRoad(-1, BasicSetCards.road);
      notifier.dropSettlement(-2, BasicSetCards.settlement);
    }

    test('by-bygge bortom yttergränsen väcker frågan i stället för att dra direkt',
        () {
      buildBeyondFrontier();

      final state = container.read(gameProvider);
      expect(state.awaitingScoutDecision, isTrue);
      expect(state.pendingRegions, isEmpty);
      expect(state.pendingRegionJunction, -3);
      expect(state.scoutChoices, isNull);
    });

    test('declineScout drar 2 slumpmässiga kort som vanligt', () {
      buildBeyondFrontier();
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.declineScout();

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.awaitingScoutDecision, isFalse);
      expect(state.pendingRegions, hasLength(2));
      // Kortet ligger kvar på handen – det är bara använt om man tackar ja.
      expect(state.you.hand.any((c) => c.id == BasicSetCards.scout.id), isTrue);
    });

    test(
        'useScout öppnar hela regionstapeln, pickScoutRegion väljer 2 kort och tar bort kortet',
        () {
      buildBeyondFrontier();
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.useScout(), isNull);
      final choices = container.read(gameProvider).scoutChoices;
      expect(choices, isNotNull);
      // Hela den kvarvarande regionstapeln (RegionDeck: 2 kort per typ,
      // 6 typer) – inte bara några få översta.
      expect(choices, hasLength(12));

      final firstPick = choices![0];
      final secondPick = choices[1];

      expect(notifier.pickScoutRegion(firstPick), isNull);
      var state = container.read(gameProvider);
      expect(state.pendingRegions, [firstPick]);
      expect(state.scoutChoices, isNotNull); // väntar fortfarande på val 2
      expect(state.scoutChoices!.contains(firstPick), isFalse);

      expect(notifier.pickScoutRegion(secondPick), isNull);
      state = container.read(gameProvider);
      expect(state.pendingRegions, [firstPick, secondPick]);
      expect(state.scoutChoices, isNull);
      expect(state.awaitingScoutDecision, isFalse);
      expect(state.you.hand.any((c) => c.id == BasicSetCards.scout.id), isFalse);
      expect(state.pendingRegionJunction, -3);
    });

    test('placePendingRegion fungerar som vanligt efter ett Spejare-val', () {
      buildBeyondFrontier();
      final notifier = container.read(gameProvider.notifier);
      notifier.useScout();
      final choices = container.read(gameProvider).scoutChoices!;
      notifier.pickScoutRegion(choices[0]);
      notifier.pickScoutRegion(container.read(gameProvider).scoutChoices![0]);
      final pending = container.read(gameProvider).pendingRegions;

      final error = notifier.placePendingRegion(BuildingRow.above, pending[0]);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.regionAt(-3, BuildingRow.above)!.card.id,
          pending[0].id);
      expect(after.pendingRegions, [pending[1]]);
    });

    test('bygga vidare är blockerat medan frågan väntar på svar', () {
      buildBeyondFrontier();
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.dropRoad(-3, BasicSetCards.road);

      expect(error, isNotNull);
    });
  });
}
