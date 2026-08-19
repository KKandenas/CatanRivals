/// De olika korttyperna som förekommer i Catan Duellen.
enum CardType {
  region, // Landskapskort (producerar resurser)
  settlement, // By
  city, // Stad
  road, // Väg
  building, // Byggnadskort (t.ex. hamn, kyrka, marknad)
  unit, // Enhetskort (t.ex. riddare)
  event, // Händelsekort (t.ex. handels-/politik-/kyrkofas)
}

/// De resurstyper som finns i spelet.
enum ResourceType { lumber, brick, ore, grain, wool, gold, none }

/// Ett enskilt kort i spelet – motsvarar ett fysiskt spelkort.
///
/// `GameCard` beskriver kortets *definition* (vad det är), inte var det
/// befinner sig. Placering på spelbrädet hanteras separat av [PlacedCard]
/// i realm_board.dart, så att samma kortdefinition kan återanvändas för
/// t.ex. handkort och kort som ligger i draghögen.
class GameCard {
  final String id;
  final String name;
  final CardType type;

  /// Resurs kortet producerar. `ResourceType.none` för kort som inte
  /// producerar resurser (byar, byggnader, enheter, etc).
  final ResourceType resource;

  /// Tärningstal (2–12) som utlöser produktion för landskapskort.
  /// `null` för kort som inte reagerar på tärningsslag.
  final int? productionNumber;

  final int victoryPoints;

  /// Sökväg till bild/ikon-asset, t.ex. 'assets/images/cards/hills.png'.
  final String imageAsset;

  final String? description;

  const GameCard({
    required this.id,
    required this.name,
    required this.type,
    this.resource = ResourceType.none,
    this.productionNumber,
    this.victoryPoints = 0,
    required this.imageAsset,
    this.description,
  });

  GameCard copyWith({
    String? id,
    String? name,
    CardType? type,
    ResourceType? resource,
    int? productionNumber,
    int? victoryPoints,
    String? imageAsset,
    String? description,
  }) {
    return GameCard(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      resource: resource ?? this.resource,
      productionNumber: productionNumber ?? this.productionNumber,
      victoryPoints: victoryPoints ?? this.victoryPoints,
      imageAsset: imageAsset ?? this.imageAsset,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'resource': resource.name,
        'productionNumber': productionNumber,
        'victoryPoints': victoryPoints,
        'imageAsset': imageAsset,
        'description': description,
      };

  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
        id: json['id'] as String,
        name: json['name'] as String,
        type: CardType.values.byName(json['type'] as String),
        resource: ResourceType.values.byName(json['resource'] as String),
        productionNumber: json['productionNumber'] as int?,
        victoryPoints: json['victoryPoints'] as int? ?? 0,
        imageAsset: json['imageAsset'] as String,
        description: json['description'] as String?,
      );

  /// Två [GameCard] räknas som samma kort om de har samma id, eftersom
  /// varje fysiskt kortexemplar är unikt (jämfört med kortets *typ*).
  @override
  bool operator ==(Object other) => other is GameCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GameCard($id, $name)';
}
