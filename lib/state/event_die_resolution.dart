import '../data/basic_set_cards.dart';
import '../data/era_of_gold_cards.dart';
import '../data/era_of_progress_cards.dart';
import '../models/models.dart';
import 'game_state.dart';

/// Räknar ut den FAKTISKA utfallet av händelsetärningens icke-
/// händelsekorts-sidor (se [EventDieFace]) för den aktuella
/// spelställningen, som en färdig svensk mening att visa bredvid den
/// generella regeltexten (se DiceRollSummaryBanner) – regelhäftet ger
/// bara regeln i ord, den här funktionen räknar ut VEM/VAD den
/// faktiskt gäller för just den här omgången. Fortfarande bara TEXT:
/// precis som byggkostnader visas men inte dras av automatiskt,
/// flyttar appen inga resurser – spelarna gör det själva med +/-.
///
/// `null` betyder att det inte finns någon extra uträkning att visa
/// utöver den generella regeltexten – gäller alltid
/// [EventDieFace.eventCard] (hanteras helt separat, se
/// GameNotifier.drawEventCard/EventCardRevealCard) och ibland
/// [EventDieFace.plentifulHarvest] (bara om ingen spelare har Tullbro).
String? resolveEventDieFace(EventDieFace face, GameState state) {
  switch (face) {
    case EventDieFace.brigandAttack:
      return _resolveBrigandAttack(state);
    case EventDieFace.trade:
      return _resolveTrade(state);
    case EventDieFace.celebration:
      return _resolveCelebration(state);
    case EventDieFace.plentifulHarvest:
      return _resolvePlentifulHarvest(state);
    case EventDieFace.eventCard:
      return null;
  }
}

/// Alla resurser en spelare har lagrade, UTOM de som ligger på en
/// region som gränsar till ett av spelarens Lagerhus (regelhäftet,
/// Lagerhusets egen regeltext: "Do not count the resources on the 2
/// neighboring regions when the event Brigand Attack is rolled).
/// Räknar bara [RealmBoard.regionsAbove]/[regionsBelow] (via
/// [RealmBoard.resourceTotalExcluding]) – guld lagrat i en Guldgömma
/// ligger i en helt separat karta ([RealmBoard.regionExpansionsAbove]/
/// [regionExpansionsBelow]) och är därför redan, per konstruktion,
/// automatiskt undantaget här (regelhäftet, Guldgömmans egen
/// regeltext: "det kan inte stjälas") – INGEN extra avdrag behövs
/// (och skulle dra bort det två gånger om det gjordes här).
int _effectiveResourceTotal(Player player) {
  final board = player.principality;
  final excluded = <(int, BuildingRow)>{};
  for (final loc in board.expansionLocations(BasicSetCards.storehouse.id)) {
    excluded.add((loc.column - 1, loc.row));
    excluded.add((loc.column + 1, loc.row));
  }
  var total = 0;
  for (final type in ResourceType.values) {
    if (type == ResourceType.none) continue;
    total += board.resourceTotalExcluding(type, excluded);
  }
  return total;
}

/// Texten för en drabbad spelare (se [_resolveBrigandAttack]) – nämner
/// Guldgömman uttryckligen när den håller guld, så att det inte ser ut
/// som ett missat fall när spelarens guld inte minskar lika mycket som
/// väntat (se regelhäftets Guldgömma-text: "det kan inte stjälas").
String _brigandAffectedLine(Player player, int total) {
  final protectedGold =
      player.principality.regionExpansionResourceTotal(ResourceType.gold);
  final protectedNote = protectedGold > 0
      ? ' (guldet i Guldgömman är skyddat och räknas inte bort)'
      : '';
  return '${player.name} har $total resurser och blir av med allt guld och ull$protectedNote.';
}

String _resolveBrigandAttack(GameState state) {
  final youTotal = _effectiveResourceTotal(state.you);
  final oppTotal = _effectiveResourceTotal(state.opponent);
  final youAffected = youTotal > 7;
  final oppAffected = oppTotal > 7;

  if (!youAffected && !oppAffected) {
    return 'Ingen spelare har fler än 7 resurser (Lagerhus/Guldgömma oräknat). Inget händer.';
  }

  final lines = <String>[];
  if (youAffected) lines.add(_brigandAffectedLine(state.you, youTotal));
  if (oppAffected) lines.add(_brigandAffectedLine(state.opponent, oppTotal));
  return lines.join('\n');
}

