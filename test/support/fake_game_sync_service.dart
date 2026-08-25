import 'dart:async';

import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_service.dart';

/// In-memory-fejk av [GameSyncService] för tester, eftersom riktig
/// Firebase-anslutning inte går att testa i CI/sandboxmiljö. Delar en
/// enda "databas" (statiska maps) så att två [GameNotifier]-instanser
/// (host + guest) kan synka mot varandra i samma test, precis som två
/// riktiga klienter skulle göra via Firebase.
class FakeGameSyncService implements GameSyncService {
  final Map<String, Map<String, Player>> _players = {};
  final Map<String, Map<String, int>> _centerStacks = {};
  final Map<String, TurnState> _turnStates = {};
  final Map<String, FraternalFeudsRequest?> _fraternalFeudsRequests = {};
  final Map<String, List<GameCard>> _discardPiles = {};
  final Map<String, Set<ExpansionSet>> _activeExpansions = {};
  final Map<String, List<GameCard>> _faceUpExpansionCards = {};
  final Map<String, List<List<GameCard>>> _drawStacks = {};
  final Map<String, StreamController<Map<String, Player>>> _playerControllers = {};
  final Map<String, StreamController<Map<String, int>>> _centerStackControllers = {};
  final Map<String, StreamController<TurnState>> _turnStateControllers = {};
  final Map<String, StreamController<FraternalFeudsRequest?>>
      _fraternalFeudsRequestControllers = {};
  final Map<String, StreamController<List<GameCard>>> _discardPileControllers = {};
  final Map<String, StreamController<Set<ExpansionSet>>>
      _activeExpansionsControllers = {};
  final Map<String, StreamController<List<GameCard>>>
      _faceUpExpansionCardsControllers = {};
  final Map<String, StreamController<List<List<GameCard>>>>
      _drawStacksControllers = {};

  StreamController<Map<String, Player>> _playersController(String roomCode) =>
      _playerControllers.putIfAbsent(roomCode, () => StreamController.broadcast());

  StreamController<Map<String, int>> _centerStacksController(String roomCode) =>
      _centerStackControllers.putIfAbsent(roomCode, () => StreamController.broadcast());

  StreamController<TurnState> _turnStateController(String roomCode) =>
      _turnStateControllers.putIfAbsent(roomCode, () => StreamController.broadcast());

  StreamController<FraternalFeudsRequest?> _fraternalFeudsRequestController(
          String roomCode) =>
      _fraternalFeudsRequestControllers.putIfAbsent(
          roomCode, () => StreamController.broadcast());

  StreamController<List<GameCard>> _discardPileController(String roomCode) =>
      _discardPileControllers.putIfAbsent(
          roomCode, () => StreamController.broadcast());

  StreamController<Set<ExpansionSet>> _activeExpansionsController(
          String roomCode) =>
      _activeExpansionsControllers.putIfAbsent(
          roomCode, () => StreamController.broadcast());

  StreamController<List<GameCard>> _faceUpExpansionCardsController(
          String roomCode) =>
      _faceUpExpansionCardsControllers.putIfAbsent(
          roomCode, () => StreamController.broadcast());

  StreamController<List<List<GameCard>>> _drawStacksController(
          String roomCode) =>
      _drawStacksControllers.putIfAbsent(
          roomCode, () => StreamController.broadcast());

  @override
  Future<void> createRoom(
    String roomCode,
    String hostId,
    Player hostPlayer,
    Map<String, int> centerStacks,
    TurnState turnState, {
    Set<ExpansionSet> activeExpansions = const {},
    List<GameCard> faceUpExpansionCards = const [],
    List<List<GameCard>> drawStacks = const [],
  }) async {
    _players[roomCode] = {hostId: hostPlayer};
    _centerStacks[roomCode] = Map.of(centerStacks);
    _turnStates[roomCode] = turnState;
    _discardPiles[roomCode] = const [];
    _activeExpansions[roomCode] = Set.of(activeExpansions);
    _faceUpExpansionCards[roomCode] = List.of(faceUpExpansionCards);
    _drawStacks[roomCode] = drawStacks.map(List<GameCard>.of).toList();
    _playersController(roomCode).add(Map.of(_players[roomCode]!));
    _centerStacksController(roomCode).add(Map.of(_centerStacks[roomCode]!));
    _turnStateController(roomCode).add(turnState);
    _discardPileController(roomCode).add(const []);
    _activeExpansionsController(roomCode).add(Set.of(activeExpansions));
    _faceUpExpansionCardsController(roomCode)
        .add(List.of(faceUpExpansionCards));
    _drawStacksController(roomCode).add(List.of(_drawStacks[roomCode]!));
  }

  @override
  Future<String?> joinRoom(String roomCode, String guestId, Player guestPlayer) async {
    final players = _players[roomCode];
    if (players == null) return 'Rummet finns inte. Kontrollera koden.';
    if (players.length >= 2) return 'Rummet är redan fullt.';
    players[guestId] = guestPlayer;
    _playersController(roomCode).add(Map.of(players));
    return null;
  }

