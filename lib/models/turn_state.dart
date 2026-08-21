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

  const TurnState({
    required this.activePlayerId,
    this.diceRolled = false,
    this.productionRoll,
    this.eventDieFace,
    this.drawnEventCard,
  });

  Map<String, dynamic> toJson() => {
        'activePlayerId': activePlayerId,
        'diceRolled': diceRolled,
        if (productionRoll != null) 'productionRoll': productionRoll,
        if (eventDieFace != null) 'eventDieFace': eventDieFace!.name,
        if (drawnEventCard != null) 'drawnEventCard': drawnEventCard!.toJson(),
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
      );
}
