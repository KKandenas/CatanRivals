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
        'You once more receive the resource of each region whose number you rolled at the '
        'beginning of your turn.',
    imageAsset: 'assets/images/cards/action_benjamin.png',
  );

  static const doctor = GameCard(
    id: 'action-doctor',
    name: 'Doktorn',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Bath House',
    effectText:
        'Each region bordering your Bath House receives 1 resource. If you have various Bath '
        'Houses, you may only use 1 of them.',
    imageAsset: 'assets/images/cards/action_doctor.png',
  );

  static const guidoTheAmbassador = GameCard(
    id: 'action-guido',
    name: 'Guido ambassadören',
    category: CardCategory.action,
    actionKind: ActionKind.attack,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Town Hall, or fewer victory points than your opponent',
    effectText: "You may choose 1 card from the discard pile (Tournament: from your opponent's discard pile).",
    imageAsset: 'assets/images/cards/action_guido.png',
  );

  static const gustavTheLibrarian = GameCard(
    id: 'action-gustav',
    name: 'Gustav bibliotekarien',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Library, or fewer victory points than your opponent',
    effectText: 'You may choose 1 card from the discard pile (Tournament: from your own discard pile).',
    imageAsset: 'assets/images/cards/action_gustav.png',
  );

  static const mineralMining = GameCard(
    id: 'action-mineral-mining',
    name: 'Malmbrytning',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'University',
    effectText: 'You receive up to 2 ore.',
    imageAsset: 'assets/images/cards/action_mineral_mining.png',
  );

  static const threeFieldSystem = GameCard(
    id: 'action-three-field-system',
    name: 'Trevångsbruk',
    category: CardCategory.action,
    actionKind: ActionKind.neutral,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'University',
    effectText: 'You receive up to 2 grain.',
    imageAsset: 'assets/images/cards/action_three_field_system.png',
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
    requirement: 'University',
    buildingCost: {ResourceType.lumber: 1, ResourceType.ore: 1},
    strengthPoints: 4,
    effectText:
        "I'll show you how to produce a romantic castle ruin. Is a unit but not a hero – you "
        'may place 2 Chief Cannoneers in your principality. Cards referring to heroes do not '
        'apply to it; cards referring to units do.',
    imageAsset: 'assets/images/cards/unit_chief_cannoneer.png',
  );

  // ---------------------------------------------------------------------
  // Stadsutbyggnader (röd textruta, kräver befintlig stad)
  // ---------------------------------------------------------------------

  static const bathHouse = GameCard(
    id: 'city-expansion-bath-house',
    name: 'Badhus',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    buildingCost: {ResourceType.brick: 1, ResourceType.wool: 1, ResourceType.ore: 1},
    effectText: 'Protects all 4 regions bordering this city from the effects of the event Plague.',
    imageAsset: 'assets/images/cards/city_expansion_bath_house.png',
  );

  static const buildingCrane = GameCard(
    id: 'city-expansion-building-crane',
    name: 'Byggkran',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'University',
    buildingCost: {ResourceType.lumber: 1},
    effectText: 'Every city expansion you build that costs more than 4 resources costs you 1 resource less.',
    imageAsset: 'assets/images/cards/city_expansion_building_crane.png',
  );

  static const library = GameCard(
    id: 'city-expansion-library',
    name: 'Bibliotek',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    buildingCost: {ResourceType.lumber: 1, ResourceType.grain: 2},
    progressPoints: 1,
    effectText: 'When you build the Library, you may immediately choose a card from a draw stack (Tournament: from your own stack).',
    imageAsset: 'assets/images/cards/city_expansion_library.png',
  );

  static const parliament = GameCard(
    id: 'city-expansion-parliament',
    name: 'Parlament',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: '2 progress points',
    buildingCost: {ResourceType.lumber: 1, ResourceType.brick: 1, ResourceType.wool: 1},
    effectText: 'For the benefit of the people and their representatives in particular.',
    imageAsset: 'assets/images/cards/city_expansion_parliament.png',
  );

  static const pharmacy = GameCard(
    id: 'city-expansion-pharmacy',
    name: 'Apotek',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    buildingCost: {ResourceType.wool: 1, ResourceType.gold: 1},
    effectText:
        'When the event Plague occurs, you receive any 1 resource of your choice. You receive '
        'this resource whether you previously lost resources or not.',
    imageAsset: 'assets/images/cards/city_expansion_pharmacy.png',
  );

  static const townHall = GameCard(
    id: 'city-expansion-town-hall',
    name: 'Rådhus',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    requirement: 'Parish Hall',
    buildingCost: {ResourceType.wool: 1, ResourceType.ore: 1, ResourceType.brick: 1},
    effectText:
        'Place the Town Hall on your Parish Hall. At the end of your turn, you no longer pay '
        'for choosing a card.',
    imageAsset: 'assets/images/cards/city_expansion_town_hall.png',
  );

  static const university = GameCard(
    id: 'city-expansion-university',
    name: 'Universitet',
    category: CardCategory.cityExpansion,
    expansionSet: ExpansionSet.eraOfProgress,
    isUnique: true,
    requirement: 'Abbey or Library',
    buildingCost: {ResourceType.lumber: 1, ResourceType.grain: 1, ResourceType.wool: 1},
    progressPoints: 1,
    effectText: 'Formerly, there was a hedge-tavern here. Now there are two of them next door.',
    imageAsset: 'assets/images/cards/city_expansion_university.png',
  );

  // ---------------------------------------------------------------------
  // Händelsekort
  // ---------------------------------------------------------------------

  static const plague = GameCard(
    id: 'event-plague',
    name: 'Pest',
    category: CardCategory.event,
    expansionSet: ExpansionSet.eraOfProgress,
    effectText: 'Every region bordering a city loses 1 resource.',
    imageAsset: 'assets/images/cards/event_plague.png',
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
