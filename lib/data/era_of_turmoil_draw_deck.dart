import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';
import 'era_of_gold_cards.dart';
import 'era_of_turmoil_cards.dart';

/// Oroligheternas tids (Era of Turmoil) 28 fysiska kort, uppdelade
/// enligt samma mönster som Gulderan (se [EraOfGoldDrawDeck]):
///
/// - 2× Värdshus sorteras ut FÖRE blandning och läggs i en öppen,
///   "ansikte-upp" hög som båda spelarna kan bygga direkt ifrån genom
///   att betala byggkostnaden (se [faceUpCards]/
///   [GameNotifier.buyFaceUpExpansion]) – blandas alltså aldrig in
///   bland de dolda draghögarna.
/// - 4 händelsekort (Upplopp ×2, plus en extra kopia vardera av
///   Fejd/Brödrafejd) går in i den gemensamma händelsekortsstapeln (se
///   [eventCards]/[EventDeck]).
/// - Resterande 22 kort blandas och delas i 2 jämna 11-korts högar (se
///   [shuffledTwoStacks]), som läggs till grundspelets egna draghögar
///   (då omfördelade till 3 i stället för 4, se [BasicSetDrawDeck]).
///
/// Rövare (action-brigands) återanvänder Gulderans kortdefinition rakt
/// av (bara fler fysiska kopior i Oroligheternas tids egen 28-korsslek,
/// se [EraOfTurmoilCards]-klassdoc) – slås därför upp i [EraOfGoldCards]
/// i stället för [EraOfTurmoilCards] när det inte finns där. Fejd/
/// Brödrafejd slås på motsvarande sätt upp i [BasicSetCards].
class EraOfTurmoilDrawDeck {
  EraOfTurmoilDrawDeck._();

  static final Map<String, GameCard> _ownById = {
    for (final c in EraOfTurmoilCards.all) c.id: c
  };
  static final Map<String, GameCard> _basicById = {
    for (final c in BasicSetCards.all) c.id: c
  };
  static final Map<String, GameCard> _goldById = {
    for (final c in EraOfGoldCards.all) c.id: c
  };

  static GameCard? _templateFor(String id) =>
      _ownById[id] ?? _basicById[id] ?? _goldById[id];

  /// De 2 Värdshus som sorteras ut före blandning, ett per spelare
  /// (index 0 = du/host, index 1 = motståndaren/gästen, se
  /// [GameNotifier._resetDecks]-doc) – se [Player.faceUpExpansionCard].
  static List<GameCard> faceUpCards() {
    const template = EraOfTurmoilCards.hedgeTavern;
    return [
      for (var i = 0; i < 2; i++) template.copyWith(id: '${template.id}-faceup-$i'),
    ];
  }

  /// Oroligheternas tids egna 4 händelsekort – läggs till i den
  /// gemensamma händelsekortsstapeln (se
  /// [EventDeck.shuffledWithYuleFourthFromBottom]).
  static List<GameCard> eventCards() {
    final cards = <GameCard>[];
    EraOfTurmoilCards.supplyCounts.forEach((id, count) {
      if (!id.startsWith('event-')) return;
      final template = _templateFor(id);
      if (template == null) return;
      for (var i = 0; i < count; i++) {
        cards.add(template.copyWith(id: '$id-turmoil-event-$i'));
      }
    });
    return cards;
  }

  static List<GameCard> _drawPoolCards() {
    final cards = <GameCard>[];
    EraOfTurmoilCards.supplyCounts.forEach((id, count) {
      if (id.startsWith('event-')) return;
      // Värdshus går aldrig in i draghögarna – alla fysiska kopior
      // ligger ansikte-upp från start (se [faceUpCards]).
      if (id == EraOfTurmoilCards.hedgeTavern.id) return;
      final template = _templateFor(id);
      if (template == null) return;
      for (var i = 0; i < count; i++) {
        cards.add(template.copyWith(id: '$id-turmoil-draw-$i'));
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
