import 'event_die_face.dart';
import 'game_card.dart';
import 'realm_board.dart';

/// Vems tur det är och hur långt omgången kommit (regelhäftet s. 7:
/// 1) slå tärningarna, 2) utför åtgärder, 3) kontrollera handkort,
/// 4) byt ut kort). Produktions- och händelsetärningen slås samtidigt
/// (se [EventDieFace]) – stegen efter tärningsslaget är senare steg.
class TurnState {
  final String activePlayerId;
  final bool diceRolled;
  final int? productionRoll;
  final EventDieFace? eventDieFace;

  /// Händelsekortet draget när [eventDieFace] visade "?" (regelhäftet:
  /// "reads the event aloud"), synkat så båda spelarna ser samma kort –
  /// se [GameNotifier.drawEventCard].
  final GameCard? drawnEventCard;

  /// Vilken draghög (0–3) den aktiva spelaren just nu kikar i under
  /// kortbytesfasens kika-alternativ (regelhäftet s. 9) – se
  /// [GameNotifier.choosePeekStack]. Bara index, aldrig vilka kort som
  /// faktiskt ligger där (det förblir hemligt) – precis som att man vid
  /// ett fysiskt bord ser motståndaren plocka upp och läsa en specifik
  /// hög, utan att se innehållet själv. `null` när ingen kikar just nu.
  final int? peekingStackIndex;

  /// Id på spelaren som vunnit (regelhäftet: 7 eller fler segerpoäng
  /// vid slutet av sin egen runda), satt i
  /// [GameNotifier._advanceToNextPlayer] – `null` så länge ingen vunnit.
  /// När satt lämnas turen INTE över (spelet fryser i vinnarens
  /// slutställning) – se [GameOverOverlay] i game_board_screen.dart.
  final String? winnerId;

  /// Om den ICKE aktiva spelaren måste välja bort ett eget handelsskepp
  /// (Piratskepp, regelhäftet: "Your opponent must remove 1 trade ship
  /// of his choice"), se [GameNotifier.resolvePirateShipDiscard]. Till
  /// skillnad från t.ex. Fejd (som härleds lokalt ur redan synkad data,
  /// se GameNotifier-docen) triggas det här av ett ENGÅNGS-BYGGE – det
  /// finns inget jämförbart tillstånd motståndarens klient kan räkna ut
  /// på egen hand, så en riktig synkad signal behövs.
  final bool pirateShipDiscardPending;

  /// Om Reiner härolden spelades för att framtvinga den här omgångens
  /// Fest-utfall (regelhäftet: kortets egen effekt sätter
  /// händelsetärningen till Fest), se [GameNotifier.useReinerTheHerald].
  /// Läses av [resolveEventDieFace]/`_resolveCelebration` för att lägga
  /// till en extra rad i popupen om vem som spelade kortet – annars
  /// finns inget sätt att skilja ett Reiner-framtvingat Fest-utfall från
  /// ett vanligt tärningsslag. Nollställs varje ny omgång (se
  /// [GameNotifier._advanceToNextPlayer]), precis som
  /// [pirateShipDiscardPending].
  final bool reinerHeraldUsed;

  /// Vilka spelar-id:n som redan avslutat sin egen Upplopp-hantering
  /// (betalat eller valt bort en enhet, se
  /// [GameNotifier.resolveRiotsPay]/[resolveRiotsUnitRemoval]) för det
  /// just nu uppslagna händelsekortet. Till skillnad från Fejd/
  /// Brödrafejd (bara EN sida agerar, se `strengthAdvantagePlayerId`)
  /// kan BÅDA spelarna behöva agera oberoende av varandra – var och en
  /// utifrån sin egen enhetsräkning. Kortet stängs (drawnEventCard
  /// rensas) först när båda id:na finns här, se
  /// [GameNotifier._finishRiotsForMe]. Nollställs (tom mängd) varje
  /// gång ett nytt händelsekort dras.
  final Set<String> riotsResolvedPlayerIds;

  /// Vilket attackkort (Bågskytt/Pyroman, Oroligheternas tid) som just
  /// nu väntar på att MOTSTÅNDAREN (den drabbade) ska välja bort en
  /// egen kvalificerande enhet och lägga den underst i en draghög – se
  /// [GameNotifier._maybeTriggerAttackCard]/[selectAttackCardUnit].
  /// Samma "riktig synkad signal krävs" resonemang som
  /// [pirateShipDiscardPending] (den drabbade är inte den aktiva
  /// spelaren), men med ett extra steg (vilken draghög), se
  /// [attackCardPickedUnit] i [GameState]. `null` när inget väntar.
  final AttackCardKind? pendingAttackCard;

  /// Vilka spelar-id:n som spelat Sebastian, den vandrande predikanten
  /// för att skydda sig mot det just nu uppslagna händelsekortet
  /// (Upplopp/Fejd/Brödrafejd, se
  /// [GameNotifier.playSebastianForCurrentEvent]) – kortets egen text:
  /// "gäller inte dessa händelser dig". Nollställs (tom mängd) varje
  /// gång ett nytt händelsekort dras, precis som
  /// [riotsResolvedPlayerIds].
  final Set<String> sebastianProtectedPlayerIds;

