import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Vilket "läge" spelet just nu är i.
///
/// [local] – ingen nätverkssynk, två spelare turas om på samma iPad
/// (eller mock-data innan ett rum finns). [host]/[guest] – anslutet till
/// ett Firebase-rum, antingen som den som skapade det eller den som gick
/// med.
enum SessionMode { local, host, guest }

/// Handkortsjustering i slutet av action-fasen (regelhäftet s. 9): du
/// ska ha exakt [GameState.handLimit] kort på hand innan turen går
/// vidare – för få och du drar, för många och du slänger.
/// [none] – ingen justering pågår (antingen redan klar, eller väntar på
/// att action-fasen avslutas). [drawing]/[discarding] – väntar på att
/// du drar från/slänger till en av de fyra draghögarna, en i taget.
enum HandAdjustmentPhase { none, drawing, discarding }

/// Kortbytesfasen, sist i din omgång efter att handen är justerad
/// (regelhäftet s. 9: "Trading cards"). Tre val: låt handen vara,
/// byt ett kort gratis, eller betala för att kika i en hel stapel.
///
/// [none] – inte i bytesfasen. [choosing] – väljer ett av de tre
/// alternativen. [exchangeDiscard]/[exchangeDraw] – det gratis bytet:
/// slänger först ett handkort till valfri stapel, drar sedan ett kort
/// från toppen av valfri (kanske annan) stapel. [peekPaying] –
/// betalar 2 valfria resurser (självbevakat, precis som
/// byggkostnader). [peekDiscard] – slänger, precis som det gratis
/// bytet, ett handkort till valfri stapel (annars skulle handen växa
/// med ett kort utan motsvarande byte). [peekChoosingStack] – väljer
/// vilken stapel att kika i. [peekViewing] – alla kort i den valda
/// stapeln visas, ett tryck väljer vilket du behåller (resten läggs
/// tillbaka i samma ordning – se [GameNotifier.peekTakeCard]).
enum TradePhase {
  none,
  choosing,
  exchangeDiscard,
  exchangeDraw,
  peekPaying,
  peekDiscard,
  peekChoosingStack,
  peekViewing,
}

/// Allt UI:t behöver rendera spelbrädet: de två spelarna, hur många
/// kort som återstår i center-dragstaplarna, och (om något) vilket
/// kort som just nu dras – används för att tända giltiga rutor.
///
/// Rent state-innehav – själva spelreglerna/mutationerna bor i
/// [GameNotifier] (game_notifier.dart).
@immutable
class GameState {
  final Player you;
  final Player opponent;
  final Map<String, int> centerStacks;
  final GameCard? draggingCard;

  /// Vilka temaset (utöver grundspelet) som är aktiva i den här matchen –
  /// satt en gång vid `hostRoom`/`playLocally` (gästen ärver hostens val
  /// via `joinRoom`/rummets state, se [GameNotifier]) och sedan oförändrat
  /// resten av matchen. Tom mängd = rent grundspel (allt beteende som
  /// idag). Styr bl.a. segervillkoret ([victoryPointTarget]) och hur
  /// draghögarna byggs upp vid start.
  final Set<ExpansionSet> activeExpansions;

  /// Slänghögen: spelade handlingskort och byggnader/enheter/skepp som
  /// bytts ut mot ett nytt kort på samma plats (se
  /// [GameNotifier._discardToPile]) – senast tillagda kortet sist/överst.
  /// Delad mellan spelarna (inte per spelare), bara det översta kortet
  /// visas i UI:t (se [DiscardPileView]) men hela listan finns här så
  /// att framtida kort (Gustav bibliotekarien/Guido ambassadören, se
  /// era_of_progress_cards.dart) kan välja fritt bland alla.
  final List<GameCard> discardPile;

  final SessionMode mode;
  final String? roomCode;
  final String myPlayerId;
  final String opponentPlayerId;
  final bool opponentConnected;
  final String? sessionError;

  /// Vems tur det är just nu (regelhäftet s. 7). Röd går alltid först
  /// – matchar samma förenkling som starthandsvalet ([pendingHandChooserId]).
  final String activePlayerId;

