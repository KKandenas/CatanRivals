import 'event_die_face.dart';

/// Vems tur det är och hur långt omgången kommit (regelhäftet s. 7:
/// 1) slå tärningarna, 2) utför åtgärder, 3) kontrollera handkort,
/// 4) byt ut kort). Produktions- och händelsetärningen slås samtidigt
/// (se [EventDieFace]) – stegen efter tärningsslaget är senare steg.
class TurnState {
  final String activePlayerId;
  final bool diceRolled;
  final int? productionRoll;
  final EventDieFace? eventDieFace;

  const TurnState({
    required this.activePlayerId,
    this.diceRolled = false,
    this.productionRoll,
    this.eventDieFace,
  });

  Map<String, dynamic> toJson() => {
        'activePlayerId': activePlayerId,
        'diceRolled': diceRolled,
        if (productionRoll != null) 'productionRoll': productionRoll,
        if (eventDieFace != null) 'eventDieFace': eventDieFace!.name,
      };

  factory TurnState.fromJson(Map<String, dynamic> json) => TurnState(
        activePlayerId: json['activePlayerId'] as String,
        diceRolled: json['diceRolled'] as bool? ?? false,
        productionRoll: json['productionRoll'] as int?,
        eventDieFace: (json['eventDieFace'] as String?) == null
            ? null
            : EventDieFace.values.byName(json['eventDieFace'] as String),
      );
}
