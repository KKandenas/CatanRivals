import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
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
          'Ingen spelare har fler än 7 resurser (Lagerhus/Guldgömma oräknat). Inget händer.');
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
          'Ingen spelare har fler än 7 resurser (Lagerhus/Guldgömma oräknat). Inget händer.');
    });
  });

  group('resolveEventDieFace: Brigadanfall + Guldgömma', () {
    GameState stateWithGoldCache(int youLumber, int goldCacheGold) {
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeRegion(-1, BuildingRow.above,
          PlacedCard(card: BasicSetCards.forest, storedResources: youLumber));
      // Guldgömma kräver en region av matchande resurstyp (gold) - ett
      // eget Guldfält, skilt från timmer-regionen ovan.
      board.placeRegion(
          1, BuildingRow.above, const PlacedCard(card: BasicSetCards.goldField));
      board.placeRegionExpansion(
          1,
          BuildingRow.above,
          PlacedCard(
              card: EraOfGoldCards.goldCache, storedResources: goldCacheGold));
      return GameState(
        you: Player(id: 'you', name: 'Astrid', principality: board),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );
    }

    test('guld i Guldgömman räknas inte med i 7-gränsen', () {
      // 5 timmer + 3 guld i gömman = 8 fysiska resurser, men gömmans
      // guld är skyddat (regelhäftet: "det kan inte stjälas") och ska
      // alltså inte trigga Brigadanfallet.
      final state = stateWithGoldCache(5, 3);

      expect(
          resolveEventDieFace(EventDieFace.brigandAttack, state),
          'Ingen spelare har fler än 7 resurser (Lagerhus/Guldgömma oräknat). Inget händer.');
    });

    test(
        'spelaren drabbas ändå om ÖVRIGA resurser (utöver gömmans guld) redan är fler än 7 – texten nämner skyddet',
        () {
      final state = stateWithGoldCache(8, 3);

      expect(
          resolveEventDieFace(EventDieFace.brigandAttack, state),
          'Astrid har 8 resurser och blir av med allt guld och ull '
          '(guldet i Guldgömman är skyddat och räknas inte bort).');
    });

    test('guldet i Guldgömman räknas ändå i Player.resourceCount(gold)', () {
      final state = stateWithGoldCache(5, 3);

      expect(state.you.resourceCount(ResourceType.gold), 3);
    });
  });

  group('resolveEventDieFace: Handel', () {
    GameState stateWithCommerce(int youCommerce, int oppCommerce) {
      final youBoard = RealmBoard(ownerId: 'you');
      if (youCommerce > 0) {
        youBoard.placeSettlement(
            0, const PlacedCard(card: BasicSetCards.settlement));
        youBoard.placeExpansion(
            0,
            BuildingRow.above,
            0,
            PlacedCard(
                card: BasicSetCards.tollBridge
                    .copyWith(commercePoints: youCommerce)));
      }
      final oppBoard = RealmBoard(ownerId: 'opponent');
      if (oppCommerce > 0) {
        oppBoard.placeSettlement(
            0, const PlacedCard(card: BasicSetCards.settlement));
        oppBoard.placeExpansion(
            0,
            BuildingRow.above,
            0,
            PlacedCard(
                card: BasicSetCards.tollBridge
                    .copyWith(commercePoints: oppCommerce)));
      }
      return GameState(
        you: Player(id: 'you', name: 'Astrid', principality: youBoard),
        opponent:
            Player(id: 'opponent', name: 'Björn', principality: oppBoard),
        centerStacks: const {},
      );
    }

    test('lika många handelspoäng (båda 0): inget händer', () {
      final state = stateWithCommerce(0, 0);

      expect(resolveEventDieFace(EventDieFace.trade, state),
          'Ingen spelare har flest handelspoäng just nu. Inget händer.');
    });

    test('du har flest handelspoäng: får resurs från motståndaren', () {
      final state = stateWithCommerce(2, 1);

      expect(resolveEventDieFace(EventDieFace.trade, state),
          'Astrid har flest handelspoäng och får 1 valfri resurs från Björn.');
    });

    test(
        'gäller redan under Handelsbrickans tröskel på 3 poäng (speltestad bugg: '
        'den gamla brick-baserade varianten missade utslag här)', () {
      final state = stateWithCommerce(1, 0);

      expect(resolveEventDieFace(EventDieFace.trade, state),
          'Astrid har flest handelspoäng och får 1 valfri resurs från Björn.');
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

  group('resolveEventCard: Uppfinning', () {
    test('ingen byggnad med framstegspoäng: ingen extra rad', () {
      final state = GameState(
        you: buildPlayer('you', 'Astrid'),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventCard(BasicSetCards.invention, state), isNull);
    });

    test('1 byggnad med framstegspoäng (Kloster): 1 spelare får 1 resurs', () {
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.abbey));
      final state = GameState(
        you: Player(id: 'you', name: 'Astrid', principality: board),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventCard(BasicSetCards.invention, state),
          'Astrid har 1 byggnad med framstegspoäng och får ta 1 valfri resurs.');
    });

    test(
        '3 byggnader med framstegspoäng: räknar alla 3 men täcker resurserna vid taket på 2',
        () {
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeSettlement(
          2, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(
          0,
          BuildingRow.above,
          0,
          PlacedCard(
              card: BasicSetCards.marketplace.copyWith(progressPoints: 1)));
      board.placeExpansion(
          0,
          BuildingRow.below,
          0,
          PlacedCard(
              card: BasicSetCards.parishHall.copyWith(progressPoints: 1)));
      board.placeExpansion(
          2,
          BuildingRow.above,
          0,
          PlacedCard(
              card: BasicSetCards.storehouse.copyWith(progressPoints: 1)));
      final state = GameState(
        you: Player(id: 'you', name: 'Astrid', principality: board),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventCard(BasicSetCards.invention, state),
          'Astrid har 3 byggnader med framstegspoäng och får ta 2 valfria resurser.');
    });
  });

  group('resolveEventCard: Handelsskeppskapplöpning', () {
    GameState stateWithShips(int youShips, int oppShips) {
      RealmBoard buildBoard(String owner, int shipCount) {
        final board = RealmBoard(ownerId: owner);
        if (shipCount == 0) return board;
        board.placeSettlement(
            0, const PlacedCard(card: BasicSetCards.settlement));
        for (var i = 0; i < shipCount && i < 2; i++) {
          board.placeExpansion(
              0,
              i == 0 ? BuildingRow.above : BuildingRow.below,
              0,
              PlacedCard(card: BasicSetCards.grainShip));
        }
        return board;
      }

      return GameState(
        you: Player(
            id: 'you', name: 'Astrid', principality: buildBoard('you', youShips)),
        opponent: Player(
            id: 'opponent',
            name: 'Björn',
            principality: buildBoard('opponent', oppShips)),
        centerStacks: const {},
      );
    }

    test('ingen har handelsskepp: inget händer', () {
      final state = stateWithShips(0, 0);

      expect(resolveEventCard(BasicSetCards.tradeShipsRace, state),
          'Ingen spelare har något handelsskepp. Inget händer.');
    });

    test('lika många handelsskepp: båda får en resurs', () {
      final state = stateWithShips(1, 1);

      expect(resolveEventCard(BasicSetCards.tradeShipsRace, state),
          'Båda spelarna har lika många handelsskepp (1 var) och får 1 valfri resurs var.');
    });

    test('du har flest handelsskepp: du får en resurs', () {
      final state = stateWithShips(2, 1);

      expect(resolveEventCard(BasicSetCards.tradeShipsRace, state),
          'Astrid har flest handelsskepp (2) och får 1 valfri resurs.');
    });
  });

  group('resolveEventCard: Goda året', () {
    test('ingen region gränsar till Lagerhus/Kloster: ingen extra rad', () {
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeRegion(-1, BuildingRow.above,
          const PlacedCard(card: BasicSetCards.forest));
      final state = GameState(
        you: Player(id: 'you', name: 'Astrid', principality: board),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventCard(BasicSetCards.yearOfPlenty, state), isNull);
    });

    test('en region gränsar till Kloster: namnger regionen', () {
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeRegion(-1, BuildingRow.above,
          const PlacedCard(card: BasicSetCards.forest));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.abbey));
      final state = GameState(
        you: Player(id: 'you', name: 'Astrid', principality: board),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventCard(BasicSetCards.yearOfPlenty, state),
          'Astrid har skog angränsande till Lagerhus/Kloster och får 1 resurs per region (om det finns plats).');
    });

    test(
        'ett Lagerhus gränsar till 2 regioner samtidigt: listar båda med "och"',
        () {
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeRegion(-1, BuildingRow.above,
          const PlacedCard(card: BasicSetCards.forest));
      board.placeRegion(1, BuildingRow.above,
          const PlacedCard(card: BasicSetCards.goldField));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.storehouse));
      final state = GameState(
        you: Player(id: 'you', name: 'Astrid', principality: board),
        opponent: buildPlayer('opponent', 'Björn'),
        centerStacks: const {},
      );

      expect(resolveEventCard(BasicSetCards.yearOfPlenty, state),
          'Astrid har skog och guldfält angränsande till Lagerhus/Kloster och får 1 resurs per region (om det finns plats).');
    });
  });
}