  /// Om den aktiva spelaren redan slagit tärningarna den här omgången.
  /// Produktions- och händelsetärningen slås samtidigt (se
  /// [EventDieFace]) – [eventDieFace] är `null` bara innan första
  /// kastet någonsin.
  final bool diceRolled;
  final int? productionRoll;
  final EventDieFace? eventDieFace;

  /// Två nya, ännu oplacerade regionkort som en ny by längst ut i
  /// kedjan just gett dig (regelhäftet s. 8) – tomma tills du dragit
  /// vardera kortet till platsen ovanför/nedanför den nya byn (se
  /// [GameNotifier.placePendingRegion]). `pendingRegionJunction` är
  /// knutpunkten de hör hemma i.
  final List<GameCard> pendingRegions;
  final int? pendingRegionJunction;

  /// Om du just nu håller på att justera din hand till [handLimit] kort
  /// innan turen går vidare (se [HandAdjustmentPhase]).
  final HandAdjustmentPhase handAdjustmentPhase;

  /// Spelar-id:t för den som just nu har "Hero Token"/"Trade Token" –
  /// bricken som ger 1 extra segerpoäng till den med minst 3 styrke-
  /// respektive handelspoäng, och fler än motståndaren (se
  /// [GameNotifier.recomputeTokenHolders]). `null` = ingen ("banken").
  final String? heroTokenHolder;
  final String? tradeTokenHolder;

  /// Var i kortbytesfasen du är just nu (se [TradePhase]).
  final TradePhase tradePhase;

  /// Vilken draghög ([peekStackIndex], 0–3) som just nu ligger uppslagen
  /// framför dig under [TradePhase.peekViewing], och alla dess kort i
  /// den ordning de faktiskt ligger i högen (så att de kan läggas
  /// tillbaka i exakt samma ordning – regelhäftet kräver det).
  final int? peekStackIndex;
  final List<GameCard>? peekedCards;

  /// Vilken draghög (0–3) som just nu kikas i, synkat (se
  /// [TurnState.peekingStackIndex]/[GameNotifier.choosePeekStack]) så
  /// att MOTSTÅNDAREN till den som kikar kan se vilken hög det gäller
  /// – bara index, aldrig vilka kort som faktiskt ligger där (det
  /// avslöjas aldrig, till skillnad från [peekedCards] som bara den
  /// kikande spelaren själv ser). Motsvarar att man vid ett fysiskt
  /// bord ser motståndaren plocka upp och läsa en specifik hög utan
  /// att se innehållet. `null` när ingen kikar.
  final int? peekingStackIndex;

  /// Id på spelaren som vunnit (regelhäftet: 7 eller fler segerpoäng
  /// vid slutet av sin egen runda, se [totalVictoryPointsFor]), synkat
  /// (se [TurnState.winnerId]/[GameNotifier._advanceToNextPlayer]).
  /// `null` så länge ingen vunnit. Turen lämnas medvetet INTE över när
  /// det här sätts – spelet fryser i vinnarens slutställning, se
  /// [GameOverOverlay] i game_board_screen.dart.
  final String? winnerId;

  /// Om DU (den icke aktiva spelaren) måste välja bort ett eget
  /// handelsskepp (Piratskepp, se [TurnState.pirateShipDiscardPending]/
  /// [GameNotifier.resolvePirateShipDiscard]) – synkat via [TurnState],
  /// eftersom det (till skillnad från Fejd) triggas av ett engångsbygge
  /// som motståndarens klient inte kan räkna ut på egen hand.
  final bool pirateShipDiscardPending;

  /// Om Reiner härolden spelades för att framtvinga den här omgångens
  /// Fest-utfall, se [TurnState.reinerHeraldUsed] – synkat via
  /// [TurnState] av samma skäl som [pirateShipDiscardPending]. Läses av
  /// `_resolveCelebration` för att lägga till en rad i
  /// DiceRollSummaryBanner-popupen om vem som spelade kortet.
  final bool reinerHeraldUsed;

