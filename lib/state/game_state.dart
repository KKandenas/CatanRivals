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

  const GameState({
    required this.you,
    required this.opponent,
    required this.centerStacks,
    this.draggingCard,
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
  }) {
    return GameState(
      you: you ?? this.you,
      opponent: opponent ?? this.opponent,
      centerStacks: centerStacks ?? this.centerStacks,
      draggingCard:
          clearDraggingCard ? null : (draggingCard ?? this.draggingCard),
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
    );
  }
}
