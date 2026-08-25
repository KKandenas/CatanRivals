import 'package:firebase_database/firebase_database.dart';

import '../models/models.dart';
import 'game_sync_service.dart';

/// Firebase Realtime Database-implementationen av [GameSyncService].
class FirebaseGameSyncService implements GameSyncService {
  final FirebaseDatabase _db;

  FirebaseGameSyncService({FirebaseDatabase? database}) : _db = database ?? FirebaseDatabase.instance;

  DatabaseReference _roomRef(String roomCode) => _db.ref('games/$roomCode');

  @override
  Future<void> createRoom(
    String roomCode,
    String hostId,
    Player hostPlayer,
    Map<String, int> centerStacks,
    TurnState turnState, {
    Set<ExpansionSet> activeExpansions = const {},
    List<List<GameCard>> drawStacks = const [],
    List<GameCard> regionDeck = const [],
    List<GameCard> eventDeck = const [],
  }) async {
    await _roomRef(roomCode).set({
      'createdAt': ServerValue.timestamp,
      'players': {hostId: hostPlayer.toJson()},
      'centerStacks': centerStacks,
      'turnState': turnState.toJson(),
      if (activeExpansions.isNotEmpty)
        'activeExpansions': activeExpansions.map((e) => e.name).toList(),
      if (drawStacks.isNotEmpty)
        'drawStacks': drawStacks
            .map((stack) => stack.map((c) => c.toJson()).toList())
            .toList(),
      if (regionDeck.isNotEmpty)
        'regionDeck': regionDeck.map((c) => c.toJson()).toList(),
      if (eventDeck.isNotEmpty)
        'eventDeck': eventDeck.map((c) => c.toJson()).toList(),
    });
  }

  @override
  Future<String?> joinRoom(String roomCode, String guestId, Player guestPlayer) async {
    final snapshot = await _roomRef(roomCode).get();
    if (!snapshot.exists) {
      return 'Rummet finns inte. Kontrollera koden.';
    }

    final playersRaw = snapshot.child('players').value;
    final players = playersRaw is Map ? playersRaw : <Object?, Object?>{};
    if (players.length >= 2) {
      return 'Rummet är redan fullt.';
    }

    await _roomRef(roomCode).child('players').child(guestId).set(guestPlayer.toJson());
    return null;
  }

  @override
  Stream<Map<String, Player>> watchPlayers(String roomCode) {
    return _roomRef(roomCode).child('players').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <String, Player>{};
      return raw.map(
        (id, json) => MapEntry(id as String, Player.fromJson(Map<String, dynamic>.from(json as Map))),
      );
    });
  }

  @override
  Stream<Map<String, int>> watchCenterStacks(String roomCode) {
    return _roomRef(roomCode).child('centerStacks').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <String, int>{};
      return raw.map((key, value) => MapEntry(key as String, value as int));
    });
  }

  @override
  Future<void> writePlayer(String roomCode, String playerId, Player player) {
    return _roomRef(roomCode).child('players').child(playerId).set(player.toJson());
  }

  @override
  Future<void> writeCenterStacks(String roomCode, Map<String, int> centerStacks) {
    return _roomRef(roomCode).child('centerStacks').set(centerStacks);
  }

  @override
  Stream<TurnState> watchTurnState(String roomCode) {
    return _roomRef(roomCode).child('turnState').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return const TurnState(activePlayerId: 'host');
      return TurnState.fromJson(Map<String, dynamic>.from(raw));
    });
  }

  @override
  Future<void> writeTurnState(String roomCode, TurnState turnState) {
    return _roomRef(roomCode).child('turnState').set(turnState.toJson());
  }

  @override
  Stream<FraternalFeudsRequest?> watchFraternalFeudsRequest(String roomCode) {
    return _roomRef(roomCode).child('fraternalFeudsRequest').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return null;
      return FraternalFeudsRequest.fromJson(Map<String, dynamic>.from(raw));
    });
  }

  @override
  Future<void> writeFraternalFeudsRequest(
      String roomCode, FraternalFeudsRequest request) {
    return _roomRef(roomCode)
        .child('fraternalFeudsRequest')
        .set(request.toJson());
  }

  @override
  Future<void> clearFraternalFeudsRequest(String roomCode) {
    return _roomRef(roomCode).child('fraternalFeudsRequest').remove();
  }

  @override
  Stream<List<GameCard>> watchDiscardPile(String roomCode) {
    return _roomRef(roomCode).child('discardPile').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! List) return const <GameCard>[];
      return raw
          .whereType<Object>()
          .map((c) => GameCard.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    });
  }

  @override
  Future<void> writeDiscardPile(String roomCode, List<GameCard> discardPile) {
    return _roomRef(roomCode)
        .child('discardPile')
        .set(discardPile.map((c) => c.toJson()).toList());
  }

  @override
  Stream<Set<ExpansionSet>> watchActiveExpansions(String roomCode) {
    return _roomRef(roomCode).child('activeExpansions').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! List) return const <ExpansionSet>{};
      return raw
          .whereType<Object>()
          .map((e) => ExpansionSet.values.byName(e as String))
          .toSet();
    });
  }


  @override
  Stream<List<List<GameCard>>> watchDrawStacks(String roomCode) {
    return _roomRef(roomCode).child('drawStacks').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! List) return const <List<GameCard>>[];
      return raw.whereType<Object>().map((stack) {
        final cards = stack as List;
        return cards
            .whereType<Object>()
            .map((c) => GameCard.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList();
      }).toList();
    });
  }

  @override
  Future<void> writeDrawStacks(
      String roomCode, List<List<GameCard>> drawStacks) {
    return _roomRef(roomCode).child('drawStacks').set(drawStacks
        .map((stack) => stack.map((c) => c.toJson()).toList())
        .toList());
  }

  @override
  Stream<List<GameCard>> watchRegionDeck(String roomCode) {
    return _roomRef(roomCode).child('regionDeck').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! List) return const <GameCard>[];
      return raw
          .whereType<Object>()
          .map((c) => GameCard.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    });
  }

  @override
  Future<void> writeRegionDeck(String roomCode, List<GameCard> regionDeck) {
    return _roomRef(roomCode)
        .child('regionDeck')
        .set(regionDeck.map((c) => c.toJson()).toList());
  }

  @override
  Stream<List<GameCard>> watchEventDeck(String roomCode) {
    return _roomRef(roomCode).child('eventDeck').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! List) return const <GameCard>[];
      return raw
          .whereType<Object>()
          .map((c) => GameCard.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    });
  }

  @override
  Future<void> writeEventDeck(String roomCode, List<GameCard> eventDeck) {
    return _roomRef(roomCode)
        .child('eventDeck')
        .set(eventDeck.map((c) => c.toJson()).toList());
  }
}
