import '../data/basic_set_cards.dart';
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
/// neighboring regions when the event Brigand Attack is rolled").
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

String _resolveBrigandAttack(GameState state) {
  final youTotal = _effectiveResourceTotal(state.you);
  final oppTotal = _effectiveResourceTotal(state.opponent);
  final youAffected = youTotal > 7;
  final oppAffected = oppTotal > 7;

  if (!youAffected && !oppAffected) {
    return 'Ingen spelare har fler än 7 resurser (Lagerhus oräknat). Inget händer.';
  }

  final lines = <String>[];
  if (youAffected) {
    lines.add(
        '${state.you.name} har $youTotal resurser och blir av med allt guld och ull.');
  }
  if (oppAffected) {
    lines.add(
        '${state.opponent.name} har $oppTotal resurser och blir av med allt guld och ull.');
  }
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
  final winnerName =
      youCommerce > oppCommerce ? state.you.name : state.opponent.name;
  final otherName =
      youCommerce > oppCommerce ? state.opponent.name : state.you.name;
  return '$winnerName har flest handelspoäng och får 1 valfri resurs från $otherName.';
}

String _resolveCelebration(GameState state) {
  final youSkill = state.you.principality.totalSkillPoints;
  final oppSkill = state.opponent.principality.totalSkillPoints;
  if (youSkill == oppSkill) {
    return 'Båda spelarna har lika många kunskapspoäng. Båda spelarna får 1 valfri resurs var.';
  }
  final winnerName =
      youSkill > oppSkill ? state.you.name : state.opponent.name;
  return '$winnerName har flest kunskapspoäng och får 1 valfri resurs.';
}

String? _resolvePlentifulHarvest(GameState state) {
  for (final player in [state.you, state.opponent]) {
    final hasTollBridge = player.principality
        .expansionLocations(BasicSetCards.tollBridge.id)
        .isNotEmpty;
    // Bara 1 fysisk Tullbro finns i hela spelet (supplyCounts), så den
    // kan aldrig ligga hos båda spelarna samtidigt.
    if (hasTollBridge) {
      return '${player.name} har lagt ut Tullbro och får dessutom 2 guld.';
    }
  }
  return null;
}
