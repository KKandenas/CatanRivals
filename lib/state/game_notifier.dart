import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/basic_set_cards.dart';
import '../data/basic_set_draw_deck.dart';
import '../data/era_of_gold_cards.dart';
import '../data/era_of_gold_draw_deck.dart';
import '../data/event_deck.dart';
import '../data/mock_game.dart';
import '../data/region_deck.dart';
import '../models/models.dart';
import '../services/game_sync_providers.dart';
import '../services/game_sync_service.dart';
import '../services/session_storage.dart';
import 'build_requirements.dart';
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
  StreamSubscription<FraternalFeudsRequest?>? _fraternalFeudsRequestSub;
  StreamSubscription<List<GameCard>>? _discardPileSub;
  StreamSubscription<List<GameCard>>? _faceUpExpansionCardsSub;

  /// Regionstapelns kvarvarande, blandade kort (se [RegionDeck]) – dras
  /// från när en ny by byggs. Var spelares klient håller sin egen
  /// blandning; det synkas inte kort-för-kort mellan host/guest än (bara
  /// det synliga antalet i centerStacks['regions'] synkas), så exakt
  /// vilka regioner som dras kan skilja mellan de två klienterna. Fullt
  /// delad, synkad dragstapel är ett större steg för sig.
  List<GameCard> _regionDeck = RegionDeck.shuffledRemainingDeck();

  /// Grundspelets draghögar (36 kort, se [BasicSetDrawDeck]) och
  /// händelsekortsstapeln (Yule 4:e från botten, se [EventDeck]).
  /// Precis som regionstapeln hålls de lokalt per klient tills vidare –
  /// bara antalet syns i centerStacks, inte de exakta korten. Utan
  /// aktiva temaset: 4 högar à 9 kort, 9 händelsekort. Med Gulderan
  /// aktivt (se [_resetDecks]): omfördelas grundspelet till 3 högar à
  /// 12 kort för att lämna plats åt Gulderans egna 2 (11 kort vardera,
  /// se [EraOfGoldDrawDeck]) – alltså 5 högar totalt – och 3 extra
  /// händelsekort läggs till.
  List<List<GameCard>> _drawStacks = BasicSetDrawDeck.shuffledFourStacks();
  List<GameCard> _eventDeck = EventDeck.shuffledWithYuleFourthFromBottom();

  /// Bygger om alla tre lokala dragstaplar (region/drag/händelse) för
  /// en ny match, enligt vilka temaset som är aktiva. Returnerar den
  /// öppna ansikte-upp-högen (se [GameState.faceUpExpansionCards]) –
  /// anroparna (`playLocally`/`hostRoom`/`joinRoom`) sätter in den i
  /// [state] själva, eftersom `state` inte alltid är uppdaterad med
  /// [expansions] ännu vid anropstillfället.
  List<GameCard> _resetDecks(Set<ExpansionSet> expansions) {
    _regionDeck = RegionDeck.shuffledRemainingDeck();
    final hasGold = expansions.contains(ExpansionSet.eraOfGold);
    final basicStacks =
        BasicSetDrawDeck.shuffledStacks(stackCount: hasGold ? 3 : 4);
    if (hasGold) {
      _drawStacks = [...basicStacks, ...EraOfGoldDrawDeck.shuffledTwoStacks()];
      _eventDeck = EventDeck.shuffledWithYuleFourthFromBottom(
          extraCards: EraOfGoldDrawDeck.eventCards());
      return EraOfGoldDrawDeck.faceUpCards();
    }
    _drawStacks = basicStacks;
    _eventDeck = EventDeck.shuffledWithYuleFourthFromBottom();
    return const [];
  }

  /// Bygger `centerStacks`-kartan (draghögarnas synliga antal, plus de
  /// fasta grundspels-antalen väg/by/stad/region) utifrån de FAKTISKT
  /// uppbyggda dragstaplarna/händelsestapeln (se [_resetDecks]) i
  /// stället för [MockGame.centerStackCounts]s hårdkodade 4×9/9 – annars
  /// skulle en 5-högs Gulderan-match visa fel antal (och sakna
  /// `draw5` helt).
  Map<String, int> _buildCenterStacks() {
    final base = MockGame.centerStackCounts();
    final map = <String, int>{
      'roads': base['roads']!,
      'settlements': base['settlements']!,
      'cities': base['cities']!,
      'regions': base['regions']!,
      'event': _eventDeck.length,
    };
    for (var i = 0; i < _drawStacks.length; i++) {
      map['draw${i + 1}'] = _drawStacks[i].length;
    }
    return map;
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
      _fraternalFeudsRequestSub?.cancel();
      _discardPileSub?.cancel();
      _faceUpExpansionCardsSub?.cancel();
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
  /// rum. [expansions] är de temaset spelaren valt i lobbyn (tom mängd =
  /// rent grundspel) – styr segervillkoret ([GameState.victoryPointTarget])
  /// och draghögs-/ansikte-upp-uppställningen (se [_resetDecks]).
  void playLocally({Set<ExpansionSet> expansions = const {}}) {
    _playersSub?.cancel();
    _centerStacksSub?.cancel();
    _turnStateSub?.cancel();
    _fraternalFeudsRequestSub?.cancel();
    _discardPileSub?.cancel();
    _faceUpExpansionCardsSub?.cancel();
    final faceUp = _resetDecks(expansions);

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

    // _dealStartingHand ovan har redan tagit 3 kort ur högarna 0/1 (och
    // muterat _drawStacks in place), så _buildCenterStacks() här läser
    // redan de rätta, post-utdelning-antalen – ingen ytterligare -3
    // ska dras av.
    state = GameState(
      you: you,
      opponent: opponent,
      centerStacks: _buildCenterStacks(),
      activeExpansions: expansions,
      faceUpExpansionCards: faceUp,
      // Röd ("du") går alltid först – samma förenkling som starthandsvalet.
      activePlayerId: 'you',
    );
  }

  /// Skapar ett nytt rum, blir "host" och väntar på att en motståndare
  /// ska gå med. Returnerar den genererade rumskoden. [expansions] är
  /// hostens val i lobbyn (tom mängd = rent grundspel) – skickas med
  /// till rummet så gästen kan läsa samma val (se [joinRoom]/
  /// [GameSyncService.watchActiveExpansions]) i stället för att välja
  /// själv, och styr draghögs-/ansikte-upp-uppställningen (se
  /// [_resetDecks]).
  Future<String> hostRoom(String myName,
      {Set<ExpansionSet> expansions = const {}}) async {
    final roomCode = MockGame.generateRoomCode();
    final hostPlayer =
        MockGame.buildStartingPlayer('host', myName, isRed: true);
    final waitingOpponent = MockGame.buildStartingPlayer(
        'guest', 'Väntar på motståndare …',
        isRed: false);
    final faceUp = _resetDecks(expansions);
    final centerStacks = _buildCenterStacks();

    // Röd (host) går alltid först – samma förenkling som starthandsvalet.
    const initialTurnState = TurnState(activePlayerId: 'host');
    try {
      await _sync
          .createRoom(
              roomCode, 'host', hostPlayer, centerStacks, initialTurnState,
              activeExpansions: expansions, faceUpExpansionCards: faceUp)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception(
          'Fick ingen kontakt med servern. Kontrollera internetanslutningen och försök igen.');
    }

    state = GameState(
      you: hostPlayer,
      opponent: waitingOpponent,
      centerStacks: centerStacks,
      activeExpansions: expansions,
      faceUpExpansionCards: faceUp,
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
  /// gick-med, annars ett felmeddelande att visa i lobbyn. Till
  /// skillnad från [hostRoom] väljer gästen INTE själv vilka temaset
  /// som gäller – de läses från rummet (satta av hosten vid
  /// [createRoom]) så att båda klienterna bygger upp samma
  /// draghögs-/ansikte-upp-uppställning (se [_resetDecks]).
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

    var expansions = const <ExpansionSet>{};
    try {
      expansions = await _sync
          .watchActiveExpansions(roomCode)
          .first
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Antar rent grundspel om det här misslyckas – hellre en spelbar
      // (fast fel) uppställning än att hela anslutningen stupar på det.
    }
    final faceUp = _resetDecks(expansions);

    state = GameState(
      you: guestPlayer,
      opponent: MockGame.buildStartingPlayer('host', '…', isRed: true),
      // Lokal, tillfällig gissning tills [_subscribeToRoom]s
      // centerStacks-lyssnare hinner leverera hostens FAKTISKA (redan
      // skrivna) antal – precis som innan, bara nu med rätt antal
      // högar när ett temaset är aktivt.
      centerStacks: _buildCenterStacks(),
      activeExpansions: expansions,
      faceUpExpansionCards: faceUp,
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

  /// Återansluter till ett rum du redan var med i (regelhäftet ger
  /// förstås ingen ledning här – det här är bara en teknisk lösning på
  /// att en sidladdning annars kastar ut spelaren till startskärmen, se
  /// [SessionStorage]). Till skillnad från [joinRoom] skapar den här
  /// INGEN ny gäst-plats – den hämtar bara ditt eget, redan existerande
  /// spelar-id:s data på nytt (både [hostRoom] och [joinRoom] sparar
  /// spelaren under id:t "host" respektive "guest", så [role] räcker för
  /// att veta vilken av de två du är).
  ///
  /// [you]s handkort/rike hämtas alltså från Firebase precis som
  /// [opponent]s – till skillnad från normalt (där bara [_syncMyPlayer]
  /// SKRIVER dit, aldrig läser tillbaka) eftersom den här klienten just
  /// tappat sin egen lokala kopia. De fyra draghögarnas EXAKTA innehåll
  /// synkas dock aldrig (bara antalet, se [_drawStacks]) – de byggs om
  /// lokalt från grunden, se [_reconstructDrawStacksFromKnownCards].
  /// Regionstapeln och händelsekortsstapeln byggs om från grunden
  /// (nyblandade) – det finns ingen synkad information om exakt vilka
  /// kort som redan dragits därifrån, bara en känd brist.
  ///
  /// Returnerar `null` vid lyckad återanslutning, annars ett
  /// användarvänligt felmeddelande (rummet finns t.ex. inte kvar).
  Future<String?> resumeRoom(
      String roomCode, String role, String myName) async {
    if (role != 'host' && role != 'guest') return 'Okänd spelarroll.';
    final opponentRole = role == 'host' ? 'guest' : 'host';
    try {
      final players = await _sync
          .watchPlayers(roomCode)
          .first
          .timeout(const Duration(seconds: 10));
      final you = players[role];
      if (you == null) {
        return 'Rummet finns inte längre. Kontrollera koden.';
      }
      final opponent = players[opponentRole] ??
          MockGame.buildStartingPlayer(opponentRole, '…',
              isRed: opponentRole == 'host');
      final centerStacks = await _sync
          .watchCenterStacks(roomCode)
          .first
          .timeout(const Duration(seconds: 10));
      final turnState = await _sync
          .watchTurnState(roomCode)
          .first
          .timeout(const Duration(seconds: 10));
      final discardPile = await _sync
          .watchDiscardPile(roomCode)
          .first
          .timeout(const Duration(seconds: 10));
      var expansions = const <ExpansionSet>{};
      try {
        expansions = await _sync
            .watchActiveExpansions(roomCode)
            .first
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Se joinRoom – hellre en spelbar (fast fel) uppställning.
      }
      final faceUpExpansionCards = await _sync
          .watchFaceUpExpansionCards(roomCode)
          .first
          .timeout(const Duration(seconds: 10));

      _regionDeck = RegionDeck.shuffledRemainingDeck();
      final hasGold = expansions.contains(ExpansionSet.eraOfGold);
      _eventDeck = EventDeck.shuffledWithYuleFourthFromBottom(
          extraCards: hasGold ? EraOfGoldDrawDeck.eventCards() : const []);
      _reconstructDrawStacksFromKnownCards(
          you, opponent, centerStacks, expansions);

      state = GameState(
        you: you,
        opponent: opponent,
        centerStacks: centerStacks,
        activeExpansions: expansions,
        faceUpExpansionCards: faceUpExpansionCards,
        mode: role == 'host' ? SessionMode.host : SessionMode.guest,
        roomCode: roomCode,
        myPlayerId: role,
        opponentPlayerId: opponentRole,
        opponentConnected: players.containsKey(opponentRole),
        activePlayerId: turnState.activePlayerId,
        diceRolled: turnState.diceRolled,
        productionRoll: turnState.productionRoll,
        eventDieFace: turnState.eventDieFace,
        drawnEventCard: turnState.drawnEventCard,
        peekingStackIndex: turnState.peekingStackIndex,
        winnerId: turnState.winnerId,
        pirateShipDiscardPending: turnState.pirateShipDiscardPending,
        discardPile: discardPile,
      );

      // En sidladdning EFTER tredje kortvalet i starthandsutdelningen
      // (se pickHandDraftCard) men FÖRE "Klar" på regionomflyttningen
      // skulle annars fastna för alltid: hand/centerStacks är redan
      // synkade, men hasDrawnStartingHand sätts aldrig (den väntar på
      // finishRegionRearrangement) och startingRegionRearrangementActive
      // är rent lokalt UI-state som nollställs vid ombygget här ovan –
      // motståndaren skulle då aldrig få sin tur. Innan handsReady kan
      // inget annat i appen lägga kort i en odragen hand, så "egen hand
      // icke-tom men egen flagga false" pekar entydigt på det här
      // fallet.
      if (expansions.isNotEmpty &&
          !you.hasDrawnStartingHand &&
          you.hand.isNotEmpty) {
        state = state.copyWith(startingRegionRearrangementActive: true);
      }

      _subscribeToRoom(roomCode);

      // En Brödrafejd-förfrågan (se FraternalFeudsRequest) kan ha
      // kommit in medan den här klienten var nere (t.ex. en sidladdning
      // strax efter att motståndaren skickade den) – lyssnaren ovan
      // fångar bara FRAMTIDA värden, så kolla explicit efter en redan
      // väntande förfrågan också. Inte kritiskt för själva
      // återanslutningen, så ett fel här hoppas bara över i stället för
      // att blockera hela [resumeRoom].
      try {
        final pendingRequest = await _sync
            .watchFraternalFeudsRequest(roomCode)
            .first
            .timeout(const Duration(seconds: 5));
        if (pendingRequest != null && pendingRequest.requesterId != role) {
          _fulfillFraternalFeudsRequest(pendingRequest);
        }
      } catch (_) {
        // Ignoreras medvetet – se kommentaren ovan.
      }

      return null;
    } on TimeoutException {
      return 'Fick ingen kontakt med servern. Kontrollera internetanslutningen och försök igen.';
    } catch (e) {
      return 'Kunde inte återansluta till rummet: $e';
    }
  }

  /// Bygger om draghögarna lokalt efter [resumeRoom] – den här klienten
  /// känner bara till det synkade ANTALET kvar i varje hög
  /// ([centerStacks]), inte vilka specifika kort. Utgår från
  /// grundspelets fulla 36-korspool ([BasicSetDrawDeck]) – plus
  /// Gulderans egen pool när [expansions] innehåller
  /// [ExpansionSet.eraOfGold] (se [EraOfGoldDrawDeck]) – och drar bort
  /// de korttyper som redan syns i någon av spelarnas händer eller
  /// utplacerade på deras riken – annars skulle samma unika byggnad
  /// (t.ex. Klostret) kunna "dyka upp" igen i en dragstapel trots att
  /// den redan ligger på brädet. Köpmansgille räknas aldrig hit – de 2
  /// fysiska kopiorna ligger alltid ansikte-upp (se
  /// [GameState.faceUpExpansionCards], synkad separat, ingen
  /// rekonstruktion behövs där). Resten blandas och delas upp exakt
  /// enligt de synkade antalen (en hög per `centerStacks['draw$i']`
  /// som faktiskt finns, 4 eller 5 beroende på [expansions]), så att
  /// högarnas STORLEK alltid stämmer (helt avgörande – annars kan
  /// senare drag krascha mot en för kort lista); den exakta
  /// sammansättningen kan skilja sig något från vad som "egentligen"
  /// låg kvar, vilket är en accepterad brist (samma typ av brist som
  /// region-/händelsekortsstapeln redan hade).
  void _reconstructDrawStacksFromKnownCards(Player you, Player opponent,
      Map<String, int> centerStacks, Set<ExpansionSet> expansions) {
    final accountedFor = <String, int>{};
    void markKnown(GameCard card) {
      accountedFor.update(card.baseId, (v) => v + 1, ifAbsent: () => 1);
    }

    for (final card in [...you.hand, ...opponent.hand]) {
      markKnown(card);
    }
    for (final board in [you.principality, opponent.principality]) {
      for (final card in board.placedExpansionCards) {
        markKnown(card);
      }
    }

    // Fyra korttyper (Guldsmed/Lagerhus/Tullbro/Stora handelsskeppet)
    // återanvänds rakt av från grundspelet med extra fysiska kopior i
    // Gulderans egen pool (se EraOfGoldCards-doc) – samma id:n
    // förekommer alltså i BÅDA supplyCounts-tabellerna nedan. Ett känt
    // kort (i en hand/på ett rike) ska bara dras av EN gång från den
    // sammanlagda mängden, inte en gång per pool – annars saknas ett
    // kort i den slutliga sammanslagningen. remainingAccounted "spenderas"
    // här: grundspelspoolen (som byggs först) får dra av mot kända kort
    // innan Gulderan-poolen får resten.
    final remainingAccounted = Map<String, int>.from(accountedFor);
    int consumeAccounted(String id, int totalCount) {
      final have = remainingAccounted[id] ?? 0;
      final used = have < totalCount ? have : totalCount;
      remainingAccounted[id] = have - used;
      return totalCount - used;
    }

    final byId = {for (final c in BasicSetCards.all) c.id: c};
    final pool = <GameCard>[];
    BasicSetCards.supplyCounts.forEach((id, totalCount) {
      if (id == 'settlement' || id == 'city' || id == 'road') return;
      if (id.startsWith('event-')) return;
      final template = byId[id];
      if (template == null) return;
      final remaining = consumeAccounted(id, totalCount);
      // Offset (+1000) så id:na aldrig krockar med de "riktiga"
      // draghögs-id:na (0..totalCount-1) som redan kan ligga i en hand
      // eller på ett rike – kortsuffixet måste ändå matcha "-draw-N"
      // för att [GameCard.baseId] ska fortsätta strippa det korrekt.
      for (var i = 0; i < remaining; i++) {
        pool.add(template.copyWith(id: '$id-draw-${1000 + i}'));
      }
    });
    final hasGold = expansions.contains(ExpansionSet.eraOfGold);
    if (hasGold) {
      final goldById = {for (final c in EraOfGoldCards.all) c.id: c};
      EraOfGoldCards.supplyCounts.forEach((id, totalCount) {
        if (id.startsWith('event-')) return;
        if (id == EraOfGoldCards.merchantGuild.id) return;
        final template = goldById[id] ?? byId[id];
        if (template == null) return;
        final remaining = consumeAccounted(id, totalCount);
        for (var i = 0; i < remaining; i++) {
          pool.add(template.copyWith(id: '$id-gold-draw-${1000 + i}'));
        }
      });
    }
    pool.shuffle();

    final stackCount = hasGold ? 5 : 4;
    final counts = [
      for (var i = 0; i < stackCount; i++) centerStacks['draw${i + 1}'] ?? 0,
    ];
    final stacks = <List<GameCard>>[];
    var offset = 0;
    for (final count in counts) {
      final end = (offset + count).clamp(0, pool.length);
      stacks.add(pool.sublist(offset.clamp(0, pool.length), end));
      offset += count;
    }
    _drawStacks = stacks;
  }

  /// Ett JSON-ögonblick av allt som krävs för att återuppta ett HELT
  /// lokalt spel (inget rum, se [SessionMode.local]) efter en
  /// sidladdning – till skillnad från [resumeRoom] finns ingen Firebase
  /// att hämta det synkade innehållet från, så här sparas/återställs
  /// ALLT rakt av (inklusive de tre lokala dragstaplarna) i stället för
  /// att byggas om. Sparas av lyssnaren i main.dart, läses av
  /// [resumeLocalSnapshot].
  Map<String, dynamic> buildLocalSnapshotJson() => {
        'you': state.you.toJson(),
        'opponent': state.opponent.toJson(),
        'centerStacks': state.centerStacks,
        if (state.activeExpansions.isNotEmpty)
          'activeExpansions':
              state.activeExpansions.map((e) => e.name).toList(),
        'activePlayerId': state.activePlayerId,
        'diceRolled': state.diceRolled,
        if (state.productionRoll != null)
          'productionRoll': state.productionRoll,
        if (state.eventDieFace != null)
          'eventDieFace': state.eventDieFace!.name,
        if (state.drawnEventCard != null)
          'drawnEventCard': state.drawnEventCard!.toJson(),
        if (state.winnerId != null) 'winnerId': state.winnerId,
        if (state.discardPile.isNotEmpty)
          'discardPile': state.discardPile.map((c) => c.toJson()).toList(),
        if (state.faceUpExpansionCards.isNotEmpty)
          'faceUpExpansionCards':
              state.faceUpExpansionCards.map((c) => c.toJson()).toList(),
        'drawStacks': _drawStacks
            .map((stack) => stack.map((c) => c.toJson()).toList())
            .toList(),
        'eventDeck': _eventDeck.map((c) => c.toJson()).toList(),
        'regionDeck': _regionDeck.map((c) => c.toJson()).toList(),
      };

  /// Motsatsen till [buildLocalSnapshotJson] – återställer ett helt
  /// lokalt spel exakt som det var, inklusive de tre lokala
  /// dragstaplarna (ingen ombyggnad behövs, se [_reconstructDrawStacksFromKnownCards]
  /// som bara är nödvändig för rum där kortinnehållet inte är synkat).
  void resumeLocalSnapshot(Map<String, dynamic> json) {
    List<GameCard> parseCards(Object? raw) => (raw as List)
        .map((c) => GameCard.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    _drawStacks = (json['drawStacks'] as List)
        .map((stack) => parseCards(stack))
        .toList();
    _eventDeck = parseCards(json['eventDeck']);
    _regionDeck = parseCards(json['regionDeck']);

    state = GameState(
      you: Player.fromJson(Map<String, dynamic>.from(json['you'] as Map)),
      opponent:
          Player.fromJson(Map<String, dynamic>.from(json['opponent'] as Map)),
      centerStacks: Map<String, int>.from(json['centerStacks'] as Map),
      activeExpansions: json['activeExpansions'] == null
          ? const {}
          : (json['activeExpansions'] as List)
              .map((e) => ExpansionSet.values.byName(e as String))
              .toSet(),
      activePlayerId: json['activePlayerId'] as String,
      diceRolled: json['diceRolled'] as bool? ?? false,
      productionRoll: json['productionRoll'] as int?,
      eventDieFace: json['eventDieFace'] == null
          ? null
          : EventDieFace.values.byName(json['eventDieFace'] as String),
      drawnEventCard: json['drawnEventCard'] == null
          ? null
          : GameCard.fromJson(
              Map<String, dynamic>.from(json['drawnEventCard'] as Map)),
      winnerId: json['winnerId'] as String?,
      discardPile: json['discardPile'] == null
          ? const []
          : parseCards(json['discardPile']),
      faceUpExpansionCards: json['faceUpExpansionCards'] == null
          ? const []
          : parseCards(json['faceUpExpansionCards']),
    );
  }

  /// Lämnar spelet helt (till skillnad från [playLocally], som också
  /// används INOM ett spel för att t.ex. lämna ett rum och börja om
  /// lokalt): återställer till lokalt läge OCH glömmer den sparade
  /// sessionen (se [SessionStorage]) så att en efterföljande sidladdning
  /// hamnar på startskärmen i stället för att återuppta matchen man just
  /// lämnade.
  void leaveGame() {
    playLocally();
    SessionStorage.clear();
  }

  void _subscribeToRoom(String roomCode) {
    _playersSub?.cancel();
    _centerStacksSub?.cancel();
    _turnStateSub?.cancel();
    _fraternalFeudsRequestSub?.cancel();
    _discardPileSub?.cancel();
    _faceUpExpansionCardsSub?.cancel();

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
          peekingStackIndex: turnState.peekingStackIndex,
          clearPeekingStackIndex: turnState.peekingStackIndex == null,
          winnerId: turnState.winnerId,
          pirateShipDiscardPending: turnState.pirateShipDiscardPending,
        );
      },
      onError: (Object e) {
        state = state.copyWith(sessionError: 'Kunde inte synka omgången: $e');
      },
    );

    // Brödrafejd online (se pickFraternalFeudsCard/
    // _fulfillFraternalFeudsRequest): reagerar bara på en förfrågan
    // NÅGON ANNAN skickade – annars skulle avsändarens egen klient
    // (som redan hanterat sitt val lokalt) försöka tillämpa den på sig
    // själv igen så fort skrivningen ekar tillbaka via strömmen.
    _fraternalFeudsRequestSub =
        _sync.watchFraternalFeudsRequest(roomCode).listen(
      (request) {
        if (request == null) return;
        if (request.requesterId == state.myPlayerId) return;
        _fulfillFraternalFeudsRequest(request);
      },
      onError: (Object e) {
        state =
            state.copyWith(sessionError: 'Kunde inte synka Brödrafejd: $e');
      },
    );

    _discardPileSub = _sync.watchDiscardPile(roomCode).listen(
      (discardPile) => state = state.copyWith(discardPile: discardPile),
      onError: (Object e) {
        state =
            state.copyWith(sessionError: 'Kunde inte synka slänghögen: $e');
      },
    );

    _faceUpExpansionCardsSub =
        _sync.watchFaceUpExpansionCards(roomCode).listen(
      (cards) => state = state.copyWith(faceUpExpansionCards: cards),
      onError: (Object e) {
        state = state.copyWith(
            sessionError: 'Kunde inte synka ansikte-upp-högen: $e');
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

  void _syncDiscardPile() {
    final roomCode = state.roomCode;
    if (roomCode == null) return;
    unawaited(_sync.writeDiscardPile(roomCode, state.discardPile));
  }

  void _syncFaceUpExpansionCards() {
    final roomCode = state.roomCode;
    if (roomCode == null) return;
    unawaited(_sync.writeFaceUpExpansionCards(
        roomCode, state.faceUpExpansionCards));
  }

  /// Lägger [card] överst i slänghögen (se [GameState.discardPile]) och
  /// synkar den – spelade handlingskort (se [discardActionCard]) och
  /// byggnader/enheter/skepp som bytts ut mot ett nytt kort på samma
  /// plats (se [dropExpansion]) hamnar här. INTE samma sak som att lägga
  /// ett kort längst ner i en draghög (Fejd/Brödrafejd/handjustering/
  /// kika-fasen) – de mekanikerna är oförändrade och rör aldrig
  /// slänghögen.
  ///
  /// Bara relevant med minst ett tema aktivt (se
  /// [GameState.activeExpansions]) – grundspelet har ingen synlig
  /// slänghög (regelhäftet nämner ingen sådan), så utan tema försvinner
  /// kortet i stället spårlöst, precis som innan den här mekaniken
  /// fanns.
  void _discardToPile(GameCard card) {
    if (state.activeExpansions.isEmpty) return;
    state = state.copyWith(discardPile: [...state.discardPile, card]);
    _syncDiscardPile();
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
        peekingStackIndex: state.peekingStackIndex,
        winnerId: state.winnerId,
        pirateShipDiscardPending: state.pirateShipDiscardPending,
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

  /// Spelar Reiner härolden (regelhäftet: spela innan tärningen slås,
  /// bestäm att händelsen blir Fest) – tvärtom mot [useBrigitta], som
  /// tvingar PRODUKTIONStalet men slår händelsetärningen som vanligt:
  /// här slås produktionstalet som vanligt (slumpmässigt), men
  /// HÄNDELSEtärningens utfall TVINGAS till [EventDieFace.celebration]
  /// i stället för att slås. Den utlovade extra resursen står bara i
  /// kortets egen `effectText` – spelaren lägger till den själv med
  /// +/-, samma mönster som alla andra resurseffekter i appen (se
  /// event_die_resolution.dart-docen: inget flyttas automatiskt).
  /// Kortet tas bort från handen. Bara giltigt innan tärningen slagits
  /// den här omgången.
  String? useReinerTheHerald() {
    if (!state.isMyTurn) return 'Inte din tur.';
    if (state.diceRolled) {
      return 'Reiner härolden måste spelas innan tärningen slås.';
    }
    GameCard? card;
    for (final c in state.you.hand) {
      if (c.baseId == EraOfGoldCards.reinerTheHerald.id) {
        card = c;
        break;
      }
    }
    if (card == null) return null;

    final roll = Random().nextInt(6) + 1;
    state = state.copyWith(
      you: state.you.copyWith(hand: List.of(state.you.hand)..remove(card)),
      productionRoll: roll,
      eventDieFace: EventDieFace.celebration,
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
  ///
  /// UNDANTAG (Fejd/Brödrafejd online): den ena sidan ser bara en
  /// passiv "OK"-knapp medan den andra faktiskt ska göra något
  /// interaktivt (Fejd: den UTAN styrkeövertaget väljer bort en
  /// byggnad, se [startFeudBuildingPick]. Brödrafejd: den MED
  /// övertaget väljer 2 kort, se [startFraternalFeudsPick]). Trycker
  /// den passiva sidan OK för snabbt hinner det synkas till
  /// motståndaren (via [TurnState.drawnEventCard]) innan den aktiva
  /// sidan hunnit agera – båda de metoderna kräver ett uppslaget kort
  /// och skulle då tyst vägra starta, så den aktiva sidan fick aldrig
  /// chansen att göra sitt val. Så länge den aktiva sidan faktiskt har
  /// något att göra (en byggnad att ta bort, respektive kort kvar i
  /// handen att välja bland) stängs kortet därför bara LOKALT här (utan
  /// synk) – det riktiga, synkade avslutet sker i stället i
  /// [resolveFeudBuildingRemoval] respektive när båda Brödrafejd-korten
  /// är valda i [pickFraternalFeudsCard].
  String? dismissEventCard() {
    if (state.drawnEventCard == null) return null;
    final baseId = state.drawnEventCard!.baseId;
    final isFeud = baseId == BasicSetCards.feud.id;
    final isFraternalFeuds = baseId == BasicSetCards.fraternalFeuds.id;
    final advantage = state.strengthAdvantagePlayerId;
    final otherSideMustActFirst = (isFeud &&
            advantage == state.myPlayerId &&
            state.opponent.principality.hasAnyBuilding) ||
        (isFraternalFeuds &&
            advantage != null &&
            advantage != state.myPlayerId &&
            state.you.hand.isNotEmpty);
    state = state.copyWith(clearDrawnEventCard: true);
    if (!otherSideMustActFirst) _syncTurnState();
    return null;
  }

  // ---------------------------------------------------------------------
  // Fejd: spelaren utan styrkeövertaget tar bort en av sina egna
  // byggnader (inte skepp/hjältar) och lägger den underst i en
  // draghög. Fungerar i både lokalt och online läge – till skillnad
  // från Brödrafejd (se nedan) rör den bara din egen data.
  // ---------------------------------------------------------------------

  /// Startar bygg-väljaren när du är den utan styrkeövertaget (se
  /// [GameState.strengthAdvantagePlayerId]). No-op om det inte finns
  /// något uppslaget Fejd-kort, om det är oavgjort, om det är du som
  /// har övertaget (då är det motståndaren som ska välja bort en
  /// byggnad, inte du), eller om du inte har någon byggnad över huvud
  /// taget att välja mellan (se [RealmBoard.hasAnyBuilding]) – annars
  /// skulle spelet be dig välja en byggnad som inte finns, utan något
  /// sätt att komma vidare (game_board_screen.dart visar i stället
  /// "inget händer" direkt i det fallet, se [FeudResolutionCard]).
  String? startFeudBuildingPick() {
    if (state.drawnEventCard == null) return null;
    final advantage = state.strengthAdvantagePlayerId;
    if (advantage == null || advantage == state.myPlayerId) return null;
    if (!state.you.principality.hasAnyBuilding) return null;
    state = state.copyWith(
        feudBuildingPickActive: true, clearFeudPickedBuilding: true);
    return null;
  }

  /// Avbryter bygg-väljaren utan att göra något.
  String? cancelFeudBuildingPick() {
    state = state.copyWith(
        feudBuildingPickActive: false, clearFeudPickedBuilding: true);
    return null;
  }

  /// Väljer vilken av dina egna byggnader (inte skepp/hjältar –
  /// regelhäftet gäller bara byggnader för Fejd) som ska bort. Nästa
  /// steg är att välja vilken draghög den ska läggas underst i (se
  /// [resolveFeudBuildingRemoval]).
  String? selectFeudBuilding(int column, BuildingRow row, int slotIndex) {
    if (!state.feudBuildingPickActive) return null;
    final placed =
        _expansionAt(state.you.principality, column, row, slotIndex);
    if (placed == null) return null;
    if (placed.card.expansionKind != ExpansionKind.building) {
      return 'Fejd gäller bara byggnader, inte skepp eller hjältar.';
    }
    state = state.copyWith(
      feudPickedBuilding: RelocationSelection(
          kind: RelocationTargetKind.expansion,
          column: column,
          row: row,
          slotIndex: slotIndex),
    );
    return null;
  }

  /// Tar bort den valda byggnaden och lägger den underst i draghög
  /// [stackIndex] – avslutar Fejd.
  String? resolveFeudBuildingRemoval(int stackIndex) {
    final picked = state.feudPickedBuilding;
    if (picked == null) return null;
    // Peek:ar kortet (utan att ta bort det) för att kunna avvisa fel
    // hög INNAN byggnaden faktiskt plockas bort från riket – annars
    // skulle den kunna gå förlorad om högen visade sig vara fel typ.
    final peeked = state.you.principality
        .expansionAt(picked.column, picked.row, picked.slotIndex);
    if (peeked == null) return null;
    final originError = _checkStackMatchesCardOrigin(peeked.card, stackIndex);
    if (originError != null) return originError;

    final removed = state.you.principality
        .removeExpansion(picked.column, picked.row, picked.slotIndex);
    if (removed == null) return null;

    _drawStacks[stackIndex] = [..._drawStacks[stackIndex], removed.card];
    state = state.copyWith(
      you: state.you,
      centerStacks: Map.of(state.centerStacks)
        ..update('draw${stackIndex + 1}', (v) => v + 1),
      feudBuildingPickActive: false,
      clearFeudPickedBuilding: true,
      clearDrawnEventCard: true,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    _syncTurnState();
    return null;
  }

  // ---------------------------------------------------------------------
  // Piratskepp: motståndaren väljer bort ett eget handelsskepp, se
  // [_maybeTriggerPirateShip]/[TurnState.pirateShipDiscardPending]-doc.
  // Precis som Fejd tar den DRABBADE spelaren bort sitt EGET kort på sin
  // EGEN klient – funkar därför i både lokalt och online läge utan
  // särskild förgrening.
  // ---------------------------------------------------------------------

  /// Väljer bort och kasserar ETT av dina egna handelsskepp – ett enda
  /// tryck räcker (till skillnad från Fejd behövs ingen draghögsval,
  /// kortet hamnar direkt i slänghögen, se kortets egen text).
  /// No-op om ingen väntar-flagga är satt, platsen är tom, eller kortet
  /// där inte är ett handelsskepp.
  String? resolvePirateShipDiscard(int column, BuildingRow row, int slotIndex) {
    if (!state.pirateShipDiscardPending) return null;
    final placed = state.you.principality.expansionAt(column, row, slotIndex);
    if (placed == null) return null;
    if (placed.card.expansionKind != ExpansionKind.tradeShip) {
      return 'Piratskepp kräver att du väljer ett handelsskepp.';
    }
    final removed =
        state.you.principality.removeExpansion(column, row, slotIndex);
    if (removed == null) return null;
    state = state.copyWith(you: state.you, pirateShipDiscardPending: false);
    recomputeTokenHolders();
    _syncMyPlayer();
    _syncTurnState();
    _discardToPile(removed.card);
    return null;
  }

  // ---------------------------------------------------------------------
  // Brödrafejd: spelaren MED styrkeövertaget väljer 2 kort från
  // motståndarens hand. Lokalt muteras motståndarens hand/draghög
  // direkt (samma [GameNotifier] äger båda spelarnas data där). Online
  // äger ingen klient skrivrätt till den andra spelarens Firebase-post
  // (se [_syncMyPlayer] – bara "mig själv" skrivs), så i stället för att
  // mutera lokalt skickas en [FraternalFeudsRequest] så fort båda korten
  // är valda – motståndarens klient tillämpar den på sig själv (se
  // [_fulfillFraternalFeudsRequest]) och rensar den sedan.
  // ---------------------------------------------------------------------

  /// Startar handväljaren när du har styrkeövertaget. No-op utan
  /// uppslaget Brödrafejd-kort, vid oavgjort, eller om det är
  /// motståndaren som har övertaget.
  String? startFraternalFeudsPick() {
    if (state.drawnEventCard == null) return null;
    if (state.strengthAdvantagePlayerId != state.myPlayerId) return null;
    state = state.copyWith(
        fraternalFeudsPicking: true,
        fraternalFeudsPicked: const [],
        fraternalFeudsPickedStacks: const []);
    return null;
  }

  /// Avbryter handväljaren utan att göra något.
  String? cancelFraternalFeudsPick() {
    state = state.copyWith(
        fraternalFeudsPicking: false,
        fraternalFeudsPicked: const [],
        fraternalFeudsPickedStacks: const []);
    return null;
  }

  /// Väljer [card] från motståndarens hand och lägger den underst i
  /// draghög [stackIndex]. Upprepas tills 2 kort är valda, då avslutas
  /// Brödrafejd automatiskt – lokalt genom att mutera motståndarens
  /// hand/draghög direkt, online genom att skicka en
  /// [FraternalFeudsRequest] som motståndarens klient tillämpar på sig
  /// själv.
  String? pickFraternalFeudsCard(GameCard card, int stackIndex) {
    if (!state.fraternalFeudsPicking) return null;
    if (!state.opponent.hand.contains(card)) return null;
    final originError = _checkStackMatchesCardOrigin(card, stackIndex);
    if (originError != null) return originError;

    final picked = [...state.fraternalFeudsPicked, card];
    final pickedStacks = [...state.fraternalFeudsPickedStacks, stackIndex];
    final done = picked.length >= 2;

    if (!state.isOnline) {
      _drawStacks[stackIndex] = [..._drawStacks[stackIndex], card];
      final updatedOpponent = state.opponent
          .copyWith(hand: List.of(state.opponent.hand)..remove(card));
      state = state.copyWith(
        opponent: updatedOpponent,
        centerStacks: Map.of(state.centerStacks)
          ..update('draw${stackIndex + 1}', (v) => v + 1),
        fraternalFeudsPicked: picked,
        fraternalFeudsPickedStacks: pickedStacks,
        fraternalFeudsPicking: !done,
        clearDrawnEventCard: done,
      );
      _syncCenterStacks();
      if (done) _syncTurnState();
      return null;
    }

    // Online: bara lokalt UI-state tills båda korten är valda – ingen
    // mutation av motståndarens (synkade, men bara läsbara) data här.
    state = state.copyWith(
      fraternalFeudsPicked: picked,
      fraternalFeudsPickedStacks: pickedStacks,
      fraternalFeudsPicking: !done,
      clearDrawnEventCard: done,
    );
    if (done) {
      final roomCode = state.roomCode;
      if (roomCode != null) {
        unawaited(_sync.writeFraternalFeudsRequest(
          roomCode,
          FraternalFeudsRequest(
            requesterId: state.myPlayerId,
            cardIds: picked.map((c) => c.id).toList(),
            stackIndices: pickedStacks,
          ),
        ));
      }
      _syncTurnState();
    }
    return null;
  }

  /// Tillämpar en mottagen [FraternalFeudsRequest] på DIN EGEN hand –
  /// bara motståndarens klient (den UTAN styrkeövertaget) kör den här,
  /// som svar på att den MED övertaget (online) valt 2 kort ur din hand
  /// (se [pickFraternalFeudsCard]). Letar upp de två angivna korten via
  /// id (precis som andra handkorts-operationer) och lägger dem underst
  /// i respektive draghög, sedan rensar förfrågan så den inte tillämpas
  /// igen (t.ex. efter en sidladdning, se [resumeRoom]).
  void _fulfillFraternalFeudsRequest(FraternalFeudsRequest request) {
    var hand = List<GameCard>.of(state.you.hand);
    final centerStacks = Map<String, int>.of(state.centerStacks);
    for (var i = 0; i < request.cardIds.length; i++) {
      GameCard? card;
      for (final c in hand) {
        if (c.id == request.cardIds[i]) {
          card = c;
          break;
        }
      }
      if (card == null) continue; // redan borta – t.ex. dubbelleverans
      hand = List.of(hand)..remove(card);
      final stackIndex = request.stackIndices[i];
      _drawStacks[stackIndex] = [..._drawStacks[stackIndex], card];
      centerStacks.update('draw${stackIndex + 1}', (v) => v + 1);
    }
    state = state.copyWith(
      you: state.you.copyWith(hand: hand),
      centerStacks: centerStacks,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    final roomCode = state.roomCode;
    if (roomCode != null) unawaited(_sync.clearFraternalFeudsRequest(roomCode));
  }

  /// Spelar ett självbevakat handlingskort (Handelskaravan/Guldsmed):
  /// tar bort kortet från handen och lägger det överst i slänghögen (se
  /// [_discardToPile]) – spelaren justerar sedan själv resurserna
  /// manuellt med +/- på sina regioner utifrån kortets `effectText`,
  /// precis som byggkostnader och tärningsutdelning. Bara giltigt under
  /// action-fasen, precis som ett bygge (se [_checkCanBuild]) –
  /// handlingskort spelas efter tärningsslaget, inte innan.
  String? discardActionCard(GameCard card) {
    final turnError = _checkCanBuild();
    if (turnError != null) return turnError;
    if (!state.you.hand.contains(card)) return null;

    state = state.copyWith(
      you: state.you.copyWith(hand: List.of(state.you.hand)..remove(card)),
    );
    _syncMyPlayer();
    _discardToPile(card);
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

  /// Som [adjustRegionResource], men för en landskapsutbyggnads EGNA
  /// lager (t.ex. guld i en Guldgömma), se
  /// [RealmBoard.addResourceToRegionExpansion].
  void adjustRegionExpansionResource(int junctionColumn, BuildingRow row, int delta) {
    state.you.principality.addResourceToRegionExpansion(junctionColumn, row, delta);
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
  ///
  /// Kollar också vinstvillkoret (regelhäftet: [GameState.victoryPointTarget]
  /// eller fler segerpoäng vid slutet av sin egen runda, se
  /// [GameState.totalVictoryPointsFor]) – bara här, eftersom det här är
  /// enda stället en runda faktiskt tar slut (se
  /// [skipTrade]/[exchangeDraw]/[peekTakeCard]). Om du vann lämnas turen
  /// INTE över – [GameState.winnerId] sätts i stället och spelet fryser
  /// i din slutställning (se [GameOverOverlay]).
  void _advanceToNextPlayer() {
    final youWon =
        state.totalVictoryPointsFor(state.you) >= state.victoryPointTarget;
    final next = youWon
        ? state.activePlayerId
        : (state.activePlayerId == state.myPlayerId
            ? state.opponentPlayerId
            : state.myPlayerId);
    state = state.copyWith(
      activePlayerId: next,
      winnerId: youWon ? state.myPlayerId : null,
      diceRolled: false,
      clearProductionRoll: true,
      clearDrawnEventCard: true,
      handAdjustmentPhase: HandAdjustmentPhase.none,
      tradePhase: TradePhase.none,
      clearPeekStackIndex: true,
      clearPeekedCards: true,
      clearPeekingStackIndex: true,
      awaitingScoutDecision: false,
      clearScoutChoices: true,
      relocationActive: false,
      clearRelocationFirst: true,
      feudBuildingPickActive: false,
      clearFeudPickedBuilding: true,
      fraternalFeudsPicking: false,
      fraternalFeudsPicked: const [],
      fraternalFeudsPickedStacks: const [],
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

  /// Om draghög [stackIndex] är en av Gulderans EGNA högar (de sista 2
  /// av 5, se [_resetDecks]/[EraOfGoldDrawDeck]) – `false` för
  /// grundspelets högar, och alltid `false` utan Gulderan aktivt (bara
  /// 4 högar då).
  bool _isGoldStackIndex(int stackIndex) =>
      _drawStacks.length == 5 && stackIndex >= _drawStacks.length - 2;

  /// Om [card] fysiskt drogs från en av Gulderans egna högar – avgörs
  /// av draghögs-suffixet i [GameCard.id] ("-gold-draw-N", se
  /// [EraOfGoldDrawDeck]/[_reconstructDrawStacksFromKnownCards]), INTE
  /// av [GameCard.expansionSet]: fyra korttyper (Guldsmed/Lagerhus/
  /// Tullbro/Stora handelsskeppet) återanvänds från grundspelets egna
  /// definition (`expansionSet: basic`) men fyller ändå platser i
  /// Gulderans fysiska hög – bara suffixet avslöjar vilken pool kortet
  /// faktiskt kom ifrån.
  bool _isGoldCard(GameCard card) => card.id.contains('-gold-draw-');

  /// Kollar att [card] hör hemma i draghög [stackIndex] – grundspelskort
  /// får bara läggas tillbaka i grundspelets högar, Gulderan-kort bara i
  /// Gulderans (regelhäftets uppdelning per set, se
  /// [_isGoldStackIndex]/[_isGoldCard]) – annars ett tydligt
  /// felmeddelande i stället för att tyst blanda ihop högarna.
  String? _checkStackMatchesCardOrigin(GameCard card, int stackIndex) {
    if (_isGoldCard(card) == _isGoldStackIndex(stackIndex)) return null;
    return _isGoldCard(card)
        ? 'Det kortet hör till en av Gulderans högar.'
        : 'Det kortet hör till en av grundspelets högar.';
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
  /// under [HandAdjustmentPhase.discarding] – spelaren väljer själv
  /// vilken hög, men den måste höra till samma set som [card]
  /// ursprungligen kom ifrån (se [_checkStackMatchesCardOrigin]). Går
  /// vidare till kortbytesfasen automatiskt så fort
  /// [GameState.handLimit] är nått.
  String? discardHandCard(GameCard card, int stackIndex) {
    if (state.handAdjustmentPhase != HandAdjustmentPhase.discarding) {
      return null;
    }
    if (!state.you.hand.contains(card)) return null;
    final originError = _checkStackMatchesCardOrigin(card, stackIndex);
    if (originError != null) return originError;

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
    final originError = _checkStackMatchesCardOrigin(card, stackIndex);
    if (originError != null) return originError;

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
    final originError = _checkStackMatchesCardOrigin(card, stackIndex);
    if (originError != null) return originError;

    _discardCardToStack(card, stackIndex);
    state = state.copyWith(tradePhase: TradePhase.peekChoosingStack);
    return null;
  }

  /// Slår upp alla kort i draghög [stackIndex], i den ordning de
  /// faktiskt ligger (första kortet i listan är överst), så att UI kan
  /// visa dem och spelaren väljer ett att behålla (se [peekTakeCard]).
  /// [GameState.peekingStackIndex] synkas samtidigt – bara vilken hög,
  /// aldrig vilka kort – så att motståndaren ser att (och var) man
  /// kikar, precis som vid ett fysiskt bord.
  String? choosePeekStack(int stackIndex) {
    if (state.tradePhase != TradePhase.peekChoosingStack) return null;
    state = state.copyWith(
      tradePhase: TradePhase.peekViewing,
      peekStackIndex: stackIndex,
      peekedCards: List.of(_drawStacks[stackIndex]),
      peekingStackIndex: stackIndex,
    );
    _syncTurnState();
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

  /// Väljer draghög [index] (0–3) och tar dess 3 översta kort BLINT som
  /// starthand (regelhäftet s. 6) – grundspelets väg, utan tema aktivt
  /// (se game_board_screen.dart:s `onChooseStack`, som väljer den här
  /// eller [startHandDraft] beroende på [GameState.activeExpansions]).
  /// Bara giltigt om det är den här spelarens tur att välja (se
  /// [GameState.isMyTurnToChooseHand]) och högen inte redan är vald.
  /// Returnerar `null` vid lyckat val, annars ett felmeddelande.
  String? chooseStartingStack(int index) {
    if (state.handsReady) return null;
    if (!state.isMyTurnToChooseHand) {
      return 'Inte din tur att välja en draghög.';
    }
    final key = 'draw${index + 1}';
    final fullSize = state.initialDrawStackSizes[index];
    if ((state.centerStacks[key] ?? 0) < fullSize) {
      return 'Den högen är redan vald.';
    }

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
  // Starthand med tema: kika i en av grundspelets 3 högar, välj 3 kort
  // ---------------------------------------------------------------------

  /// Väljer en av grundspelets 3 draghögar (index 0–2, aldrig en av
  /// Gulderans egna) att KIKA I, i stället för att blint dra – bekräftad
  /// regel: "Man väljer en av de tre högarna som innehåller korten från
  /// grundspelet. Man får kika på alla kort i högen och välja ut tre."
  /// Alla kortet i högen läggs synliga i [GameState.startingHandDraftPool]
  /// (se [pickHandDraftCard] för själva valet). Ingen synk här – rent
  /// lokalt tills utdelningen är klar (se [pickHandDraftCard]s doc för
  /// vad det betyder vid en sidladdning mitt i).
  String? startHandDraft(int index) {
    if (state.handsReady) return null;
    if (!state.isMyTurnToChooseHand) {
      return 'Inte din tur att välja en draghög.';
    }
    if (state.startingHandDraftStackIndex != null) return null;
    // UI:t ska aldrig göra det här möjligt (se CenterStacksStrip), men
    // dubbelkollar ändå – Gulderans egna högar hör inte till starthanden.
    if (_isGoldStackIndex(index)) return null;
    final key = 'draw${index + 1}';
    final fullSize = state.initialDrawStackSizes[index];
    if ((state.centerStacks[key] ?? 0) < fullSize) {
      return 'Den högen är redan vald.';
    }

    state = state.copyWith(
      startingHandDraftStackIndex: index,
      startingHandDraftPool: List.of(_drawStacks[index]),
      startingHandDraftPicked: const [],
    );
    return null;
  }

  /// Plockar [card] ur den uppslagna högen (se [startHandDraft]) till
  /// din starthand. Vid det tredje kortet avslutas utdelningen: de
  /// återstående 9 korten läggs tillbaka i draghögen i exakt samma
  /// inbördes ordning som de låg i innan (de har bara tagits BORT ur en
  /// kopia av den ursprungliga högen, aldrig blandats om), handen/
  /// centerStacks uppdateras i ett enda svep och synkas.
  ///
  /// Går sedan direkt in i den fria regionomflyttningsfasen (bekräftad
  /// regel: "Fri omflyttning av egna 6 regioner", se
  /// [selectRegionRearrangementTarget]/[finishRegionRearrangement]) i
  /// stället för att sätta [Player.hasDrawnStartingHand] direkt – den
  /// flaggan väntar tills spelaren uttryckligen trycker "Klar" där, så
  /// att motståndarens klient automatiskt väntar genom HELA sekvensen
  /// (se [GameState.pendingHandChooserId]).
  String? pickHandDraftCard(GameCard card) {
    final pool = state.startingHandDraftPool;
    if (pool == null || !pool.contains(card)) return null;

    final newPool = List<GameCard>.of(pool)..remove(card);
    final picked = [...state.startingHandDraftPicked, card];
    if (picked.length < 3) {
      state = state.copyWith(
          startingHandDraftPool: newPool, startingHandDraftPicked: picked);
      return null;
    }

    final stackIndex = state.startingHandDraftStackIndex!;
    _drawStacks[stackIndex] = newPool;
    state = state.copyWith(
      you: state.you.copyWith(hand: [...state.you.hand, ...picked]),
      centerStacks: Map.of(state.centerStacks)
        ..update('draw${stackIndex + 1}', (v) => v - 3),
      clearStartingHandDraftStackIndex: true,
      clearStartingHandDraftPool: true,
      startingHandDraftPicked: const [],
      startingRegionRearrangementActive: true,
      clearStartingRegionRearrangementFirst: true,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return null;
  }

  // ---------------------------------------------------------------------
  // Fri regionomflyttning direkt efter starthandsutdelningen med tema
  // ---------------------------------------------------------------------

  /// Väljer en region i ditt eget rike under den fria
  /// regionomflyttningen (se [pickHandDraftCard]) – samma "första
  /// tryck lagras, andra tryck genomför bytet"-mönster som
  /// [selectRelocationTarget], men BARA regioner, inget kort inblandat
  /// och ingen [_checkCanBuild]-spärr (fasen sker före första
  /// tärningsslaget). Obegränsat antal byten, inget kostar något – se
  /// [finishRegionRearrangement] för det uttryckliga slutsteget.
  String? selectRegionRearrangementTarget(int column, BuildingRow row) {
    if (!state.startingRegionRearrangementActive) return null;

    final selection =
        RelocationSelection(kind: RelocationTargetKind.region, column: column, row: row);
    final first = state.startingRegionRearrangementFirst;

    if (first == null) {
      if (state.you.principality.regionAt(column, row) == null) return null;
      state = state.copyWith(startingRegionRearrangementFirst: selection);
      return null;
    }
    if (first == selection) {
      state = state.copyWith(clearStartingRegionRearrangementFirst: true);
      return null;
    }

    try {
      state.you.principality.swapRegions(first.column, first.row, column, row);
    } on StateError catch (e) {
      return e.message;
    }
    state = state.copyWith(
        you: state.you, clearStartingRegionRearrangementFirst: true);
    _syncMyPlayer();
    return null;
  }

  /// Avslutar den fria regionomflyttningen explicit (obligatoriskt
  /// steg, eftersom fri/obegränsad omflyttning annars saknar ett
  /// naturligt slut) – sätter [Player.hasDrawnStartingHand], som är
  /// det som faktiskt släpper fram motståndarens tur (se
  /// [GameState.pendingHandChooserId]). En kvarhängande första-
  /// markering (tryckt men inte bytt) släpps tyst.
  String? finishRegionRearrangement() {
    if (!state.startingRegionRearrangementActive) return null;
    state = state.copyWith(
      startingRegionRearrangementActive: false,
      clearStartingRegionRearrangementFirst: true,
      you: state.you.copyWith(hasDrawnStartingHand: true),
    );
    _syncMyPlayer();
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
    if (state.feudBuildingPickActive || state.fraternalFeudsPicking) {
      return 'Avsluta händelsekortet innan du bygger vidare.';
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

  /// Kollar om [column]/[row]/[slotIndex] redan har ett bygg-/enhets-/
  /// skeppskort MEN inget tema är aktivt – "byt ut byggnad" finns bara
  /// med minst ett tema aktivt (regelhäftet har ingen sådan regel för
  /// grundspelet, se [_discardToPile]-doc), så utan tema ska platsen
  /// avvisas precis som innan mekaniken fanns, i stället för att tyst
  /// byta ut det befintliga kortet. `null` om det går bra att bygga.
  String? _checkReplaceAllowed(int column, BuildingRow row, int slotIndex) {
    if (state.activeExpansions.isNotEmpty) return null;
    if (state.you.principality.expansionAt(column, row, slotIndex) != null) {
      return 'Den platsen är redan bebyggd.';
    }
    return null;
  }

  /// Delad kärna för [dropExpansion]/[buyFaceUpExpansion]: placerar
  /// [card] på byggplatsen (byter ut ett eventuellt redan liggande
  /// kort mot slänghögen, se [_discardToPile] – eventuella poäng det
  /// gav försvinner automatiskt eftersom det inte längre ligger i
  /// riket), synkar ditt rike. Anroparen ansvarar själv för att ta bort
  /// [card] från sin KÄLLA (hand respektive den delade ansikte-upp-
  /// högen) och synka den separat, INNAN det här anropas (annars skulle
  /// [recomputeTokenHolders] hinna räkna med kortet på fel ställe).
  void _placeExpansionCardAndSync(
      int column, BuildingRow row, int slotIndex, GameCard card) {
    final replaced =
        state.you.principality.removeExpansion(column, row, slotIndex);
    state.you.principality
        .placeExpansion(column, row, slotIndex, PlacedCard(card: card));
    state = state.copyWith(you: state.you, clearDraggingCard: true);
    recomputeTokenHolders();
    _syncMyPlayer();
    if (replaced != null) _discardToPile(replaced.card);
  }

  /// Bygger ett bygg-/enhets-/skeppskort FRÅN HANDEN på en byggplats.
  /// Om platsen redan har ett kort byts det ut i stället för att
  /// avvisas (se [PrincipalityGrid]s `onRequestBuildConfirm`/
  /// [BuildConfirmCard]s "Ersätter X"-text): [card] kostar sitt fulla
  /// pris som vanligt (ingen rabatt), se [_placeExpansionCardAndSync].
  String? dropExpansion(
      int column, BuildingRow row, int slotIndex, GameCard card) {
    final turnError = _checkCanBuild();
    if (turnError != null) return turnError;
    if (!state.you.hand.contains(card)) return null;
    if (card.isUnique &&
        state.you.principality.hasExpansionCard(card.baseId)) {
      return 'Du kan bara ha en ${card.name} i ditt rike.';
    }
    final replaceError = _checkReplaceAllowed(column, row, slotIndex);
    if (replaceError != null) return replaceError;
    final blockedReason =
        buildRequirementBlockedReason(card, state.you.principality, column, row);
    if (blockedReason != null) return blockedReason;

    state = state.copyWith(
        you: state.you.copyWith(hand: List.of(state.you.hand)..remove(card)));
    _placeExpansionCardAndSync(column, row, slotIndex, card);
    _maybeTriggerPirateShip(card);
    return null;
  }

  /// När [card] är Piratskepp och bygget lyckats: motståndaren måste
  /// välja bort ett eget handelsskepp (regelhäftet, se
  /// [EraOfGoldCards.pirateShip]-doc) – men bara om det faktiskt finns
  /// något att välja bort (kortets egen text: "Om motståndaren inte har
  /// några handelsskepp så händer inget"), se
  /// [RealmBoard.hasAnyTradeShip]. Sätter en synkad flagga i stället för
  /// att lösa det direkt här, eftersom det är MOTSTÅNDAREN (inte den
  /// aktiva spelaren) som ska välja – se [resolvePirateShipDiscard] och
  /// [TurnState.pirateShipDiscardPending]-doc för varför det (till
  /// skillnad från Fejd) kräver en riktig synkad signal.
  void _maybeTriggerPirateShip(GameCard card) {
    if (card.baseId != EraOfGoldCards.pirateShip.id) return;
    if (!state.opponent.principality.hasAnyTradeShip) return;
    state = state.copyWith(pirateShipDiscardPending: true);
    _syncTurnState();
  }

  /// Bygger ett landskapsutbyggnadskort (brun textruta, t.ex.
  /// Guldgömma) FRÅN HANDEN intill en av dina egna, redan utplacerade
  /// regioner AV MATCHANDE RESURSTYP (Guldgömma får bara plats på
  /// Guldfält, se [RealmBoard.placeRegionExpansion]), högst 1 per
  /// region. Ingen "byt ut"-variant behövs (bara 1 fysisk kopia av
  /// Guldgömma finns i hela spelet, kan aldrig behöva ersättas), och
  /// ingen kostnad dras av – precis som övriga bygg-/enhetskort visas
  /// kostnaden bara, den dras aldrig av automatiskt (se
  /// [_placeExpansionCardAndSync]-doc).
  String? dropRegionExpansion(int column, BuildingRow row, GameCard card) {
    final turnError = _checkCanBuild();
    if (turnError != null) return turnError;
    if (!state.you.hand.contains(card)) return null;
    final region = state.you.principality.regionAt(column, row);
    if (region == null) return null;
    if (region.card.resource != card.resource) {
      return '${card.name} kan bara placeras på en region av rätt resurstyp.';
    }
    if (state.you.principality.regionExpansionAt(column, row) != null) {
      return 'Den regionen har redan en landskapsutbyggnad.';
    }
    final blockedReason =
        buildRequirementBlockedReason(card, state.you.principality, column, row);
    if (blockedReason != null) return blockedReason;

    state = state.copyWith(
        you: state.you.copyWith(hand: List.of(state.you.hand)..remove(card)));
    state.you.principality.placeRegionExpansion(column, row, PlacedCard(card: card));
    state = state.copyWith(you: state.you, clearDraggingCard: true);
    recomputeTokenHolders();
    _syncMyPlayer();
    return null;
  }

  /// Köper ett kort direkt från den öppna ansikte-upp-högen (se
  /// [GameState.faceUpExpansionCards], t.ex. Gulderans Köpmansgille) –
  /// vem som helst kan bygga härifrån på sin egen tur, precis som ett
  /// vanligt bygge från handen (se [dropExpansion], samma byt-ut-regel
  /// om platsen redan är bebyggd).
  String? buyFaceUpExpansion(
      int column, BuildingRow row, int slotIndex, GameCard card) {
    final turnError = _checkCanBuild();
    if (turnError != null) return turnError;
    if (!state.faceUpExpansionCards.contains(card)) return null;
    if (card.isUnique &&
        state.you.principality.hasExpansionCard(card.baseId)) {
      return 'Du kan bara ha en ${card.name} i ditt rike.';
    }
    final replaceError = _checkReplaceAllowed(column, row, slotIndex);
    if (replaceError != null) return replaceError;

    state = state.copyWith(
        faceUpExpansionCards: List.of(state.faceUpExpansionCards)
          ..remove(card));
    _syncFaceUpExpansionCards();
    _placeExpansionCardAndSync(column, row, slotIndex, card);
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
  /// förlora kortet. Bara giltigt under action-fasen, precis som ett
  /// bygge (se [_checkCanBuild]) – kortet spelas efter tärningsslaget,
  /// inte innan.
  String? startRelocation() {
    final turnError = _checkCanBuild();
    if (turnError != null) return turnError;
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