/// Jämför spelarnas handelspoäng direkt (precis som [_resolveCelebration]
/// gör för kunskapspoäng) – INTE samma sak som [GameState.tradeTokenHolder]
/// (Handelsbrickan, som kräver minst 3 poäng OCH mer än motståndaren för
/// att vara "sticky" och även ge en extra segerpoäng). Handel-sidan på
/// tärningen gäller bara den här enskilda omgången: den med flest
/// handelspoäng just nu vinner, även under 3 poäng – bekräftat mot det
/// fysiska spelet (spelartest: den gamla, brick-baserade varianten
/// missade att ge utslag så fort ingen hunnit nå tröskeln på 3).
String _resolveTrade(GameState state) {
  final youCommerce = state.you.principality.totalCommercePoints;
  final oppCommerce = state.opponent.principality.totalCommercePoints;
  if (youCommerce == oppCommerce) {
    return 'Ingen spelare har flest handelspoäng just nu. Inget händer.';
  }
  final winner = youCommerce > oppCommerce ? state.you : state.opponent;
  final other = youCommerce > oppCommerce ? state.opponent : state.you;
  // Ockrare: "Vid handelsövertag: den spelare som har handelsövertaget
  // får ta 2 (i stället för 1) valfria resurser från motståndaren."
  final hasMoneylender =
      winner.principality.hasExpansionCard(EraOfGoldCards.moneylender.id);
  if (hasMoneylender) {
    return '${winner.name} har flest handelspoäng och Ockrare, och får 2 valfria resurser från ${other.name}.';
  }
  return '${winner.name} har flest handelspoäng och får 1 valfri resurs från ${other.name}.';
}

String _resolveCelebration(GameState state) {
  final youSkill = state.you.principality.totalSkillPoints;
  final oppSkill = state.opponent.principality.totalSkillPoints;
  final lines = <String>[];
  if (youSkill == oppSkill) {
    lines.add(
        'Båda spelarna har lika många kunskapspoäng. Båda spelarna får 1 valfri resurs var.');
  } else {
    final winnerName =
        youSkill > oppSkill ? state.you.name : state.opponent.name;
    lines.add('$winnerName har flest kunskapspoäng och får 1 valfri resurs.');
  }
  // Reiner härolden tvingar fram Fest-utfallet i stället för att slå
  // händelsetärningen (se [TurnState.reinerHeraldUsed]) – spelaren som
  // spelade kortet är alltid den aktiva spelaren (GameNotifier.
  // useReinerTheHerald kräver att det är dennes tur).
  if (state.reinerHeraldUsed) {
    final player = state.activePlayerIsMe ? state.you : state.opponent;
    lines.add(
        '${player.name} spelade Reiner härolden och får en extra resurs.');
  }
  return lines.join('\n');
}

String? _resolvePlentifulHarvest(GameState state) {
  final lines = <String>[];
  for (final player in [state.you, state.opponent]) {
    final hasTollBridge = player.principality
        .expansionLocations(BasicSetCards.tollBridge.id)
        .isNotEmpty;
    // Bara 1 fysisk Tullbro finns i hela spelet (supplyCounts), så den
    // kan aldrig ligga hos båda spelarna samtidigt.
    if (hasTollBridge) {
      lines.add('${player.name} har lagt ut Tullbro och får dessutom 2 guld.');
    }
    // Piratskepp: "Riklig skörd: Du får 1 guld." – till skillnad från
    // Tullbro finns flera fysiska Piratskepp (se supplyCounts), så
    // båda spelarna kan i teorin ha lagt ut varsitt.
    final hasPirateShip = player.principality
        .expansionLocations(EraOfGoldCards.pirateShip.id)
        .isNotEmpty;
    if (hasPirateShip) {
      lines.add('${player.name} har lagt Piratskepp och får 1 guld.');
    }
  }
  if (lines.isEmpty) return null;
  return lines.join('\n');
}

