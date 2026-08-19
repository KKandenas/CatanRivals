import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/starter_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BasicSetCards', () {
    test('has 44 distinct card types', () {
      expect(BasicSetCards.all, hasLength(44));
    });

    test('supply counts plus the 24 region cards add up to the full 94-card set', () {
      final nonRegionCopies = BasicSetCards.supplyCounts.values.fold(0, (a, b) => a + b);
      const regionTypeCount = 6;
      const copiesPerRegionType = 4;

      expect(nonRegionCopies + regionTypeCount * copiesPerRegionType, 94);
    });

    test('every catalog id has a supply count, except the 6 region templates', () {
      final idsWithoutCount = BasicSetCards.all
          .where((card) => card.category != CardCategory.region)
          .map((card) => card.id)
          .where((id) => !BasicSetCards.supplyCounts.containsKey(id));

      expect(idsWithoutCount, isEmpty);
    });
  });

  group('RealmBoard – starting principality', () {
    test('has 2 settlements, 1 road and 6 regions worth 2 victory points', () {
      final board = StarterCards.buildStartingPrincipality('p1');

      expect(board.settlements, hasLength(2));
      expect(board.roads, hasLength(1));
      expect(board.regionsAbove, hasLength(3));
      expect(board.regionsBelow, hasLength(3));
      expect(board.totalVictoryPoints, 2); // 2 byar à 1 poäng
    });

    test('the two settlements share their corner regions via the road junction', () {
      final board = StarterCards.buildStartingPrincipality('p1');

      final rightCornersOfLeftSettlement = board.cornerRegions(0, BuildingRow.above)[1];
      final leftCornersOfRightSettlement = board.cornerRegions(2, BuildingRow.above)[0];

      expect(rightCornersOfLeftSettlement, isNotNull);
      expect(rightCornersOfLeftSettlement, same(leftCornersOfRightSettlement));
    });

    test('placing a settlement on an occupied column throws', () {
      final board = StarterCards.buildStartingPrincipality('p1');

      expect(
        () => board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement)),
        throwsStateError,
      );
    });

    test('upgrading to a city adds a second building site on each side', () {
      final board = StarterCards.buildStartingPrincipality('p1');

      board.upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
      final node = board.settlementAt(0)!;

      expect(node.isCity, isTrue);
      expect(node.aboveSites, hasLength(2));
      expect(node.belowSites, hasLength(2));
      expect(board.totalVictoryPoints, 3); // 1 stad (2p) + 1 by (1p)
    });

    test('round-trips through JSON', () {
      final board = StarterCards.buildStartingPrincipality('p1');

      final restored = RealmBoard.fromJson(board.toJson());

      expect(restored.settlements.keys.toSet(), board.settlements.keys.toSet());
      expect(restored.totalVictoryPoints, board.totalVictoryPoints);
    });
  });

  group('Player', () {
    test('addResource accumulates counts', () {
      final player = Player(id: 'p1', name: 'Alice');
      final updated = player
          .addResource(ResourceType.wool, 2)
          .addResource(ResourceType.wool, 1);

      expect(updated.resourceCount(ResourceType.wool), 3);
      expect(player.resourceCount(ResourceType.wool), 0); // originalet är oförändrat
    });
  });
}
