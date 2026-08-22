import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar regionvalet efter en ny by längst ut i kedjan (regelhäftet
/// s. 8): de 2 nydragna regionkorten placeras inte automatiskt, utan
/// väntar i [GameState.pendingRegions] tills spelaren själv väljer
/// ovanför/nedanför.
void main() {
  group('Val av plats för nya regionkort', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    void buildSettlementBeyondFrontier() {
      final notifier = container.read(gameProvider.notifier);
      // Bygga kräver att tärningen är slagen på din tur (regelhäftet s. 7).
      notifier.rollProductionDie();
      final before = container.read(gameProvider);
      before.you.principality.addResourceToRegion(-1, BuildingRow.below, 2);
      before.you.principality.addResourceToRegion(-1, BuildingRow.above, 1);
      notifier.dropRoad(-1, BasicSetCards.road);
      notifier.dropSettlement(-2, BasicSetCards.settlement);
      // Mock-handen innehåller Spejare (se MockGame.buildYou) – den
      // väcker nu frågan "Vill du använda Spejare?" i stället för att
      // dra regionkorten direkt (se scout_test.dart för den frågan).
      // Den här testfilen testar bara pendingRegions-flödet, så vi
      // tackar nej precis som om spelaren inte haft kortet.
      notifier.declineScout();
    }

    test('placePendingRegion placerar ett kort och lämnar det andra kvar', () {
      buildSettlementBeyondFrontier();
      final notifier = container.read(gameProvider.notifier);
      final pending = container.read(gameProvider).pendingRegions;
      expect(pending, hasLength(2));

      final error = notifier.placePendingRegion(BuildingRow.above, pending[0]);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.regionAt(-3, BuildingRow.above)!.card.id, pending[0].id);
      expect(after.pendingRegions, [pending[1]]);
      expect(after.pendingRegionJunction, -3);
    });

    test('placerar båda korten – tömmer pendingRegions när klart', () {
      buildSettlementBeyondFrontier();
      final notifier = container.read(gameProvider.notifier);
      final pending = container.read(gameProvider).pendingRegions;

      notifier.placePendingRegion(BuildingRow.above, pending[0]);
      final error = notifier.placePendingRegion(BuildingRow.below, pending[1]);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.regionAt(-3, BuildingRow.below)!.card.id, pending[1].id);
      expect(after.pendingRegions, isEmpty);
      expect(after.pendingRegionJunction, isNull);
    });

    test('avvisar placering på en redan upptagen plats', () {
      buildSettlementBeyondFrontier();
      final notifier = container.read(gameProvider.notifier);
      final pending = container.read(gameProvider).pendingRegions;
      notifier.placePendingRegion(BuildingRow.above, pending[0]);

      final error = notifier.placePendingRegion(BuildingRow.above, pending[1]);

      expect(error, isNotNull);
      final after = container.read(gameProvider);
      expect(after.pendingRegions, [pending[1]]); // oförändrat
    });

    test('bygga vidare är blockerat tills regionerna är placerade', () {
      buildSettlementBeyondFrontier();
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.dropRoad(-3, BasicSetCards.road);

      expect(error, isNotNull);
    });
  });
}
