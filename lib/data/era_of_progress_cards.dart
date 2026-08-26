import '../models/models.dart';

/// Alla korttyper i temasetet "The Era of Progress" (31 fysiska kort) –
/// det sista av de tre temaseten.
///
/// Källor: regelhäftets kortindex (s. 25–27) för regeltext, kopieantal
/// och krav, samt kortbilderna för byggkostnader och den fulla
/// effekttexten (regelhäftets index innehåller ibland bara en
/// förtydligande kommentar, inte hela korttexten).
///
/// Setet återanvänder tre korttyper rakt av från grundspelet: Brigitta
/// den visa kvinnan, Omlokalisering och Uppfinning. De är därför inte
/// omdefinierade här – se [BasicSetCards].
class EraOfProgressCards {
  EraOfProgressCards._();

  // ---------------------------------------------------------------------
  // Handlingskort
  // ---------------------------------------------------------------------

  static const benjaminTheTravelingScholar = GameCard(
    id: 'action-benjamin',
    name: 'Benjamin, den vandrande lärden',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    effectText:
        'Du får på nytt resursen från varje region vars tal du slog '
        'i början av din tur.',
    imageAsset: 'assets/images/cards/action_benjamin.webp',
  );

  static const doctor = GameCard(
    id: 'action-doctor',
    name: 'Doktorn',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Badhus',
    effectText:
        'Varje region som gränsar till ditt Badhus får 1 resurs. Har '
        'du flera Badhus får du bara använda ett av dem.',
    imageAsset: 'assets/images/cards/action_doctor.webp',
  );

  static const guidoTheAmbassador = GameCard(
    id: 'action-guido',
    name: 'Guido ambassadören',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Rådhus, eller färre segerpoäng än motståndaren',
    effectText: 'Du får välja 1 kort från kasserade kort (turneringsspel: från motståndarens kasserade kort).',
    imageAsset: 'assets/images/cards/action_guido.webp',
  );

  static const gustavTheLibrarian = GameCard(
    id: 'action-gustav',
    name: 'Gustav bibliotekarien',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Bibliotek, eller färre segerpoäng än motståndaren',
    effectText: 'Du får välja 1 kort från kasserade kort (turneringsspel: från dina egna kasserade kort).',
    imageAsset: 'assets/images/cards/action_gustav.webp',
  );

  static const mineralMining = GameCard(
    id: 'action-mineral-mining',
    name: 'Malmbrytning',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Universitet',
    effectText: 'Du får upp till 2 malm.',
    imageAsset: 'assets/images/cards/action_mineral_mining.webp',
  );

  static const threeFieldSystem = GameCard(
    id: 'action-three-field-system',
    name: 'Trevångsbruk',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Universitet',
    effectText: 'Du får upp till 2 säd.',
    imageAsset: 'assets/images/cards/action_three_field_system.webp',
  );

  // ---------------------------------------------------------------------
  // By-/stadsutbyggnad (grön textruta): enhet
  // ---------------------------------------------------------------------

  static const chiefCannoneer = GameCard(
    id: 'unit-chief-cannoneer',
    name: 'Kanonmästare',
    category: CardCategory.expansion,
    expansionKind: ExpansionKind.otherUnit,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Universitet',
    buildingCost: {ResourceType.lumber: 1, ResourceType.ore: 1},
    strengthPoints: 4,
    effectText:
        'Jag ska visa dig hur man skapar en romantisk slottsruin. Är '
        'en enhet men ingen hjälte – du får ha 2 Kanonmästare i ditt '
        'rike. Kort som gäller hjältar gäller inte den, men kort som '
        'gäller enheter gör det.',
    imageAsset: 'assets/images/cards/unit_chief_cannoneer.webp',
  );

  // ---------------------------------------------------------------------
  // Stadsutbyggnader (röd textruta, kräver befintlig stad)
  // ---------------------------------------------------------------------

  static const bathHouse = GameCard(
    id: 'city-expansion-bath-house',
    name: 'Badhus',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Stad',
    buildingCost: {ResourceType.brick: 2, ResourceType.wool: 1, ResourceType.ore: 1},
    victoryPoints: 1,
    effectText: 'Skyddar alla 4 regioner som gränsar till den här staden från effekterna av händelsen Pest.',
    imageAsset: 'assets/images/cards/city_expansion_bath_house.webp',
  );

