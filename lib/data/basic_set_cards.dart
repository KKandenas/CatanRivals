import '../models/models.dart';

/// Alla korttyper i grundspelet ("Basic Set", 94 fysiska kort totalt).
///
/// Detta är korttypernas *definitioner* – hur många fysiska kopior som
/// finns av varje typ hanteras separat i [supplyCounts], eftersom flera
/// kopior av samma korttyp (t.ex. by, väg, stad) är helt identiska
/// ("Since the cards in each stack are identical, you don't need to
/// shuffle them" – regelhäftet s. 4). Landskapskort är undantaget: varje
/// fysiskt exemplar har ett eget tärningstal (1–6) tryckt på kortet, så
/// de skapas som separata instanser (se [StarterCards] och den
/// kommande region-/dragstapel-logiken) istället för att katalogiseras
/// här med ett fast tal.
///
/// Källor: regelhäftets kortindex (s. 18–20) för regeltext och
/// kopieantal, samt kortbilderna för byggkostnader (resurs-ikonerna
/// i kortens övre vänstra hörn).
class BasicSetCards {
  BasicSetCards._();

  // ---------------------------------------------------------------------
  // Center cards: regioner, byar, städer, vägar
  // ---------------------------------------------------------------------

  static const forest = GameCard(
    id: 'region-forest',
    name: 'Skog',
    category: CardCategory.region,
    resource: ResourceType.lumber,
    imageAsset: 'assets/images/cards/region_forest.png',
  );

  static const pasture = GameCard(
    id: 'region-pasture',
    name: 'Betesmark',
    category: CardCategory.region,
    resource: ResourceType.wool,
    imageAsset: 'assets/images/cards/region_pasture.png',
  );

  static const fields = GameCard(
    id: 'region-fields',
    name: 'Åker',
    category: CardCategory.region,
    resource: ResourceType.grain,
    imageAsset: 'assets/images/cards/region_fields.png',
  );

  static const hills = GameCard(
    id: 'region-hills',
    name: 'Kulle',
    category: CardCategory.region,
    resource: ResourceType.brick,
    imageAsset: 'assets/images/cards/region_hills.png',
  );

  static const mountains = GameCard(
    id: 'region-mountains',
    name: 'Berg',
    category: CardCategory.region,
    resource: ResourceType.ore,
    imageAsset: 'assets/images/cards/region_mountains.png',
  );

  static const goldField = GameCard(
    id: 'region-gold-field',
    name: 'Guldfält',
    category: CardCategory.region,
    resource: ResourceType.gold,
    imageAsset: 'assets/images/cards/region_gold_field.png',
  );

  static const settlement = GameCard(
    id: 'settlement',
    name: 'By',
    category: CardCategory.settlement,
    victoryPoints: 1,
    buildingCost: {
      ResourceType.brick: 1,
      ResourceType.grain: 1,
      ResourceType.wool: 1,
      ResourceType.lumber: 1
    },
    imageAsset: 'assets/images/cards/settlement.png',
  );

  static const city = GameCard(
    id: 'city',
    name: 'Stad',
    category: CardCategory.city,
    victoryPoints: 2,
    buildingCost: {ResourceType.ore: 3, ResourceType.grain: 2},
    imageAsset: 'assets/images/cards/city.png',
  );

  static const road = GameCard(
    id: 'road',
    name: 'Väg',
    category: CardCategory.road,
    buildingCost: {ResourceType.brick: 2, ResourceType.lumber: 1},
    imageAsset: 'assets/images/cards/road.png',
  );

  // ---------------------------------------------------------------------
  // Handlingskort (kostar inget, spelas från handen)
  // ---------------------------------------------------------------------

  static const brigittaTheWiseWoman = GameCard(
    id: 'action-brigitta',
    name: 'Brigitta, den visa kvinnan',
    category: CardCategory.action,
    expansionSet: ExpansionSet.basic,
    effectText:
        'Spela detta kort innan du slår tärningen. Välj resultatet på '
        'produktionstärningens slag.',
    imageAsset: 'assets/images/cards/actions/action_fortune_teller_cards.png',
  );