  /// Vilka spelar-id:n som redan avslutat sin egen Upplopp-hantering
  /// för det just nu uppslagna händelsekortet, se
  /// [TurnState.riotsResolvedPlayerIds] – synkat via [TurnState] av
  /// samma skäl som [pirateShipDiscardPending].
  final Set<String> riotsResolvedPlayerIds;

  /// Upplopp (regelhäftet: "must remove one of these units") när du
  /// inte betalar guldet – riket blir tryckbart: tryck på en av dina
  /// egna enheter med styrke- eller handelspoäng (byggnad, skepp eller
  /// hjälte) för att ta bort den (se
  /// [GameNotifier.selectRiotsUnit]/[riotsQualifyingUnitCount]). Rent
  /// lokalt UI-state, precis som [feudBuildingPickActive] – bara den
  /// egna klienten som faktiskt väljer behöver veta om det.
  /// [riotsPickedUnit] är den valda platsen, `null` tills något
  /// tryckts – då väntar bara valet av vilken draghög den ska läggas
  /// underst i (se [GameNotifier.resolveRiotsUnitRemoval]).
  final bool riotsUnitPickActive;
  final RelocationSelection? riotsPickedUnit;

  /// Vilket attackkort (Bågskytt/Pyroman) som väntar på att DU (den
  /// drabbade, dvs [pendingAttackCard] bara betyder något om det INTE
  /// är din tur) ska välja bort en egen kvalificerande enhet, se
  /// [TurnState.pendingAttackCard]-doc – synkat via [TurnState] av
  /// samma skäl som [pirateShipDiscardPending].
  final AttackCardKind? pendingAttackCard;

  /// Den redan valda platsen under [pendingAttackCard]s enhetsval –
  /// `null` tills något tryckts, precis som [riotsPickedUnit] (rent
  /// lokalt UI-state, bara den drabbade klienten som väljer behöver
  /// veta om det).
  final RelocationSelection? attackCardPickedUnit;

  /// Vilka spelar-id:n som spelat Sebastian, den vandrande predikanten
  /// för att skydda sig mot det just nu uppslagna händelsekortet, se
  /// [TurnState.sebastianProtectedPlayerIds]-doc – synkat via
  /// [TurnState] av samma skäl som [pirateShipDiscardPending].
  final Set<String> sebastianProtectedPlayerIds;

  /// Vilket attackkort (baseId) som väntar på att DU (om du har
  /// Vakttorn) ska slå tärningen för att eventuellt avvärja det, se
  /// [TurnState.pendingDefenseRollCard]-doc – synkat via [TurnState] av
  /// samma skäl som [pirateShipDiscardPending].
  final String? pendingDefenseRollCard;

  /// Händelsekortet som just nu ligger uppslaget för alla att läsa,
  /// draget när händelsetärningen visade "?" (se [EventDieFace.eventCard]
  /// och [GameNotifier.drawEventCard]) – synkas till båda spelarna,
  /// `null` när inget är uppslaget.
  final GameCard? drawnEventCard;

  /// Om en nybyggd by (bortom rikets yttergräns, se [pendingRegions])
  /// just väckt frågan "Vill du använda Spejare?" – bara sant om
  /// spelaren har kortet på hand (regelhäftet: "Play this card when
  /// building a settlement"). Rent lokalt UI-state (bara den aktiva
  /// spelaren, alltså du själv, kan se/svara på frågan).
  final bool awaitingScoutDecision;

  /// Hela den kvarvarande regionstapeln, öppen för fritt val, medan
  /// Spejare används (se [GameNotifier.useScout]/[pickScoutRegion]) –
  /// `null` när frågan bara väntar på ja/nej ([awaitingScoutDecision])
  /// eller inte alls är aktuell.
  final List<GameCard>? scoutChoices;

  /// Om Omlokalisering just nu är aktiv (se
  /// [GameNotifier.startRelocation]) – riket blir då tryckbart: tryck
  /// på 2 av dina egna regioner (eller 2 av dina egna bygg-/enhetskort,
  /// aldrig blandat) för att byta plats på dem. [relocationFirst] är
  /// det första valet, `null` tills något tryckts.
  final bool relocationActive;
  final RelocationSelection? relocationFirst;

