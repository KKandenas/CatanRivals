import 'package:catan_rivals/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexCoordinate', () {
    test('has six neighbors at distance 1', () {
      const center = HexCoordinate(0, 0);
      expect(center.neighbors, hasLength(6));
      for (final n in center.neighbors) {
        expect(center.distanceTo(n), 1);
      }
    });
  });

  group('RealmBoard', () {
    test('placing a card twice on the same position throws', () {
      final board = RealmBoard(ownerId: 'p1');
      const position = HexCoordinate(0, 0);
      const card = GameCard(
        id: 'hills-1',
        name: 'Kulle',
        type: CardType.region,
        resource: ResourceType.brick,
        productionNumber: 6,
        imageAsset: 'assets/images/cards/hills.png',
      );

      board.placeCard(position, const PlacedCard(card: card, position: position));

      expect(
        () => board.placeCard(position, const PlacedCard(card: card, position: position)),
        throwsStateError,
      );
    });

    test('round-trips through JSON', () {
      final board = RealmBoard(ownerId: 'p1');
      const position = HexCoordinate(1, -1);
      const card = GameCard(
        id: 'forest-1',
        name: 'Skog',
        type: CardType.region,
        resource: ResourceType.lumber,
        productionNumber: 8,
        imageAsset: 'assets/images/cards/forest.png',
      );
      board.placeCard(position, const PlacedCard(card: card, position: position));

      final restored = RealmBoard.fromJson(board.toJson());

      expect(restored.cardAt(position)?.card.id, 'forest-1');
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