  @override
  Stream<Map<String, Player>> watchPlayers(String roomCode) {
    final existing = _players[roomCode];
    final controller = _playersController(roomCode);
    if (existing == null) return controller.stream;
    return controller.stream.transform(_replayLatest(Map.of(existing)));
  }

  @override
  Stream<Map<String, int>> watchCenterStacks(String roomCode) {
    final existing = _centerStacks[roomCode];
    final controller = _centerStacksController(roomCode);
    if (existing != null) {
      return controller.stream.transform(_replayLatest(Map.of(existing)));
    }
    return controller.stream;
  }

  StreamTransformer<T, T> _replayLatest<T>(T initial) {
    return StreamTransformer.fromBind((stream) async* {
      yield initial;
      yield* stream;
    });
  }

  @override
  Future<void> writePlayer(String roomCode, String playerId, Player player) async {
    final players = _players.putIfAbsent(roomCode, () => {});
    players[playerId] = player;
    _playersController(roomCode).add(Map.of(players));
  }

  @override
  Future<void> writeCenterStacks(String roomCode, Map<String, int> centerStacks) async {
    _centerStacks[roomCode] = Map.of(centerStacks);
    _centerStacksController(roomCode).add(Map.of(centerStacks));
  }

  @override
  Stream<TurnState> watchTurnState(String roomCode) {
    final existing = _turnStates[roomCode];
    final controller = _turnStateController(roomCode);
    if (existing == null) return controller.stream;
    return controller.stream.transform(_replayLatest(existing));
  }

  @override
  Future<void> writeTurnState(String roomCode, TurnState turnState) async {
    _turnStates[roomCode] = turnState;
    _turnStateController(roomCode).add(turnState);
  }

  @override
  Stream<FraternalFeudsRequest?> watchFraternalFeudsRequest(String roomCode) {
    final controller = _fraternalFeudsRequestController(roomCode);
    return controller.stream
        .transform(_replayLatest(_fraternalFeudsRequests[roomCode]));
  }

  @override
  Future<void> writeFraternalFeudsRequest(
      String roomCode, FraternalFeudsRequest request) async {
    _fraternalFeudsRequests[roomCode] = request;
    _fraternalFeudsRequestController(roomCode).add(request);
  }

  @override
  Future<void> clearFraternalFeudsRequest(String roomCode) async {
    _fraternalFeudsRequests[roomCode] = null;
    _fraternalFeudsRequestController(roomCode).add(null);
  }

  @override
  Stream<List<GameCard>> watchDiscardPile(String roomCode) {
    final existing = _discardPiles[roomCode];
    final controller = _discardPileController(roomCode);
    if (existing != null) {
      return controller.stream.transform(_replayLatest(List.of(existing)));
    }
    return controller.stream;
  }

  @override
  Future<void> writeDiscardPile(String roomCode, List<GameCard> discardPile) async {
    _discardPiles[roomCode] = List.of(discardPile);
    _discardPileController(roomCode).add(List.of(discardPile));
  }

  @override
  Stream<Set<ExpansionSet>> watchActiveExpansions(String roomCode) {
    final existing = _activeExpansions[roomCode];
    final controller = _activeExpansionsController(roomCode);
    if (existing != null) {
      return controller.stream.transform(_replayLatest(Set.of(existing)));
    }
    return controller.stream;
  }

  @override
  Stream<List<GameCard>> watchFaceUpExpansionCards(String roomCode) {
    final existing = _faceUpExpansionCards[roomCode];
    final controller = _faceUpExpansionCardsController(roomCode);
    if (existing != null) {
      return controller.stream.transform(_replayLatest(List.of(existing)));
    }
    return controller.stream;
  }

  @override
  Future<void> writeFaceUpExpansionCards(
      String roomCode, List<GameCard> faceUpExpansionCards) async {
    _faceUpExpansionCards[roomCode] = List.of(faceUpExpansionCards);
    _faceUpExpansionCardsController(roomCode)
        .add(List.of(faceUpExpansionCards));
  }

  @override
  Stream<List<List<GameCard>>> watchDrawStacks(String roomCode) {
    final existing = _drawStacks[roomCode];
    final controller = _drawStacksController(roomCode);
    if (existing != null) {
      return controller.stream
          .transform(_replayLatest(existing.map(List<GameCard>.of).toList()));
    }
    return controller.stream;
  }

  @override
  Future<void> writeDrawStacks(
      String roomCode, List<List<GameCard>> drawStacks) async {
    _drawStacks[roomCode] = drawStacks.map(List<GameCard>.of).toList();
    _drawStacksController(roomCode)
        .add(_drawStacks[roomCode]!.map(List<GameCard>.of).toList());
  }
}
