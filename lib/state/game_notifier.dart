import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      ),
    ));
  }

  // ---------------------------------------------------------------------
  // Omgången: slå produktionstärningen, justera resurser, avsluta
  // ---------------------------------------------------------------------

  /// Slår produktionstärningen (1–6, regelhäftet s. 7). Båda spelarna
  /// får utdelning på sina regioner med det talet – i det här steget
  /// justerar man själv resurserna manuellt med +/- på varje region
  /// (se [adjustRegionResource]) i stället för att det sker automatiskt.
  /// Händelsetärningen och stegen efter tärningsslaget (åtgärder,
  /// handkortskontroll, byte) är inte byggda än.
  String? rollProductionDie() {
    if (!state.handsReady) return null;
    if (!state.isMyTurn) return 'Inte din tur.';
    if (state.diceRolled) return null;

    final roll = Random().nextInt(6) + 1;
    state = state.copyWith(productionRoll: roll, diceRolled: true);
    _syncTurnState();
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
  /// antal kort ([GameState.handLimit]) går turen direkt vidare till
  /// motståndaren – annars startar handjusteringen: för få kort sätter
  /// [HandAdjustmentPhase.drawing] (dra ett kort i taget från valfri
  /// draghög via [drawHandCard]), för många sätter
  /// [HandAdjustmentPhase.discarding] (släng ett kort i taget till
  /// botten av valfri draghög via [discardHandCard]). I båda fallen
  /// lämnas turen över automatiskt så fort rätt antal är nått.
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
      _advanceToNextPlayer();
    }
    return null;
  }

  /// Lämnar över turen till motståndaren och återställer tärnings- och
  /// handjusteringsläget.
  void _advanceToNextPlayer() {
    final next = state.activePlayerId == state.myPlayerId
        ? state.opponentPlayerId
        : state.myPlayerId;
    state = state.copyWith(
      activePlayerId: next,
      diceRolled: false,
      clearProductionRoll: true,
      handAdjustmentPhase: HandAdjustmentPhase.none,
    );
    _syncTurnState();
  }

  /// Drar det översta kortet från draghög [stackIndex] (0–3) till din
  /// hand under [HandAdjustmentPhase.drawing]. Lämnar turen vidare
  /// automatiskt så fort [GameState.handLimit] är nått.
  String? drawHandCard(int stackIndex) {
    if (state.handAdjustmentPhase != HandAdjustmentPhase.drawing) return null;
    final stack = _drawStacks[stackIndex];
    if (stack.isEmpty) return 'Den högen är tom.';

    final card = stack.first;
    _drawStacks[stackIndex] = stack.sublist(1);
    final updatedHand = [...state.you.hand, card];
    final done = updatedHand.length >= state.handLimit;

    state = state.copyWith(
      you: state.you.copyWith(hand: updatedHand),
      centerStacks: Map.of(state.centerStacks)
        ..update('draw${stackIndex + 1}', (v) => v - 1),
    );
    _syncMyPlayer();
    _syncCenterStacks();
    if (done) {
      _advanceToNextPlayer();
    }
    return null;
  }

  /// Slänger [card] från din hand till botten av draghög [stackIndex]
  /// (0–3) under [HandAdjustmentPhase.discarding] – spelaren väljer
  /// själv vilken av de fyra högarna, ingen matchning mot korttyp
  /// krävs. Lämnar turen vidare automatiskt så fort
  /// [GameState.handLimit] är nått.
  String? discardHandCard(GameCard card, int stackIndex) {
    if (state.handAdjustmentPhase != HandAdjustmentPhase.discarding) {
      return null;
    }
    if (!state.you.hand.contains(card)) return null;

    _drawStacks[stackIndex] = [..._drawStacks[stackIndex], card];
    final updatedHand = List<GameCard>.of(state.you.hand)..remove(card);
    final done = updatedHand.length <= state.handLimit;

    state = state.copyWith(
      you: state.you.copyWith(hand: updatedHand),
      centerStacks: Map.of(state.centerStacks)
        ..update('draw${stackIndex + 1}', (v) => v + 1),
    );
    _syncMyPlayer();
    _syncCenterStacks();
    if (done) {
      _advanceToNextPlayer();
    }
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
    if (state.pendingRegions.isNotEmpty) {
      return 'Välj plats för de nya regionkorten innan du bygger vidare.';
    }
    if (!state.canBuildNow) {
      return 'Vänta tills du har slagit tärningen på din tur.';
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
  String? dropSettlement(int column, GameCard card) {
    final error = _checkStack('settlements', card);
    if (error != null) return error;

    final oldLeft = state.you.principality.leftmostColumn;
    final oldRight = state.you.principality.rightmostColumn;

    state.you.principality.placeSettlement(column, PlacedCard(card: card));

    final newJunction = column < oldLeft ? column - 1 : column + 1;
    final wasNewSettlementFurtherOut = column < oldLeft || column > oldRight;

    state = state.copyWith(
      centerStacks: Map.of(state.centerStacks)
        ..update('settlements', (v) => v - 1)
        ..update('regions', (v) => wasNewSettlementFurtherOut ? v - 2 : v),
      clearDraggingCard: true,
      pendingRegions:
          wasNewSettlementFurtherOut ? [_drawRegion(), _drawRegion()] : null,
      pendingRegionJunction: wasNewSettlementFurtherOut ? newJunction : null,
    );
    _syncMyPlayer();
    _syncCenterStacks();
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
