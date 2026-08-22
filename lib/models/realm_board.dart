import 'game_card.dart';

/// Var (ovanför eller nedanför en by/stad) ett bygg-/enhetskort sitter.
enum BuildingRow { above, below }

/// Vilken sorts plats en [RelocationSelection] pekar på – Omlokalisering
/// (regelhäftet: "exchange 2 of your own regions or 2 of your own
/// expansion cards") tillåter bara byte inom samma sort, aldrig
/// blandat.
enum RelocationTargetKind { region, expansion }

/// En vald plats under Omlokalisering (se [RelocationTargetKind]) –
/// det första trycket lagras som "väntande" tills spelaren trycker på
/// en andra, giltig plats av samma sort (se
/// [GameNotifier.selectRelocationTarget]). `slotIndex` är bara
/// meningsfullt för [RelocationTargetKind.expansion] (0/1, se
/// [RealmBoard.placeExpansion]) – alltid 0 för regioner.
class RelocationSelection {
  final RelocationTargetKind kind;
  final int column;
  final BuildingRow row;
  final int slotIndex;

  const RelocationSelection({
    required this.kind,
    required this.column,
    required this.row,
    this.slotIndex = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is RelocationSelection &&
      other.kind == kind &&
      other.column == column &&
      other.row == row &&
      other.slotIndex == slotIndex;

  @override
  int get hashCode => Object.hash(kind, column, row, slotIndex);
}

/// Ett kortexemplar som är utplacerat på ett rike.
///
/// `storedResources` är bara meningsfullt för regionkort (0–3 resurser
/// lagrade, se regelhäftet s. 3: "you can thus store between 0 and 3
/// resources in a region") – för alla andra kategorier är det alltid 0.
/// Vi visar det som upplysta ringar (se [ResourcePipRow]) i stället för
/// att rotera kortet grafiskt, men datat är annars likvärdigt med det
/// fysiska spelets regel.
class PlacedCard {
  final GameCard card;
  final int storedResources;

  const PlacedCard({required this.card, this.storedResources = 0});

  PlacedCard copyWith({int? storedResources}) => PlacedCard(
      card: card, storedResources: storedResources ?? this.storedResources);

  Map<String, dynamic> toJson() =>
      {'card': card.toJson(), 'storedResources': storedResources};

  factory PlacedCard.fromJson(Map<String, dynamic> json) => PlacedCard(
        card: GameCard.fromJson(Map<String, dynamic>.from(json['card'] as Map)),
        storedResources: json['storedResources'] as int? ?? 0,
      );
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

  // Byggplatserna serialiseras som en nyckel-per-index-map (och hoppar
  // helt över tomma platser) i stället för en JSON-array med null-
  // luckor. Firebase Realtime Database lagrar aldrig null-värden – ett
  // null i en array-position gör att arrayen tystnar bort/glesnar när
  // den skrivs, vilket kraschade när vi sedan försökte läsa tillbaka
  // den som en fullständig List. En map där tomma platser helt enkelt
  // saknar sin nyckel har inte det problemet.
  static Map<String, dynamic> _sitesToJson(List<PlacedCard?> sites) {
    final json = <String, dynamic>{};
    for (var i = 0; i < sites.length; i++) {
      final site = sites[i];
      if (site != null) json['s$i'] = site.toJson();
    }
    return json;
  }

  static List<PlacedCard?> _sitesFromJson(dynamic raw, int slotCount) {
    final map = raw as Map? ?? {};
    return [
      for (var i = 0; i < slotCount; i++)
        map['s$i'] == null
            ? null
            : PlacedCard.fromJson(Map<String, dynamic>.from(map['s$i'] as Map)),
    ];
  }

  Map<String, dynamic> toJson() => {
        'center': center.toJson(),
        'aboveSites': _sitesToJson(aboveSites),
        'belowSites': _sitesToJson(belowSites),
      };

  factory SettlementNode.fromJson(Map<String, dynamic> json) {
    final center =
        PlacedCard.fromJson(Map<String, dynamic>.from(json['center'] as Map));
    final slotCount = center.card.category == CardCategory.city ? 2 : 1;
    return SettlementNode(
      center: center,
      aboveSites: _sitesFromJson(json['aboveSites'], slotCount),
      belowSites: _sitesFromJson(json['belowSites'], slotCount),
    );
  }
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
      row == BuildingRow.above
          ? _regionsAbove[junctionColumn]
          : _regionsBelow[junctionColumn];

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
      throw StateError(
          'Det ligger redan en region i kolumn $junctionColumn ($row).');
    }
    target[junctionColumn] = regionCard;
  }

