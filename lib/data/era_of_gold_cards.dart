import '../models/models.dart';

/// Alla korttyper i temasetet "The Era of Gold" (27 fysiska kort).
///
/// Källor: regelhäftets kortindex (s. 21–22) för regeltext, kopieantal
/// och krav, samt kortbilderna för byggkostnader.
///
/// Setet återanvänder fyra korttyper från grundspelet rakt av (samma
/// definition, bara fler fysiska kopior i det här setets stapel):
/// Goldsmith, Storehouse, Toll Bridge, Large Trade Ship och Trade Ships
/// Race/Traveling Merchant. De är därför inte omdefinierade här – se
/// [BasicSetCards].
class EraOfGoldCards {
  EraOfGoldCards._();

  // ---------------------------------------------------------------------
  // Handlingskort
  // ---------------------------------------------------------------------

  static const brigands = GameCard(
    id: 'action-brigands',
    name: 'Rövare',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfGold,
    requirement: 'Strength advantage',
    effectText:
        'You may take as many resources of the same type from your opponent as 1 of your '
        'regions can accommodate.',
    imageAsset: 'assets/images/cards/action_brigands.png',
  );

  static const gudrunTerrorOfTheSeas = GameCard(
    id: 'action-gudrun',
    name: 'Gudrun, havens skräck',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfGold,
    effectText: 'For each of your Pirate Ships, your opponent must give you up to 2 gold.',
    imageAsset: 'assets/images/cards/action_gudrun.png',
  );

  static const merchant = GameCard(
    id: 'action-merchant',
    name: 'Köpman',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfGold,
    requirement: '3 commerce points or city',
    effectText:
        'Take up to 2 resources of your choice from your opponent and give him 1 resource of '
        'your choice in return.',
    imageAsset: 'assets/images/cards/action_merchant.png',
  );

  static const reinerTheHerald = GameCard(
    id: 'action-reiner-the-herald',
    name: 'Reiner härolden',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfGold,
    effectText:
        'Play this card before rolling the dice and determine the event Celebration. You '
        'receive 1 additional resource for the Celebration.',
    imageAsset: 'assets/images/cards/action_reiner_the_herald.png',
  );

  static const tradeMaster = GameCard(
    id: 'action-trade-master',
    name: 'Handelsmästare',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfGold,
    requirement: 'Merchant Guild',
    effectText: 'You immediately receive 2 resources of your choice from your opponent.',
    imageAsset: 'assets/images/cards/action_trade_master.png',
  );

  // ---------------------------------------------------------------------
  // Landskapsutbyggnad (brun textruta, "Extraordinary Site")
  // ---------------------------------------------------------------------

  static const goldCache = GameCard(
    id: 'region-expansion-gold-cache',
    name: 'Guldgömma',
    category: CardCategory.regionExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    requirement: 'Hero with at least 1 strength point',
    effectText:
        'The Gold Cache may also be used to store the gold you received. When the event '
        'Brigand Attack is rolled, the gold in the cache is neither counted nor stolen.',
    imageAsset: 'assets/images/cards/region_expansion_gold_cache.png',
  );

  // ---------------------------------------------------------------------
  // By-/stadsutbyggnad (grön textruta): enhet
  // ---------------------------------------------------------------------