  /// Fejd (regelhäftet: "the opponent must remove one of them"): du är
  /// den utan styrkeövertaget och riket blir tryckbart – tryck på en
  /// av dina egna byggnader (inte skepp/hjältar) för att ta bort den
  /// (se [GameNotifier.selectFeudBuilding]/[strengthAdvantagePlayerId]).
  /// [feudPickedBuilding] är den valda platsen, `null` tills något
  /// tryckts – då väntar bara valet av vilken draghög den ska läggas
  /// underst i (se [GameNotifier.resolveFeudBuildingRemoval]).
  final bool feudBuildingPickActive;
  final RelocationSelection? feudPickedBuilding;

  /// Brödrafejd (regelhäftet: "selects 2 cards from the opponent's
  /// hand") – se [GameNotifier.startFraternalFeudsPick]/
  /// [GameNotifier.pickFraternalFeudsCard]. [fraternalFeudsPicked]
  /// samlar de redan valda korten (0–2) medan [fraternalFeudsPicking]
  /// är sant; [fraternalFeudsPickedStacks] samlar vilken draghög (0–3)
  /// varje motsvarande kort i [fraternalFeudsPicked] ska läggas underst
  /// i – bara relevant online (se [FraternalFeudsRequest]), där båda
  /// picken måste vara kända innan förfrågan kan skickas i väg i ett
  /// enda steg (lokalt muteras motståndarens hand/draghög direkt, kort
  /// för kort, i stället).
  final bool fraternalFeudsPicking;
  final List<GameCard> fraternalFeudsPicked;
  final List<int> fraternalFeudsPickedStacks;

  /// Förrädare (Oroligheternas tid, regelhäftet: "man får titta på
  /// motståndarens kort de har på handen och välja ett som läggs till
  /// den egna handen") – se [GameNotifier.useTraitor]/
  /// [GameNotifier.pickTraitorCard], sant tills ett kort valts eller
  /// flödet avbryts. Synkat via [TurnState] (se
  /// [TurnState.traitorPicking]-doc) – till skillnad från
  /// [fraternalFeudsPicking] kan Vakttorn (se [pendingDefenseRollCard])
  /// göra att det är FÖRSVARARENS tärningsslag, inte du själv, som
  /// avgör om du faktiskt får gå vidare hit.
  final bool traitorPicking;

  /// Starthandsutdelningen (regelhäftet s. 6) när ett tema är aktivt (se
  /// [GameNotifier.startHandDraft]/[GameNotifier.pickHandDraftCard]):
  /// spelaren väljer en av de tre grundspelshögarna, ser ALLA dess kort
  /// ([startingHandDraftPool]), och plockar ut 3 ett i taget – resten
  /// läggs tillbaka i exakt samma inbördes ordning. [startingHandDraftPool]
  /// är `null` när ingen utdelning pågår (antingen inte startad, eller
  /// redan klar). Rent lokalt UI-state, aldrig synkat till motståndaren
  /// – se [GameNotifier.startHandDraft]s doc för vad det innebär vid en
  /// sidladdning mitt i.
  final int? startingHandDraftStackIndex;
  final List<GameCard>? startingHandDraftPool;
  final List<GameCard> startingHandDraftPicked;

  /// Fri regionomflyttning direkt efter starthandsutdelningen med ett
  /// tema aktivt (bekräftad regel: "Fri omflyttning av egna 6
  /// regioner") – ett tredje, parallellt väljarläge till
  /// [relocationActive]/[feudBuildingPickActive] (se
  /// [GameNotifier.selectRegionRearrangementTarget]/
  /// [GameNotifier.finishRegionRearrangement]), medvetet INTE
  /// samma fält som Omlokaliseringen eftersom den är knuten till ett
  /// fysiskt kort och till [GameNotifier._checkCanBuild]s tur-/
  /// tärningsspärrar, som inte gäller före första tärningsslaget.
  /// [Player.hasDrawnStartingHand] sätts först när fasen avslutas
  /// explicit (se [GameNotifier.finishRegionRearrangement]), inte
  /// redan vid tredje kortvalet – se pickHandDraftCards doc.
  final bool startingRegionRearrangementActive;
  final RelocationSelection? startingRegionRearrangementFirst;

