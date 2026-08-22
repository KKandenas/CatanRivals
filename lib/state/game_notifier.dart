import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/basic_set_cards.dart';
import '../data/basic_set_draw_deck.dart';
import '../data/event_deck.dart';
import '../data/mock_game.dart';
import '../data/region_deck.dart';
import '../models/models.dart';
import '../services/game_sync_providers.dart';
import '../services/game_sync_service.dart';
import 'game_state.dart';

/// Spelets state-provider. Läs med `ref.watch(gameProvider)` och mutera
/// via `ref.read(gameProvider.notifier)`.
final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

/// Håller och muterar [GameState]: bygga vägar/byar/städer från
/// center-dragstaplarna, spela bygg-/enhetskort från handen, drag-state
/// (vilket kort som just nu dras), och – när ett rum är anslutet –
/// synka drag mot [GameSyncService] så att motståndarens iPad ser samma
/// bräde.
///
/// Metoderna som bygger något returnerar `null` vid lyckad byggnation
/// eller ett felmeddelande (t.ex. "Inte råd med X") som UI-lagret kan
/// visa i ett snackbar – notifiern har ingen BuildContext att visa det
/// själv med.
///
/// [RealmBoard] är fortfarande en muterbar klass (se realm_board.dart)
/// – vi skriver alltså till samma bräd-instans och byter sedan ut
/// `state` för att trigga ombyggnad, snarare än att bygga om hela
/// brädet immutabelt. En fullt immutabel spelbräde-modell är en större
/// omskrivning som får vänta till den behövs (t.ex. för ångra/logg).
class GameNotifier extends Notifier<GameState> {
  StreamSubscription<Map<String, Player>>? _playersSub;
  StreamSubscription<Map<String, int>>? _centerStacksSub;
  StreamSubscription<TurnState>? _turnStateSub;

  /// Regionstapelns kvarvarande, blandade kort (se [RegionDeck]) – dras
  /// från när en ny by byggs. Var spelares klient håller sin egen
  /// blandning; det synkas inte kort-för-kort mellan host/guest än (bara
  /// det synliga antalet i centerStacks['regions'] synkas), så exakt
  /// vilka regioner som dras kan skilja mellan de två klienterna. Fullt
  /// delad, synkad dragstapel är ett större steg för sig.
  List<GameCard> _regionDeck = RegionDeck.shuffledRemainingDeck();

  /// De 4 grundspels-draghögarna (36 kort, se [BasicSetDrawDeck]) och
  /// händelsekortsstapeln (9 kort, Yule 4:e från botten, se
  /// [EventDeck]). Precis som regionstapeln hålls de lokalt per klient
  /// tills vidare – bara antalet (alltid 9 vardera) syns i
  /// centerStacks, inte de exakta korten.
  List<List<GameCard>> _drawStacks = BasicSetDrawDeck.shuffledFourStacks();
  List<GameCard> _eventDeck = EventDeck.shuffledWithYuleFourthFromBottom();

  void _resetDecks() {
    _regionDeck = RegionDeck.shuffledRemainingDeck();
    _drawStacks = BasicSetDrawDeck.shuffledFourStacks();
    _eventDeck = EventDeck.shuffledWithYuleFourthFromBottom();
  }

  /// Exponerat för UI/tester – de fyra draghögarna finns, är riktigt
  /// blandade, men går inte att dra kort ifrån än (handkorts-utdelning
  /// och påfyllning är ett senare steg).
  List<GameCard> drawStack(int index) => List.unmodifiable(_drawStacks[index]);

  List<GameCard> get eventDeck => List.unmodifiable(_eventDeck);

  GameSyncService get _sync => ref.read(gameSyncServiceProvider);

  GameCard _drawRegion() {
    if (_regionDeck.isEmpty) _regionDeck = RegionDeck.shuffledRemainingDeck();
    return _regionDeck.removeLast();
  }

  /// Tar de 3 översta korten från draghög [stackIndex] och lägger dem i
  /// spelarens hand (regelhäftet s. 6). Muterar den lokala kopian av
  /// högen – de återstående 6 korten blir kvar där för framtida
  /// handpåfyllning.
  Player _dealStartingHand(Player player, int stackIndex) {
    final stack = _drawStacks[stackIndex];
    final drawn = stack.sublist(0, 3);
    _drawStacks[stackIndex] = stack.sublist(3);
    return player
        .copyWith(hand: [...player.hand, ...drawn], hasDrawnStartingHand: true);
  }

  @override
  GameState build() {
    ref.onDispose(() {
      _playersSub?.cancel();
      _centerStacksSub?.cancel();
      _turnStateSub?.cancel();
    });
    return GameState(
      you: MockGame.buildYou(),
      opponent: MockGame.buildOpponent(),
      centerStacks: MockGame.centerStackCounts(),
    );
  }

  void startDrag(GameCard card) => state = state.copyWith(draggingCard: card);

  void endDrag() => state = state.copyWith(clearDraggingCard: true);

  // ---------------------------------------------------------------------
  // Rum: skapa/gå med/lämna
  // ---------------------------------------------------------------------

