import 'game_card.dart';

/// Var (ovanför eller nedanför en by/stad) ett bygg-/enhetskort sitter.
enum BuildingRow { above, below }

/// Ett kortexemplar som är utplacerat på ett rike.
class PlacedCard {
  final GameCard card;

  const PlacedCard({required this.card});

  Map<String, dynamic> toJson() => {'card': card.toJson()};

  factory PlacedCard.fromJson(Map<String, dynamic> json) =>
      PlacedCard(card: GameCard.fromJson(Map<String, dynamic>.from(json['card'] as Map)));
}

/// En by eller stad i riket, tillsammans med dess byggplatser för
/// utbyggnadskort (byggnader/enheter).
///
/// En by har 1 byggplats ovanför och 1 nedanför. När den uppgraderas till
/// stad tillkommer ytterligare en byggplats i varje riktning (totalt 2
/// ovanför och 2 nedanför) – de två platserna på samma rad är likvärdiga:
/// båda gränsar till samma två hörnregioner.
class SettlementNode {
  final PlacedCard center; // by- eller stadskortet
  final List<PlacedCard?> aboveSites;
  final List<PlacedCard?> belowSites;

  SettlementNode({
    required this.center,
    List<PlacedCard?>? aboveSites,
    List<PlacedCard?>? belowSites,
  })  : aboveSites = aboveSites ?? [null],
        belowSites = belowSites ?? [null];

  bool get isCity => center.card.category == CardCategory.city;

  SettlementNode copyWith({
    PlacedCard? center,
    List<PlacedCard?>? aboveSites,
    List<PlacedCard?>? belowSites,
  }) {
    return SettlementNode(
      center: center ?? this.center,
      aboveSites: aboveSites ?? List.of(this.aboveSites),
      belowSites: belowSites ?? List.of(this.belowSites),
    );
  }

  /// Uppgraderar denna by till stad: byter centerkortet och utökar
  /// byggplatserna från 1 till 2 i varje riktning.
  SettlementNode upgradeToCity(PlacedCard cityCard) {
    return SettlementNode(
      center: cityCard,
      aboveSites: [aboveSites.first, null],
      belowSites: [belowSites.first, null],
    );
  }

  Map<String, dynamic> toJson() => {
        'center': center.toJson(),
        'aboveSites': aboveSites.map((c) => c?.toJson()).toList(),
        'belowSites': belowSites.map((c) => c?.toJson()).toList(),
      };

