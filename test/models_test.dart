import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
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

  group('EraOfGoldCards', () {
    test('has 15 new card types', () {
      expect(EraOfGoldCards.all, hasLength(15));
    });

    test('supply counts add up to the full 27-card set', () {
      final totalCopies = EraOfGoldCards.supplyCounts.values.fold(0, (a, b) => a + b);

      expect(totalCopies, 27);
    });

    test('every new card in the catalog has a supply count', () {
      final idsWithoutCount = EraOfGoldCards.all
          .map((card) => card.id)
          .where((id) => !EraOfGoldCards.supplyCounts.containsKey(id));

      expect(idsWithoutCount, isEmpty);
    });

    test('cards with a requirement expose it', () {
      expect(EraOfGoldCards.tradeMaster.requirement, 'Merchant Guild');
      expect(EraOfGoldCards.goldCache.requirement, 'Hero with at least 1 strength point');
    });
  });

  group('EraOfTurmoilCards', () {
    test('has 18 new card types', () {
      expect(EraOfTurmoilCards.all, hasLength(18));
    });

    test('supply counts add up to the full 28-card set', () {
      final totalCopies = EraOfTurmoilCards.supplyCounts.values.fold(0, (a, b) => a + b);

      expect(totalCopies, 28);
    });

    test('every new card in the catalog has a supply count', () {
      final idsWithoutCount = EraOfTurmoilCards.all
          .map((card) => card.id)
          .where((id) => !EraOfTurmoilCards.supplyCounts.containsKey(id));

      expect(idsWithoutCount, isEmpty);
    });

    test('the two Chapels protect against opposite production rolls', () {
      expect(EraOfTurmoilCards.chapelLowRoll.effectText, contains('1, 2, or 3'));
      expect(EraOfTurmoilCards.chapelHighRoll.effectText, contains('4, 5, or 6'));
    });

    test('attack action cards requiring Hedge Tavern are flagged', () {
      for (final card in [
        EraOfTurmoilCards.archer,
        EraOfTurmoilCards.arsonist,
        EraOfTurmoilCards.traitor,
      ]) {
        expect(card.actionKind, ActionKind.attack);
        expect(card.requirement, 'Hedge Tavern');
      }
    });
  });

  group('EraOfProgressCards', () {
    test('has 15 new card types', () {
      expect(EraOfProgressCards.all, hasLength(15));
    });

    test('supply counts add up to the full 31-card set', () {
      final totalCopies = EraOfProgressCards.supplyCounts.values.fold(0, (a, b) => a + b);

      expect(totalCopies, 31);
    });

    test('every new card in the catalog has a supply count', () {
      final idsWithoutCount = EraOfProgressCards.all
          .map((card) => card.id)
          .where((id) => !EraOfProgressCards.supplyCounts.containsKey(id));

      expect(idsWithoutCount, isEmpty);
    });

    test('University is unique and requires Abbey or Library', () {
      expect(EraOfProgressCards.university.isUnique, isTrue);
      expect(EraOfProgressCards.university.requirement, 'Abbey or Library');
    });

    test('Chief Cannoneer is a unit, not a hero, and has no skill points', () {
      expect(EraOfProgressCards.chiefCannoneer.expansionKind, ExpansionKind.otherUnit);
      expect(EraOfProgressCards.chiefCannoneer.skillPoints, 0);
    });
  });

  group('All four card sets combined', () {
    test('the full catalog totals 180 cards, matching the rulebook', () {
      const basicRegions = 24;
      final basicNonRegions = BasicSetCards.supplyCounts.values.fold(0, (a, b) => a + b);
      final gold = EraOfGoldCards.supplyCounts.values.fold(0, (a, b) => a + b);
      final turmoil = EraOfTurmoilCards.supplyCounts.values.fold(0, (a, b) => a + b);
      final progress = EraOfProgressCards.supplyCounts.values.fold(0, (a, b) => a + b);

      expect(basicRegions + basicNonRegions + gold + turmoil + progress, 180);
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

    test('serialized column keys are never purely numeric strings', () {
      // Firebase Realtime Database gör tyst om ett JSON-objekt till en
      // array om ALLA nycklar ser ut som icke-negativa heltal (t.ex.
      // "0", "2") – vilket kraschar allt när det läses tillbaka som
      // Map. Kolumnnycklarna ("0", "-1", "2" ...) måste därför alltid
      // ha ett prefix i den serialiserade formen.
      final board = StarterCards.buildStartingPrincipality('p1');
      final json = board.toJson();

      final numeric = RegExp(r'^-?\d+$');
      for (final section in ['settlements', 'roads', 'regionsAbove', 'regionsBelow']) {
        final keys = (json[section] as Map).keys.cast<String>();
        for (final key in keys) {
          expect(numeric.hasMatch(key), isFalse, reason: '$section-nyckeln "$key" ser numerisk ut');
        }
      }
    });

    test('survives Firebase dropping null values from an empty building site', () {
      // Firebase Realtime Database lagrar aldrig null – ett null i en
      // array-position gör att den positionen (och därmed hela
      // array-strukturen) försvinner vid skrivning. Simulerar det här
      // genom att koda en tom byggplats till JSON och sedan ta bort
      // den nyckeln helt (som Firebase skulle göra), innan avkodning.
      final board = StarterCards.buildStartingPrincipality('p1');
      final json = board.toJson();

      final settlement0 = Map<String, dynamic>.from((json['settlements'] as Map)['c0'] as Map);
      final aboveSites = Map<String, dynamic>.from(settlement0['aboveSites'] as Map);
      expect(aboveSites.containsKey('s0'), isFalse); // tom byggplats skrevs aldrig ut

      final restored = RealmBoard.fromJson(json);
      expect(restored.settlementAt(0)!.aboveSites, [null]);
    });
  });

  group('RealmBoard – resurslagring per region', () {
    test('starting principality has exactly 1 of each non-gold resource and 0 gold', () {
      final board = StarterCards.buildStartingPrincipality('p1', isRed: true);

      expect(board.resourceTotal(ResourceType.lumber), 1);
      expect(board.resourceTotal(ResourceType.brick), 1);
      expect(board.resourceTotal(ResourceType.ore), 1);
      expect(board.resourceTotal(ResourceType.grain), 1);
      expect(board.resourceTotal(ResourceType.wool), 1);
      expect(board.resourceTotal(ResourceType.gold), 0);
    });

    test('spend takes resources from a region with that type, clamped at 0', () {
      final board = StarterCards.buildStartingPrincipality('p1', isRed: true);

      board.spend({ResourceType.lumber: 1});

      expect(board.resourceTotal(ResourceType.lumber), 0);
      expect(board.canAfford({ResourceType.lumber: 1}), isFalse);
    });

    test('spend throws when the player cannot afford the cost', () {
      final board = StarterCards.buildStartingPrincipality('p1', isRed: true);

      expect(() => board.spend({ResourceType.lumber: 2}), throwsStateError);
      // Oförändrat efter det misslyckade försöket.
      expect(board.resourceTotal(ResourceType.lumber), 1);
    });

    test('addResourceToRegion clamps stored resources to 0-3', () {
      final board = StarterCards.buildStartingPrincipality('p1', isRed: true);

      board.addResourceToRegion(-1, BuildingRow.above, 10);

      expect(board.regionAt(-1, BuildingRow.above)!.storedResources, 3);
    });
  });
}