  static const relocation = GameCard(
    id: 'action-relocation',
    name: 'Omlokalisering',
    category: CardCategory.action,
    effectText:
        'Du får byta plats på 2 av dina egna regioner eller 2 av dina egna '
        'byggkort. Lagrade resurser på regioner får inte ändras, och de '
        'vanliga placeringsreglerna måste följas.',
    imageAsset: 'assets/images/cards/actions/action_packing_tent.png',
  );

  static const scout = GameCard(
    id: 'action-scout',
    name: 'Spejare',
    category: CardCategory.action,
    effectText:
        'Spela detta kort när du bygger en by. Ta 2 valfria kort från '
        'regionkortsstapeln. Blanda sedan om regionkortsstapeln.',
    imageAsset: 'assets/images/cards/actions/action_telescope_scout.png',
  );

  static const merchantCaravan = GameCard(
    id: 'action-merchant-caravan',
    name: 'Handelskaravan',
    category: CardCategory.action,
    effectText:
        'Släng exakt 2 av dina resurser och ta 2 valfria resurser i utbyte.',
    imageAsset: 'assets/images/cards/actions/action_horse_wagons.png',
  );

  static const goldsmith = GameCard(
    id: 'action-goldsmith',
    name: 'Guldsmed',
    category: CardCategory.action,
    effectText:
        'Släng 3 guld och ta 2 valfria resurser i utbyte.',
    imageAsset: 'assets/images/cards/actions/action_blacksmith_forge.png',
  );

  // ---------------------------------------------------------------------
  // Byggnader (by-/stadsutbyggnad, grön textruta)
  // ---------------------------------------------------------------------

  static const abbey = GameCard(
    id: 'building-abbey',
    name: 'Kloster',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    isUnique: true,
    buildingCost: {
      ResourceType.brick: 1,
      ResourceType.grain: 1,
      ResourceType.ore: 1
    },
    progressPoints: 1,
    effectText:
        'Här handlar det inte bara om framsteg – det bjuds även på rödvin '
        'och gott om mörk öl.',
    imageAsset: 'assets/images/cards/dioramas/diorama_church_building.png',
  );

  static const marketplace = GameCard(
    id: 'building-marketplace',
    name: 'Marknadsplats',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    isUnique: true,
    buildingCost: {ResourceType.wool: 1, ResourceType.grain: 1},
    commercePoints: 1,
    effectText:
        'Om ett produktionstal slås som förekommer oftare på motståndarens '
        'regioner än på dina egna, får du 1 resurs. Välj en resurs som '
        'motståndaren normalt skulle fått.',
    imageAsset: 'assets/images/cards/dioramas/diorama_busy_market.png',
  );

  static const parishHall = GameCard(
    id: 'building-parish-hall',
    name: 'Församlingshus',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    isUnique: true,
    buildingCost: {ResourceType.brick: 1, ResourceType.grain: 1},
    effectText:
        'Du betalar bara 1 resurs för att välja ett kort från en draghög.',
    imageAsset: 'assets/images/cards/dioramas/diorama_village_market_2.png',
  );

