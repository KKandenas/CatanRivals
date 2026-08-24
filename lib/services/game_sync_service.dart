import '../models/models.dart';

/// Abstraktion över "två spelare synkar över nätet, i ett rum
/// identifierat av en kod". Låter [GameNotifier] vara oberoende av om
/// det faktiskt är Firebase Realtime Database, eller en fejkad
/// in-memory-implementation i tester, som ligger bakom.
///
/// Datamodell (Firebase-implementationen, se firebase_game_sync_service.dart):
/// ```
/// /games/{roomCode}/
///   players/{playerId}       -> Player.toJson()
///   centerStacks             -> Map<String, int>
///   turnState                -> TurnState.toJson()
///   fraternalFeudsRequest    -> FraternalFeudsRequest.toJson(), eller
///                                frånvarande/null
///   discardPile              -> List<GameCard.toJson()>, senast
///                                spelade kortet sist (se
///                                [GameNotifier.discardPile])
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

  /// Strömmar den aktiva Brödrafejd-förfrågan i rummet (se
  /// [FraternalFeudsRequest]) – `null` när ingen väntar. Bara relevant
  /// online; lokalt läge muterar motståndarens data direkt utan nätverk
  /// (se [GameNotifier.pickFraternalFeudsCard]).
  Stream<FraternalFeudsRequest?> watchFraternalFeudsRequest(String roomCode);

  Future<void> writeFraternalFeudsRequest(
      String roomCode, FraternalFeudsRequest request);

  /// Tar bort förfrågan efter att mottagaren tillämpat den (eller om
  /// den aldrig ska tillämpas) – förhindrar att den appliceras igen,
  /// t.ex. vid en sidladdning (se [GameNotifier.resumeRoom]).
  Future<void> clearFraternalFeudsRequest(String roomCode);

  /// Strömmar slänghögen (se [GameNotifier.discardPile]), varje gång
  /// den ändras – delad mellan spelarna (inte per spelare), precis som
  /// [watchCenterStacks].
  Stream<List<GameCard>> watchDiscardPile(String roomCode);

  Future<void> writeDiscardPile(String roomCode, List<GameCard> discardPile);
}
