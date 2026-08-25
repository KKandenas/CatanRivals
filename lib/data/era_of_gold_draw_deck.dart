import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';
import 'era_of_gold_cards.dart';

/// Gulderans (Era of Gold) 27 fysiska kort, uppdelade i tre delar
/// enligt regelhäftets uppställning för temaset:
///
/// - 2× Köpmansgille sorteras ut FÖRE blandning och läggs i en öppen,
///   "ansikte-upp" hög som båda spelarna kan bygga direkt ifrån genom
///   att betala byggkostnaden (se [faceUpCards]/
///   [GameNotifier.buyFaceUpExpansion]) – blandas alltså aldrig in
///   bland de dolda draghögarna.
/// - 3 händelsekort (Gåva till fursten, plus en extra kopia vardera av
///   Handelsskeppskapplöpning/Handelsresande) går i stället in i den
///   gemensamma händelsekortsstapeln (se [eventCards]/[EventDeck]).
/// - Resterande 22 kort blandas och delas i 2 jämna 11-korts högar
///   (se [shuffledTwoStacks]), som läggs till grundspelets egna
///   draghögar (då omfördelade till 3 i stället för 4, se
///   [BasicSetDrawDeck]).
///
/// Fyra av korttyperna (Guldsmed/Lagerhus/Tullbro/Stora handelsskeppet)
/// återanvänder grundspelets kortdefinition rakt av – bara fler
/// fysiska kopior i Gulderans egen 27-korsslek (se
/// [EraOfGoldCards]-klassdoc) – slås därför upp i [BasicSetCards] i
/// stället för [EraOfGoldCards] när de inte finns där.
class EraOfGoldDrawDeck {
  EraOfGoldDrawDeck._();

  static final Map<String, GameCard> _ownById = {
    for (final c in EraOfGoldCards.all) c.id: c
  };
  static final Map<String, GameCard> _basicById = {
    for (final c in BasicSetCards.all) c.id: c
  };

  static GameCard? _templateFor(String id) => _ownById[id] ?? _basicById[id];

  /// De 2 Köpmansgille som sorteras ut före blandning, ett per spelare
  /// (index 0 = du/host, index 1 = motståndaren/gästen, se
  /// [GameNotifier._resetDecks]-doc) – se [Player.faceUpExpansionCard].
  static List<GameCard> faceUpCards() {
    const template = EraOfGoldCards.merchantGuild;
    return [
      for (var i = 0; i < 2; i++) template.copyWith(id: '${template.id}-faceup-$i'),
    ];
  }

  /// Gulderans egna 3 händelsekort – läggs till i den gemensamma
  /// händelsekortsstapeln (se [EventDeck.shuffledWithYuleFourthFromBottom]).
  static List<GameCard> eventCards() {
    final cards = <GameCard>[];
    EraOfGoldCards.supplyCounts.forEach((id, count) {
      if (!id.startsWith('event-')) return;
      final template = _templateFor(id);
      if (template == null) return;
      for (var i = 0; i < count; i++) {
        cards.add(template.copyWith(id: '$id-gold-event-$i'));
      }
    });
    return cards;
  }

  static List<GameCard> _drawPoolCards() {
    final cards = <GameCard>[];
    EraOfGoldCards.supplyCounts.forEach((id, count) {
      if (id.startsWith('event-')) return;
      // Köpmansgille går aldrig in i draghögarna – alla fysiska kopior
      // ligger ansikte-upp från start (se [faceUpCards]).
      if (id == EraOfGoldCards.merchantGuild.id) return;
      final template = _templateFor(id);
      if (template == null) return;
      for (var i = 0; i < count; i++) {
        cards.add(template.copyWith(id: '$id-gold-draw-$i'));
      }
    });
    return cards;
  }

  /// Blandar de 22 draghögskorten och delar dem i 2 jämna högar (11
  /// vardera).
  static List<List<GameCard>> shuffledTwoStacks({Random? random}) {
    final rng = random ?? Random();
    final cards = _drawPoolCards()..shuffle(rng);
    final half = cards.length ~/ 2;
    return [cards.sublist(0, half), cards.sublist(half)];
  }
}
