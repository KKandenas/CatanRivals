import 'dart:math';

import '../models/models.dart';
import 'basic_set_draw_deck.dart';
import 'era_of_gold_draw_deck.dart';
import 'era_of_progress_draw_deck.dart';
import 'era_of_turmoil_draw_deck.dart';
import 'event_deck.dart';

/// "Duel of the Princes" – uppställningen när alla tre temaseten
/// (Gulderan/Oroligheternas tid/Utvecklingens tid) spelas TILLSAMMANS i
/// samma match, regelhäftets sista och mest avancerade variant – till
/// skillnad från det vanliga enda-tema-i-taget-läget
/// (se [GameNotifier._resetDecks]s doc för det, och [LobbyScreen] för
/// hur spelaren väljer det här läget i stället för ett enskilt tema).
///
/// Skiljer sig från enda-tema-läget på fyra sätt:
/// - Segervillkoret är 13 segerpoäng, inte 12 (se
///   [GameState.victoryPointTarget]).
/// - Grundspelet delas fortfarande upp i 3 högar à 12 (se
///   [BasicSetDrawDeck.shuffledStacks]) – precis som med ett enda tema.
/// - VARJE temaset bidrar med EN EGEN blandad hög (i stället för 2, en
///   per spelare) byggd av HELA setets egna kortpool, INKLUSIVE
///   Köpmansgille/Värdshus/Universitet – det finns INGA ansikte-upp-kort
///   i det här läget (se [Player.faceUpExpansionCard]) – MINUS ett
///   förutbestämt urval namngivna kort (se [_goldRemoveCounts]/
///   [_turmoilRemoveCounts]/[_progressRemoveCounts]) som helt plockas
///   bort ur spelet. Ordningen är FAST (Gulderan/Oroligheternas tid/
///   Utvecklingens tid, index 3/4/5 av de 6 högarna) – se
///   [GameNotifier._checkStackMatchesCardOrigin]/[CenterStacksStrip],
///   som båda förutsätter den ordningen.
/// - Händelsekortsstapeln kuraterar 15 särskilt namngivna kort NER till
///   bara 6 slumpmässigt utvalda (se [shuffledEventDeck]) – resten av
///   grundspelets/temasetens händelsekort är precis som vanligt med.
class DuelOfThePrincesSetup {
  DuelOfThePrincesSetup._();

  // ---------------------------------------------------------------------
  // Draghögar
  // ---------------------------------------------------------------------

  static const _goldRemoveCounts = {
    'building-storehouse': 1,
    'building-toll-bridge': 1,
    'unit-large-trade-ship': 1,
    'city-expansion-merchant-guild': 1,
    'city-expansion-harbor': 1,
    'city-expansion-trading-base': 1,
    'city-expansion-mint': 1,
    'city-expansion-staple-house': 1,
    'action-trade-master': 1,
    'action-reiner-the-herald': 1,
    'action-goldsmith': 1,
    'action-brigands': 1,
  };

  static const _turmoilRemoveCounts = {
    'building-drill-ground': 1,
    'hero-carl-forkbeard': 1,
    'hero-irmgard': 1,
    'city-expansion-fairgrounds': 1,
    'city-expansion-hedge-tavern': 1,
    'city-expansion-tithe-barn': 1,
    'city-expansion-fire-brigade': 1,
    'action-voyage-of-plunder': 1,
    'action-archer': 1,
    'action-arsonist': 1,
    'action-sebastian': 1,
    'action-traitor': 1,
  };

  static const _progressRemoveCounts = {
    'unit-chief-cannoneer': 1,
    'city-expansion-town-hall': 1,
    'city-expansion-university': 1,
    'city-expansion-library': 1,
    'city-expansion-pharmacy': 1,
    'city-expansion-bath-house': 1,
    'city-expansion-parliament': 1,
    'action-three-field-system': 1,
    'action-mineral-mining': 1,
    'action-doctor': 1,
    'action-brigitta': 1,
    'action-relocation': 1,
  };

