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

    test('dropExpansion places a hand card without touching resources', () {
      // Appen håller inte längre koll på om spelaren har råd – kostnaden
      // visas i bekräftelserutan (build_confirm_dialog.dart) och
      // spelarna betalar själva med +/- på sina regioner, precis som i
      // det fysiska spelet (regelhäftet s. 9).
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final storehouse = before.you.hand.firstWhere((c) => c.id == 'building-storehouse');
      final lumberBefore = before.you.resourceCount(ResourceType.lumber);

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, storehouse);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(storehouse), isFalse);
      expect(after.you.resourceCount(ResourceType.lumber), lumberBefore);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id, storehouse.id);
    });

    test('dropExpansion places a hand card the player cannot afford (no affordability check)', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final siglind = before.you.hand.firstWhere((c) => c.id == 'hero-siglind');

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, siglind);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(siglind), isFalse);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id, siglind.id);
    });

    test('dropRoad builds a road at the frontier and decrements the stack', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final roadsBefore = before.centerStacks['roads']!;

      final error = notifier.dropRoad(-1, BasicSetCards.road);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.roads.containsKey(-1), isTrue);
      expect(after.centerStacks['roads'], roadsBefore - 1);
    });

    test('dropSettlement builds beyond a dangling road and queues 2 new regions to place', () {
      final notifier = container.read(gameProvider.notifier);
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

    test('dropCityUpgrade upgrades the settlement without an affordability check', () {
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.dropCityUpgrade(0, BasicSetCards.city);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.settlementAt(0)!.isCity, isTrue);
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
