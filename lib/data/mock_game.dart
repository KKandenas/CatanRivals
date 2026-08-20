import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';
import 'starter_cards.dart';

/// Statisk exempeldata för att rendera spelbrädet innan ett riktigt
/// rum finns: två spelare med startuppställning (riktiga startresurser,
/// se [StarterCards]) och en handfull mock-handkort att visa i UI:t.
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
        BasicSetCards.siglind,
      ],
      principality: StarterCards.buildStartingPrincipality('you', isRed: true),
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
      principality: StarterCards.buildStartingPrincipality('opponent', isRed: false),
    );
  }

  /// Bygger en riktig startspelare (samma startuppställning som
  /// [buildYou]/[buildOpponent], men med angivet id/namn) – används när
  /// två spelare möts via Firebase-synk i stället för mock-datan ovan.
  /// Regelhäftet ger den röda och den blå spelaren olika tärningstal på
  /// samma sex regioner (s. 2 och 4), så [isRed] avgör vilken
  /// uppsättning tal som används.
  static Player buildStartingPlayer(String id, String name, {required bool isRed}) {
    return Player(
      id: id,
      name: name,
      principality: StarterCards.buildStartingPrincipality(id, isRed: isRed),
    );
  }

  static final _roomCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'.split('');

  /// Genererar en slumpad, lättstavad 4-teckens rumskod (utan tvetydiga
  /// tecken som 0/O/1/I) för att dela mellan de två iPads.
  static String generateRoomCode() {
    return List.generate(4, (_) => _roomCodeChars[_rng.nextInt(_roomCodeChars.length)]).join();
  }

  /// Antal kvar i center-dragstaplarna vid start: grundspelets totala
  /// antal minus de kort de två startuppställningarna redan använder
  /// (2 byar + 1 väg + 6 regioner vardera).
  static Map<String, int> centerStackCounts() => {
        'roads': BasicSetCards.supplyCounts['road']! - 2,
        'settlements': BasicSetCards.supplyCounts['settlement']! - 4,
        'cities': BasicSetCards.supplyCounts['city']!,
        'regions': 24 - 12,
        'draw1': 9,
        'draw2': 9,
        'draw3': 9,
        'draw4': 9,
        'event': 9,
      };

  static final _rng = Random();
}
