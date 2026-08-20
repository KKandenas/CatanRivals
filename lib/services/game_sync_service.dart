import '../models/models.dart';

/// Abstraktion över "två spelare synkar över nätet, i ett rum
/// identifierat av en kod". Låter [GameNotifier] vara oberoende av om
/// det faktiskt är Firebase Realtime Database, eller en fejkad
/// in-memory-implementation i tester, som ligger bakom.
///
/// Datamodell (Firebase-implementationen, se firebase_game_sync_service.dart):
/// ```
/// /games/{roomCode}/
///   players/{playerId} -> Player.toJson()
///   centerStacks       -> Map<String, int>
///   turnState          -> TurnState.toJson()
/// ```
abstract class GameSyncService {
  /// Skapar ett nytt rum med given kod och sätter värden-spelaren som
  /// första spelare. Antar att koden inte redan är upptagen (koden
  /// genereras slumpmässigt av anroparen).
  Future<void> createRoom(
    String roomCode,
    String hostId,
    Player hostPlayer,
    Map<String, int> centerStacks,
    TurnState turnState,
  );

  /// Går med i ett befintligt rum. Returnerar `null` vid lyckat
  /// gick-med, annars ett användarvänligt felmeddelande (rummet finns
  /// inte / är redan fullt).
  Future<String?> joinRoom(String roomCode, String guestId, Player guestPlayer);

  /// Strömmar samtliga spelare i rummet (nyckel = spelar-id), varje
  /// gång någon av dem ändras.
  Stream<Map<String, Player>> watchPlayers(String roomCode);

  /// Strömmar center-dragstaplarnas antal, varje gång de ändras.
  Stream<Map<String, int>> watchCenterStacks(String roomCode);

  Future<void> writePlayer(String roomCode, String playerId, Player player);

  Future<void> writeCenterStacks(String roomCode, Map<String, int> centerStacks);

  /// Strömmar vems tur det är och tärningsläget, varje gång det ändras.
  Stream<TurnState> watchTurnState(String roomCode);

  Future<void> writeTurnState(String roomCode, TurnState turnState);
}
