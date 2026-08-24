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
    requirement: 'Värdshus',
    effectText:
        'Motståndaren måste lägga en av sina egna enheter med minst '
        '1 styrkepoäng underst i motsvarande draghög.',
    imageAsset: 'assets/images/cards/action_archer.webp',
  );

  static const arsonist = GameCard(
    id: 'action-arsonist',
    name: 'Pyroman',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfTurmoil,
    requirement: 'Värdshus',
    effectText:
        'Välj 1 av motståndarens byggnader intill en by/stad. '
        'Motståndaren måste lägga den underst i valfri draghög.',
    imageAsset: 'assets/images/cards/action_arsonist.webp',
  );

  static const sebastianTheItinerantPreacher = GameCard(
    id: 'action-sebastian',
    name: 'Sebastian, den vandrande predikanten',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfTurmoil,
    effectText:
        'Spelar du detta kort när händelserna Upplopp, Fejd eller '
        'Brödrafejd inträffar gäller inte dessa händelser dig.',
    imageAsset: 'assets/images/cards/action_sebastian.webp',
  );

  static const traitor = GameCard(
    id: 'action-traitor',
    name: 'Förrädare',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfTurmoil,
    requirement: 'Värdshus',
    effectText:
        'Motståndaren måste visa dig alla korten på sin hand. Du får '
        'lägga 1 av dem till din egen hand (i turneringsspelet bara '
        'enhets- och handlingskort).',
    imageAsset: 'assets/images/cards/action_traitor.webp',
  );

  static const voyageOfPlunder = GameCard(
    id: 'action-voyage-of-plunder',
    name: 'Plundringsfärd',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfTurmoil,
    requirement: 'Styrkeövertag',
    effectText:
        'Har motståndaren fler segerpoäng måste hen ge dig 2 valfria '
        'resurser. Ligger hen inte i ledningen får du bara 1 resurs.',
    imageAsset: 'assets/images/cards/action_voyage_of_plunder.webp',
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
    buildingCost: {ResourceType.brick: 1, ResourceType.ore: 1},
    strengthPoints: 1,
    effectText: 'Varje hjälte du bygger i ditt rike kostar 1 valfri resurs mindre.',
    imageAsset: 'assets/images/cards/building_drill_ground.webp',
  );

  static const lookoutTower = GameCard(
    id: 'building-lookout-tower',
    name: 'Vakttorn',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.building,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.lumber: 1, ResourceType.grain: 1},
    strengthPoints: 1,
    effectText:
        'När motståndaren spelar Bågskytt, Pyroman eller Förrädare, slå '
        'tärningen. Slår du 1 eller 2 har kortet ingen effekt.',
    imageAsset: 'assets/images/cards/building_lookout_tower.webp',
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
    buildingCost: {ResourceType.wool: 2, ResourceType.grain: 1, ResourceType.ore: 1},
    strengthPoints: 5,
    effectText: 'Vilken vacker ö! Den tar jag.',
    imageAsset: 'assets/images/cards/hero_carl_forkbeard.webp',
  );

  static const heinrichTheSentinel = GameCard(
    id: 'hero-heinrich-the-sentinel',
    name: 'Heinrich väktaren',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.grain: 1, ResourceType.wool: 1, ResourceType.ore: 1},
    strengthPoints: 2,
    effectText:
        'Heinrich är en hjälte som, utöver sina styrkepoäng, har en '
        'särskild effekt. Har du även ett Vakttorn i ditt rike är du '
        'skyddad när 1, 2, 3, 4 eller 5 slås. Kombineras Heinrich med '
        'Vakttornet slås tärningen ändå bara en gång.',
    imageAsset: 'assets/images/cards/hero_heinrich_the_sentinel.webp',
  );

  static const irmgardKeeperOfTheLight = GameCard(
    id: 'hero-irmgard',
    name: 'Irmgard, ljusets väktare',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.hero,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.grain: 1, ResourceType.gold: 1},
    skillPoints: 2,
    effectText:
        'Förlorar du ett kort ur ditt rike på grund av en händelse '
        'eller ett handlingskort får du 1 valfri resurs.',
    imageAsset: 'assets/images/cards/hero_irmgard.webp',
  );

  // ---------------------------------------------------------------------
  // Stadsutbyggnader (röd textruta, kräver befintlig stad)
  // ---------------------------------------------------------------------

  static const chapelLowRoll = GameCard(
    id: 'city-expansion-chapel-low',
    name: 'Kapell (1–3)',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.ore: 2, ResourceType.brick: 1, ResourceType.grain: 1},
    victoryPoints: 1,
    effectText: 'Slås 1, 2 eller 3 på produktionstärningen gäller inte händelsen Upplopp dig.',
    imageAsset: 'assets/images/cards/city_expansion_chapel_low.webp',
  );

  static const chapelHighRoll = GameCard(
    id: 'city-expansion-chapel-high',
    name: 'Kapell (4–6)',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.ore: 2, ResourceType.brick: 1, ResourceType.grain: 1},
    victoryPoints: 1,
    effectText: 'Slås 4, 5 eller 6 på produktionstärningen gäller inte händelsen Upplopp dig.',
    imageAsset: 'assets/images/cards/city_expansion_chapel_high.webp',
  );

  static const fairgrounds = GameCard(
    id: 'city-expansion-fairgrounds',
    name: 'Marknadsfält',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.lumber: 2, ResourceType.grain: 1, ResourceType.wool: 1},
    victoryPoints: 1,
    effectText:
        'Har du fler kunskapspoäng än motståndaren får du omedelbart '
        '2 valfria resurser efter att ha byggt Marknadsfältet.',
    imageAsset: 'assets/images/cards/city_expansion_fairgrounds.webp',
  );

  static const fireBrigade = GameCard(
    id: 'city-expansion-fire-brigade',
    name: 'Brandkår',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.wool: 2, ResourceType.brick: 1, ResourceType.ore: 1},
    victoryPoints: 1,
    effectText:
        'Brandkåren skyddar alla byggnader (by-/stadsutbyggnader och '
        'stadsutbyggnader) i den stad där Brandkåren är placerad, '
        'inklusive Brandkåren själv. Den stadens byggnader är skyddade '
        'mot Pyromanen.',
    imageAsset: 'assets/images/cards/city_expansion_fire_brigade.webp',
  );

  static const hedgeTavern = GameCard(
    id: 'city-expansion-hedge-tavern',
    name: 'Värdshus',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    isUnique: true,
    buildingCost: {ResourceType.gold: 2, ResourceType.grain: 1, ResourceType.wool: 1},
    victoryPoints: 1,
    effectText:
        'Grannarna viskar om att fler har setts gå in än komma ut. '
        'Krävs för många attack-handlingskort.',
    imageAsset: 'assets/images/cards/city_expansion_hedge_tavern.webp',
  );

  static const titheBarn = GameCard(
    id: 'city-expansion-tithe-barn',
    name: 'Tiondelada',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.lumber: 2, ResourceType.brick: 1, ResourceType.ore: 1},
    victoryPoints: 1,
    effectText:
        'När du bygger Tiondeladan väljer du en resurstyp – antingen '
        'ull eller säd. För varje egen hjälte får du 1 resurs av den '
        'valda typen.',
    imageAsset: 'assets/images/cards/city_expansion_tithe_barn.webp',
  );

  static const largeFestivalHall = GameCard(
    id: 'city-expansion-large-festival-hall',
    name: 'Stora festsalen',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfTurmoil,
    buildingCost: {ResourceType.grain: 3, ResourceType.ore: 3, ResourceType.brick: 2},
    victoryPoints: 2,
    effectText: 'Detta kort är värt 2 segerpoäng.',
    imageAsset: 'assets/images/cards/city_expansion_large_festival_hall.webp',
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
        'En spelare som har 1 eller 2 enheter med styrke- eller '
        'handelspoäng betalar 1 guld. Har spelaren fler än 2 sådana '
        'enheter betalar hen 2 guld. Betalar spelaren inte måste hen '
        'ta bort en av dessa enheter och lägga den underst i '
        'motsvarande draghög.',
    imageAsset: 'assets/images/cards/event_riots.webp',
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