  /// Vilket attackkort (baseId, Bågskytt/Pyroman/Förrädare) som just nu
  /// väntar på att MOTSTÅNDAREN (som har Vakttorn) ska slå tärningen för
  /// att eventuellt avvärja det, se
  /// [GameNotifier.rollLookoutTowerDefense]/EraOfTurmoilCards.
  /// lookoutTower-doc. Sätts av den AKTIVA spelaren (som spelade kortet)
  /// i stället för att gå direkt till [pendingAttackCard]/[traitorPicking]
  /// – rensas av försvararen efter tärningsslaget, oavsett utfall.
  /// `null` när ingen försvarstärning väntar.
  final String? pendingDefenseRollCard;

  /// Förrädare (regelhäftet: "titta på motståndarens kort ... välj ett
  /// som läggs till den egna handen") – om DU just nu ska välja ett kort
  /// ur motståndarens hand, se [GameNotifier.useTraitor]/
  /// [pickTraitorCard]. Till skillnad från Brödrafejds motsvarande
  /// väljarläge (som aldrig behöver synkas, se [fraternalFeudsPicking] i
  /// [GameState]) måste den här synkas via [TurnState], eftersom
  /// Vakttorn (se [pendingDefenseRollCard]) kan göra att det är
  /// FÖRSVARARENS tärningsslag – inte du själv – som avgör om du
  /// faktiskt får gå vidare hit.
  final bool traitorPicking;

  const TurnState({
    required this.activePlayerId,
    this.diceRolled = false,
    this.productionRoll,
    this.eventDieFace,
    this.drawnEventCard,
    this.peekingStackIndex,
    this.winnerId,
    this.pirateShipDiscardPending = false,
    this.reinerHeraldUsed = false,
    this.riotsResolvedPlayerIds = const {},
    this.pendingAttackCard,
    this.sebastianProtectedPlayerIds = const {},
    this.pendingDefenseRollCard,
    this.traitorPicking = false,
  });

  Map<String, dynamic> toJson() => {
        'activePlayerId': activePlayerId,
        'diceRolled': diceRolled,
        if (productionRoll != null) 'productionRoll': productionRoll,
        if (eventDieFace != null) 'eventDieFace': eventDieFace!.name,
        if (drawnEventCard != null) 'drawnEventCard': drawnEventCard!.toJson(),
        if (peekingStackIndex != null) 'peekingStackIndex': peekingStackIndex,
        if (winnerId != null) 'winnerId': winnerId,
        if (pirateShipDiscardPending) 'pirateShipDiscardPending': true,
        if (reinerHeraldUsed) 'reinerHeraldUsed': true,
        if (riotsResolvedPlayerIds.isNotEmpty)
          'riotsResolvedPlayerIds': riotsResolvedPlayerIds.toList(),
        if (pendingAttackCard != null)
          'pendingAttackCard': pendingAttackCard!.name,
        if (sebastianProtectedPlayerIds.isNotEmpty)
          'sebastianProtectedPlayerIds': sebastianProtectedPlayerIds.toList(),
        if (pendingDefenseRollCard != null)
          'pendingDefenseRollCard': pendingDefenseRollCard,
        if (traitorPicking) 'traitorPicking': true,
      };

  factory TurnState.fromJson(Map<String, dynamic> json) => TurnState(
        activePlayerId: json['activePlayerId'] as String,
        diceRolled: json['diceRolled'] as bool? ?? false,
        productionRoll: json['productionRoll'] as int?,
        eventDieFace: (json['eventDieFace'] as String?) == null
            ? null
            : EventDieFace.values.byName(json['eventDieFace'] as String),
        drawnEventCard: json['drawnEventCard'] == null
            ? null
            : GameCard.fromJson(
                Map<String, dynamic>.from(json['drawnEventCard'] as Map)),
        peekingStackIndex: json['peekingStackIndex'] as int?,
        winnerId: json['winnerId'] as String?,
        pirateShipDiscardPending:
            json['pirateShipDiscardPending'] as bool? ?? false,
        reinerHeraldUsed: json['reinerHeraldUsed'] as bool? ?? false,
        riotsResolvedPlayerIds: json['riotsResolvedPlayerIds'] == null
            ? const {}
            : Set<String>.from(json['riotsResolvedPlayerIds'] as List),
        pendingAttackCard: (json['pendingAttackCard'] as String?) == null
            ? null
            : AttackCardKind.values.byName(json['pendingAttackCard'] as String),
        sebastianProtectedPlayerIds:
            json['sebastianProtectedPlayerIds'] == null
                ? const {}
                : Set<String>.from(
                    json['sebastianProtectedPlayerIds'] as List),
        pendingDefenseRollCard: json['pendingDefenseRollCard'] as String?,
        traitorPicking: json['traitorPicking'] as bool? ?? false,
      );
}
