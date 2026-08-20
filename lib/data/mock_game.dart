import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';
import 'starter_cards.dart';

/// Statisk exempeldata för att rendera spelbrädet innan riktig
/// spelstate (Riverpod) finns. Två spelare med startuppställning, en
/// handfull handkort och lite mock-resurser att visa i UI:t.
class MockGame {
  MockGame._();

  static Player buildYou() {
    return Player(
      id: 'you',
      name: 'Du',
      hand: [
        BasicSetCards.merchantCaravan,
        BasicSetCards.scout,
        BasicSetCards.storehouse,
        BasicSetCards.grainMill,
        BasicSetCards.austin,
      ],
      resources: {
        ResourceType.lumber: 3,
        ResourceType.brick: 3,
        ResourceType.ore: 0,
        ResourceType.grain: 2,
        ResourceType.wool: 1,
        ResourceType.gold: 0,
      },
      principality: StarterCards.buildStartingPrincipality('you'),
    );
  }

  static Player buildOpponent() {
    return Player(
      id: 'opponent',
      name: 'Motståndare',
      hand: [
        BasicSetCards.goldsmith,
        BasicSetCards.brigittaTheWiseWoman,
      ],
      principality: StarterCards.buildStartingPrincipality('opponent'),
    );
  }

  /// Bygger en riktig startspelare (samma startuppställning som
  /// [buildYou]/[buildOpponent], men med angivet id/namn) – används när
  /// två spelare möts via Firebase-synk i stället för mock-datan ovan.
  static Player buildStartingPlayer(String id, String name) {
    return Player(
      id: id,
      name: name,
      principality: StarterCards.buildStartingPrincipality(id),
    );
  }

  static final _roomCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'.split('');

  /// Genererar en slumpad, lättstavad 4-teckens rumskod (utan tvetydiga
  /// tecken som 0/O/1/I) för att dela mellan de två iPads.
  static String generateRoomCode() {
    return List.generate(4, (_) => _roomCodeChars[_rng.nextInt(_roomCodeChars.length)]).join();
  }

  /// Mock-lager för pip-visning: kortid -> antal resurser (0–3).
  static Map<String, int> resourceStorageFor(RealmBoard board) {
    final storage = <String, int>{};
    var i = 0;
    for (final region in [...board.regionsAbove.values, ...board.regionsBelow.values]) {
      storage[region.card.id] = i % 4;
      i++;
    }
    return storage;
  }

  /// Mock-antal kvar i center-dragstaplarna: grundspelets totala antal
  /// minus de kort de två startuppställningarna redan använder.
  static Map<String, int> centerStackCounts() => {
        'roads': BasicSetCards.supplyCounts['road']! - 2,
        'settlements': BasicSetCards.supplyCounts['settlement']! - 4,
        'cities': BasicSetCards.supplyCounts['city']!,
        'regions': 24 - 12,
        'event': 9,
      };

  static final _regionTemplates = [
    BasicSetCards.forest,
    BasicSetCards.pasture,
    BasicSetCards.fields,
    BasicSetCards.hills,
    BasicSetCards.mountains,
    BasicSetCards.goldField,
  ];
  static var _regionDrawCounter = 0;
  static final _rng = Random();

  /// Drar en "slumpad" region från region-dragstapeln, med ett unikt
  /// tärningstal likt de fysiska korten. Riktig regeldragstapel med
  /// faktiska fysiska kort kommer i ett senare steg.
  static GameCard drawRandomRegion() {
    final template = _regionTemplates[_rng.nextInt(_regionTemplates.length)];
    final number = _rng.nextInt(6) + 1;
    _regionDrawCounter++;
    return template.copyWith(id: '${template.id}-drawn-$_regionDrawCounter', productionNumber: number);
  }
}