  /// De 6 draghögarna: grundspelets 3 (à 12 kort) följt av EN egen
  /// blandad hög per temaset, i FAST ordning (Gulderan, Oroligheternas
  /// tid, Utvecklingens tid – index 3/4/5, se klassdoc).
  static List<List<GameCard>> shuffledDrawStacks({Random? random}) {
    final rng = random ?? Random();
    final basicStacks =
        BasicSetDrawDeck.shuffledStacks(stackCount: 3, random: rng);
    final gold = EraOfGoldDrawDeck.reducedPoolCards(_goldRemoveCounts)
      ..shuffle(rng);
    final turmoil =
        EraOfTurmoilDrawDeck.reducedPoolCards(_turmoilRemoveCounts)
          ..shuffle(rng);
    final progress =
        EraOfProgressDrawDeck.reducedPoolCards(_progressRemoveCounts)
          ..shuffle(rng);
    return [...basicStacks, gold, turmoil, progress];
  }

  // ---------------------------------------------------------------------
  // Händelsekort
  // ---------------------------------------------------------------------

  static const _basicEventRemoveCounts = {
    'event-year-of-plenty': 1,
    'event-fraternal-feuds': 1,
    'event-feud': 1,
    'event-traveling-merchant': 1,
    'event-trade-ships-race': 1,
  };
  static const _goldEventRemoveCounts = {
    'event-gift-for-the-prince': 1,
    'event-trade-ships-race': 1,
    'event-traveling-merchant': 1,
  };
  static const _turmoilEventRemoveCounts = {
    'event-riots': 1,
    'event-feud': 1,
    'event-fraternal-feuds': 1,
  };
  static const _progressEventRemoveCounts = {
    'event-plague': 2,
    'event-invention': 2,
  };

  /// Delar [cards] (alla fysiska kopior av flera korttyper, från EN
  /// källa) i "med automatiskt" och "kandidat till 15-poolen", enligt
  /// hur många av VARJE korttyp (matchat på [GameCard.baseId] – kopior
  /// av samma typ är sinsemellan utbytbara, så VILKEN specifik kopia
  /// som hamnar var spelar ingen roll) [removeCounts] pekar ut.
  static (List<GameCard>, List<GameCard>) _splitByRemovalCount(
      List<GameCard> cards, Map<String, int> removeCounts) {
    final remaining = Map<String, int>.from(removeCounts);
    final automatic = <GameCard>[];
    final pool = <GameCard>[];
    for (final card in cards) {
      final left = remaining[card.baseId] ?? 0;
      if (left > 0) {
        pool.add(card);
        remaining[card.baseId] = left - 1;
      } else {
        automatic.add(card);
      }
    }
    return (automatic, pool);
  }

  /// Händelsekortsstapeln: de 5 kort som är kvar automatiskt (grund-
  /// spelets/temasetens 20 fysiska händelsekort minus de 15 namngivna,
  /// se [_basicEventRemoveCounts] m.fl.) plus 6 SLUMPMÄSSIGT utvalda av
  /// just de 15 (regelhäftet: "bara 6 av dem ska vara med i spelet") –
  /// resten (9 av 15) är helt borta ur den här matchen. Jul läggs in
  /// som vanligt, 4:e kortet räknat från botten (se
  /// [EventDeck.shuffledFromCards]).
  static List<GameCard> shuffledEventDeck({Random? random}) {
    final rng = random ?? Random();
    final automatic = <GameCard>[];
    final pool = <GameCard>[];
    void addSplit(List<GameCard> cards, Map<String, int> removeCounts) {
      final split = _splitByRemovalCount(cards, removeCounts);
      automatic.addAll(split.$1);
      pool.addAll(split.$2);
    }

    addSplit(EventDeck.basicEventCards(), _basicEventRemoveCounts);
    addSplit(EraOfGoldDrawDeck.eventCards(), _goldEventRemoveCounts);
    addSplit(EraOfTurmoilDrawDeck.eventCards(), _turmoilEventRemoveCounts);
    addSplit(
        EraOfProgressDrawDeck.eventCards(), _progressEventRemoveCounts);

    pool.shuffle(rng);
    final chosen = pool.sublist(0, 6);
    return EventDeck.shuffledFromCards([...automatic, ...chosen],
        random: rng);
  }
}
