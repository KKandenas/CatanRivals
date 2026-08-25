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

  /// Grundspelets 8 egna händelsekort (utan Jul, se klassdoc) – en EN
  /// källa till sanning, delad mellan [shuffledWithYuleFourthFromBottom]
  /// och [DuelOfThePrincesSetup] (som kuraterar dem ihop med temasetens
  /// egna INNAN blandning, i stället för att bara lägga till dem som
  /// råa extraCards).
  static List<GameCard> basicEventCards() {
    final cards = <GameCard>[];
    _basicEventIds.forEach((id, count) {
      final template = _byId[id]!;
      for (var i = 0; i < count; i++) {
        cards.add(template.copyWith(id: '$id-draw-$i'));
      }
    });
    return cards;
  }

  static List<GameCard> shuffledWithYuleFourthFromBottom(
      {Random? random, List<GameCard> extraCards = const []}) {
    return shuffledFromCards([...basicEventCards(), ...extraCards],
        random: random);
  }

  /// Blandar [cards] – som redan innehåller ALLA kort som ska vara med,
  /// till skillnad från [shuffledWithYuleFourthFromBottom] som alltid
  /// lägger till grundspelets 8 egna på egen hand – och lägger in Jul
  /// som 4:e kortet räknat från botten, exakt samma ordningslogik som
  /// [shuffledWithYuleFourthFromBottom] (se dess doc). Delad hjälpare
  /// för [DuelOfThePrincesSetup], som bygger en helt egen kortlista
  /// (kuraterad från 15 namngivna kort ner till 6, se dess doc) i
  /// stället för att bara skicka extraCards.
  static List<GameCard> shuffledFromCards(List<GameCard> cards,
      {Random? random}) {
    final rng = random ?? Random();
    final others = List<GameCard>.of(cards)..shuffle(rng);

    final bottomThree = others.sublist(others.length - 3);
    final topRest = others.sublist(0, others.length - 3);
    const yule = BasicSetCards.yule;

    return [...topRest, yule, ...bottomThree];
  }
}
