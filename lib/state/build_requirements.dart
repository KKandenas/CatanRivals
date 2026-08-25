import '../data/era_of_gold_cards.dart';
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
String? buildRequirementBlockedReason(
    GameCard card, RealmBoard board, int column, BuildingRow row) {
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
  return null;
}
