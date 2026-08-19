import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Allt UI:t behöver rendera spelbrädet: de två spelarna, hur många
/// kort som återstår i center-dragstaplarna, och (om något) vilket
/// kort som just nu dras – används för att tända giltiga rutor.
///
/// Rent state-innehav – själva spelreglerna/mutationerna bor i
/// [GameNotifier] (game_notifier.dart).
@immutable
class GameState {
  final Player you;
  final Player opponent;
  final Map<String, int> centerStacks;
  final GameCard? draggingCard;

  const GameState({
    required this.you,
    required this.opponent,
    required this.centerStacks,
    this.draggingCard,
  });

  GameState copyWith({
    Player? you,
    Player? opponent,
    Map<String, int>? centerStacks,
    GameCard? draggingCard,
    bool clearDraggingCard = false,
  }) {
    return GameState(
      you: you ?? this.you,
      opponent: opponent ?? this.opponent,
      centerStacks: centerStacks ?? this.centerStacks,
      draggingCard: clearDraggingCard ? null : (draggingCard ?? this.draggingCard),
    );
  }
}
