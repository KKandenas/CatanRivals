import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Vilket "läge" spelet just nu är i.
///
/// [local] – ingen nätverkssynk, två spelare turas om på samma iPad
/// (eller mock-data innan ett rum finns). [host]/[guest] – anslutet till
/// ett Firebase-rum, antingen som den som skapade det eller den som gick
/// med.
enum SessionMode { local, host, guest }

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

  final SessionMode mode;
  final String? roomCode;
  final String myPlayerId;
  final String opponentPlayerId;
  final bool opponentConnected;
  final String? sessionError;

  const GameState({
    required this.you,
    required this.opponent,
    required this.centerStacks,
    this.draggingCard,
    this.mode = SessionMode.local,
    this.roomCode,
    this.myPlayerId = 'you',
    this.opponentPlayerId = 'opponent',
    this.opponentConnected = false,
    this.sessionError,
  });

  bool get isOnline => mode != SessionMode.local;

  /// Röd/blå-tillhörighet härleds från spelar-id:t (satt av
  /// [GameNotifier.hostRoom]/[joinRoom]/mock-datan): host/"you" är
  /// alltid röd, guest/"opponent" är alltid blå – matchar vilken
  /// startuppställning ([StarterCards]) spelaren fick.
  bool get amIRed => myPlayerId == 'host' || myPlayerId == 'you';

  Player get _redPlayer => amIRed ? you : opponent;
  Player get _bluePlayer => amIRed ? opponent : you;

  /// Vem som ska ta sina 3 starthandkort härnäst (regelhäftet s. 6: den
  /// röda/startande spelaren väljer en draghög och tar de tre översta
  /// korten, sedan väljer den andra spelaren en annan hög). `null` när
  /// båda redan har dragit. Röd går alltid först – riktig tärningsslag
  /// för att avgöra startspelare är inte byggt än.
  String? get pendingHandChooserId {
    if (!_redPlayer.hasDrawnStartingHand) return _redPlayer.id;
    if (!_bluePlayer.hasDrawnStartingHand) return _bluePlayer.id;
    return null;
  }

  bool get isMyTurnToChooseHand => pendingHandChooserId == myPlayerId;

  bool get handsReady => pendingHandChooserId == null;

  GameState copyWith({
    Player? you,
    Player? opponent,
    Map<String, int>? centerStacks,
    GameCard? draggingCard,
    bool clearDraggingCard = false,
    SessionMode? mode,
    String? roomCode,
    String? myPlayerId,
    String? opponentPlayerId,
    bool? opponentConnected,
    String? sessionError,
    bool clearSessionError = false,
  }) {
    return GameState(
      you: you ?? this.you,
      opponent: opponent ?? this.opponent,
      centerStacks: centerStacks ?? this.centerStacks,
      draggingCard: clearDraggingCard ? null : (draggingCard ?? this.draggingCard),
      mode: mode ?? this.mode,
      roomCode: roomCode ?? this.roomCode,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      opponentPlayerId: opponentPlayerId ?? this.opponentPlayerId,
      opponentConnected: opponentConnected ?? this.opponentConnected,
      sessionError: clearSessionError ? null : (sessionError ?? this.sessionError),
    );
  }
}