  /// Placerar ett bygg-/enhetskort på en av byggplatserna för byn/staden
  /// i given kolumn. `slotIndex` är 0 för den ursprungliga byggplatsen
  /// och 1 för stadens andra (tillkommande) byggplats.
  void placeExpansion(
      int column, BuildingRow row, int slotIndex, PlacedCard expansionCard) {
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

  /// Byter plats på två av dina egna, redan utplacerade regionkort
  /// (Omlokalisering, regelhäftet: "You may exchange 2 of your own
  /// regions ... Resources stored on regions may not be changed"). Hela
  /// [PlacedCard] (kort och lagrade resurser tillsammans) byter plats
  /// som en enhet – precis som att fysiskt lyfta upp regionkortet med
  /// resurserna som ligger på det och lägga det på den andra platsen –
  /// så ingen enskild regions lagrade mängd ändras av bytet i sig.
  /// Kastar [StateError] om någon av platserna är tom.
  void swapRegions(
      int columnA, BuildingRow rowA, int columnB, BuildingRow rowB) {
    final a = regionAt(columnA, rowA);
    final b = regionAt(columnB, rowB);
    if (a == null || b == null) {
      throw StateError('Båda platserna måste ha en region för att bytas.');
    }
    final targetA = rowA == BuildingRow.above ? _regionsAbove : _regionsBelow;
    final targetB = rowB == BuildingRow.above ? _regionsAbove : _regionsBelow;
    targetA[columnA] = b;
    targetB[columnB] = a;
  }

  /// Byter plats på två av dina egna, redan utplacerade bygg-/
  /// enhetskort (Omlokalisering, regelhäftet: "... or 2 of your own
  /// expansion cards"). Kastar [StateError] om någon av platserna
  /// saknar by/stad eller är tom.
  void swapExpansions(int columnA, BuildingRow rowA, int slotA, int columnB,
      BuildingRow rowB, int slotB) {
    final nodeA = _settlements[columnA];
    final nodeB = _settlements[columnB];
    if (nodeA == null || nodeB == null) {
      throw StateError('Ingen by/stad i kolumn $columnA eller $columnB.');
    }
    final sitesA = rowA == BuildingRow.above ? nodeA.aboveSites : nodeA.belowSites;
    final sitesB = rowB == BuildingRow.above ? nodeB.aboveSites : nodeB.belowSites;
    final cardA = sitesA[slotA];
    final cardB = sitesB[slotB];
    if (cardA == null || cardB == null) {
      throw StateError('Båda platserna måste ha ett kort för att bytas.');
    }
    sitesA[slotA] = cardB;
    sitesB[slotB] = cardA;
  }

  /// Tar bort och returnerar bygg-/enhetskortet på en byggplats (Fejd,
  /// regelhäftet: "the opponent must remove one of them"). `null` om
  /// platsen redan var tom. Kastar [StateError] om det inte finns
  /// någon by/stad i kolumnen.
  PlacedCard? removeExpansion(int column, BuildingRow row, int slotIndex) {
    final node = _settlements[column];
    if (node == null) {
      throw StateError('Ingen by/stad i kolumn $column.');
    }
    final sites = row == BuildingRow.above ? node.aboveSites : node.belowSites;
    if (slotIndex >= sites.length) return null;
    final removed = sites[slotIndex];
    sites[slotIndex] = null;
    return removed;
  }

  /// Om riket har minst en byggnad (inte skepp/hjältar/andra enheter)
  /// utplacerad – Fejd (regelhäftet: "the opponent must remove one of
  /// them") kan bara göra något om det faktiskt finns en byggnad att
  /// välja mellan, se [GameNotifier.startFeudBuildingPick]. Utan den
  /// här kontrollen skulle spelet be spelaren välja en byggnad som
  /// inte finns, utan något sätt att komma vidare.
  bool get hasAnyBuilding {
    for (final node in _settlements.values) {
      for (final site in [...node.aboveSites, ...node.belowSites]) {
        if (site?.card.expansionKind == ExpansionKind.building) return true;
      }
    }
    return false;
  }

  /// Om ett kort med [cardId] redan ligger på en byggplats någonstans i
  /// riket (byar/städers ovanför-/nedanför-platser) – används för att
  /// kontrollera unika kort (regelhäftet: "(1x)" i kortnamnet, t.ex.
  /// Kloster/Marknadsplats/Församlingshus), se
  /// [GameNotifier.dropExpansion].
  bool hasExpansionCard(String cardId) {
    for (final node in _settlements.values) {
      for (final site in [...node.aboveSites, ...node.belowSites]) {
        if (site?.card.id == cardId) return true;
      }
    }
    return false;
  }

  /// Alla bygg-/enhetskort som just nu ligger på en byggplats någonstans
  /// i riket (byar/städers ovanför-/nedanför-platser) – används för att
  /// räkna ut vilka kort som redan är "kända" (utdelade) när
  /// [GameNotifier.resumeRoom] bygger om de lokala draghögarna efter en
  /// sidladdning.
  List<GameCard> get placedExpansionCards => [
        for (final node in _settlements.values)
          for (final site in [...node.aboveSites, ...node.belowSites])
            if (site != null) site.card,
      ];

  /// Summan av lagrade resurser av given typ över alla regioner i riket
  /// (regelhäftet s. 3: varje region lagrar 0–3 av sin egen resurstyp).
  int resourceTotal(ResourceType type) {
    var total = 0;
    for (final region in [..._regionsAbove.values, ..._regionsBelow.values]) {
      if (region.card.resource == type) total += region.storedResources;
    }
    return total;
  }

  bool canAfford(Map<ResourceType, int> cost) =>
      cost.entries.every((entry) => resourceTotal(entry.key) >= entry.value);

  /// Förbrukar `cost` genom att plocka från de regioner som har den
  /// aktuella resurstypen lagrad, tills kostnaden är täckt. Vilken
  /// specifik region man "roterar ner" är upp till spelaren enligt
  /// reglerna (s. 9: "The resources paid can be taken from various
  /// regions of the same type") – vi väljer automatiskt bland de
  /// regioner som har mest lagrat, i väntan på en manuell väljare.
  /// Kastar [StateError] om det inte finns tillräckligt (anropa
  /// [canAfford] först).
  void spend(Map<ResourceType, int> cost) {
    if (!canAfford(cost)) {
      throw StateError(
          'Inte tillräckligt med resurser för att betala kostnaden.');
    }
    for (final entry in cost.entries) {
      var remaining = entry.value;
      final candidates = [
        for (final col in _regionsAbove.keys) MapEntry(col, BuildingRow.above),
        for (final col in _regionsBelow.keys) MapEntry(col, BuildingRow.below),
      ]..sort((a, b) {
          final regionA = regionAt(a.key, a.value)!;
          final regionB = regionAt(b.key, b.value)!;
          return regionB.storedResources.compareTo(regionA.storedResources);
        });
      for (final location in candidates) {
        if (remaining <= 0) break;
        final region = regionAt(location.key, location.value)!;
        if (region.card.resource != entry.key || region.storedResources <= 0) {
          continue;
        }
        final taken = remaining < region.storedResources
            ? remaining
            : region.storedResources;
        _setRegionStorage(
            location.key, location.value, region.storedResources - taken);
        remaining -= taken;
      }
    }
  }

  /// Lägger till (eller drar ifrån) lagrade resurser på en specifik
  /// region, t.ex. vid tärningsproduktion. Klämmer till 0–3.
  void addResourceToRegion(int junctionColumn, BuildingRow row, int delta) {
    final region = regionAt(junctionColumn, row);
    if (region == null) return;
    final clamped = (region.storedResources + delta).clamp(0, 3);
    _setRegionStorage(junctionColumn, row, clamped);
  }

  void _setRegionStorage(
      int junctionColumn, BuildingRow row, int storedResources) {
    final target = row == BuildingRow.above ? _regionsAbove : _regionsBelow;
    final region = target[junctionColumn];
    if (region == null) return;
    target[junctionColumn] = region.copyWith(storedResources: storedResources);
  }

  int get leftmostColumn => _settlements.keys.isEmpty
      ? 0
      : _settlements.keys.reduce((a, b) => a < b ? a : b);

  int get rightmostColumn => _settlements.keys.isEmpty
      ? 0
      : _settlements.keys.reduce((a, b) => a > b ? a : b);

  int get totalVictoryPoints => _sumPoints((card) => card.victoryPoints);
  int get totalStrengthPoints => _sumPoints((card) => card.strengthPoints);
  int get totalCommercePoints => _sumPoints((card) => card.commercePoints);
  int get totalSkillPoints => _sumPoints((card) => card.skillPoints);
  int get totalProgressPoints => _sumPoints((card) => card.progressPoints);

  /// Summerar en poängtyp (VP, styrka, handel, färdighet eller
  /// framsteg) över alla utplacerade kort: byar/städer, bygg-/
  /// enhetskort på deras byggplatser, vägar och regioner.
  int _sumPoints(int Function(GameCard card) points) {
    var total = 0;
    for (final node in _settlements.values) {
      total += points(node.center.card);
      for (final site in [...node.aboveSites, ...node.belowSites]) {
        if (site != null) total += points(site.card);
      }
    }
    for (final road in _roads.values) {
      total += points(road.card);
    }
    for (final region in [..._regionsAbove.values, ..._regionsBelow.values]) {
      total += points(region.card);
    }
    return total;
  }

  // Kolumnnycklarna är heltal (även negativa), t.ex. "0", "-1", "2".
  // Firebase Realtime Database gör om ett JSON-objekt till en array om
  // alla nycklar ser ut som array-index – vilket krossar allt så fort
  // en spelare har en by i kolumn 0 eller 2. Prefixet "c" garanterar
  // att nycklarna aldrig ser numeriska ut för Firebase.
  static String _columnKey(int col) => 'c$col';
  static int _parseColumnKey(String key) => int.parse(key.substring(1));

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'settlements': _settlements
            .map((col, node) => MapEntry(_columnKey(col), node.toJson())),
        'roads':
            _roads.map((col, card) => MapEntry(_columnKey(col), card.toJson())),
        'regionsAbove': _regionsAbove
            .map((col, card) => MapEntry(_columnKey(col), card.toJson())),
        'regionsBelow': _regionsBelow
            .map((col, card) => MapEntry(_columnKey(col), card.toJson())),
      };

  factory RealmBoard.fromJson(Map<String, dynamic> json) {
    Map<int, T> parseColumnMap<T>(
        dynamic raw, T Function(Map<String, dynamic>) fromJson) {
      return (raw as Map? ?? {}).map(
        (col, value) => MapEntry(_parseColumnKey(col as String),
            fromJson(Map<String, dynamic>.from(value as Map))),
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