  const GameState({
    required this.you,
    required this.opponent,
    required this.centerStacks,
    this.draggingCard,
    this.activeExpansions = const {},
    this.discardPile = const [],
    this.mode = SessionMode.local,
    this.roomCode,
    this.myPlayerId = 'you',
    this.opponentPlayerId = 'opponent',
    this.opponentConnected = false,
    this.sessionError,
    this.activePlayerId = 'you',
    this.diceRolled = false,
    this.productionRoll,
    this.eventDieFace,
    this.pendingRegions = const [],
    this.pendingRegionJunction,
    this.handAdjustmentPhase = HandAdjustmentPhase.none,
    this.heroTokenHolder,
    this.tradeTokenHolder,
    this.tradePhase = TradePhase.none,
    this.peekStackIndex,
    this.peekedCards,
    this.peekingStackIndex,
    this.winnerId,
    this.pirateShipDiscardPending = false,
    this.reinerHeraldUsed = false,
    this.riotsResolvedPlayerIds = const {},
    this.riotsUnitPickActive = false,
    this.riotsPickedUnit,
    this.pendingAttackCard,
    this.attackCardPickedUnit,
    this.sebastianProtectedPlayerIds = const {},
    this.pendingDefenseRollCard,
    this.drawnEventCard,
    this.awaitingScoutDecision = false,
    this.scoutChoices,
    this.relocationActive = false,
    this.relocationFirst,
    this.feudBuildingPickActive = false,
    this.feudPickedBuilding,
    this.fraternalFeudsPicking = false,
    this.fraternalFeudsPicked = const [],
    this.fraternalFeudsPickedStacks = const [],
    this.traitorPicking = false,
    this.startingHandDraftStackIndex,
    this.startingHandDraftPool,
    this.startingHandDraftPicked = const [],
    this.startingRegionRearrangementActive = false,
    this.startingRegionRearrangementFirst,
  });

  bool get isOnline => mode != SessionMode.local;

  /// I lokalt läge (samma iPad) finns ingen verklig spärr mot vem som
  /// får slå/avsluta omgången – det är samma enhet. Online gäller den
  /// riktiga tur-spärren.
  bool get isMyTurn => !isOnline || activePlayerId == myPlayerId;

  /// Om DU faktiskt är den aktiva spelaren just nu – till skillnad från
  /// [isMyTurn] (som alltid är sant lokalt, eftersom det inte finns
  /// någon riktig spärr mellan två spelare på samma enhet), används den
  /// här för turvisning (banner/ram/nedtoning): den ska visa det
  /// verkliga läget även lokalt.
  bool get activePlayerIsMe => activePlayerId == myPlayerId;

  /// Om du får bygga/köpa just nu (regelhäftet s. 7: bara den aktiva
  /// spelaren, och bara efter att produktionstärningen är slagen).
  bool get canBuildNow => isMyTurn && diceRolled;

  /// Som [canBuildNow], men speglar även [GameNotifier._checkCanBuild]s
  /// övriga spärrar (väntande regionval, Spejare-frågan, Omlokalisering,
  /// handjustering, kortbytesfasen) – styr om vägar/byar/städer och
  /// byggkort över huvud taget går att dra/släppa just nu (se
  /// [HandDock]/[CenterStacksStrip]), i stället för att man ska behöva
  /// försöka och få ett felmeddelande efteråt.
  bool get canBuildRightNow =>
      canBuildNow &&
      pendingRegions.isEmpty &&
      !awaitingScoutDecision &&
      !relocationActive &&
      handAdjustmentPhase == HandAdjustmentPhase.none &&
      tradePhase == TradePhase.none;

  /// Spelar-id:t för den som just nu har flest styrkepoäng (styrke-
  /// övertaget, regelhäftets krav på flera handlings-/händelsekort som
  /// Fejd/Brödrafejd/Rövare) – till skillnad från [heroTokenHolder]
  /// finns ingen minimigräns på 3 poäng, bara ett rakt övertag. `null`
  /// vid oavgjort (ingen har övertaget).
  String? get strengthAdvantagePlayerId {
    final yours = you.principality.totalStrengthPoints;
    final theirs = opponent.principality.totalStrengthPoints;
    if (yours == theirs) return null;
    return yours > theirs ? myPlayerId : opponentPlayerId;
  }