  /// Startar om till lokalt läge (mock-data, ingen synk) – "spela
  /// lokalt"-genvägen i lobbyn, och det man hamnar i om man lämnar ett
  /// rum.
  void playLocally() {
    _playersSub?.cancel();
    _centerStacksSub?.cancel();
    _turnStateSub?.cancel();
    _resetDecks();

    // Lokalt läge har ingen egen vy för en andra spelare att trycka
    // sig igenom "välj en draghög"-steget interaktivt, så här delas
    // starthänderna ut direkt (röd från hög 1, blå från hög 2) i
    // stället för att vänta på [chooseStartingStack]. I ett riktigt
    // rum (host/guest) väljer varje spelare interaktivt på sin egen
    // enhet – se [hostRoom]/[joinRoom].
    final you = _dealStartingHand(
        MockGame.buildStartingPlayer('you', 'Du', isRed: true), 0);
    final opponent = _dealStartingHand(
        MockGame.buildStartingPlayer('opponent', 'Motståndare', isRed: false),
        1);

    state = GameState(
      you: you,
      opponent: opponent,
      centerStacks: Map.of(MockGame.centerStackCounts())
        ..update('draw1', (v) => v - 3)
        ..update('draw2', (v) => v - 3),
      // Röd ("du") går alltid först – samma förenkling som starthandsvalet.
      activePlayerId: 'you',
    );
  }

  /// Skapar ett nytt rum, blir "host" och väntar på att en motståndare
  /// ska gå med. Returnerar den genererade rumskoden.
  Future<String> hostRoom(String myName) async {
    final roomCode = MockGame.generateRoomCode();
    final hostPlayer =
        MockGame.buildStartingPlayer('host', myName, isRed: true);
    final waitingOpponent = MockGame.buildStartingPlayer(
        'guest', 'Väntar på motståndare …',
        isRed: false);
    final centerStacks = MockGame.centerStackCounts();
    _resetDecks();

    // Röd (host) går alltid först – samma förenkling som starthandsvalet.
    const initialTurnState = TurnState(activePlayerId: 'host');
    try {
      await _sync
          .createRoom(
              roomCode, 'host', hostPlayer, centerStacks, initialTurnState)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception(
          'Fick ingen kontakt med servern. Kontrollera internetanslutningen och försök igen.');
    }

    state = GameState(
      you: hostPlayer,
      opponent: waitingOpponent,
      centerStacks: centerStacks,
      mode: SessionMode.host,
      roomCode: roomCode,
      myPlayerId: 'host',
      opponentPlayerId: 'guest',
      opponentConnected: false,
      activePlayerId: initialTurnState.activePlayerId,
    );
    _subscribeToRoom(roomCode);
    return roomCode;
  }

  /// Går med i ett befintligt rum. Returnerar `null` vid lyckat
  /// gick-med, annars ett felmeddelande att visa i lobbyn.
  Future<String?> joinRoom(String roomCode, String myName) async {
    final guestPlayer =
        MockGame.buildStartingPlayer('guest', myName, isRed: false);
    String? error;
    try {
      error = await _sync
          .joinRoom(roomCode, 'guest', guestPlayer)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      return 'Fick ingen kontakt med servern. Kontrollera internetanslutningen och försök igen.';
    }
    if (error != null) return error;
    _resetDecks();

    state = GameState(
      you: guestPlayer,
      opponent: MockGame.buildStartingPlayer('host', '…', isRed: true),
      centerStacks: MockGame.centerStackCounts(),
      mode: SessionMode.guest,
      roomCode: roomCode,
      myPlayerId: 'guest',
      opponentPlayerId: 'host',
      opponentConnected: true,
      // Host är alltid röd och går alltid först – överskrivs så fort
      // [watchTurnState] hinner leverera det riktiga läget.
      activePlayerId: 'host',
    );
    _subscribeToRoom(roomCode);
    return null;
  }

  void _subscribeToRoom(String roomCode) {
    _playersSub?.cancel();
    _centerStacksSub?.cancel();
    _turnStateSub?.cancel();

    _playersSub = _sync.watchPlayers(roomCode).listen(
      (players) {
        final opponentPlayer = players[state.opponentPlayerId];
        if (opponentPlayer == null) return;
        state = state.copyWith(
            opponent: opponentPlayer,
            opponentConnected: true,
            clearSessionError: true);
        recomputeTokenHolders();
      },
      // Utan den här hanteraren skulle t.ex. ett rättighetsfel i
      // Firebase-databasreglerna tysta misslyckas – "väntar på
      // motståndare" skulle stå kvar för evigt utan någon förklaring.
      onError: (Object e) {
        state = state.copyWith(
            sessionError: 'Kunde inte synka med motståndaren: $e');
      },
    );

    _centerStacksSub = _sync.watchCenterStacks(roomCode).listen(
      (centerStacks) {
        if (centerStacks.isEmpty) return;
        state = state.copyWith(centerStacks: centerStacks);
      },
      onError: (Object e) {
        state =
            state.copyWith(sessionError: 'Kunde inte synka dragstaplarna: $e');
      },
    );

    _turnStateSub = _sync.watchTurnState(roomCode).listen(
      (turnState) {
        state = state.copyWith(
          activePlayerId: turnState.activePlayerId,
          diceRolled: turnState.diceRolled,
          productionRoll: turnState.productionRoll,
          clearProductionRoll: turnState.productionRoll == null,
          eventDieFace: turnState.eventDieFace,
          clearEventDieFace: turnState.eventDieFace == null,
          drawnEventCard: turnState.drawnEventCard,
          clearDrawnEventCard: turnState.drawnEventCard == null,
        );
      },
      onError: (Object e) {
        state = state.copyWith(sessionError: 'Kunde inte synka omgången: $e');
      },
    );
  }

  void _syncMyPlayer() {
    final roomCode = state.roomCode;
    if (roomCode == null) return;
    unawaited(_sync.writePlayer(roomCode, state.myPlayerId, state.you));
  }

  void _syncCenterStacks() {
    final roomCode = state.roomCode;
    if (roomCode == null) return;
    unawaited(_sync.writeCenterStacks(roomCode, state.centerStacks));
  }

