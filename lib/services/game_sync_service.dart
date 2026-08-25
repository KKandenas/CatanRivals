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
///   activeExpansions          -> List<String> (ExpansionSet-namn),
///                                satt en gång vid rumsskapande, se
///                                [GameState.activeExpansions]
///   drawStacks                -> List<List<GameCard.toJson()>>, de
///                                delade dragstaplarnas EXAKTA innehåll
///                                (se [GameNotifier]s `_drawStacks`-doc)
///   regionDeck                -> List<GameCard.toJson()>, se
///                                [GameNotifier]s `_regionDeck`-doc
///   eventDeck                 -> List<GameCard.toJson()>, se
///                                [GameNotifier]s `_eventDeck`-doc
/// ```
abstract class GameSyncService {
  /// Skapar ett nytt rum med given kod och sätter värden-spelaren som
  /// första spelare. Antar att koden inte redan är upptagen (koden
  /// genereras slumpmässigt av anroparen). [activeExpansions] sätts en
  /// gång här och ändras aldrig sedan (se [GameState.activeExpansions])
  /// – gästen läser det via [watchActiveExpansions] i stället för att
  /// välja själv. [drawStacks]/[regionDeck]/[eventDeck] är hostens
  /// FAKTISKT hopblandade staplar (se [GameNotifier._resetDecks]) –
  /// gästen läser dem via respektive `watchX` i stället för att blanda
  /// sina egna, annars skulle varje unikt kort (t.ex. en hjälte med bara
  /// 1 fysisk kopia) kunna dyka upp i BÅDA klienternas separata,
  /// oberoende blandade högar. [hostPlayer]s eget ansikte-upp-kort (se
  /// [Player.faceUpExpansionCard]) skickas med som en del av
  /// [hostPlayer] själv, precis som handen/riket – ingen egen kanal.
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
  });

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

  /// Strömmar vilka temaset rummet spelas med (satt en gång vid
  /// [createRoom], ändras aldrig sedan) – [GameNotifier.joinRoom]/
  /// [GameNotifier.resumeRoom] läser bara det första värdet (`.first`),
  /// precis som centerStacks/turnState redan görs vid återanslutning.
  Stream<Set<ExpansionSet>> watchActiveExpansions(String roomCode);

  /// Strömmar de delade dragstaplarnas EXAKTA innehåll (se
  /// [GameNotifier]s `_drawStacks`-doc), varje gång de ändras – ett drag
  /// av ENDERA spelaren (från handjustering, kika-fasen, Fejd,
  /// Brödrafejd, starthandsutdelning, m.m.) skriver den nya, fullständiga
  /// listan hit, så att BÅDA klienterna alltid ser samma kvarvarande pool
  /// och aldrig kan dra samma fysiska kort två gånger.
  Stream<List<List<GameCard>>> watchDrawStacks(String roomCode);

  Future<void> writeDrawStacks(
      String roomCode, List<List<GameCard>> drawStacks);

  /// Strömmar regionstapelns EXAKTA, kvarvarande innehåll (se
  /// [GameNotifier]s `_regionDeck`-doc), varje gång den ändras – t.ex.
  /// när en by byggs bortom rikets nuvarande yttergräns (regelhäftet s.
  /// 8) eller Spejare används, av ENDERA spelaren.
  Stream<List<GameCard>> watchRegionDeck(String roomCode);

  Future<void> writeRegionDeck(String roomCode, List<GameCard> regionDeck);

  /// Strömmar händelsekortsstapelns EXAKTA, kvarvarande innehåll (se
  /// [GameNotifier]s `_eventDeck`-doc), varje gång den ändras – ett drag
  /// av ENDERA spelaren (eller en Jul-omblandning, se
  /// [GameNotifier._drawEventCardResolvingYule]).
  Stream<List<GameCard>> watchEventDeck(String roomCode);

  Future<void> writeEventDeck(String roomCode, List<GameCard> eventDeck);
}