  /// Röd/blå-tillhörighet härleds från spelar-id:t (satt av
  /// [GameNotifier.hostRoom]/[joinRoom]/mock-datan): host/"you" är
  /// alltid röd, guest/"opponent" är alltid blå – matchar vilken
  /// startuppställning ([StarterCards]) spelaren fick.
  bool get amIRed => myPlayerId == 'host' || myPlayerId == 'you';

  Player get _redPlayer => amIRed ? you : opponent;
  Player get _bluePlayer => amIRed ? opponent : you;

  /// Vem som ska ta sina 3 starthandkort härnäst (regelhäftet s. 6: den
  /// röda/startande spelaren väljer en draghög och tar de tre översta
  /// korten, sedan väljer den andra spelaren en annan hög). `null` när
  /// båda redan har dragit. Röd går alltid först – riktig tärningsslag
  /// för att avgöra startspelare är inte byggt än.
  String? get pendingHandChooserId {
    if (!_redPlayer.hasDrawnStartingHand) return _redPlayer.id;
    if (!_bluePlayer.hasDrawnStartingHand) return _bluePlayer.id;
    return null;
  }

  bool get isMyTurnToChooseHand => pendingHandChooserId == myPlayerId;

  bool get handsReady => pendingHandChooserId == null;

  /// Antal handkort du ska ha när action-fasen avslutas (regelhäftet
  /// s. 9): 3 som grund, plus 1 per framstegspoäng du har i spel.
  int get handLimit => you.principality.totalProgressPoints + 3;

  /// Hur många segerpoäng som krävs för att vinna (regelhäftet: 7 i
  /// grundspelet, men 12 så fort minst ett temaset är aktivt – fler
  /// byggmöjligheter gör 7 poäng för lätt uppnått). Enda stället det här
  /// jämförs är [GameNotifier._advanceToNextPlayer].
  int get victoryPointTarget => activeExpansions.isEmpty ? 7 : 12;

  /// Hur många kort respektive draghög startar med (innan någon dragit
  /// ur den) – grundspelets 36 kort delas på 4 högar (9 vardera) utan
  /// tema, men på 3 högar (12 vardera) när ett temaset är aktivt (se
  /// [GameNotifier._resetDecks]), plus 2 högar till med temasetets egna
  /// draghögskort: Gulderans 22 (11 vardera, efter att 2 Köpmansgille
  /// sorterats ut till ansikte-upp-högen) och Oroligheternas tids 22
  /// (11 vardera, efter att 2 Värdshus sorterats ut på samma sätt)
  /// respektive Utvecklingens tids 24 (12 vardera, efter att 2
  /// Universitet sorterats ut – setet har fler fysiska kort totalt) –
  /// de tre temaseten kombineras aldrig i samma match, se
  /// [LobbyScreen]. Används för att avgöra om en hög redan är vald
  /// under starthandsvalet (se [CenterStacksStrip]/
  /// [GameNotifier.chooseStartingStack]) – kan inte bara jämföra mot ett
  /// hårdkodat 9 längre nu när högstorleken varierar beroende på tema.
  List<int> get initialDrawStackSizes {
    if (activeExpansions.contains(ExpansionSet.eraOfGold) ||
        activeExpansions.contains(ExpansionSet.eraOfTurmoil)) {
      return const [12, 12, 12, 11, 11];
    }
    if (activeExpansions.contains(ExpansionSet.eraOfProgress)) {
      return const [12, 12, 12, 12, 12];
    }
    return const [9, 9, 9, 9];
  }

  /// [player]s totala segerpoäng: poängen från riket plus 1 vardera om
  /// spelaren just nu har Hero Token/Trade Token (se
  /// [GameNotifier.recomputeTokenHolders]).
  int totalVictoryPointsFor(Player player) {
    var total = player.principality.totalVictoryPoints;
    if (heroTokenHolder == player.id) total += 1;
    if (tradeTokenHolder == player.id) total += 1;
    return total;
  }