  void _syncTurnState() {
    final roomCode = state.roomCode;
    if (roomCode == null) return;
    unawaited(_sync.writeTurnState(
      roomCode,
      TurnState(
        activePlayerId: state.activePlayerId,
        diceRolled: state.diceRolled,
        productionRoll: state.productionRoll,
        eventDieFace: state.eventDieFace,
        drawnEventCard: state.drawnEventCard,
      ),
    ));
  }

  // ---------------------------------------------------------------------
  // Omgången: slå produktionstärningen, justera resurser, avsluta
  // ---------------------------------------------------------------------

  /// Slår produktions- och händelsetärningen samtidigt (regelhäftet
  /// s. 7, händelsetärningens referenskort – se [EventDieFace]). Båda
  /// spelarna får utdelning på sina regioner med produktionstalet – i
  /// det här steget justerar man själv resurserna manuellt med +/- på
  /// varje region (se [adjustRegionResource]) i stället för att det
  /// sker automatiskt. Händelsetärningens utfall visas bara – vad det
  /// faktiskt innebär (handel/fest/skörd/brigadanfall/händelsekort)
  /// sköter spelarna själva utifrån [EventDieFace.ruleText], precis
  /// som byggkostnader.
  String? rollProductionDie() {
    if (!state.handsReady) return null;
    if (!state.isMyTurn) return 'Inte din tur.';
    if (state.diceRolled) return null;

    final roll = Random().nextInt(6) + 1;
    final eventFace = EventDieFace.fromRoll(Random().nextInt(6));
    state = state.copyWith(
        productionRoll: roll, eventDieFace: eventFace, diceRolled: true);
    _syncTurnState();
    return null;
  }

  /// Spelar Brigitta, den visa kvinnan (regelhäftet: "Play this card
  /// before rolling the dice. Choose the result of the production die
  /// roll.") – väljer alltså produktionstärningens resultat direkt i
  /// stället för att slå den. Händelsetärningen slås ändå som vanligt
  /// (kortet gäller bara produktionstärningen, se [EventDieFace]).
  /// Kortet tas bort från handen. Bara giltigt innan tärningen slagits
  /// den här omgången.
  String? useBrigitta(int chosenNumber) {
    if (!state.isMyTurn) return 'Inte din tur.';
    if (state.diceRolled) {
      return 'Brigitta måste spelas innan tärningen slås.';
    }
    if (chosenNumber < 1 || chosenNumber > 6) return null;
    GameCard? card;
    for (final c in state.you.hand) {
      if (c.baseId == BasicSetCards.brigittaTheWiseWoman.id) {
        card = c;
        break;
      }
    }
    if (card == null) return null;

    final eventFace = EventDieFace.fromRoll(Random().nextInt(6));
    state = state.copyWith(
      you: state.you.copyWith(hand: List.of(state.you.hand)..remove(card)),
      productionRoll: chosenNumber,
      eventDieFace: eventFace,
      diceRolled: true,
    );
    _syncMyPlayer();
    _syncTurnState();
    return null;
  }

  /// Drar det översta händelsekortet när händelsetärningen visade "?"
  /// (regelhäftets referenskort: "The player who rolled the dice draws
  /// the topmost event card and reads the event aloud") – bara den som
  /// slog tärningen får dra, och bara en gång per omgång. Kortet synkas
  /// till motståndaren (se [TurnState.drawnEventCard]) så båda ser
  /// samma kort, och stängs igen med [dismissEventCard]. Vad kortets
  /// effekt faktiskt innebär sköter spelarna själva utifrån dess
  /// `effectText`, precis som byggkostnader.
  String? drawEventCard() {
    if (state.eventDieFace != EventDieFace.eventCard) return null;
    if (!state.isMyTurn) return 'Inte din tur.';
    if (!state.diceRolled) return null;
    if (state.drawnEventCard != null) return null;

    final card = _drawEventCardResolvingYule();
    if (card == null) return 'Inga fler händelsekort kvar.';

    state = state.copyWith(
      drawnEventCard: card,
      centerStacks: Map.of(state.centerStacks)..['event'] = _eventDeck.length,
    );
    _syncCenterStacks();
    _syncTurnState();
    return null;
  }

  /// Drar översta kortet från händelsekortsstapeln. Är det Jul
  /// (regelhäftet: "Shuffle the event card stack as performed at the
  /// beginning of the game. Afterwards, draw an event card again.")
  /// byggs stapeln om automatiskt och nästa kort dras direkt i
  /// stället – Jul visas alltså aldrig för spelarna, bara kortet som
  /// kommer efter.
  GameCard? _drawEventCardResolvingYule() {
    if (_eventDeck.isEmpty) return null;
    var card = _eventDeck.removeAt(0);
    while (card.id == BasicSetCards.yule.id) {
      _eventDeck = EventDeck.shuffledWithYuleFourthFromBottom();
      if (_eventDeck.isEmpty) return null;
      card = _eventDeck.removeAt(0);
    }
    return card;
  }

  /// Stänger det uppslagna händelsekortet (se [drawEventCard]) – vem
  /// som helst av spelarna kan stänga det när det är läst och (om det
  /// påverkar någon) genomfört, det är bara en informationsruta.
  String? dismissEventCard() {
    if (state.drawnEventCard == null) return null;
    state = state.copyWith(clearDrawnEventCard: true);
    _syncTurnState();
    return null;
  }