  factory SettlementNode.fromJson(Map<String, dynamic> json) => SettlementNode(
        center: PlacedCard.fromJson(Map<String, dynamic>.from(json['center'] as Map)),
        aboveSites: (json['aboveSites'] as List)
            .map((c) => c == null ? null : PlacedCard.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        belowSites: (json['belowSites'] as List)
            .map((c) => c == null ? null : PlacedCard.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
      );
}

/// En spelares rike (Fyrstendöme).
///
/// Byar/städer bildar en horisontell kedja, förbundna av vägar. Varje
/// by/stad har ett heltalskolumn-index (jämnt tal). Vägarna sitter i
/// kolumnen mitt emellan två byar/städer (udda tal). Landskapsregioner
/// sitter också i udda kolumner ("knutpunkter") men i ett eget lager
/// ovanför respektive nedanför kedjan – en knutpunkt delas av de två
/// byar/städer som ligger direkt till vänster och höger om den, precis
/// som i det fysiska spelet där ett landskapskort ligger i hörnet mellan
/// två bebyggelser.
///
/// Exempel (spelets startuppställning, 2 byar förbundna av 1 väg):
/// ```
/// kolumn:      -1      0      1      2      3
/// above:    region        region        region
/// spine:            by    väg    by
/// below:    region        region        region
/// ```
class RealmBoard {
  final String ownerId;
  final Map<int, SettlementNode> _settlements;
  final Map<int, PlacedCard> _roads;
  final Map<int, PlacedCard> _regionsAbove;
  final Map<int, PlacedCard> _regionsBelow;

  RealmBoard({
    required this.ownerId,
    Map<int, SettlementNode>? settlements,
    Map<int, PlacedCard>? roads,
    Map<int, PlacedCard>? regionsAbove,
    Map<int, PlacedCard>? regionsBelow,
  })  : _settlements = settlements ?? {},
        _roads = roads ?? {},
        _regionsAbove = regionsAbove ?? {},
        _regionsBelow = regionsBelow ?? {};

  Map<int, SettlementNode> get settlements => Map.unmodifiable(_settlements);
  Map<int, PlacedCard> get roads => Map.unmodifiable(_roads);
  Map<int, PlacedCard> get regionsAbove => Map.unmodifiable(_regionsAbove);
  Map<int, PlacedCard> get regionsBelow => Map.unmodifiable(_regionsBelow);

  SettlementNode? settlementAt(int column) => _settlements[column];

  PlacedCard? regionAt(int junctionColumn, BuildingRow row) =>
      row == BuildingRow.above ? _regionsAbove[junctionColumn] : _regionsBelow[junctionColumn];

  /// De två hörnregioner (vänster/höger knutpunkt) som ligger ovanför
  /// respektive nedanför byn/staden i given kolumn.
  List<PlacedCard?> cornerRegions(int settlementColumn, BuildingRow row) => [
        regionAt(settlementColumn - 1, row),
        regionAt(settlementColumn + 1, row),
      ];

  void placeSettlement(int column, PlacedCard settlementCard) {
    if (_settlements.containsKey(column)) {
      throw StateError('Det finns redan en by/stad i kolumn $column.');
    }
    _settlements[column] = SettlementNode(center: settlementCard);
  }

  void upgradeToCity(int column, PlacedCard cityCard) {
    final existing = _settlements[column];
    if (existing == null) {
      throw StateError('Ingen by att uppgradera i kolumn $column.');
    }
    _settlements[column] = existing.upgradeToCity(cityCard);
  }

  void placeRoad(int junctionColumn, PlacedCard roadCard) {
    if (_roads.containsKey(junctionColumn)) {
      throw StateError('Det ligger redan en väg i kolumn $junctionColumn.');
    }
    _roads[junctionColumn] = roadCard;
  }

  void placeRegion(int junctionColumn, BuildingRow row, PlacedCard regionCard) {
    final target = row == BuildingRow.above ? _regionsAbove : _regionsBelow;
    if (target.containsKey(junctionColumn)) {
      throw StateError('Det ligger redan en region i kolumn $junctionColumn ($row).');
    }
    target[junctionColumn] = regionCard;
  }

  /// Placerar ett bygg-/enhetskort på en av byggplatserna för byn/staden
  /// i given kolumn. `slotIndex` är 0 för den ursprungliga byggplatsen
  /// och 1 för stadens andra (tillkommande) byggplats.
  void placeExpansion(int column, BuildingRow row, int slotIndex, PlacedCard expansionCard) {
    final node = _settlements[column];
    if (node == null) {
      throw StateError('Ingen by/stad i kolumn $column.');
    }
    final sites = row == BuildingRow.above ? node.aboveSites : node.belowSites;
    if (slotIndex >= sites.length) {
      throw StateError('Byggplats $slotIndex finns inte (kräver stad).');
    }
    if (sites[slotIndex] != null) {
      throw StateError('Byggplatsen är redan upptagen.');
    }
    sites[slotIndex] = expansionCard;
  }

  int get leftmostColumn =>
      _settlements.keys.isEmpty ? 0 : _settlements.keys.reduce((a, b) => a < b ? a : b);

  int get rightmostColumn =>
      _settlements.keys.isEmpty ? 0 : _settlements.keys.reduce((a, b) => a > b ? a : b);

  int get totalVictoryPoints {
    var total = 0;
    for (final node in _settlements.values) {
      total += node.center.card.victoryPoints;
      for (final site in [...node.aboveSites, ...node.belowSites]) {
        total += site?.card.victoryPoints ?? 0;
      }
    }
    for (final road in _roads.values) {
      total += road.card.victoryPoints;
    }
    for (final region in [..._regionsAbove.values, ..._regionsBelow.values]) {
      total += region.card.victoryPoints;
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'settlements': _settlements.map((col, node) => MapEntry(col.toString(), node.toJson())),
        'roads': _roads.map((col, card) => MapEntry(col.toString(), card.toJson())),
        'regionsAbove':
            _regionsAbove.map((col, card) => MapEntry(col.toString(), card.toJson())),
        'regionsBelow':
            _regionsBelow.map((col, card) => MapEntry(col.toString(), card.toJson())),
      };

  factory RealmBoard.fromJson(Map<String, dynamic> json) {
    Map<int, T> parseColumnMap<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
      return (raw as Map? ?? {}).map(
        (col, value) =>
            MapEntry(int.parse(col as String), fromJson(Map<String, dynamic>.from(value as Map))),
      );
    }

    return RealmBoard(
      ownerId: json['ownerId'] as String,
      settlements: parseColumnMap(json['settlements'], SettlementNode.fromJson),
      roads: parseColumnMap(json['roads'], PlacedCard.fromJson),
      regionsAbove: parseColumnMap(json['regionsAbove'], PlacedCard.fromJson),
      regionsBelow: parseColumnMap(json['regionsBelow'], PlacedCard.fromJson),
    );
  }
}