  static const buildingCrane = GameCard(
    id: 'city-expansion-building-crane',
    name: 'Byggkran',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Stad, Universitet',
    buildingCost: {ResourceType.lumber: 1},
    effectText: 'Varje stadsutbyggnad du bygger som kostar mer än 4 resurser kostar 1 resurs mindre.',
    imageAsset: 'assets/images/cards/city_expansion_building_crane.webp',
  );

  static const library = GameCard(
    id: 'city-expansion-library',
    name: 'Bibliotek',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Stad',
    buildingCost: {ResourceType.lumber: 2, ResourceType.brick: 1, ResourceType.ore: 1},
    victoryPoints: 1,
    effectText: 'När du bygger Biblioteket får du omedelbart välja ett kort från en draghög (turneringsspel: från din egen hög).',
    imageAsset: 'assets/images/cards/city_expansion_library.webp',
  );

  static const parliament = GameCard(
    id: 'city-expansion-parliament',
    name: 'Parlament',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Stad, 2 framstegspoäng',
    buildingCost: {ResourceType.lumber: 3, ResourceType.brick: 2, ResourceType.wool: 2},
    victoryPoints: 2,
    effectText: 'Till folkets fromma, och särskilt deras företrädares.',
    imageAsset: 'assets/images/cards/city_expansion_parliament.webp',
  );

  static const pharmacy = GameCard(
    id: 'city-expansion-pharmacy',
    name: 'Apotek',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Stad',
    buildingCost: {ResourceType.wool: 2, ResourceType.brick: 1, ResourceType.gold: 1},
    victoryPoints: 1,
    effectText:
        'När händelsen Pest inträffar får du 1 valfri resurs. Du får '
        'den oavsett om du tidigare förlorat resurser eller inte.',
    imageAsset: 'assets/images/cards/city_expansion_pharmacy.webp',
  );

  static const townHall = GameCard(
    id: 'city-expansion-town-hall',
    name: 'Rådhus',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Stad, Församlingshus',
    buildingCost: {ResourceType.wool: 2, ResourceType.ore: 2, ResourceType.brick: 1},
    victoryPoints: 1,
    effectText:
        'Placera Rådhuset på ditt Församlingshus. I slutet av din tur '
        'betalar du inte längre för att välja ett kort.',
    imageAsset: 'assets/images/cards/city_expansion_town_hall.webp',
  );

  static const university = GameCard(
    id: 'city-expansion-university',
    name: 'Universitet',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    isUnique: true,
    requirement: 'Stad, samt Kloster eller Bibliotek',
    buildingCost: {ResourceType.lumber: 2, ResourceType.grain: 2, ResourceType.brick: 1},
    progressPoints: 1,
    victoryPoints: 1,
    effectText: 'Här låg tidigare ett värdshus. Nu finns det två stycken alldeles intill.',
    imageAsset: 'assets/images/cards/city_expansion_university.webp',
  );

  // ---------------------------------------------------------------------
  // Händelsekort
  // ---------------------------------------------------------------------

  static const plague = GameCard(
    id: 'event-plague',
    name: 'Pest',
    category: CardCategory.event,
    expansionSet: ExpansionSet.eraOfProgress,
    effectText: 'Varje region som gränsar till en stad förlorar 1 resurs.',
    imageAsset: 'assets/images/cards/event_plague.webp',
  );

  /// Samtliga korttyper som är nya för det här setet (dvs. exklusive de
  /// återanvända Brigitta, Omlokalisering och Uppfinning – se filens
  /// doc-kommentar).
  static List<GameCard> get all => [
        benjaminTheTravelingScholar, doctor, guidoTheAmbassador, gustavTheLibrarian,
        mineralMining, threeFieldSystem,
        chiefCannoneer,
        bathHouse, buildingCrane, library, parliament, pharmacy, townHall, university,
        plague,
      ];

  /// Antal fysiska kopior per korttyp i det här setets 31-korsslek.
  static const Map<String, int> supplyCounts = {
    'action-benjamin': 1,
    'action-doctor': 2,
    'action-guido': 1,
    'action-gustav': 1,
    'action-mineral-mining': 2,
    'action-three-field-system': 2,
    'action-brigitta': 1, // återanvänd från BasicSetCards
    'action-relocation': 1, // återanvänd från BasicSetCards
    'unit-chief-cannoneer': 2,
    'city-expansion-bath-house': 3,
    'city-expansion-building-crane': 1,
    'city-expansion-library': 2,
    'city-expansion-parliament': 1,
    'city-expansion-pharmacy': 2,
    'city-expansion-town-hall': 2,
    'city-expansion-university': 2,
    'event-plague': 3,
    'event-invention': 2, // återanvänd från BasicSetCards
  };
}