/// Räknar ut den FAKTISKA uträkningen av ett draget händelsekorts effekt
/// (se [EventDieFace.eventCard]/[GameNotifier.drawEventCard]) – samma
/// princip som [resolveEventDieFace], bara TEXT (appen flyttar inga
/// resurser åt spelarna). `null` för kort utan någon egen uträkning att
/// visa (t.ex. Fejd/Brödrafejd, som redan har egna väljarflöden, eller
/// ett kort utan träff för någon spelare).
String? resolveEventCard(GameCard card, GameState state) {
  switch (card.baseId) {
    case 'event-invention':
      return _resolveInvention(state);
    case 'event-trade-ships-race':
      return _resolveTradeShipsRace(state);
    case 'event-year-of-plenty':
      return _resolveYearOfPlenty(state);
    case 'event-gift-for-the-prince':
      return _resolveGiftForThePrince(state);
    case 'event-plague':
      return _resolvePlague(state);
    default:
      return null;
  }
}

/// Pest (Utvecklingens tid): "Varje region som gränsar till en stad
/// förlorar 1 resurs" – ren text, precis som övriga händelsekort ovan
/// (appen flyttar inga resurser). Nämner Badhus (skyddar sin egen stads
/// 4 grannregioner helt från förlusten) och Apotek (ger 1 valfri resurs
/// ändå, oavsett om spelaren förlorat något eller inte) bara för den
/// spelare som faktiskt har kortet.
String? _resolvePlague(GameState state) {
  final lines = <String>[];
  for (final player in [state.you, state.opponent]) {
    final board = player.principality;
    if (board.hasExpansionCard(EraOfProgressCards.bathHouse.id)) {
      lines.add(
          '${player.name}s Badhus skyddar sin stads 4 grannregioner mot Pesten.');
    }
    if (board.hasExpansionCard(EraOfProgressCards.pharmacy.id)) {
      lines.add('${player.name} har Apotek och får 1 valfri resurs ändå.');
    }
  }
  if (lines.isEmpty) return null;
  return lines.join('\n');
}

/// Uppfinning: "Varje spelare får 1 valfri resurs för varje byggnad med
/// en framstegspoäng – upp till max 2 resurser."
String? _resolveInvention(GameState state) {
  final lines = <String>[];
  for (final player in [state.you, state.opponent]) {
    final buildingsWithProgress = player.principality.placedExpansionCards
        .where((c) =>
            c.expansionKind == ExpansionKind.building && c.progressPoints > 0)
        .length;
    if (buildingsWithProgress == 0) continue;
    final awarded = buildingsWithProgress > 2 ? 2 : buildingsWithProgress;
    final buildingWord = buildingsWithProgress == 1 ? 'byggnad' : 'byggnader';
    final resourceWord = awarded == 1 ? 'valfri resurs' : 'valfria resurser';
    lines.add(
        '${player.name} har $buildingsWithProgress $buildingWord med framstegspoäng och får ta $awarded $resourceWord.');
  }
  if (lines.isEmpty) return null;
  return lines.join('\n');
}

/// Gåva till fursten: "1 guld per enhet med minst 1 styrkepoäng" – ett
/// huvudräkne (antal ENHETER), inte en summering av styrkepoäng, precis
/// som kortets egen text säger. Räknar bygg-/enhetskort generellt (inte
/// bara hjältar), samma mönster som [_resolveInvention]s
/// `buildingsWithProgress`.
String? _resolveGiftForThePrince(GameState state) {
  final lines = <String>[];
  for (final player in [state.you, state.opponent]) {
    final units = player.principality.placedExpansionCards
        .where((c) => c.strengthPoints > 0)
        .length;
    if (units == 0) continue;
    final unitWord = units == 1 ? 'enhet' : 'enheter';
    lines.add(
        '${player.name} har $units $unitWord med styrkepoäng och får $units guld.');
  }
  if (lines.isEmpty) return null;
  return lines.join('\n');
}

/// Handelsskeppskapplöpning: "Spelaren som äger flest handelsskepp får
/// 1 valfri resurs. Vid lika antal får båda spelarna 1 valfri resurs
/// var (båda måste ha minst 1 handelsskepp)."
String _resolveTradeShipsRace(GameState state) {
  int shipCount(Player player) => player.principality.placedExpansionCards
      .where((c) => c.expansionKind == ExpansionKind.tradeShip)
      .length;

  final youShips = shipCount(state.you);
  final oppShips = shipCount(state.opponent);

  if (youShips == 0 && oppShips == 0) {
    return 'Ingen spelare har något handelsskepp. Inget händer.';
  }
  if (youShips == oppShips) {
    return 'Båda spelarna har lika många handelsskepp ($youShips var) och får 1 valfri resurs var.';
  }
  final winnerName =
      youShips > oppShips ? state.you.name : state.opponent.name;
  final winnerShips = youShips > oppShips ? youShips : oppShips;
  return '$winnerName har flest handelsskepp ($winnerShips) och får 1 valfri resurs.';
}