  /// Spelar ett självbevakat handlingskort (Handelskaravan/Guldsmed):
  /// tar bara bort kortet från handen – spelaren justerar sedan själv
  /// resurserna manuellt med +/- på sina regioner utifrån kortets
  /// `effectText`, precis som byggkostnader och tärningsutdelning. Bara
  /// giltigt på din egen tur.
  String? discardActionCard(GameCard card) {
    if (!state.isMyTurn) return 'Inte din tur.';
    if (!state.you.hand.contains(card)) return null;

    state = state.copyWith(
      you: state.you.copyWith(hand: List.of(state.you.hand)..remove(card)),
    );
    _syncMyPlayer();
    return null;
  }

  /// Justerar lagrade resurser på en av dina egna regioner – den
  /// manuella motsvarigheten till att en region ger/förlorar en resurs.
  /// Klämmer till 0–3 (regelhäftet s. 3), se [RealmBoard.addResourceToRegion].
  void adjustRegionResource(int junctionColumn, BuildingRow row, int delta) {
    state.you.principality.addResourceToRegion(junctionColumn, row, delta);
    state = state.copyWith(you: state.you);
    _syncMyPlayer();
  }

  /// Avslutar action-fasen (regelhäftet s. 9). Om handen redan har rätt
  /// antal kort ([GameState.handLimit]) går det direkt vidare till
  /// kortbytesfasen ([TradePhase]) – annars startar handjusteringen:
  /// för få kort sätter [HandAdjustmentPhase.drawing] (dra ett kort i
  /// taget från valfri draghög via [drawHandCard]), för många sätter
  /// [HandAdjustmentPhase.discarding] (släng ett kort i taget till
  /// botten av valfri draghög via [discardHandCard]). I båda fallen
  /// går det vidare till kortbytesfasen automatiskt så fort rätt antal
  /// är nått.
  String? endActionPhase() {
    if (!state.isMyTurn) return 'Inte din tur.';
    if (!state.diceRolled) {
      return 'Slå tärningen innan du avslutar action-fasen.';
    }
    if (state.handAdjustmentPhase != HandAdjustmentPhase.none) return null;

    final count = state.you.hand.length;
    final limit = state.handLimit;
    if (count < limit) {
      state = state.copyWith(handAdjustmentPhase: HandAdjustmentPhase.drawing);
    } else if (count > limit) {
      state =
          state.copyWith(handAdjustmentPhase: HandAdjustmentPhase.discarding);
    } else {
      _enterTradePhase();
    }
    return null;
  }

  /// Lämnar över turen till motståndaren och återställer tärnings-,
  /// handjusterings- och kortbytesläget. [eventDieFace] rensas
  /// medvetet INTE – den ständigt synliga symbolen bredvid
  /// produktionstärningen (se EventDieIcon i game_board_screen.dart)
  /// ska fortsätta visa senast slagna sida i stället för att falla
  /// tillbaka till en tom platshållare mellan omgångar; den skrivs
  /// bara över av nästa [rollProductionDie].
  void _advanceToNextPlayer() {
    final next = state.activePlayerId == state.myPlayerId
        ? state.opponentPlayerId
        : state.myPlayerId;
    state = state.copyWith(
      activePlayerId: next,
      diceRolled: false,
      clearProductionRoll: true,
      clearDrawnEventCard: true,
      handAdjustmentPhase: HandAdjustmentPhase.none,
      tradePhase: TradePhase.none,
      clearPeekStackIndex: true,
      clearPeekedCards: true,
      awaitingScoutDecision: false,
      clearScoutChoices: true,
      relocationActive: false,
      clearRelocationFirst: true,
    );
    _syncTurnState();
  }

