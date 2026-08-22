import 'event_die_face.dart';
import 'game_card.dart';

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

  const TurnState({
    required this.activePlayerId,
    this.diceRolled = false,
    this.productionRoll,
    this.eventDieFace,
    this.drawnEventCard,
    this.peekingStackIndex,
    this.winnerId,
  });

  Map<String, dynamic> toJson() => {
        'activePlayerId': activePlayerId,
        'diceRolled': diceRolled,
        if (productionRoll != null) 'productionRoll': productionRoll,
        if (eventDieFace != null) 'eventDieFace': eventDieFace!.name,
        if (drawnEventCard != null) 'drawnEventCard': drawnEventCard!.toJson(),
        if (peekingStackIndex != null) 'peekingStackIndex': peekingStackIndex,
        if (winnerId != null) 'winnerId': winnerId,
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
      );
}