/// Antal Lagerhus/Kloster som gränsar till regionen på [regionColumn]/
/// [row] – de sitter i samma rad, på byggplatserna hos de två
/// grannbyarna/-städerna (`regionColumn - 1`/`+ 1`), se
/// [RealmBoard.expansionLocations] för motsvarande uträkning åt andra
/// hållet (byggnadens grannregioner).
int _neighboringStorehouseOrAbbeyCount(
    RealmBoard board, int regionColumn, BuildingRow row) {
  bool isStorehouseOrAbbey(PlacedCard? site) =>
      site != null &&
      (site.card.baseId == BasicSetCards.storehouse.id ||
          site.card.baseId == BasicSetCards.abbey.id);

  int countAt(int settlementColumn) {
    final node = board.settlementAt(settlementColumn);
    if (node == null) return 0;
    final sites = row == BuildingRow.above ? node.aboveSites : node.belowSites;
    return sites.where(isStorehouseOrAbbey).length;
  }

  return countAt(regionColumn - 1) + countAt(regionColumn + 1);
}

/// Skriver ihop en lista på svenska: "skog", "skog och guldfält", eller
/// "skog, guldfält och åker".
String _swedishJoin(List<String> items) {
  if (items.length == 1) return items.single;
  return '${items.sublist(0, items.length - 1).join(', ')} och ${items.last}';
}

String? _resolveYearOfPlentyForPlayer(Player player) {
  final board = player.principality;
  final qualifyingRegionNames = <String>[];
  void checkRegions(Map<int, PlacedCard> regions, BuildingRow row) {
    for (final entry in regions.entries) {
      if (_neighboringStorehouseOrAbbeyCount(board, entry.key, row) == 0) {
        continue;
      }
      final name = entry.value.card.name.toLowerCase();
      if (!qualifyingRegionNames.contains(name)) {
        qualifyingRegionNames.add(name);
      }
    }
  }

  checkRegions(board.regionsAbove, BuildingRow.above);
  checkRegions(board.regionsBelow, BuildingRow.below);
  if (qualifyingRegionNames.isEmpty) return null;

  return '${player.name} har ${_swedishJoin(qualifyingRegionNames)} '
      'angränsande till Lagerhus/Kloster och får 1 resurs per region '
      '(om det finns plats).';
}

/// Goda året: "Varje region får 1 resurs för varje angränsande Lagerhus
/// och Kloster, förutsatt att det finns lagringsutrymme kvar."
String? _resolveYearOfPlenty(GameState state) {
  final lines = [state.you, state.opponent]
      .map(_resolveYearOfPlentyForPlayer)
      .whereType<String>()
      .toList();
  if (lines.isEmpty) return null;
  return lines.join('\n');
}

/// Antal av [player]s egna enheter med styrke- ELLER handelspoäng
/// (byggnad, skepp eller hjälte – region-/regionutbyggnadskort som
/// Guldgömma har alltid 0 av båda, så de räknas aldrig med här) – se
/// Oroligheternas tids Upplopp (EraOfTurmoilCards.riots): avgör hur
/// mycket guld spelaren ska betala ([riotsGoldOwed]), eller om Upplopp
/// inte berör hen alls (0 enheter). Handlingskortet Riots hanteras helt
/// separat (se [RiotsResolutionCard]/[GameNotifier.resolveRiotsPay]) –
/// inte via [resolveEventCard] som övriga händelsekort, eftersom det
/// kräver ett riktigt val (betala eller välj bort ett kort), inte bara
/// en informationsrad.
int riotsQualifyingUnitCount(Player player) => player.principality
    .placedExpansionCards
    .where((c) => c.strengthPoints > 0 || c.commercePoints > 0)
    .length;

/// Hur mycket guld Upplopp kräver för [unitCount] kvalificerande
/// enheter (se [riotsQualifyingUnitCount]) – regelhäftet: 1 guld vid
/// 1–2 enheter, 2 guld vid fler, 0 om spelaren inte har någon alls.
int riotsGoldOwed(int unitCount) {
  if (unitCount == 0) return 0;
  return unitCount <= 2 ? 1 : 2;
}
