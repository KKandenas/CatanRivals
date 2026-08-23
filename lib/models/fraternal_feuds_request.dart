/// En synkad "gör det här mot din egen hand"-förfrågan för Brödrafejd
/// i onlineläge (regelhäftet: spelaren MED styrkeövertaget väljer 2 kort
/// från motståndarens hand) – se [GameNotifier.pickFraternalFeudsCard].
///
/// Till skillnad från Fejd (som bara rör den egna spelarens rike, och
/// därför redan fungerar online utan vidare) kräver Brödrafejd att
/// mutera MOTSTÅNDARENS hand. Ingen klient äger skrivrätt till den andra
/// spelarens Firebase-post i normala fall (se [GameSyncService.
/// writePlayer] – varje klient skriver bara sin egen), så i stället för
/// att spelaren med övertaget muterar motståndarens data direkt skickas
/// den här förfrågan: motståndarens klient ser den, tillämpar den på sin
/// EGEN hand/draghög (som den redan har full rätt att skriva till), och
/// rensar sedan förfrågan.
class FraternalFeudsRequest {
  /// Spelar-id på den som skickade förfrågan (den MED styrkeövertaget)
  /// – låter mottagande klient skilja på sin egen skickade förfrågan
  /// (ska ignoreras, redan hanterad lokalt) och en som väntar på att
  /// tillämpas.
  final String requesterId;

  /// Exakt 2 kort-id, hämtade direkt ur mottagarens (då fullt synkade
  /// och synliga) hand.
  final List<String> cardIds;

  /// Vilken draghög (0–3) respektive kort i [cardIds] ska läggas underst
  /// i, i samma ordning.
  final List<int> stackIndices;

  const FraternalFeudsRequest({
    required this.requesterId,
    required this.cardIds,
    required this.stackIndices,
  });

  Map<String, dynamic> toJson() => {
        'requesterId': requesterId,
        'cardIds': cardIds,
        'stackIndices': stackIndices,
      };

  factory FraternalFeudsRequest.fromJson(Map<String, dynamic> json) =>
      FraternalFeudsRequest(
        requesterId: json['requesterId'] as String,
        cardIds: List<String>.from(json['cardIds'] as List),
        stackIndices:
            List<int>.from((json['stackIndices'] as List).map((e) => e as int)),
      );
}
