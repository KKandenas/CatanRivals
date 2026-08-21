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
        'Play this card before rolling the dice. Choose the result of the production die roll.',
    imageAsset: 'assets/images/cards/actions/action_fortune_teller_cards.png',
  );

  static const relocation = GameCard(
    id: 'action-relocation',
    name: 'Omlokalisering',
    category: CardCategory.action,
    effectText:
        'You may exchange 2 of your own regions or 2 of your own expansion cards. Resources '
        'stored on regions may not be changed and card placement rules must be followed.',
    imageAsset: 'assets/images/cards/actions/action_packing_tent.png',
  );

  static const scout = GameCard(
    id: 'action-scout',
    name: 'Spejare',
    category: CardCategory.action,
    effectText:
        'Play this card when building a settlement. Take 2 cards of your choice from the '
        'region card stack. Reshuffle the region card stack.',
    imageAsset: 'assets/images/cards/actions/action_telescope_scout.png',
  );

  static const merchantCaravan = GameCard(
    id: 'action-merchant-caravan',
    name: 'Handelskaravan',
    category: CardCategory.action,
    effectText:
        'Discard exactly 2 of your resources and take any 2 resources of your choice in return.',
    imageAsset: 'assets/images/cards/actions/action_horse_wagons.png',
  );

  static const goldsmith = GameCard(
    id: 'action-goldsmith',
    name: 'Guldsmed',
    category: CardCategory.action,
    effectText:
        'Discard 3 gold and take any 2 resources of your choice in return.',
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
        'Progress is not the only thing here; you also get red wine and lots of dark beer.',
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
        "If a production number is rolled that appears more frequently on your opponent's "
        'regions than yours, you receive 1 resource. Choose a resource your opponent can '
        'normally receive.',
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
        'You pay only 1 resource for choosing a card from a draw stack.',
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
        'Do not count the resources on the 2 neighboring regions when the event Brigand Attack is rolled.',
    imageAsset: 'assets/images/cards/buildings/storehouse.png',
  );

  static const tollBridge = GameCard(
    id: 'building-toll-bridge',
    name: 'Tullbro',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.lumber: 1, ResourceType.brick: 1},
    commercePoints: 1,
    effectText: 'Even: Plentiful Harvest: You receive 2 gold.',
    imageAsset: 'assets/images/cards/buildings/toll_bridge.png',
  );

  static const brickFactory = GameCard(
    id: 'building-brick-factory',
    name: 'Tegelbruk',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.brick: 1, ResourceType.ore: 1},
    affectsBothNeighboringRegions: true,
    effectText: 'Doubles the brick production of the neighboring hills.',
    imageAsset: 'assets/images/cards/buildings/forge_1.png',
  );

  static const grainMill = GameCard(
    id: 'building-grain-mill',
    name: 'Kvarn',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.grain: 1, ResourceType.lumber: 1},
    affectsBothNeighboringRegions: true,
    effectText: 'Doubles the grain production of the neighboring fields.',
    imageAsset: 'assets/images/cards/buildings/water_mill_1.png',
  );

  static const ironFoundry = GameCard(
    id: 'building-iron-foundry',
    name: 'Järngjuteri',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.brick: 1, ResourceType.ore: 1},
    affectsBothNeighboringRegions: true,
    effectText: 'Doubles the ore production of the neighboring mountains.',
    imageAsset: 'assets/images/cards/buildings/forge_2_active.png',
  );

  static const lumberCamp = GameCard(
    id: 'building-lumber-camp',
    name: 'Timmerläger',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.lumber: 1, ResourceType.ore: 1},
    affectsBothNeighboringRegions: true,
    effectText: 'Doubles the lumber production of the neighboring forests.',
    imageAsset: 'assets/images/cards/buildings/lumber_camp.png',
  );

  static const weaversShop = GameCard(
    id: 'building-weavers-shop',
    name: 'Vävstuga',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    buildingCost: {ResourceType.lumber: 1, ResourceType.wool: 1},
    affectsBothNeighboringRegions: true,
    effectText: 'Doubles the wool production of the neighboring pastures.',
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
    effectText:
        'You may trade 2 resources of the left or right neighboring region for any 1 other '
        'resource of your choice.',
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
            'During your turn, you may trade 2 $resourceName for any 1 other resource as often as you wish.',
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
        "If you hit my left cheek, don't even think you'll have time to hit the right one too.",
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
        'I knock you out faster than you can carve the word "strategy" in this stone.',
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
        'The gods are expecting more offerings. And they expect you to hand them over to me!',
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
        'When it comes to gold and women, friendship stops. And it also stops when it comes to power. '
        'Actually, friendship never lasts very long.',
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
        'A well-sharpened axe is a tried and tested starting position for a successful conversation.',
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
        'Turning men into heroes belittles the importance of being a hero.',
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
        "The player who has the strength advantage selects 3 of his opponent's buildings. The "
        'opponent must remove one of them and return it to the bottom of a matching draw stack.',
    imageAsset: 'assets/images/cards/event_feud.png',
  );

  static const fraternalFeuds = GameCard(
    id: 'event-fraternal-feuds',
    name: 'Brödrafejd',
    category: CardCategory.event,
    effectText:
        "The player who has the strength advantage selects 2 cards from the opponent's hand and "
        'returns them to the bottom of matching draw stacks.',
    imageAsset: 'assets/images/cards/event_fraternal_feuds.png',
  );

  static const invention = GameCard(
    id: 'event-invention',
    name: 'Uppfinning',
    category: CardCategory.event,
    effectText:
        'Each player gets 1 resource of his choice for each building with a progress point – up '
        'to a maximum of 2 resources.',
    imageAsset: 'assets/images/cards/event_invention.png',
  );

  static const tradeShipsRace = GameCard(
    id: 'event-trade-ships-race',
    name: 'Handelsskeppskapplöpning',
    category: CardCategory.event,
    effectText:
        'The player who owns the most trade ships receives any 1 resource of his choice. In case '
        'of a tie, each player receives any 1 resource of his choice (each must have at least 1 '
        'trade ship).',
    imageAsset: 'assets/images/cards/event_trade_ships_race.png',
  );

  static const travelingMerchant = GameCard(
    id: 'event-traveling-merchant',
    name: 'Resande köpman',
    category: CardCategory.event,
    effectText:
        'Each player may take up to 2 resources of his choice, paying 1 gold per resource.',
    imageAsset: 'assets/images/cards/event_traveling_merchant.png',
  );

  static const yule = GameCard(
    id: 'event-yule',
    name: 'Jul',
    category: CardCategory.event,
    effectText:
        'Shuffle the event card stack as performed at the beginning of the game. Afterwards, '
        'draw an event card again.',
    imageAsset: 'assets/images/cards/event_yule.png',
  );

  static const yearOfPlenty = GameCard(
    id: 'event-year-of-plenty',
    name: 'Goda året',
    category: CardCategory.event,
    effectText:
        'Each region gets 1 resource for each adjacent Storehouse and Abbey, provided that '
        'storage space is available.',
    imageAsset: 'assets/images/cards/event_year_of_plenty.png',
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
