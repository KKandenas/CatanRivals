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
    requirement: 'Styrkeövertag',
    effectText:
        'Du får ta lika många resurser av samma sort från motståndaren '
        'som en av dina regioner har plats för.',
    imageAsset: 'assets/images/cards/action_brigands.png',
  );

  static const gudrunTerrorOfTheSeas = GameCard(
    id: 'action-gudrun',
    name: 'Gudrun, havens skräck',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfGold,
    effectText: 'För varje eget piratskepp måste motståndaren ge dig upp till 2 guld.',
    imageAsset: 'assets/images/cards/action_gudrun.png',
  );

  static const merchant = GameCard(
    id: 'action-merchant',
    name: 'Köpman',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfGold,
    requirement: '3 handelspoäng eller stad',
    effectText:
        'Ta upp till 2 valfria resurser från motståndaren och ge tillbaka '
        '1 valfri resurs.',
    imageAsset: 'assets/images/cards/action_merchant.png',
  );

  static const reinerTheHerald = GameCard(
    id: 'action-reiner-the-herald',
    name: 'Reiner härolden',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfGold,
    effectText:
        'Spela detta kort innan du slår tärningen och bestäm att '
        'händelsen blir Fest. Du får 1 extra resurs för Festen.',
    imageAsset: 'assets/images/cards/actions/action_elder_with_bird.png',
  );

  static const tradeMaster = GameCard(
    id: 'action-trade-master',
    name: 'Handelsmästare',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfGold,
    requirement: 'Köpmansgille',
    effectText: 'Du får omedelbart 2 valfria resurser från motståndaren.',
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
    requirement: 'Hjälte med minst 1 styrkepoäng',
    effectText:
        'Guldgömman kan även användas för att lagra guld du fått. När '
        'händelsen Brigadanfall slås räknas inte guldet i gömman, och '
        'det kan inte stjälas.',
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
        'Motståndaren måste ta bort 1 valfritt handelsskepp från sitt '
        'rike och lägga det bland kasserade kort. Riklig skörd: Du får '
        '1 guld.',
    imageAsset: 'assets/images/cards/dioramas/diorama_two_ships.png',
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
    buildingCost: {ResourceType.brick: 2, ResourceType.wool: 2, ResourceType.grain: 1},
    victoryPoints: 1,
    commercePoints: 2,
    effectText:
        'Pengar köper ingen lycka. Men att ta dem från andra gör det. '
        'Krävs för vissa andra bygg- och handlingskort.',
    imageAsset: 'assets/images/cards/city_expansion_merchant_guild.png',
  );

  static const moneylender = GameCard(
    id: 'city-expansion-moneylender',
    name: 'Ockrare',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    isUnique: true,
    buildingCost: {ResourceType.lumber: 2, ResourceType.ore: 2, ResourceType.brick: 1},
    victoryPoints: 1,
    effectText:
        'Om du har handelsövertaget och händelsen Handel slås på '
        'händelsetärningen får du ta 2 valfria resurser från '
        'motståndaren.',
    imageAsset: 'assets/images/cards/city_expansion_moneylender.png',
  );

  static const harbor = GameCard(
    id: 'city-expansion-harbor',
    name: 'Hamn',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.brick: 1, ResourceType.wool: 1, ResourceType.ore: 1},
    commercePoints: 1,
    effectText:
        'Så länge du har minst 3 handelsskepp i ditt rike är Hamnen '
        'värd 1 segerpoäng.',
    imageAsset: 'assets/images/cards/city_expansion_harbor.png',
  );

  static const tradingBase = GameCard(
    id: 'city-expansion-trading-base',
    name: 'Handelsplats',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.grain: 2, ResourceType.wool: 2, ResourceType.brick: 1},
    commercePoints: 1,
    victoryPoints: 1,
    effectText: 'Marknadsplatsen och Hamnen får ytterligare 1 handelspoäng.',
    imageAsset: 'assets/images/cards/dioramas/diorama_small_shop.png',
  );

  static const mint = GameCard(
    id: 'city-expansion-mint',
    name: 'Myntverk',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.lumber: 2, ResourceType.ore: 2, ResourceType.brick: 1},
    victoryPoints: 1,
    effectText: 'En gång per egen tur får du använda Myntverket för att byta 1 guld mot 1 valfri annan resurs.',
    imageAsset: 'assets/images/cards/city_expansion_mint.png',
  );

  static const stapleHouse = GameCard(
    id: 'city-expansion-staple-house',
    name: 'Stapelhus',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.brick: 2, ResourceType.ore: 2, ResourceType.wool: 1},
    victoryPoints: 1,
    requirement: 'Köpmansgille',
    effectText: 'Bygger du Stapelhuset får du omedelbart 2 valfria resurser.',
    imageAsset: 'assets/images/cards/city_expansion_staple_house.png',
  );

  static const saltSilo = GameCard(
    id: 'city-expansion-salt-silo',
    name: 'Saltsilo',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfGold,
    buildingCost: {ResourceType.wool: 2, ResourceType.gold: 2, ResourceType.brick: 1},
    victoryPoints: 1,
    effectText: 'Vart och ett av dina handelsskepp är värt 1 handelspoäng till.',
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
    effectText: 'Varje spelare får 1 guld för varje enhet med minst 1 styrkepoäng.',
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
