import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/event_die_resolution.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar dels de nya [RealmBoard]-hjälparna (`expansionLocations`/
/// `resourceTotalExcluding`) som ligger till grund för uträkningen,
/// dels själva [resolveEventDieFace] – den faktiska uträkningen av
/// händelsetärningens icke-händelsekorts-sidor (regelhäftets
/// referenskort ger bara regeln i ord, den här funktionen räknar ut
/// VEM/VAD den gäller för en given spelställning).
void main() {
  Player buildPlayer(String id, String name) => Player(id: id, name: name);

  group('RealmBoard.expansionLocations', () {
    test('tom lista utan det sökta kortet', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.austin));

      expect(
          board.expansionLocations(BasicSetCards.storehouse.id), isEmpty);
    });

    test('hittar kortet oavsett kolumn/rad, matchat på baseId', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      // Ett DRAGET (suffixerat) exemplar – samma som skulle komma från
      // en draghög, se BasicSetDrawDeck.
      board.placeExpansion(
          0,
          BuildingRow.above,
          0,
          PlacedCard(
              card: BasicSetCards.storehouse.copyWith(
                  id: '${BasicSetCards.storehouse.id}-draw-0')));

      final locations = board.expansionLocations(BasicSetCards.storehouse.id);

      expect(locations, hasLength(1));
      expect(locations.single.column, 0);
      expect(locations.single.row, BuildingRow.above);
    });
  });

  group('RealmBoard.resourceTotalExcluding', () {
    test('summerar precis som resourceTotal när inget är undantaget', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeRegion(
          -1, BuildingRow.above,
          const PlacedCard(card: BasicSetCards.forest, storedResources: 2));
      board.placeRegion(
          1, BuildingRow.above,
          const PlacedCard(card: BasicSetCards.forest, storedResources: 1));

      expect(
          board.resourceTotalExcluding(ResourceType.lumber, {}),
          board.resourceTotal(ResourceType.lumber));
      expect(board.resourceTotal(ResourceType.lumber), 3);
    });

    test('hoppar över de angivna (kolumn, rad)-platserna', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeRegion(
          -1, BuildingRow.above,
          const PlacedCard(card: BasicSetCards.forest, storedResources: 2));
      board.placeRegion(
          1, BuildingRow.above,
          const PlacedCard(card: BasicSetCards.forest, storedResources: 1));

      final total = board.resourceTotalExcluding(
          ResourceType.lumber, {(-1, BuildingRow.above)});

      expect(total, 1);
    });
  });

  group('resolveEventDieFace: Brigadanfall', () {
    GameState stateWithResources(int youLumber, {bool youHasStorehouse = false}) {
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeRegion(
          -1,
          BuildingRow.above,
          PlacedCard(
              card: BasicSetCards.forest, storedResources: youLumber));
      if (youHasStorehouse) {
        board.placeExpansion(0, BuildingRow.above, 0,
            const PlacedCard(card: BasicSetCards.storehouse));
      }
      return GameState(
        you: Player(id: 'you', name: 'Astrid', principality: board),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );
    }

    test('ingen spelare över 7 resurser: inget händer', () {
      final state = stateWithResources(3);

      expect(
          resolveEventDieFace(EventDieFace.brigandAttack, state),
          'Ingen spelare har fler än 7 resurser (Lagerhus oräknat). Inget händer.');
    });

    test('en spelare över 7 resurser: namnges och tappar guld/ull', () {
      final state = stateWithResources(8);

      expect(
          resolveEventDieFace(EventDieFace.brigandAttack, state),
          'Astrid har 8 resurser och blir av med allt guld och ull.');
    });

    test(
        'Lagerhus intill regionen undantar den från räkningen (annars skulle 8 räknas)',
        () {
      final state = stateWithResources(8, youHasStorehouse: true);

      expect(
          resolveEventDieFace(EventDieFace.brigandAttack, state),
          'Ingen spelare har fler än 7 resurser (Lagerhus oräknat). Inget händer.');
    });
  });

  group('resolveEventDieFace: Handel', () {
    test('ingen har handelsövertaget: inget händer', () {
      final state = GameState(
        you: buildPlayer('you', 'Astrid'),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventDieFace(EventDieFace.trade, state),
          'Ingen spelare har handelsövertaget just nu. Inget händer.');
    });

    test('du har handelsövertaget: får resurs från motståndaren', () {
      final state = GameState(
        you: buildPlayer('you', 'Astrid'),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
        tradeTokenHolder: 'you',
      );

      expect(resolveEventDieFace(EventDieFace.trade, state),
          'Astrid har handelsövertaget och får 1 valfri resurs från Björn.');
    });
  });

  group('resolveEventDieFace: Fest', () {
    GameState stateWithSkill(int youSkill, int oppSkill) {
      final youBoard = RealmBoard(ownerId: 'you');
      if (youSkill > 0) {
        youBoard.placeSettlement(
            0, const PlacedCard(card: BasicSetCards.settlement));
        youBoard.placeExpansion(
            0,
            BuildingRow.above,
            0,
            PlacedCard(
                card: BasicSetCards.austin.copyWith(skillPoints: youSkill)));
      }
      final oppBoard = RealmBoard(ownerId: 'opponent');
      if (oppSkill > 0) {
        oppBoard.placeSettlement(
            0, const PlacedCard(card: BasicSetCards.settlement));
        oppBoard.placeExpansion(
            0,
            BuildingRow.above,
            0,
            PlacedCard(
                card: BasicSetCards.austin.copyWith(skillPoints: oppSkill)));
      }
      return GameState(
        you: Player(id: 'you', name: 'Astrid', principality: youBoard),
        opponent:
            Player(id: 'opponent', name: 'Björn', principality: oppBoard),
        centerStacks: const {},
      );
    }

    test('lika många kunskapspoäng: båda får en resurs', () {
      final state = stateWithSkill(2, 2);

      expect(resolveEventDieFace(EventDieFace.celebration, state),
          'Båda spelarna har lika många kunskapspoäng. Båda spelarna får 1 valfri resurs var.');
    });

    test('du har flest kunskapspoäng: bara du får en resurs', () {
      final state = stateWithSkill(3, 1);

      expect(resolveEventDieFace(EventDieFace.celebration, state),
          'Astrid har flest kunskapspoäng och får 1 valfri resurs.');
    });
  });

  group('resolveEventDieFace: Riklig skörd', () {
    test('ingen har Tullbro: ingen extra rad', () {
      final state = GameState(
        you: buildPlayer('you', 'Astrid'),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventDieFace(EventDieFace.plentifulHarvest, state), isNull);
    });

    test('du har Tullbro: får dessutom 2 guld', () {
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.tollBridge));
      final state = GameState(
        you: Player(id: 'you', name: 'Astrid', principality: board),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventDieFace(EventDieFace.plentifulHarvest, state),
          'Astrid har lagt ut Tullbro och får dessutom 2 guld.');
    });
  });

  group('resolveEventDieFace: Händelsekort', () {
    test('ingen extra uträkning (hanteras separat)', () {
      final state = GameState(
        you: buildPlayer('you', 'Astrid'),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventDieFace(EventDieFace.eventCard, state), isNull);
    });
  });
}
