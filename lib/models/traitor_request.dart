/// En synkad "gör det här mot din egen hand"-förfrågan för Förrädare
/// i onlineläge (regelhäftet: "man får titta på motståndarens kort de
/// har på handen och välja ett som läggs till den egna handen") – se
/// [GameNotifier.pickTraitorCard].
///
/// Samma resonemang som [FraternalFeudsRequest] (ingen klient äger
/// skrivrätt till den andra spelarens Firebase-post, se
/// [GameSyncService.writePlayer]): spelaren som spelar Förrädare lägger
/// själv (redan skrivbart) det valda kortet till sin EGEN hand direkt,
/// men skickar den här förfrågan så att MOTSTÅNDARENS klient kan ta
/// bort samma kort ur sin EGEN hand (som den redan har full rätt att
/// skriva till). Till skillnad från Brödrafejd hamnar kortet aldrig
/// underst i en draghög – bara [cardId] behövs, ingen stackIndex.
class TraitorRequest {
  /// Spelar-id på den som spelade Förrädare – låter mottagande klient
  /// skilja på sin egen skickade förfrågan (ska ignoreras, redan
  /// hanterad lokalt) och en som väntar på att tillämpas.
  final String requesterId;

  /// Kort-id, hämtat direkt ur mottagarens (då fullt synkade och
  /// synliga) hand.
  final String cardId;

  const TraitorRequest({
    required this.requesterId,
    required this.cardId,
  });

  Map<String, dynamic> toJson() => {
        'requesterId': requesterId,
        'cardId': cardId,
      };

  factory TraitorRequest.fromJson(Map<String, dynamic> json) => TraitorRequest(
        requesterId: json['requesterId'] as String,
        cardId: json['cardId'] as String,
      );
}