  GameState copyWith({
    Player? you,
    Player? opponent,
    Map<String, int>? centerStacks,
    GameCard? draggingCard,
    bool clearDraggingCard = false,
    Set<ExpansionSet>? activeExpansions,
    List<GameCard>? discardPile,
    SessionMode? mode,
    String? roomCode,
    String? myPlayerId,
    String? opponentPlayerId,
    bool? opponentConnected,
    String? sessionError,
    bool clearSessionError = false,
    String? activePlayerId,
    bool? diceRolled,
    int? productionRoll,
    bool clearProductionRoll = false,
    EventDieFace? eventDieFace,
    bool clearEventDieFace = false,
    List<GameCard>? pendingRegions,
    int? pendingRegionJunction,
    bool clearPendingRegionJunction = false,
    HandAdjustmentPhase? handAdjustmentPhase,
    String? heroTokenHolder,
    bool clearHeroTokenHolder = false,
    String? tradeTokenHolder,
    bool clearTradeTokenHolder = false,
    TradePhase? tradePhase,
    int? peekStackIndex,
    bool clearPeekStackIndex = false,
    List<GameCard>? peekedCards,
    bool clearPeekedCards = false,
    int? peekingStackIndex,
    bool clearPeekingStackIndex = false,
    String? winnerId,
    bool? pirateShipDiscardPending,
    bool? reinerHeraldUsed,
    Set<String>? riotsResolvedPlayerIds,
    bool? riotsUnitPickActive,
    RelocationSelection? riotsPickedUnit,
    bool clearRiotsPickedUnit = false,
    AttackCardKind? pendingAttackCard,
    bool clearPendingAttackCard = false,
    RelocationSelection? attackCardPickedUnit,
    bool clearAttackCardPickedUnit = false,
    Set<String>? sebastianProtectedPlayerIds,
    String? pendingDefenseRollCard,
    bool clearPendingDefenseRollCard = false,
    GameCard? drawnEventCard,
    bool clearDrawnEventCard = false,
    bool? awaitingScoutDecision,
    List<GameCard>? scoutChoices,
    bool clearScoutChoices = false,
    bool? relocationActive,
    RelocationSelection? relocationFirst,
    bool clearRelocationFirst = false,
    bool? feudBuildingPickActive,
    RelocationSelection? feudPickedBuilding,
    bool clearFeudPickedBuilding = false,
    bool? fraternalFeudsPicking,
    List<GameCard>? fraternalFeudsPicked,
    List<int>? fraternalFeudsPickedStacks,
    bool? traitorPicking,
    int? startingHandDraftStackIndex,
    bool clearStartingHandDraftStackIndex = false,
    List<GameCard>? startingHandDraftPool,
    bool clearStartingHandDraftPool = false,
    List<GameCard>? startingHandDraftPicked,
    bool? startingRegionRearrangementActive,
    RelocationSelection? startingRegionRearrangementFirst,
    bool clearStartingRegionRearrangementFirst = false,
  }) {
    return GameState(
      you: you ?? this.you,
      opponent: opponent ?? this.opponent,
      centerStacks: centerStacks ?? this.centerStacks,
      draggingCard:
          clearDraggingCard ? null : (draggingCard ?? this.draggingCard),
      activeExpansions: activeExpansions ?? this.activeExpansions,
      discardPile: discardPile ?? this.discardPile,
      mode: mode ?? this.mode,
      roomCode: roomCode ?? this.roomCode,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      opponentPlayerId: opponentPlayerId ?? this.opponentPlayerId,
      opponentConnected: opponentConnected ?? this.opponentConnected,
      sessionError:
          clearSessionError ? null : (sessionError ?? this.sessionError),
      activePlayerId: activePlayerId ?? this.activePlayerId,
      diceRolled: diceRolled ?? this.diceRolled,
      productionRoll:
          clearProductionRoll ? null : (productionRoll ?? this.productionRoll),
      eventDieFace:
          clearEventDieFace ? null : (eventDieFace ?? this.eventDieFace),
      pendingRegions: pendingRegions ?? this.pendingRegions,
      pendingRegionJunction: clearPendingRegionJunction
          ? null
          : (pendingRegionJunction ?? this.pendingRegionJunction),
      handAdjustmentPhase: handAdjustmentPhase ?? this.handAdjustmentPhase,
      heroTokenHolder: clearHeroTokenHolder
          ? null
          : (heroTokenHolder ?? this.heroTokenHolder),
      tradeTokenHolder: clearTradeTokenHolder
          ? null
          : (tradeTokenHolder ?? this.tradeTokenHolder),
      tradePhase: tradePhase ?? this.tradePhase,
      peekStackIndex:
          clearPeekStackIndex ? null : (peekStackIndex ?? this.peekStackIndex),
      peekedCards: clearPeekedCards ? null : (peekedCards ?? this.peekedCards),
      peekingStackIndex: clearPeekingStackIndex
          ? null
          : (peekingStackIndex ?? this.peekingStackIndex),
      winnerId: winnerId ?? this.winnerId,
      pirateShipDiscardPending:
          pirateShipDiscardPending ?? this.pirateShipDiscardPending,
      reinerHeraldUsed: reinerHeraldUsed ?? this.reinerHeraldUsed,
      riotsResolvedPlayerIds:
          riotsResolvedPlayerIds ?? this.riotsResolvedPlayerIds,
      riotsUnitPickActive: riotsUnitPickActive ?? this.riotsUnitPickActive,
      riotsPickedUnit: clearRiotsPickedUnit
          ? null
          : (riotsPickedUnit ?? this.riotsPickedUnit),
      pendingAttackCard: clearPendingAttackCard
          ? null
          : (pendingAttackCard ?? this.pendingAttackCard),
      attackCardPickedUnit: clearAttackCardPickedUnit
          ? null
          : (attackCardPickedUnit ?? this.attackCardPickedUnit),
      sebastianProtectedPlayerIds:
          sebastianProtectedPlayerIds ?? this.sebastianProtectedPlayerIds,
      pendingDefenseRollCard: clearPendingDefenseRollCard
          ? null
          : (pendingDefenseRollCard ?? this.pendingDefenseRollCard),
      drawnEventCard: clearDrawnEventCard
          ? null
          : (drawnEventCard ?? this.drawnEventCard),
      awaitingScoutDecision:
          awaitingScoutDecision ?? this.awaitingScoutDecision,
      scoutChoices:
          clearScoutChoices ? null : (scoutChoices ?? this.scoutChoices),
      relocationActive: relocationActive ?? this.relocationActive,
      relocationFirst: clearRelocationFirst
          ? null
          : (relocationFirst ?? this.relocationFirst),
      feudBuildingPickActive:
          feudBuildingPickActive ?? this.feudBuildingPickActive,
      feudPickedBuilding: clearFeudPickedBuilding
          ? null
          : (feudPickedBuilding ?? this.feudPickedBuilding),
      fraternalFeudsPicking:
          fraternalFeudsPicking ?? this.fraternalFeudsPicking,
      fraternalFeudsPicked:
          fraternalFeudsPicked ?? this.fraternalFeudsPicked,
      fraternalFeudsPickedStacks:
          fraternalFeudsPickedStacks ?? this.fraternalFeudsPickedStacks,
      traitorPicking: traitorPicking ?? this.traitorPicking,
      startingHandDraftStackIndex: clearStartingHandDraftStackIndex
          ? null
          : (startingHandDraftStackIndex ?? this.startingHandDraftStackIndex),
      startingHandDraftPool: clearStartingHandDraftPool
          ? null
          : (startingHandDraftPool ?? this.startingHandDraftPool),
      startingHandDraftPicked:
          startingHandDraftPicked ?? this.startingHandDraftPicked,
      startingRegionRearrangementActive: startingRegionRearrangementActive ??
          this.startingRegionRearrangementActive,
      startingRegionRearrangementFirst: clearStartingRegionRearrangementFirst
          ? null
          : (startingRegionRearrangementFirst ??
              this.startingRegionRearrangementFirst),
    );
  }
}