  static const pirateShip = GameCard(
    id: 'unit-pirate-ship',
    name: 'Piratskepp',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.otherUnit,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.lumber: 1, ResourceType.wool: 1},
    effectText:
        'Your opponent must remove 1 trade ship of his choice from his principality and place '
        'it on the discard pile. Event Plentiful Harvest: You receive 1 gold.',
    imageAsset: 'assets/images/cards/unit_pirate_ship.png',
  );

  // ---------------------------------------------------------------------
  // Stadsutbyggnader (röd textruta, kräver befintlig stad)
  // ---------------------------------------------------------------------

  static const merchantGuild = GameCard(
    id: 'city-expansion-merchant-guild',
    name: 'Köpmansgille',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    isUnique: true,
    buildingCost: {ResourceType.brick: 1, ResourceType.wool: 1, ResourceType.grain: 1},
    commercePoints: 2,
    effectText:
        "Money can't buy you happiness. But taking it away from others can. Is a prerequisite "
        'for other expansion and action cards.',
    imageAsset: 'assets/images/cards/city_expansion_merchant_guild.png',
  );

  static const moneylender = GameCard(
    id: 'city-expansion-moneylender',
    name: 'Ockrare',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    isUnique: true,
    buildingCost: {ResourceType.lumber: 1, ResourceType.ore: 1, ResourceType.brick: 1},
    effectText:
        'If you have the trade advantage and the event Trade is rolled on the event die, you '
        'may take 2 resources of your choice from your opponent.',
    imageAsset: 'assets/images/cards/city_expansion_moneylender.png',
  );

  static const harbor = GameCard(
    id: 'city-expansion-harbor',
    name: 'Hamn',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.grain: 1, ResourceType.wool: 1, ResourceType.ore: 1},
    commercePoints: 1,
    effectText:
        'As long as at least 3 trade ships are placed in your principality, the Harbor is '
        'worth 1 victory point.',
    imageAsset: 'assets/images/cards/city_expansion_harbor.png',
  );

  static const tradingBase = GameCard(
    id: 'city-expansion-trading-base',
    name: 'Handelsplats',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.grain: 1},
    commercePoints: 1,
    victoryPoints: 1,
    effectText: 'The Marketplace and the Harbor receive a second commerce point.',
    imageAsset: 'assets/images/cards/city_expansion_trading_base.png',
  );

  static const mint = GameCard(
    id: 'city-expansion-mint',
    name: 'Myntverk',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.lumber: 1, ResourceType.ore: 1, ResourceType.brick: 1},
    effectText: 'Once per each of your turns, you may use this Mint to trade 1 gold for 1 other resource of your choice.',
    imageAsset: 'assets/images/cards/city_expansion_mint.png',
  );

  static const stapleHouse = GameCard(
    id: 'city-expansion-staple-house',
    name: 'Stapelhus',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.lumber: 1, ResourceType.wool: 1, ResourceType.grain: 1},
    requirement: 'Merchant Guild',
    effectText: 'If you build the Staple House, you immediately receive 2 resources of your choice.',
    imageAsset: 'assets/images/cards/city_expansion_staple_house.png',
  );

  static const saltSilo = GameCard(
    id: 'city-expansion-salt-silo',
    name: 'Saltsilo',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.wool: 1, ResourceType.gold: 1, ResourceType.brick: 1},
    effectText: 'Each of your trade ships is worth 1 more commerce point.',
    imageAsset: 'assets/images/cards/city_expansion_salt_silo.png',
  );

  // ---------------------------------------------------------------------
  // Händelsekort
  // ---------------------------------------------------------------------

  static const giftForThePrince = GameCard(
    id: 'event-gift-for-the-prince',
    name: 'Gåva till fursten',
    category: CardCategory.event,
    expansionSet: ExpansionSet.eraOfGold,
    effectText: 'Each player receives 1 gold for each unit with at least 1 strength point.',
    imageAsset: 'assets/images/cards/event_gift_for_the_prince.png',
  );

  /// Samtliga korttyper som är nya för det här setet (dvs. exklusive de
  /// återanvända grundspelskorten – se filens doc-kommentar).
  static List<GameCard> get all => [
        brigands, gudrunTerrorOfTheSeas, merchant, reinerTheHerald, tradeMaster,
        goldCache,
        pirateShip,
        merchantGuild, moneylender, harbor, tradingBase, mint, stapleHouse, saltSilo,
        giftForThePrince,
      ];

  /// Antal fysiska kopior per korttyp i det här setets 27-korsslek.
  /// Kort som återanvänds från grundspelet (Goldsmith, Storehouse, Toll
  /// Bridge, Large Trade Ship, Trade Ships Race, Traveling Merchant)
  /// listas här med sina id:n från [BasicSetCards], eftersom de fyller
  /// platser i det här setets stapel trots att de inte omdefinieras.
  static const Map<String, int> supplyCounts = {
    'action-brigands': 1,
    'action-gudrun': 1,
    'action-merchant': 2,
    'action-reiner-the-herald': 1,
    'action-trade-master': 2,
    'action-goldsmith': 1, // återanvänd från BasicSetCards
    'region-expansion-gold-cache': 1,
    'building-storehouse': 1, // återanvänd
    'building-toll-bridge': 1, // återanvänd
    'unit-large-trade-ship': 1, // återanvänd
    'unit-pirate-ship': 2,
    'city-expansion-merchant-guild': 2,
    'city-expansion-moneylender': 1,
    'city-expansion-harbor': 1,
    'city-expansion-trading-base': 1,
    'city-expansion-mint': 2,
    'city-expansion-staple-house': 2,
    'city-expansion-salt-silo': 1,
    'event-gift-for-the-prince': 1,
    'event-trade-ships-race': 1, // återanvänd
    'event-traveling-merchant': 1, // återanvänd
  };
}
