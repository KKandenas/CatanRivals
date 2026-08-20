/// Vems tur det är och hur långt omgången kommit (regelhäftet s. 7:
/// 1) slå tärningarna, 2) utför åtgärder, 3) kontrollera handkort,
/// 4) byt ut kort). Bara steg 1 (produktionstärningen) är byggt än –
/// händelsetärningen och stegen efter tärningsslaget är senare steg.
class TurnState {
  final String activePlayerId;
  final bool diceRolled;
  final int? productionRoll;

  const TurnState({
    required this.activePlayerId,
    this.diceRolled = false,
    this.productionRoll,
  });

  Map<String, dynamic> toJson() => {
        'activePlayerId': activePlayerId,
        'diceRolled': diceRolled,
        if (productionRoll != null) 'productionRoll': productionRoll,
      };

  factory TurnState.fromJson(Map<String, dynamic> json) => TurnState(
        activePlayerId: json['activePlayerId'] as String,
        diceRolled: json['diceRolled'] as bool? ?? false,
        productionRoll: json['productionRoll'] as int?,
      );
}
