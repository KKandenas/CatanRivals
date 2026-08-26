import '../data/basic_set_cards.dart';
import '../data/era_of_gold_cards.dart';
import '../data/era_of_progress_cards.dart';
import '../models/models.dart';

/// Returnerar en förklarande text om [card] inte får byggas/placeras på
/// (column, row) i [board] just nu – annars `null`. Ren funktion, inga
/// sidoeffekter, kollas på TVÅ ställen: i UI:t innan "Bekräfta bygge"
/// visas (se [PrincipalityGrid]/[BuildConfirmCard], ersätter kostnad+
/// "Betalt" med bara den här texten och en "Stäng"-knapp) och som ett
/// sista skydd i [GameNotifier.dropExpansion]/[dropRegionExpansion] –
/// samma dubbelkontroll-princip som redan gäller för `isUnique`-kollen
/// där.
///
/// [row]/[column] tolkas olika beroende på [card]s kategori: för
/// [CardCategory.cityExpansion]/[CardCategory.expansion] är det en
/// by/stads kolumn (se [RealmBoard.settlementAt]); för
/// [CardCategory.regionExpansion] är det en regions knutpunkt (se
/// [RealmBoard.regionAt]) – anroparen vet redan vilket eftersom den
/// bara kallar den här funktionen från rätt drop-mål.
///
/// [slotIndex] pekar ut VILKEN byggplats (0 eller 1, se
/// [RealmBoard.placeExpansion]) inom kolumnen – bara relevant för
/// Rådhus (se nedan), som måste läggas på exakt den plats där
/// Församlingshus redan ligger, inte bara någonstans i riket. Standard
/// 0 för anrop där platsen ändå aldrig kan gälla Rådhus (t.ex.
/// landskapsutbyggnader, som saknar slotIndex helt).
String? buildRequirementBlockedReason(
    GameCard card, RealmBoard board, int column, BuildingRow row,
    [int slotIndex = 0]) {
  if (card.category == CardCategory.cityExpansion) {
    final node = board.settlementAt(column);
    if (node == null || !node.isCity) {
      return '${card.name} kräver en stad, inte bara en by.';
    }
  }
  if (card.baseId == EraOfGoldCards.goldCache.id) {
    final hasHero = board.placedExpansionCards.any(
        (c) => c.expansionKind == ExpansionKind.hero && c.strengthPoints > 0);
    if (!hasHero) {
      return 'Guldgömma kräver att du spelat ut en hjälte med minst 1 styrkepoäng.';
    }
  }
  if (card.baseId == EraOfGoldCards.stapleHouse.id) {
    if (!board.hasExpansionCard(EraOfGoldCards.merchantGuild.id)) {
      return 'Stapelhus kräver Köpmansgille i ditt rike.';
    }
  }
  if (card.baseId == EraOfProgressCards.university.id) {
    if (!board.hasExpansionCard(BasicSetCards.abbey.id) &&
        !board.hasExpansionCard(EraOfProgressCards.library.id)) {
      return 'Universitet kräver Kloster eller Bibliotek i ditt rike.';
    }
  }
  if (card.baseId == EraOfProgressCards.chiefCannoneer.id ||
      card.baseId == EraOfProgressCards.buildingCrane.id) {
    if (!board.hasExpansionCard(EraOfProgressCards.university.id)) {
      return '${card.name} kräver Universitet i ditt rike.';
    }
  }
  if (card.baseId == EraOfProgressCards.parliament.id) {
    if (board.totalProgressPoints < 2) {
      return 'Parlament kräver minst 2 framstegspoäng i ditt rike.';
    }
  }
  if (card.baseId == EraOfProgressCards.townHall.id) {
    // Regelhäftet/korttexten: "Placera Rådhuset på ditt Församlingshus" –
    // inte bara "någonstans i ett rike som råkar ha ett Församlingshus".
    // Utan slotIndex-kontrollen gick Rådhus tidigare att bygga på en tom
    // plats, eller byta ut en helt annan byggnad, så länge Församlingshus
    // fanns kvar NÅGONSTANS i riket (rapporterad bugg).
    final onExistingSite = board.expansionAt(column, row, slotIndex);
    if (onExistingSite?.card.baseId != BasicSetCards.parishHall.id) {
      return 'Rådhus måste läggas ovanpå ditt Församlingshus.';
    }
  }
  return null;
}