  /// Tar det översta kortet från draghög [stackIndex] till din hand,
  /// och uppdaterar centerStacks/synk. Delas av [drawHandCard] (under
  /// handjusteringen) och [exchangeDraw]/[startExchange] (under
  /// kortbytesfasens gratisbyte) – bara vem som får anropa den och vad
  /// som händer efteråt skiljer.
  GameCard? _drawCardFromStack(int stackIndex) {
    final stack = _drawStacks[stackIndex];
    if (stack.isEmpty) return null;

    final card = stack.first;
    _drawStacks[stackIndex] = stack.sublist(1);
    state = state.copyWith(
      you: state.you.copyWith(hand: [...state.you.hand, card]),
      centerStacks: Map.of(state.centerStacks)
        ..update('draw${stackIndex + 1}', (v) => v - 1),
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return card;
  }

  /// Slänger [card] till botten av draghög [stackIndex], och
  /// uppdaterar centerStacks/synk (så motståndaren ser vilken hög –
  /// centerStacks synkas alltid). Delas av [discardHandCard] och
  /// [exchangeDiscard].
  void _discardCardToStack(GameCard card, int stackIndex) {
    _drawStacks[stackIndex] = [..._drawStacks[stackIndex], card];
    state = state.copyWith(
      you: state.you
          .copyWith(hand: List<GameCard>.of(state.you.hand)..remove(card)),
      centerStacks: Map.of(state.centerStacks)
        ..update('draw${stackIndex + 1}', (v) => v + 1),
    );
    _syncMyPlayer();
    _syncCenterStacks();
  }

  /// Drar det översta kortet från draghög [stackIndex] (0–3) till din
  /// hand under [HandAdjustmentPhase.drawing]. Går vidare till
  /// kortbytesfasen automatiskt så fort [GameState.handLimit] är nått.
  String? drawHandCard(int stackIndex) {
    if (state.handAdjustmentPhase != HandAdjustmentPhase.drawing) return null;
    final card = _drawCardFromStack(stackIndex);
    if (card == null) return 'Den högen är tom.';

    if (state.you.hand.length >= state.handLimit) {
      _enterTradePhase();
    }
    return null;
  }

  /// Slänger [card] från din hand till botten av draghög [stackIndex]
  /// (0–3) under [HandAdjustmentPhase.discarding] – spelaren väljer
  /// själv vilken av de fyra högarna, ingen matchning mot korttyp
  /// krävs. Går vidare till kortbytesfasen automatiskt så fort
  /// [GameState.handLimit] är nått.
  String? discardHandCard(GameCard card, int stackIndex) {
    if (state.handAdjustmentPhase != HandAdjustmentPhase.discarding) {
      return null;
    }
    if (!state.you.hand.contains(card)) return null;

    _discardCardToStack(card, stackIndex);
    if (state.you.hand.length <= state.handLimit) {
      _enterTradePhase();
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Kortbytesfasen: sist i omgången, efter handjusteringen (regelhäftet
  // s. 9 "Trading cards") – tre val, se [TradePhase].
  // ---------------------------------------------------------------------

  void _enterTradePhase() {
    state = state.copyWith(
      handAdjustmentPhase: HandAdjustmentPhase.none,
      tradePhase: TradePhase.choosing,
    );
  }

  /// Väljer att inte byta något kort – lämnar turen vidare direkt.
  String? skipTrade() {
    if (state.tradePhase != TradePhase.choosing) return null;
    _advanceToNextPlayer();
    return null;
  }

  /// Startar det gratis bytet (regelhäftet s. 9): ett handkort ska
  /// slängas till valfri draghög (se [exchangeDiscard]), sedan dras ett
  /// kort från toppen av valfri – kanske en annan – draghög (se
  /// [exchangeDraw]).
  String? startExchange() {
    if (state.tradePhase != TradePhase.choosing) return null;
    state = state.copyWith(tradePhase: TradePhase.exchangeDiscard);
    return null;
  }

  /// Slänger [card] till botten av draghög [stackIndex] – första
  /// halvan av det gratis bytet (se [startExchange]). centerStacks
  /// synkas alltid, så motståndaren ser vilken hög kortet hamnade i,
  /// precis som regelhäftet kräver.
  String? exchangeDiscard(GameCard card, int stackIndex) {
    if (state.tradePhase != TradePhase.exchangeDiscard) return null;
    if (!state.you.hand.contains(card)) return null;

    _discardCardToStack(card, stackIndex);
    state = state.copyWith(tradePhase: TradePhase.exchangeDraw);
    return null;
  }

  /// Drar det översta kortet från draghög [stackIndex] – andra (och
  /// sista) halvan av det gratis bytet (se [exchangeDiscard]). Lämnar
  /// turen vidare när kortet är draget.
  String? exchangeDraw(int stackIndex) {
    if (state.tradePhase != TradePhase.exchangeDraw) return null;
    final card = _drawCardFromStack(stackIndex);
    if (card == null) return 'Den högen är tom.';

    _advanceToNextPlayer();
    return null;
  }

  /// Startar köpet av att få kika i en hel draghög (regelhäftet s. 9):
  /// 2 valfria resurser. Precis som byggkostnader håller appen inte
  /// koll på om spelaren har råd – kostnaden visas bara i
  /// bekräftelserutan, och spelaren betalar själv genom att trycka −
  /// på valfria regioner innan hen bekräftar (se [confirmPeekPayment]).
  String? startPeek() {
    if (state.tradePhase != TradePhase.choosing) return null;
    state = state.copyWith(tradePhase: TradePhase.peekPaying);
    return null;
  }

  /// Ångrar köpet av att kika – tillbaka till de tre huvudvalen, innan
  /// någon resurs faktiskt behöver ha rörts (spelaren kan redan ha
  /// tryckt − några gånger, men appen håller inte reda på om det
  /// faktiskt hände, precis som med byggkostnader).
  String? cancelPeek() {
    if (state.tradePhase != TradePhase.peekPaying) return null;
    state = state.copyWith(tradePhase: TradePhase.choosing);
    return null;
  }

  /// Bekräftar att de 2 valfria resurserna är betalda – nästa steg är
  /// att slänga ett handkort (se [peekDiscardCard]), precis som det
  /// gratis bytet: annars skulle handen växa med ett extra kort utan
  /// motsvarande byte, vilket skulle göra kika-alternativet strikt
  /// bättre än de andra två.
  String? confirmPeekPayment() {
    if (state.tradePhase != TradePhase.peekPaying) return null;
    state = state.copyWith(tradePhase: TradePhase.peekDiscard);
    return null;
  }

  /// Slänger [card] till botten av draghög [stackIndex] – steget efter
  /// betalningen (se [confirmPeekPayment]) och innan man väljer vilken
  /// hög man vill kika i (se [choosePeekStack]).
  String? peekDiscardCard(GameCard card, int stackIndex) {
    if (state.tradePhase != TradePhase.peekDiscard) return null;
    if (!state.you.hand.contains(card)) return null;

    _discardCardToStack(card, stackIndex);
    state = state.copyWith(tradePhase: TradePhase.peekChoosingStack);
    return null;
  }

  /// Slår upp alla kort i draghög [stackIndex], i den ordning de
  /// faktiskt ligger (första kortet i listan är överst), så att UI kan
  /// visa dem och spelaren väljer ett att behålla (se [peekTakeCard]).
  String? choosePeekStack(int stackIndex) {
    if (state.tradePhase != TradePhase.peekChoosingStack) return null;
    state = state.copyWith(
      tradePhase: TradePhase.peekViewing,
      peekStackIndex: stackIndex,
      peekedCards: List.of(_drawStacks[stackIndex]),
    );
    return null;
  }

  /// Behåller [card] från den uppslagna draghögen (se
  /// [choosePeekStack]) – resten av korten läggs tillbaka i högen i
  /// exakt samma ordning de låg i (regelhäftet kräver det), eftersom
  /// vi bara plockar bort det valda kortet ur samma lista i stället för
  /// att bygga om högen från grunden. Lämnar turen vidare direkt efter.
  String? peekTakeCard(GameCard card) {
    if (state.tradePhase != TradePhase.peekViewing) return null;
    final stackIndex = state.peekStackIndex;
    if (stackIndex == null) return null;
    if (!_drawStacks[stackIndex].contains(card)) return null;

    _drawStacks[stackIndex] = List.of(_drawStacks[stackIndex])..remove(card);
    state = state.copyWith(
      you: state.you.copyWith(hand: [...state.you.hand, card]),
      centerStacks: Map.of(state.centerStacks)
        ..update('draw${stackIndex + 1}', (v) => v - 1),
    );
    _syncMyPlayer();
    _syncCenterStacks();
    _advanceToNextPlayer();
    return null;
  }

  // ---------------------------------------------------------------------
  // Starthand: välj en draghög och ta dess 3 översta kort
  // ---------------------------------------------------------------------

  /// Väljer draghög [index] (0–3) och tar dess 3 översta kort som
  /// starthand (regelhäftet s. 6). Bara giltigt om det är den här
  /// spelarens tur att välja (se [GameState.isMyTurnToChooseHand]) och
  /// högen inte redan är vald. Returnerar `null` vid lyckat val, annars
  /// ett felmeddelande.
  String? chooseStartingStack(int index) {
    if (state.handsReady) return null;
    if (!state.isMyTurnToChooseHand) {
      return 'Inte din tur att välja en draghög.';
    }
    final key = 'draw${index + 1}';
    if ((state.centerStacks[key] ?? 0) < 9) return 'Den högen är redan vald.';

    final updated = _dealStartingHand(state.you, index);
    state = state.copyWith(
      you: updated,
      centerStacks: Map.of(state.centerStacks)..update(key, (v) => v - 3),
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return null;
  }

  // ---------------------------------------------------------------------
  // Bygga: spela kort från handen / center-dragstaplarna
  // ---------------------------------------------------------------------

  /// Kollar att det är din tur och att du redan slagit tärningen
  /// (regelhäftet s. 7: "bara den aktiva spelaren, och bara efter att
  /// tärningarna är slagna"), att regionvalet efter en tidigare by inte
  /// väntar, och att stapeln inte är slut. Null om allt stämmer, annars
  /// ett felmeddelande.
  ///
  /// Ingen kontroll av om spelaren har råd – kostnaden visas i
  /// bekräftelserutan (se `showBuildConfirmDialog`) och spelarna
  /// betalar själva med +/- på sina regioner, precis som i det
  /// fysiska spelet.
  String? _checkStack(String stackKey, GameCard card) {
    final turnError = _checkCanBuild();
    if (turnError != null) return turnError;
    if ((state.centerStacks[stackKey] ?? 0) <= 0) {
      return 'Inga fler ${card.name.toLowerCase()}or kvar i stapeln';
    }
    return null;
  }

  String? _checkCanBuild() {
    if (state.awaitingScoutDecision) {
      return 'Svara på frågan om Spejare innan du bygger vidare.';
    }
    if (state.relocationActive) {
      return 'Avsluta Omlokaliseringen innan du bygger vidare.';
    }
    if (state.pendingRegions.isNotEmpty) {
      return 'Välj plats för de nya regionkorten innan du bygger vidare.';
    }
    if (!state.canBuildNow) {
      return 'Vänta tills du har slagit tärningen på din tur.';
    }
    if (state.handAdjustmentPhase != HandAdjustmentPhase.none ||
        state.tradePhase != TradePhase.none) {
      return 'Klart med handjusteringen/kortbytet innan du kan bygga vidare.';
    }
    return null;
  }

  String? dropExpansion(
      int column, BuildingRow row, int slotIndex, GameCard card) {
    final turnError = _checkCanBuild();
    if (turnError != null) return turnError;
    if (!state.you.hand.contains(card)) return null;
    if (card.isUnique && state.you.principality.hasExpansionCard(card.id)) {
      return 'Du kan bara ha en ${card.name} i ditt rike.';
    }

    state.you.principality
        .placeExpansion(column, row, slotIndex, PlacedCard(card: card));
    final updated =
        state.you.copyWith(hand: List.of(state.you.hand)..remove(card));

    state = state.copyWith(you: updated, clearDraggingCard: true);
    recomputeTokenHolders();
    _syncMyPlayer();
    return null;
  }

  String? dropRoad(int column, GameCard card) {
    final error = _checkStack('roads', card);
    if (error != null) return error;

    state.you.principality.placeRoad(column, PlacedCard(card: card));

    state = state.copyWith(
      centerStacks: Map.of(state.centerStacks)..update('roads', (v) => v - 1),
      clearDraggingCard: true,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return null;
  }

  /// Bygger en by. Hamnar den bortom rikets nuvarande yttergräns tar
  /// spelaren de 2 översta korten från regionstapeln (regelhäftet s. 8)
  /// – men i stället för att de placeras automatiskt hamnar de i
  /// [GameState.pendingRegions], och spelaren drar själv vartdera
  /// kortet till platsen ovanför/nedanför (se [placePendingRegion]).
  ///
  /// Har spelaren Spejare på hand väcks i stället frågan "Vill du
  /// använda Spejare?" (regelhäftet: "Play this card when building a
  /// settlement") – se [GameState.awaitingScoutDecision],
  /// [useScout]/[declineScout] – i stället för att de 2 korten dras
  /// slumpmässigt direkt.
  String? dropSettlement(int column, GameCard card) {
    final error = _checkStack('settlements', card);
    if (error != null) return error;

    final oldLeft = state.you.principality.leftmostColumn;
    final oldRight = state.you.principality.rightmostColumn;

    state.you.principality.placeSettlement(column, PlacedCard(card: card));

    final newJunction = column < oldLeft ? column - 1 : column + 1;
    final wasNewSettlementFurtherOut = column < oldLeft || column > oldRight;
    final hasScout = wasNewSettlementFurtherOut &&
        state.you.hand.any((c) => c.baseId == BasicSetCards.scout.id);

    state = state.copyWith(
      centerStacks: Map.of(state.centerStacks)
        ..update('settlements', (v) => v - 1)
        ..update('regions', (v) => wasNewSettlementFurtherOut ? v - 2 : v),
      clearDraggingCard: true,
      pendingRegions: (wasNewSettlementFurtherOut && !hasScout)
          ? [_drawRegion(), _drawRegion()]
          : null,
      pendingRegionJunction: wasNewSettlementFurtherOut ? newJunction : null,
      awaitingScoutDecision: hasScout,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return null;
  }

  /// Tackar nej till att använda Spejare på den by som just byggdes
  /// (se [dropSettlement]) – de 2 nya regionkorten dras slumpmässigt
  /// som vanligt.
  String? declineScout() {
    if (!state.awaitingScoutDecision) return null;
    state = state.copyWith(
      pendingRegions: [_drawRegion(), _drawRegion()],
      awaitingScoutDecision: false,
    );
    return null;
  }

  /// Använder Spejare (regelhäftet: "Play this card when building a
  /// settlement. Take 2 cards of your choice from the region card
  /// stack. Reshuffle the region card stack.") – öppnar hela den
  /// kvarvarande regionstapeln (se [GameState.scoutChoices]) så
  /// spelaren kan välja 2 valfria kort i stället för att dra
  /// slumpmässigt (se [pickScoutRegion]).
  String? useScout() {
    if (!state.awaitingScoutDecision) return null;
    state = state.copyWith(scoutChoices: List.of(_regionDeck));
    return null;
  }

  /// Väljer [card] ur den öppna regionstapeln (se [useScout]) till ett
  /// av de två väntande platserna. När det andra (och sista) kortet är
  /// valt blandas resten av stapeln om (regelhäftet: "Reshuffle the
  /// region card stack") och Spejare tas bort från handen.
  String? pickScoutRegion(GameCard card) {
    if (state.scoutChoices == null) return null;
    if (!_regionDeck.contains(card)) return null;

    _regionDeck = List.of(_regionDeck)..remove(card);
    final picked = [...state.pendingRegions, card];

    if (picked.length < 2) {
      state = state.copyWith(
        pendingRegions: picked,
        scoutChoices: List.of(_regionDeck),
      );
      return null;
    }

    _regionDeck = List.of(_regionDeck)..shuffle();
    GameCard? scoutCard;
    for (final c in state.you.hand) {
      if (c.baseId == BasicSetCards.scout.id) {
        scoutCard = c;
        break;
      }
    }
    state = state.copyWith(
      you: scoutCard == null
          ? state.you
          : state.you
              .copyWith(hand: List.of(state.you.hand)..remove(scoutCard)),
      pendingRegions: picked,
      clearScoutChoices: true,
      awaitingScoutDecision: false,
    );
    _syncMyPlayer();
    return null;
  }

  String? dropCityUpgrade(int column, GameCard card) {
    final error = _checkStack('cities', card);
    if (error != null) return error;

    state.you.principality.upgradeToCity(column, PlacedCard(card: card));

    state = state.copyWith(
      centerStacks: Map.of(state.centerStacks)..update('cities', (v) => v - 1),
      clearDraggingCard: true,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return null;
  }

  /// Placerar ett av de två väntande regionkorten (se [dropSettlement])
  /// på platsen ovanför eller nedanför den nya byn. När båda är
  /// placerade töms [GameState.pendingRegions] och byggande går bra
  /// igen.
  String? placePendingRegion(BuildingRow row, GameCard card) {
    final junction = state.pendingRegionJunction;
    if (junction == null || !state.pendingRegions.contains(card)) return null;
    if (state.you.principality.regionAt(junction, row) != null) {
      return 'Den platsen är redan upptagen.';
    }

    state.you.principality.placeRegion(junction, row, PlacedCard(card: card));
    final remaining = List<GameCard>.of(state.pendingRegions)..remove(card);

    state = state.copyWith(
      pendingRegions: remaining,
      clearPendingRegionJunction: remaining.isEmpty,
    );
    _syncMyPlayer();
    return null;
  }

  // ---------------------------------------------------------------------
  // Omlokalisering: byt plats på 2 egna regioner eller 2 egna byggkort
  // ---------------------------------------------------------------------

  /// Startar Omlokalisering (regelhäftet: "You may exchange 2 of your
  /// own regions or 2 of your own expansion cards ...") – riket blir
  /// tryckbart för att välja de 2 platserna som ska byta plats (se
  /// [selectRelocationTarget]). Kortet tas bort från handen först när
  /// bytet faktiskt genomförs (efter det andra valet), inte redan här
  /// – spelaren ska kunna ångra sig med [cancelRelocation] utan att
  /// förlora kortet.
  String? startRelocation() {
    if (!state.isMyTurn) return 'Inte din tur.';
    if (!state.you.hand.any((c) => c.baseId == BasicSetCards.relocation.id)) {
      return null;
    }
    state =
        state.copyWith(relocationActive: true, clearRelocationFirst: true);
    return null;
  }

  /// Avbryter Omlokalisering utan att göra något – kortet stannar kvar
  /// på handen.
  String? cancelRelocation() {
    state =
        state.copyWith(relocationActive: false, clearRelocationFirst: true);
    return null;
  }

  /// Väljer en plats i ditt eget rike under Omlokalisering (se
  /// [startRelocation]). Första giltiga trycket (en plats som faktiskt
  /// har ett kort) lagras som väntande ([GameState.relocationFirst]);
  /// trycker man på samma plats igen avmarkeras den. Ett andra tryck av
  /// samma sort ([RelocationTargetKind]) på en annan plats genomför
  /// bytet direkt och tar bort kortet från handen; en annan sort
  /// avvisas (regelhäftet tillåter inte att blanda regioner och
  /// byggkort i samma byte).
  String? selectRelocationTarget(
      RelocationTargetKind kind, int column, BuildingRow row, int slotIndex) {
    if (!state.relocationActive) return null;

    final selection = RelocationSelection(
        kind: kind, column: column, row: row, slotIndex: slotIndex);
    final first = state.relocationFirst;

    if (first == null) {
      final occupied = kind == RelocationTargetKind.region
          ? state.you.principality.regionAt(column, row) != null
          : _expansionAt(state.you.principality, column, row, slotIndex) !=
              null;
      if (!occupied) return null;
      state = state.copyWith(relocationFirst: selection);
      return null;
    }
    if (first == selection) {
      state = state.copyWith(clearRelocationFirst: true);
      return null;
    }
    if (first.kind != kind) {
      return 'Välj två regioner eller två byggkort, inte blandat.';
    }

    try {
      if (kind == RelocationTargetKind.region) {
        state.you.principality
            .swapRegions(first.column, first.row, column, row);
      } else {
        state.you.principality.swapExpansions(first.column, first.row,
            first.slotIndex, column, row, slotIndex);
      }
    } on StateError catch (e) {
      return e.message;
    }

    GameCard? relocationCard;
    for (final c in state.you.hand) {
      if (c.baseId == BasicSetCards.relocation.id) {
        relocationCard = c;
        break;
      }
    }
    state = state.copyWith(
      you: relocationCard == null
          ? state.you
          : state.you.copyWith(
              hand: List.of(state.you.hand)..remove(relocationCard)),
      relocationActive: false,
      clearRelocationFirst: true,
    );
    _syncMyPlayer();
    return null;
  }

  // ---------------------------------------------------------------------
  // Hero Token / Trade Token: vem har mest styrka/handel just nu
  // ---------------------------------------------------------------------

  /// Räknar om vem som just nu har Hero Token (flest styrkepoäng) och
  /// Trade Token (flest handelspoäng) och uppdaterar
  /// [GameState.heroTokenHolder]/[GameState.tradeTokenHolder] om det
  /// ändrats. Anropas efter varje ändring som kan påverka styrke-/
  /// handelspoängen hos någon av spelarna – [dropExpansion] för dig
  /// själv, och när motståndarens spelardata synkas in.
  void recomputeTokenHolders() {
    final hero = _resolveTokenHolder(
      currentHolder: state.heroTokenHolder,
      yourPoints: state.you.principality.totalStrengthPoints,
      opponentPoints: state.opponent.principality.totalStrengthPoints,
    );
    final trade = _resolveTokenHolder(
      currentHolder: state.tradeTokenHolder,
      yourPoints: state.you.principality.totalCommercePoints,
      opponentPoints: state.opponent.principality.totalCommercePoints,
    );
    if (hero == state.heroTokenHolder && trade == state.tradeTokenHolder) {
      return;
    }
    state = state.copyWith(
      heroTokenHolder: hero,
      clearHeroTokenHolder: hero == null,
      tradeTokenHolder: trade,
      clearTradeTokenHolder: trade == null,
    );
  }

  /// Avgör vem som ska ha en av de två brickorna: minst 3 poäng av den
  /// aktuella typen, och fler än motståndaren. Lika poäng ändrar
  /// ingenting – den som redan har bricken ("fick poängen först")
  /// behåller den. Tappar den aktuella innehavaren kravet (under 3,
  /// eller ikappad/omsprungen) går bricken till motståndaren om hen
  /// uppfyller kravet, annars tillbaka till "banken" (`null`).
  String? _resolveTokenHolder({
    required String? currentHolder,
    required int yourPoints,
    required int opponentPoints,
  }) {
    final youId = state.you.id;
    final oppId = state.opponent.id;
    if (currentHolder == youId) {
      if (yourPoints >= 3 && yourPoints >= opponentPoints) return youId;
      return opponentPoints >= 3 && opponentPoints > yourPoints ? oppId : null;
    }
    if (currentHolder == oppId) {
      if (opponentPoints >= 3 && opponentPoints >= yourPoints) return oppId;
      return yourPoints >= 3 && yourPoints > opponentPoints ? youId : null;
    }
    // Banken: bara ett rakt övertag ger bricken, inte ett oavgjort.
    if (yourPoints >= 3 && yourPoints > opponentPoints) return youId;
    if (opponentPoints >= 3 && opponentPoints > yourPoints) return oppId;
    return null;
  }
}

/// Kortet på en byggplats, om någon – hjälper
/// [GameNotifier.selectRelocationTarget] avgöra om Omlokaliseringens
/// första tryck landade på en tom platshållare (ignoreras) eller ett
/// riktigt bygg-/enhetskort.
PlacedCard? _expansionAt(
    RealmBoard board, int column, BuildingRow row, int slotIndex) {
  final node = board.settlementAt(column);
  if (node == null) return null;
  final sites = row == BuildingRow.above ? node.aboveSites : node.belowSites;
  if (slotIndex >= sites.length) return null;
  return sites[slotIndex];
}
