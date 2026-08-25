import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';
import 'era_of_progress_cards.dart';

/// Utvecklingens tids (Era of Progress) 31 fysiska kort, uppdelade
/// enligt samma mönster som Gulderan/Oroligheternas tid (se
/// [EraOfGoldDrawDeck]/[EraOfTurmoilDrawDeck]):
///
/// - 2× Universitet sorteras ut FÖRE blandning och läggs i en öppen,
///   "ansikte-upp" hög som båda spelarna kan bygga direkt ifrån genom
///   att betala byggkostnaden (se [faceUpCards]/
///   [GameNotifier.buyFaceUpExpansion]) – blandas alltså aldrig in
///   bland de dolda draghögarna.
/// - 5 händelsekort (Pest ×3, plus 2 extra kopior av Uppfinning) går in
///   i den gemensamma händelsekortsstapeln (se [eventCards]/
///   [EventDeck]).
/// - Resterande 24 kort blandas och delas i 2 jämna 12-korts högar (se
///   [shuffledTwoStacks]), som läggs till grundspelets egna draghögar
///   (då omfördelade till 3 i stället för 4, se [BasicSetDrawDeck]).
///
/// Brigitta den visa kvinnan/Omlokalisering (action-brigitta/action-
/// relocation) och Uppfinning (event-invention) återanvänder
/// grundspelets kortdefinition rakt av (bara fler fysiska kopior i det
/// här setets egen 31-korsslek, se [EraOfProgressCards]-klassdoc) –
/// slås därför upp i [BasicSetCards] i stället för [EraOfProgressCards]
/// när de inte finns där.
class EraOfProgressDrawDeck {
  EraOfProgressDrawDeck._();

  static final Map<String, GameCard> _ownById = {
    for (final c in EraOfProgressCards.all) c.id: c
  };
  static final Map<String, GameCard> _basicById = {
    for (final c in BasicSetCards.all) c.id: c
  };

  static GameCard? _templateFor(String id) => _ownById[id] ?? _basicById[id];

  /// De 2 Universitet som sorteras ut före blandning, ett per spelare
  /// (index 0 = du/host, index 1 = motståndaren/gästen, se
  /// [GameNotifier._resetDecks]-doc) – se [Player.faceUpExpansionCard].
  static List<GameCard> faceUpCards() {
    const template = EraOfProgressCards.university;
    return [
      for (var i = 0; i < 2; i++) template.copyWith(id: '${template.id}-faceup-$i'),
    ];
  }

  /// Utvecklingens tids egna 5 händelsekort – läggs till i den
  /// gemensamma händelsekortsstapeln (se
  /// [EventDeck.shuffledWithYuleFourthFromBottom]).
  static List<GameCard> eventCards() {
    final cards = <GameCard>[];
    EraOfProgressCards.supplyCounts.forEach((id, count) {
      if (!id.startsWith('event-')) return;
      final template = _templateFor(id);
      if (template == null) return;
      for (var i = 0; i < count; i++) {
        cards.add(template.copyWith(id: '$id-progress-event-$i'));
      }
    });
    return cards;
  }

  static List<GameCard> _drawPoolCards() {
    final cards = <GameCard>[];
    EraOfProgressCards.supplyCounts.forEach((id, count) {
      if (id.startsWith('event-')) return;
      // Universitet går aldrig in i draghögarna – alla fysiska kopior
      // ligger ansikte-upp från start (se [faceUpCards]).
      if (id == EraOfProgressCards.university.id) return;
      final template = _templateFor(id);
      if (template == null) return;
      for (var i = 0; i < count; i++) {
        cards.add(template.copyWith(id: '$id-progress-draw-$i'));
      }
    });
    return cards;
  }

  /// Blandar de 24 draghögskorten och delar dem i 2 jämna högar (12
  /// vardera).
  static List<List<GameCard>> shuffledTwoStacks({Random? random}) {
    final rng = random ?? Random();
    final cards = _drawPoolCards()..shuffle(rng);
    final half = cards.length ~/ 2;
    return [cards.sublist(0, half), cards.sublist(half)];
  }

  /// Duel of the Princes ("Alla expansioner", se
  /// [DuelOfThePrincesSetup]-klassdoc): EN oblandad kortpool av
  /// Utvecklingens tids EGNA kort – till skillnad från [_drawPoolCards]
  /// utesluts INTE Universitet här (det finns inga ansikte-upp-kort i
  /// det här läget), bara det antal [removeCounts] (nyckel =
  /// [GameCard.baseId]) pekar ut plockas bort innan resten fyller
  /// poolen.
  static List<GameCard> reducedPoolCards(Map<String, int> removeCounts) {
    final cards = <GameCard>[];
    EraOfProgressCards.supplyCounts.forEach((id, count) {
      if (id.startsWith('event-')) return;
      final reduced = count - (removeCounts[id] ?? 0);
      if (reduced <= 0) return;
      final template = _templateFor(id);
      if (template == null) return;
      for (var i = 0; i < reduced; i++) {
        cards.add(template.copyWith(id: '$id-progress-draw-$i'));
      }
    });
    return cards;
  }
}
