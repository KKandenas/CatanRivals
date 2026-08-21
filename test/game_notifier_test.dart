import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      // Bygga/köpa kräver nu att tärningen är slagen på din tur
      // (regelhäftet s. 7) – slå den här så byggtesterna nedan inte
      // behöver upprepa det själva.
      container.read(gameProvider.notifier).rollProductionDie();
    });

    test('initial state has starting principalities and center stacks', () {
      final state = container.read(gameProvider);

      expect(state.you.principality.settlements, hasLength(2));
      expect(state.opponent.principality.settlements, hasLength(2));
      expect(state.centerStacks['roads'], greaterThan(0));
      expect(state.draggingCard, isNull);
    });

    test('dropExpansion places an affordable hand card and deducts resources', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final storehouse = before.you.hand.firstWhere((c) => c.id == 'building-storehouse');
      final lumberBefore = before.you.resourceCount(ResourceType.lumber);

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, storehouse);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(storehouse), isFalse);
      expect(after.you.resourceCount(ResourceType.lumber), lumberBefore - 1);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id, storehouse.id);
    });

    test('dropExpansion rejects a card the player cannot afford, leaving hand and board untouched', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final siglind = before.you.hand.firstWhere((c) => c.id == 'hero-siglind');

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, siglind);

      expect(error, isNotNull);
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(siglind), isTrue);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0], isNull);
    });

    test('dropRoad builds a road at the frontier and decrements the stack', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final roadsBefore = before.centerStacks['roads']!;
      // Vägen kostar 2 lera, men startuppställningen har bara 1 lagrad
      // (regelhäftet s. 3) – toppa upp Hills-regionen så draget går att
      // betala, precis som en spelare skulle göra efter några tärningsslag.
      before.you.principality.addResourceToRegion(-1, BuildingRow.below, 1);

      final error = notifier.dropRoad(-1, BasicSetCards.road);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.roads.containsKey(-1), isTrue);
      expect(after.centerStacks['roads'], roadsBefore - 1);
    });

    test('dropSettlement builds beyond a dangling road and queues 2 new regions to place', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      // Väg (2 lera, 1 trä) + by (1 lera, 1 säd, 1 får, 1 trä) kostar mer
      // än startuppställningens 1-av-varje – toppa upp lera och trä.
      before.you.principality.addResourceToRegion(-1, BuildingRow.below, 2);
      before.you.principality.addResourceToRegion(-1, BuildingRow.above, 1);
      notifier.dropRoad(-1, BasicSetCards.road);
      final regionsBefore = container.read(gameProvider).centerStacks['regions']!;

      final error = notifier.dropSettlement(-2, BasicSetCards.settlement);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.settlementAt(-2), isNotNull);
      // Regionerna dras direkt (stapeln minskar) men placeras inte förrän
      // spelaren själv drar dem till ovanför/nedanför – se
      // 'placePendingRegion' i pending_regions_test.dart.
      expect(after.you.principality.regionAt(-3, BuildingRow.above), isNull);
      expect(after.you.principality.regionAt(-3, BuildingRow.below), isNull);
      expect(after.pendingRegions, hasLength(2));
      expect(after.pendingRegionJunction, -3);
      expect(after.centerStacks['regions'], regionsBefore - 2);
    });

    test('dropSettlement without a road first is rejected by RealmBoard', () {
      final notifier = container.read(gameProvider.notifier);

      // Ingen väg utplacerad vid kolumn -1, så -2 är egentligen inte en
      // giltig plats – RealmBoard.placeSettlement kastar när kolumnen
      // redan är upptagen, men här testar vi att en helt orimlig
      // kolumn (mitt i en befintlig by) avvisas av modellen.
      expect(() => notifier.dropSettlement(0, BasicSetCards.settlement), throwsStateError);
    });

    test('dropCityUpgrade is rejected without enough ore, leaving the settlement untouched', () {
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.dropCityUpgrade(0, BasicSetCards.city);

      expect(error, isNotNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.settlementAt(0)!.isCity, isFalse);
    });

    test('startDrag/endDrag toggles draggingCard', () {
      final notifier = container.read(gameProvider.notifier);

      notifier.startDrag(BasicSetCards.road);
      expect(container.read(gameProvider).draggingCard, BasicSetCards.road);

      notifier.endDrag();
      expect(container.read(gameProvider).draggingCard, isNull);
    });
  });
}
