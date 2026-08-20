import 'dart:async';

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
final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

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

  @override
  GameState build() {
    ref.onDispose(() {
      _playersSub?.cancel();
      _centerStacksSub?.cancel();
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
    _resetDecks();
    state = GameState(
      you: MockGame.buildYou(),
      opponent: MockGame.buildOpponent(),
      centerStacks: MockGame.centerStackCounts(),
    );
  }

  /// Skapar ett nytt rum, blir "host" och väntar på att en motståndare
  /// ska gå med. Returnerar den genererade rumskoden.
  Future<String> hostRoom(String myName) async {
    final roomCode = MockGame.generateRoomCode();
    final hostPlayer = MockGame.buildStartingPlayer('host', myName, isRed: true);
    final waitingOpponent = MockGame.buildStartingPlayer('guest', 'Väntar på motståndare …', isRed: false);
    final centerStacks = MockGame.centerStackCounts();
    _resetDecks();

    try {
      await _sync.createRoom(roomCode, 'host', hostPlayer, centerStacks).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Fick ingen kontakt med servern. Kontrollera internetanslutningen och försök igen.');
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
    );
    _subscribeToRoom(roomCode);
    return roomCode;
  }

  /// Går med i ett befintligt rum. Returnerar `null` vid lyckat
  /// gick-med, annars ett felmeddelande att visa i lobbyn.
  Future<String?> joinRoom(String roomCode, String myName) async {
    final guestPlayer = MockGame.buildStartingPlayer('guest', myName, isRed: false);
    String? error;
    try {
      error = await _sync.joinRoom(roomCode, 'guest', guestPlayer).timeout(const Duration(seconds: 10));
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
    );
    _subscribeToRoom(roomCode);
    return null;
  }

  void _subscribeToRoom(String roomCode) {
    _playersSub?.cancel();
    _centerStacksSub?.cancel();

    _playersSub = _sync.watchPlayers(roomCode).listen(
      (players) {
        final opponentPlayer = players[state.opponentPlayerId];
        if (opponentPlayer == null) return;
        state = state.copyWith(opponent: opponentPlayer, opponentConnected: true, clearSessionError: true);
      },
      // Utan den här hanteraren skulle t.ex. ett rättighetsfel i
      // Firebase-databasreglerna tysta misslyckas – "väntar på
      // motståndare" skulle stå kvar för evigt utan någon förklaring.
      onError: (Object e) {
        state = state.copyWith(sessionError: 'Kunde inte synka med motståndaren: $e');
      },
    );

    _centerStacksSub = _sync.watchCenterStacks(roomCode).listen(
      (centerStacks) {
        if (centerStacks.isEmpty) return;
        state = state.copyWith(centerStacks: centerStacks);
      },
      onError: (Object e) {
        state = state.copyWith(sessionError: 'Kunde inte synka dragstaplarna: $e');
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

  // ---------------------------------------------------------------------
  // Bygga: spela kort från handen / center-dragstaplarna
  // ---------------------------------------------------------------------

  bool _canAfford(GameCard card) => state.you.principality.canAfford(card.buildingCost);

  /// Kollar att stapeln inte är slut och att spelaren har råd. Null om
  /// allt stämmer, annars ett felmeddelande.
  String? _checkStack(String stackKey, GameCard card) {
    if ((state.centerStacks[stackKey] ?? 0) <= 0) {
      return 'Inga fler ${card.name.toLowerCase()}or kvar i stapeln';
    }
    if (!_canAfford(card)) {
      return 'Inte råd med ${card.name}';
    }
    return null;
  }

  String? dropExpansion(int column, BuildingRow row, int slotIndex, GameCard card) {
    if (!state.you.hand.contains(card)) return null;
    if (!_canAfford(card)) return 'Inte råd med ${card.name}';

    state.you.principality.placeExpansion(column, row, slotIndex, PlacedCard(card: card));
    state.you.principality.spend(card.buildingCost);
    final updated = state.you.copyWith(hand: List.of(state.you.hand)..remove(card));

    state = state.copyWith(you: updated, clearDraggingCard: true);
    _syncMyPlayer();
    return null;
  }

  String? dropRoad(int column, GameCard card) {
    final error = _checkStack('roads', card);
    if (error != null) return error;

    state.you.principality.placeRoad(column, PlacedCard(card: card));
    state.you.principality.spend(card.buildingCost);

    state = state.copyWith(
      centerStacks: Map.of(state.centerStacks)..update('roads', (v) => v - 1),
      clearDraggingCard: true,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return null;
  }

  String? dropSettlement(int column, GameCard card) {
    final error = _checkStack('settlements', card);
    if (error != null) return error;

    final oldLeft = state.you.principality.leftmostColumn;
    final oldRight = state.you.principality.rightmostColumn;

    state.you.principality.placeSettlement(column, PlacedCard(card: card));

    // Regelhäftet s. 8: en ny by ger automatiskt de 2 översta korten
    // från regionstapeln, placerade i den nya, ännu tomma knutpunkten.
    final newJunction = column < oldLeft ? column - 1 : column + 1;
    final wasNewSettlementFurtherOut = column < oldLeft || column > oldRight;
    if (wasNewSettlementFurtherOut) {
      // Regelhäftet s. 8: nydragna regioner börjar tomma (sidan med 0
      // resurssymboler vänd mot dig).
      state.you.principality.placeRegion(newJunction, BuildingRow.above, PlacedCard(card: _drawRegion()));
      state.you.principality.placeRegion(newJunction, BuildingRow.below, PlacedCard(card: _drawRegion()));
    }

    state.you.principality.spend(card.buildingCost);

    state = state.copyWith(
      centerStacks: Map.of(state.centerStacks)
        ..update('settlements', (v) => v - 1)
        ..update('regions', (v) => wasNewSettlementFurtherOut ? v - 2 : v),
      clearDraggingCard: true,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return null;
  }

  String? dropCityUpgrade(int column, GameCard card) {
    final error = _checkStack('cities', card);
    if (error != null) return error;

    state.you.principality.upgradeToCity(column, PlacedCard(card: card));
    state.you.principality.spend(card.buildingCost);

    state = state.copyWith(
      centerStacks: Map.of(state.centerStacks)..update('cities', (v) => v - 1),
      clearDraggingCard: true,
    );
    _syncMyPlayer();
    _syncCenterStacks();
    return null;
  }
}
