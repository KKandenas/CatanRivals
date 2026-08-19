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
      ],
      resources: {
        ResourceType.lumber: 3,
        ResourceType.brick: 1,
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
}
