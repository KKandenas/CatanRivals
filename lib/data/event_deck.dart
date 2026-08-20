import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';

/// Grundspelets händelsekortsstapel (regelhäftet s. 5, steg 4–5): de 9
/// händelsekorten som hör till Basic Set. Julkortet (Yule) hålls
/// separat, de andra 8 blandas, och stapeln byggs underifrån: 3
/// slumpade kort längst ner, sedan Yule, sedan de återstående 5
/// slumpade korten överst. Det gör att Yule alltid är det 4:e kortet
/// räknat från botten/slutet av stapeln.
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

  static List<GameCard> shuffledWithYuleFourthFromBottom({Random? random}) {
    final rng = random ?? Random();
    final others = <GameCard>[];
    _basicEventIds.forEach((id, count) {
      final template = _byId[id]!;
      for (var i = 0; i < count; i++) {
        others.add(template.copyWith(id: '$id-draw-$i'));
      }
    });
    others.shuffle(rng);

    final bottomThree = others.sublist(5, 8);
    final topFive = others.sublist(0, 5);
    const yule = BasicSetCards.yule;

    return [...topFive, yule, ...bottomThree];
  }
}
