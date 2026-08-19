/// Vilken kategori ett kort tillhör – motsvarar färgen på kortets textruta
/// i det fysiska spelet, och styr var/hur kortet får placeras.
enum CardCategory {
  region, // Landskapskort (center card)
  settlement, // By (center card)
  city, // Stad (center card)
  road, // Väg (center card)
  expansion, // By-/stadsutbyggnad: byggnad eller enhet (grön textruta)
  cityExpansion, // Stadsutbyggnad, kräver befintlig stad (röd textruta)
  regionExpansion, // Landskapsutbyggnad, placeras ovanför/under en region (brun textruta)
  action, // Handlingskort, spelas från handen, kostar inget ("A")
  event, // Händelsekort
}

/// Underkategori för kort med [CardCategory.expansion] – dessa delas i
/// byggnader och enheter, där enheter i sin tur är hjältar, handelsskepp
/// eller övriga enheter (t.ex. Pirate Ship, som varken är hjälte eller
/// handelsskepp men ändå är en "Unit"-kortkategori).
enum ExpansionKind { building, hero, tradeShip, otherUnit }

/// Underkategori för [CardCategory.action] – attackkort kan blockeras av
/// försvarskort (t.ex. Lookout Tower), neutrala kan det inte.
enum ActionKind { neutral, attack }

/// De resurstyper som finns i spelet.
enum ResourceType { lumber, brick, ore, grain, wool, gold, none }

/// Vilket set (grundspel eller temaset) ett kort hör till.
enum ExpansionSet { basic, eraOfGold, eraOfTurmoil, eraOfProgress }

/// Ett enskilt kort i spelet – motsvarar ett fysiskt spelkort.
///
/// `GameCard` beskriver kortets *definition* (vad det är), inte var det
/// befinner sig. Placering på spelbrädet hanteras separat av [PlacedCard]
/// i realm_board.dart, så att samma kortdefinition kan återanvändas för
/// t.ex. handkort och kort som ligger i draghögen.
class GameCard {
  final String id;
  final String name;
  final CardCategory category;
  final ExpansionKind? expansionKind;
  final ActionKind? actionKind;
  final ExpansionSet expansionSet;

  /// Resurs kortet producerar. `ResourceType.none` för kort som inte
  /// producerar resurser (byar, byggnader, enheter, etc).
  final ResourceType resource;

  /// Tärningstal (2–12) som utlöser produktion för landskapskort.
  /// `null` för kort som inte reagerar på tärningsslag.
  final int? productionNumber;

  /// Resurser som måste betalas för att bygga/placera kortet.
  /// Tom map för handlingskort och center-kort (regioner byggs inte,
  /// de dras och placeras gratis).
  final Map<ResourceType, int> buildingCost;

  /// Motsvarar "(1x)" i kortnamnet – du får bara ha ett exemplar av
  /// kortet i ditt rike samtidigt.
  final bool isUnique;

  final int victoryPoints;
  final int strengthPoints; // yxsymbol
  final int commercePoints; // vågsymbol
  final int skillPoints; // harpsymbol (endast hjältar)
  final int progressPoints; // boksymbol (fler handkort tillåtna)

  /// Regeltext/effekt som visas på kortet.
  final String? effectText;

  /// Förutsättning som måste vara uppfylld för att spela/bygga kortet,
  /// t.ex. "Requires: Merchant Guild" eller "Requires: Strength advantage".
  /// `null` om kortet saknar krav.
  final String? requirement;

  /// Sökväg till bild/ikon-asset, t.ex. 'assets/images/cards/hills.png'.
  final String imageAsset;

  const GameCard({
    required this.id,
    required this.name,
    required this.category,
    this.expansionKind,
    this.actionKind,
    this.expansionSet = ExpansionSet.basic,
    this.resource = ResourceType.none,
    this.productionNumber,
    this.buildingCost = const {},
    this.isUnique = false,
    this.victoryPoints = 0,
    this.strengthPoints = 0,
    this.commercePoints = 0,
    this.skillPoints = 0,
    this.progressPoints = 0,
    this.effectText,
    this.requirement,
    required this.imageAsset,
  });

  GameCard copyWith({
    String? id,
    String? name,
    CardCategory? category,
    ExpansionKind? expansionKind,
    ActionKind? actionKind,
    ExpansionSet? expansionSet,
    ResourceType? resource,
    int? productionNumber,
    Map<ResourceType, int>? buildingCost,
    bool? isUnique,
    int? victoryPoints,
    int? strengthPoints,
    int? commercePoints,
    int? skillPoints,
    int? progressPoints,
    String? effectText,
    String? requirement,
    String? imageAsset,
  }) {
    return GameCard(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      expansionKind: expansionKind ?? this.expansionKind,
      actionKind: actionKind ?? this.actionKind,
      expansionSet: expansionSet ?? this.expansionSet,
      resource: resource ?? this.resource,
      productionNumber: productionNumber ?? this.productionNumber,
      buildingCost: buildingCost ?? this.buildingCost,
      isUnique: isUnique ?? this.isUnique,
      victoryPoints: victoryPoints ?? this.victoryPoints,
      strengthPoints: strengthPoints ?? this.strengthPoints,
      commercePoints: commercePoints ?? this.commercePoints,
      skillPoints: skillPoints ?? this.skillPoints,
      progressPoints: progressPoints ?? this.progressPoints,
      effectText: effectText ?? this.effectText,
      requirement: requirement ?? this.requirement,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'expansionKind': expansionKind?.name,
        'actionKind': actionKind?.name,
        'expansionSet': expansionSet.name,
        'resource': resource.name,
        'productionNumber': productionNumber,
        'buildingCost':
            buildingCost.map((type, amount) => MapEntry(type.name, amount)),
        'isUnique': isUnique,
        'victoryPoints': victoryPoints,
        'strengthPoints': strengthPoints,
        'commercePoints': commercePoints,
        'skillPoints': skillPoints,
        'progressPoints': progressPoints,
        'effectText': effectText,
        'requirement': requirement,
        'imageAsset': imageAsset,
      };

  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
        id: json['id'] as String,
        name: json['name'] as String,
        category: CardCategory.values.byName(json['category'] as String),
        expansionKind: (json['expansionKind'] as String?) == null
            ? null
            : ExpansionKind.values.byName(json['expansionKind'] as String),
        actionKind: (json['actionKind'] as String?) == null
            ? null
            : ActionKind.values.byName(json['actionKind'] as String),
        expansionSet:
            ExpansionSet.values.byName(json['expansionSet'] as String? ?? 'basic'),
        resource: ResourceType.values.byName(json['resource'] as String),
        productionNumber: json['productionNumber'] as int?,
        buildingCost: (json['buildingCost'] as Map? ?? {}).map(
          (type, amount) =>
              MapEntry(ResourceType.values.byName(type as String), amount as int),
        ),
        isUnique: json['isUnique'] as bool? ?? false,
        victoryPoints: json['victoryPoints'] as int? ?? 0,
        strengthPoints: json['strengthPoints'] as int? ?? 0,
        commercePoints: json['commercePoints'] as int? ?? 0,
        skillPoints: json['skillPoints'] as int? ?? 0,
        progressPoints: json['progressPoints'] as int? ?? 0,
        effectText: json['effectText'] as String?,
        requirement: json['requirement'] as String?,
        imageAsset: json['imageAsset'] as String,
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
