import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';

/// Händelsekortsstapeln (regelhäftet s. 5, steg 4–5): grundspelets 9
/// händelsekort, plus – när ett temaset är aktivt – det setets egna
/// händelsekort (se [extraCards], t.ex. Gulderans Gåva till fursten,
/// se [EraOfGoldDrawDeck.eventCards]). Julkortet (Yule) hålls separat,
/// resten blandas, och stapeln byggs underifrån: 3 slumpade kort
/// längst ner, sedan Yule, sedan resten (oavsett hur många det är)
/// överst. Det gör att Yule alltid är det 4:e kortet räknat från
/// botten/slutet av stapeln, oavsett om ett temaset lagt till fler
/// kort.
///
/// Listan här har index 0 = högst upp (dras först).
class EventDeck {
  EventDeck._();

  static const _basicEventIds = {
    'event-feud': 1,
    'event-fraternal-feuds': 1,
    'event-invention': 1,
    'event-trade-ships-race': 1,
    'event-traveling-merchant': 2,
    'event-year-of-plenty': 2,
  };

  static final Map<String, GameCard> _byId = {for (final c in BasicSetCards.all) c.id: c};

  static List<GameCard> shuffledWithYuleFourthFromBottom(
      {Random? random, List<GameCard> extraCards = const []}) {
    final rng = random ?? Random();
    final others = <GameCard>[...extraCards];
    _basicEventIds.forEach((id, count) {
      final template = _byId[id]!;
      for (var i = 0; i < count; i++) {
        others.add(template.copyWith(id: '$id-draw-$i'));
      }
    });
    others.shuffle(rng);

    final bottomThree = others.sublist(others.length - 3);
    final topRest = others.sublist(0, others.length - 3);
    const yule = BasicSetCards.yule;

    return [...topRest, yule, ...bottomThree];
  }
}
