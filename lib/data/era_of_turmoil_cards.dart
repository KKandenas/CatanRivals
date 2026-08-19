import '../models/models.dart';

/// Alla korttyper i temasetet "The Era of Turmoil" (28 fysiska kort).
///
/// Källor: regelhäftets kortindex (s. 23–25) för regeltext, kopieantal
/// och krav, samt kortbilderna för byggkostnader.
///
/// Setet återanvänder tre korttyper rakt av från tidigare set (samma
/// definition, bara fler fysiska kopior i det här setets stapel): Feud
/// och Fraternal Feuds (grundspelet) samt Brigands (Era of Gold). De är
/// därför inte omdefinierade här – se [BasicSetCards] och
/// [EraOfGoldCards].
class EraOfTurmoilCards {
  EraOfTurmoilCards._();

  // ---------------------------------------------------------------------
  // Handlingskort
  // ---------------------------------------------------------------------

  static const archer = GameCard(
    id: 'action-archer',
    name: 'Bågskytt',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfTurmoil,
    requirement: 'Hedge Tavern',
    effectText:
        'Your opponent must place 1 of his own units with at least 1 strength point under a '
        'matching draw stack.',
    imageAsset: 'assets/images/cards/action_archer.png',
  );

  static const arsonist = GameCard(
    id: 'action-arsonist',
    name: 'Pyroman',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfTurmoil,
    requirement: 'Hedge Tavern',
    effectText:
        "Choose 1 of your opponent's buildings adjacent to a settlement/city. He must place it "
        'under a draw stack of his choice.',
    imageAsset: 'assets/images/cards/action_arsonist.png',
  );

  static const sebastianTheItinerantPreacher = GameCard(
    id: 'action-sebastian',
    name: 'Sebastian, den vandrande predikanten',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfTurmoil,
    effectText:
        'If you play this card when the events Riots, Feud, or Fraternal Feud occur, these '
        'events do not apply to you.',
    imageAsset: 'assets/images/cards/action_sebastian.png',
  );

  static const traitor = GameCard(
    id: 'action-traitor',
    name: 'Förrädare',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfTurmoil,
    requirement: 'Hedge Tavern',
    effectText:
        'Your opponent must show you all the cards in his hand. You may add 1 of them to your '
        'hand (in the Tournament Game, only units and action cards).',
    imageAsset: 'assets/images/cards/action_traitor.png',
  );

  static const voyageOfPlunder = GameCard(
    id: 'action-voyage-of-plunder',
    name: 'Plundringsfärd',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfTurmoil,
    requirement: 'Strength advantage',
    effectText:
        'If your opponent has more victory points, he must give you 2 resources of your '
        "choice. If he isn't in the lead, you only receive one resource.",
    imageAsset: 'assets/images/cards/action_voyage_of_plunder.png',
  );

  // ---------------------------------------------------------------------
  // By-/stadsutbyggnad (grön textruta): byggnader
  // ---------------------------------------------------------------------

  static const drillGround = GameCard(
    id: 'building-drill-ground',
    name: 'Övningsplats',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    expansionSet: ExpansionSet.eraOfTurmoil,
    isUnique: true,
    buildingCost: {ResourceType.brick: 1, ResourceType.grain: 1},
    effectText: 'Each hero you build in your principality costs you 1 resource of your choice less.',
    imageAsset: 'assets/images/cards/building_drill_ground.png',
  );