  static const storehouse = GameCard(
    id: 'building-storehouse',
    name: 'Lagerhus',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.lumber: 1, ResourceType.wool: 1},
    affectsBothNeighboringRegions: true,
    effectText:
        'Räkna inte resurserna på de 2 grannregionerna när händelsen '
        'Brigadanfall slås.',
    imageAsset: 'assets/images/cards/buildings/storehouse.png',
  );

  static const tollBridge = GameCard(
    id: 'building-toll-bridge',
    name: 'Tullbro',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.lumber: 1, ResourceType.brick: 1},
    commercePoints: 1,
    effectText: 'Riklig skörd: Du får 2 guld.',
    imageAsset: 'assets/images/cards/buildings/toll_bridge.png',
  );

  static const brickFactory = GameCard(
    id: 'building-brick-factory',
    name: 'Tegelbruk',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.brick: 1, ResourceType.ore: 1},
    resource: ResourceType.brick,
    affectsBothNeighboringRegions: true,
    doublesNeighborProduction: true,
    effectText: 'Dubblar tegelproduktionen på de angränsande kullarna.',
    imageAsset: 'assets/images/cards/buildings/forge_1.png',
  );

  static const grainMill = GameCard(
    id: 'building-grain-mill',
    name: 'Kvarn',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.grain: 1, ResourceType.lumber: 1},
    resource: ResourceType.grain,
    affectsBothNeighboringRegions: true,
    doublesNeighborProduction: true,
    effectText: 'Dubblar sädesproduktionen på de angränsande åkrarna.',
    imageAsset: 'assets/images/cards/buildings/water_mill_1.png',
  );

  static const ironFoundry = GameCard(
    id: 'building-iron-foundry',
    name: 'Järngjuteri',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.brick: 1, ResourceType.ore: 1},
    resource: ResourceType.ore,
    affectsBothNeighboringRegions: true,
    doublesNeighborProduction: true,
    effectText: 'Dubblar malmproduktionen på de angränsande bergen.',
    imageAsset: 'assets/images/cards/buildings/forge_2_active.png',
  );

  static const lumberCamp = GameCard(
    id: 'building-lumber-camp',
    name: 'Timmerläger',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.lumber: 1, ResourceType.ore: 1},
    resource: ResourceType.lumber,
    affectsBothNeighboringRegions: true,
    doublesNeighborProduction: true,
    effectText: 'Dubblar timmerproduktionen på de angränsande skogarna.',
    imageAsset: 'assets/images/cards/buildings/lumber_camp.png',
  );

  static const weaversShop = GameCard(
    id: 'building-weavers-shop',
    name: 'Vävstuga',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.lumber: 1, ResourceType.wool: 1},
    resource: ResourceType.wool,
    affectsBothNeighboringRegions: true,
    doublesNeighborProduction: true,
    effectText: 'Dubblar ullproduktionen på de angränsande betesmarkerna.',
    imageAsset: 'assets/images/cards/buildings/storage_shed_2.png',
  );

  // ---------------------------------------------------------------------
  // Enheter: handelsskepp
  // ---------------------------------------------------------------------

  static const largeTradeShip = GameCard(
    id: 'unit-large-trade-ship',
    name: 'Stort handelsskepp',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.tradeShip,
    buildingCost: {ResourceType.lumber: 1, ResourceType.wool: 1},
    commercePoints: 1,
    affectsBothNeighboringRegions: true,
    effectText:
        'Du får byta 2 resurser från vänster eller höger grannregion mot '
        '1 valfri annan resurs.',
    imageAsset: 'assets/images/cards/heroes/trade_ship_dock_1.png',
  );

  static GameCard _tradeShip(String resourceName, ResourceType resource) =>
      GameCard(
        id: 'unit-trade-ship-$resourceName',
        name: '${_swedishResourceName(resource)}skepp',
        category: CardCategory.expansion,
        expansionKind: ExpansionKind.tradeShip,
        resource: resource,
        buildingCost: {ResourceType.lumber: 1, ResourceType.wool: 1},
        commercePoints: 1,
        effectText:
            'Under din tur får du byta 2 ${_swedishResourceName(resource).toLowerCase()} '
            'mot 1 valfri annan resurs, så ofta du vill.',
        imageAsset: 'assets/images/cards/heroes/trade_ship_dock_2.png',
      );

  static final grainShip = _tradeShip('grain', ResourceType.grain);
  static final lumberShip = _tradeShip('lumber', ResourceType.lumber);
  static final brickShip = _tradeShip('brick', ResourceType.brick);
  static final woolShip = _tradeShip('wool', ResourceType.wool);
  static final goldShip = _tradeShip('gold', ResourceType.gold);
  static final oreShip = _tradeShip('ore', ResourceType.ore);

  // ---------------------------------------------------------------------
  // Enheter: hjältar ("Common heroes")
  // ---------------------------------------------------------------------

  static const austin = GameCard(
    id: 'hero-austin',
    name: 'Austin',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    buildingCost: {ResourceType.grain: 1, ResourceType.ore: 1},
    strengthPoints: 1,
    skillPoints: 2,
    effectText:
        'Slår du mig på ena kinden hinner du aldrig vända fram den andra.',
    imageAsset: 'assets/images/cards/heroes/hero_plain_man_1.png',
  );

  static const harald = GameCard(
    id: 'hero-harald',
    name: 'Harald',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    buildingCost: {ResourceType.grain: 1, ResourceType.ore: 1},
    strengthPoints: 2,
    skillPoints: 1,
    effectText:
        'Jag slår ner dig snabbare än du hinner rista ordet "strategi" i '
        'den där stenen.',
    imageAsset: 'assets/images/cards/heroes/hero_plain_man_2.png',
  );

  static const inga = GameCard(
    id: 'hero-inga',
    name: 'Inga',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    buildingCost: {
      ResourceType.grain: 1,
      ResourceType.wool: 1,
      ResourceType.ore: 1
    },
    strengthPoints: 1,
    skillPoints: 3,
    effectText:
        'Gudarna väntar sig fler offergåvor. Och de förväntar sig att du '
        'lämnar dem till mig!',
    imageAsset: 'assets/images/cards/heroes/hero_inga.jpg',
  );

  static const osmund = GameCard(
    id: 'hero-osmund',
    name: 'Osmund',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    buildingCost: {
      ResourceType.grain: 1,
      ResourceType.wool: 1,
      ResourceType.ore: 1
    },
    strengthPoints: 2,
    skillPoints: 2,
    effectText:
        'När det gäller guld och kvinnor tar vänskapen slut. Det gör den '
        'även när det gäller makt. Sanningen är att vänskap sällan varar '
        'särskilt länge.',
    imageAsset: 'assets/images/cards/heroes/hero_man_with_lamb.png',
  );

  static const candamir = GameCard(
    id: 'hero-candamir',
    name: 'Candamir',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    buildingCost: {
      ResourceType.wool: 2,
      ResourceType.grain: 1,
      ResourceType.ore: 1
    },
    strengthPoints: 4,
    skillPoints: 1,
    effectText:
        'En väl slipad yxa är en beprövad utgångspunkt för ett '
        'framgångsrikt samtal.',
    imageAsset: 'assets/images/cards/heroes/hero_candamir.jpg',
  );

  static const siglind = GameCard(
    id: 'hero-siglind',
    name: 'Siglind',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    buildingCost: {
      ResourceType.wool: 2,
      ResourceType.grain: 1,
      ResourceType.ore: 1
    },
    strengthPoints: 2,
    skillPoints: 3,
    effectText:
        'Att göra vem som helst till hjälte förringar vad det egentligen '
        'innebär att vara en.',
    imageAsset: 'assets/images/cards/heroes/hero_pair_woman_man.png',
  );

  // ---------------------------------------------------------------------
  // Händelsekort
  // ---------------------------------------------------------------------

  static const feud = GameCard(
    id: 'event-feud',
    name: 'Fejd',
    category: CardCategory.event,
    effectText:
        'Spelaren med styrkeövertaget väljer ut 3 av motståndarens '
        'byggnader. Motståndaren måste ta bort en av dem och lägga den '
        'underst i motsvarande draghög.',
    imageAsset: 'assets/images/cards/events/feud.jpg',
  );

  static const fraternalFeuds = GameCard(
    id: 'event-fraternal-feuds',
    name: 'Brödrafejd',
    category: CardCategory.event,
    effectText:
        'Spelaren med styrkeövertaget väljer 2 kort från motståndarens '
        'hand och lägger dem underst i motsvarande draghögar.',
    imageAsset: 'assets/images/cards/events/fraternal_feuds.jpg',
  );

  static const invention = GameCard(
    id: 'event-invention',
    name: 'Uppfinning',
    category: CardCategory.event,
    effectText:
        'Varje spelare får 1 valfri resurs för varje byggnad med en '
        'framstegspoäng – upp till max 2 resurser.',
    imageAsset: 'assets/images/cards/events/invention.jpg',
  );

  static const tradeShipsRace = GameCard(
    id: 'event-trade-ships-race',
    name: 'Handelsskeppskapplöpning',
    category: CardCategory.event,
    effectText:
        'Spelaren som äger flest handelsskepp får 1 valfri resurs. Vid '
        'lika antal får båda spelarna 1 valfri resurs var (båda måste ha '
        'minst 1 handelsskepp).',
    imageAsset: 'assets/images/cards/events/trade_ships_race.jpg',
  );

  static const travelingMerchant = GameCard(
    id: 'event-traveling-merchant',
    name: 'Resande köpman',
    category: CardCategory.event,
    effectText:
        'Varje spelare får ta upp till 2 valfria resurser mot att betala '
        '1 guld per resurs.',
    imageAsset: 'assets/images/cards/events/traveling_merchant.jpg',
  );

  static const yule = GameCard(
    id: 'event-yule',
    name: 'Jul',
    category: CardCategory.event,
    effectText:
        'Blanda om händelsekortsstapeln på samma sätt som vid spelets '
        'start. Dra sedan ett nytt händelsekort.',
    imageAsset: 'assets/images/cards/events/yule.jpg',
  );

  static const yearOfPlenty = GameCard(
    id: 'event-year-of-plenty',
    name: 'Goda året',
    category: CardCategory.event,
    effectText:
        'Varje region får 1 resurs för varje angränsande Lagerhus och '
        'Kloster, förutsatt att det finns lagringsutrymme kvar.',
    imageAsset: 'assets/images/cards/events/year_of_plenty.jpg',
  );

  /// Samtliga korttyper i grundspelet, för iteration/uppslag.
  static List<GameCard> get all => [
        forest,
        pasture,
        fields,
        hills,
        mountains,
        goldField,
        settlement,
        city,
        road,
        brigittaTheWiseWoman,
        relocation,
        scout,
        merchantCaravan,
        goldsmith,
        abbey,
        marketplace,
        parishHall,
        storehouse,
        tollBridge,
        brickFactory,
        grainMill,
        ironFoundry,
        lumberCamp,
        weaversShop,
        largeTradeShip,
        grainShip,
        lumberShip,
        brickShip,
        woolShip,
        goldShip,
        oreShip,
        austin,
        harald,
        inga,
        osmund,
        candamir,
        siglind,
        feud,
        fraternalFeuds,
        invention,
        tradeShipsRace,
        travelingMerchant,
        yule,
        yearOfPlenty,
      ];

  /// Antal fysiska kopior av varje korttyp i grundspelets 94-korsslek.
  /// Regioner räknas inte här – varje fysiskt regionkort har ett eget
  /// tärningstal och skapas som en egen instans (se [StarterCards]).
  static const Map<String, int> supplyCounts = {
    'settlement': 9,
    'city': 7,
    'road': 9,
    'action-brigitta': 2,
    'action-relocation': 1,
    'action-scout': 2,
    'action-merchant-caravan': 2,
    'action-goldsmith': 2,
    'building-abbey': 2,
    'building-marketplace': 2,
    'building-parish-hall': 2,
    'building-storehouse': 2,
    'building-toll-bridge': 1,
    'building-brick-factory': 1,
    'building-grain-mill': 1,
    'building-iron-foundry': 1,
    'building-lumber-camp': 1,
    'building-weavers-shop': 1,
    'unit-large-trade-ship': 1,
    'unit-trade-ship-grain': 1,
    'unit-trade-ship-lumber': 1,
    'unit-trade-ship-brick': 1,
    'unit-trade-ship-wool': 1,
    'unit-trade-ship-gold': 1,
    'unit-trade-ship-ore': 1,
    'hero-austin': 1,
    'hero-harald': 1,
    'hero-inga': 1,
    'hero-osmund': 1,
    'hero-candamir': 1,
    'hero-siglind': 1,
    'event-feud': 1,
    'event-fraternal-feuds': 1,
    'event-invention': 1,
    'event-trade-ships-race': 1,
    'event-traveling-merchant': 2,
    'event-yule': 1,
    'event-year-of-plenty': 2,
  };
}

String _swedishResourceName(ResourceType type) {
  switch (type) {
    case ResourceType.lumber:
      return 'Timmer';
    case ResourceType.brick:
      return 'Tegel';
    case ResourceType.ore:
      return 'Malm';
    case ResourceType.grain:
      return 'Säd';
    case ResourceType.wool:
      return 'Ull';
    case ResourceType.gold:
      return 'Guld';
    case ResourceType.none:
      return '';
  }
}