  static const lookoutTower = GameCard(
    id: 'building-lookout-tower',
    name: 'Vakttorn',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.lumber: 1, ResourceType.grain: 1},
    effectText:
        'When your opponent plays an Archer, Arsonist, or Traitor, roll the die. If you roll a '
        '1 or 2, the card has no effect.',
    imageAsset: 'assets/images/cards/building_lookout_tower.png',
  );

  // ---------------------------------------------------------------------
  // By-/stadsutbyggnad (grön textruta): hjältar
  // ---------------------------------------------------------------------

  static const carlForkbeard = GameCard(
    id: 'hero-carl-forkbeard',
    name: 'Carl Kluvskägg',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.wool: 1, ResourceType.grain: 1, ResourceType.ore: 1},
    strengthPoints: 3,
    skillPoints: 1,
    effectText: 'What a beautiful island! I take it.',
    imageAsset: 'assets/images/cards/hero_carl_forkbeard.png',
  );

  static const heinrichTheSentinel = GameCard(
    id: 'hero-heinrich-the-sentinel',
    name: 'Heinrich väktaren',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.grain: 1, ResourceType.wool: 1, ResourceType.ore: 1},
    strengthPoints: 3,
    effectText:
        'Heinrich is a hero who, in addition to his strength points, has a special effect. If '
        'you also have a Lookout Tower in your principality, you are protected when a 1, 2, 3, '
        '4, or 5 is rolled. If Heinrich is combined with the Lookout Tower, the die is still '
        'rolled only once.',
    imageAsset: 'assets/images/cards/hero_heinrich_the_sentinel.png',
  );

  static const irmgardKeeperOfTheLight = GameCard(
    id: 'hero-irmgard',
    name: 'Irmgard, ljusets väktare',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.grain: 1, ResourceType.gold: 1},
    strengthPoints: 1,
    skillPoints: 1,
    effectText:
        'If you lose a card of your principality due to an event or an action, you receive '
        'any 1 resource of your choice.',
    imageAsset: 'assets/images/cards/hero_irmgard.png',
  );

  // ---------------------------------------------------------------------
  // Stadsutbyggnader (röd textruta, kräver befintlig stad)
  // ---------------------------------------------------------------------

  static const chapelLowRoll = GameCard(
    id: 'city-expansion-chapel-low',
    name: 'Kapell (1–3)',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.gold: 1, ResourceType.grain: 1},
    effectText: 'If a 1, 2, or 3 is rolled with the production die, the event Riots does not apply to you.',
    imageAsset: 'assets/images/cards/city_expansion_chapel_low.png',
  );

  static const chapelHighRoll = GameCard(
    id: 'city-expansion-chapel-high',
    name: 'Kapell (4–6)',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.gold: 1, ResourceType.grain: 1},
    effectText: 'If a 4, 5, or 6 is rolled with the production die, the event Riots does not apply to you.',
    imageAsset: 'assets/images/cards/city_expansion_chapel_high.png',
  );

  static const fairgrounds = GameCard(
    id: 'city-expansion-fairgrounds',
    name: 'Marknadsfält',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.lumber: 1, ResourceType.grain: 1, ResourceType.wool: 1},
    effectText:
        'If you have more skill points than your opponent you immediately receive 2 resources '
        'of your choice after building the Fairground.',
    imageAsset: 'assets/images/cards/city_expansion_fairgrounds.png',
  );

  static const fireBrigade = GameCard(
    id: 'city-expansion-fire-brigade',
    name: 'Brandkår',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.wool: 1, ResourceType.brick: 1, ResourceType.ore: 1},
    effectText:
        'The Fire Brigade protects all buildings (settlement/city expansions and city '
        'expansions) in the city where the Fire Brigade is placed, including the Fire Brigade '
        "itself. This city's buildings are safe from the Arsonist.",
    imageAsset: 'assets/images/cards/city_expansion_fire_brigade.png',
  );

  static const hedgeTavern = GameCard(
    id: 'city-expansion-hedge-tavern',
    name: 'Värdshus',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    isUnique: true,
    buildingCost: {ResourceType.ore: 1, ResourceType.grain: 1, ResourceType.wool: 1},
    effectText:
        'In the neighborhood, word has it that more people were seen going inside than coming '
        'out. Is a prerequisite for many action-attack cards.',
    imageAsset: 'assets/images/cards/city_expansion_hedge_tavern.png',
  );

  static const titheBarn = GameCard(
    id: 'city-expansion-tithe-barn',
    name: 'Tiondelada',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.lumber: 1, ResourceType.grain: 1},
    effectText:
        'When you build the Tithe Barn, choose a resource type – either wool or grain. For '
        'each of your heroes, you receive 1 resource of the chosen type.',
    imageAsset: 'assets/images/cards/city_expansion_tithe_barn.png',
  );

  static const largeFestivalHall = GameCard(
    id: 'city-expansion-large-festival-hall',
    name: 'Stora festsalen',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.grain: 1, ResourceType.ore: 1, ResourceType.wool: 1},
    victoryPoints: 2,
    effectText: 'This card is worth 2 victory points.',
    imageAsset: 'assets/images/cards/city_expansion_large_festival_hall.png',
  );

  // ---------------------------------------------------------------------
  // Händelsekort
  // ---------------------------------------------------------------------

  static const riots = GameCard(
    id: 'event-riots',
    name: 'Upplopp',
    category: CardCategory.event,
    expansionSet: ExpansionSet.eraOfTurmoil,
    effectText:
        'A player who has 1 or 2 units with strength points or commerce points pays 1 gold. A '
        'player who has more than 2 of these units pays 2 gold. If a player doesn\'t pay, he '
        'must remove one of these units and return it to the bottom of a matching draw stack.',
    imageAsset: 'assets/images/cards/event_riots.png',
  );

  /// Samtliga korttyper som är nya för det här setet (dvs. exklusive de
  /// återanvända Feud, Fraternal Feuds och Brigands – se filens
  /// doc-kommentar).
  static List<GameCard> get all => [
        archer, arsonist, sebastianTheItinerantPreacher, traitor, voyageOfPlunder,
        drillGround, lookoutTower,
        carlForkbeard, heinrichTheSentinel, irmgardKeeperOfTheLight,
        chapelLowRoll, chapelHighRoll, fairgrounds, fireBrigade, hedgeTavern, titheBarn,
        largeFestivalHall,
        riots,
      ];

  /// Antal fysiska kopior per korttyp i det här setets 28-korsslek.
  static const Map<String, int> supplyCounts = {
    'action-archer': 2,
    'action-arsonist': 2,
    'action-sebastian': 1,
    'action-traitor': 2,
    'action-voyage-of-plunder': 2,
    'action-brigands': 1, // återanvänd från EraOfGoldCards
    'building-drill-ground': 1,
    'building-lookout-tower': 1,
    'hero-carl-forkbeard': 1,
    'hero-heinrich-the-sentinel': 1,
    'hero-irmgard': 1,
    'city-expansion-chapel-low': 1,
    'city-expansion-chapel-high': 1,
    'city-expansion-fairgrounds': 1,
    'city-expansion-fire-brigade': 2,
    'city-expansion-hedge-tavern': 2,
    'city-expansion-tithe-barn': 1,
    'city-expansion-large-festival-hall': 1,
    'event-riots': 2,
    'event-feud': 1, // återanvänd från BasicSetCards
    'event-fraternal-feuds': 1, // återanvänd från BasicSetCards
  };
}
