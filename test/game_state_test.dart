import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar [GameState.canBuildRightNow] – speglar
/// [GameNotifier._checkCanBuild]s samtliga spärrar, så att UI:t
/// (HandDock/CenterStacksStrip) kan stänga av dragbarheten helt i
/// stället för att låta spelaren dra ett kort och sedan mötas av ett
/// felmeddelande efter "Betalt" (speltestad bugg).
void main() {
  Player buildPlayer() => Player(id: 'you', name: 'Du');

  GameState baseState({
    bool diceRolled = true,
    List<GameCard> pendingRegions = const [],
    bool awaitingScoutDecision = false,
    bool relocationActive = false,
    HandAdjustmentPhase handAdjustmentPhase = HandAdjustmentPhase.none,
    TradePhase tradePhase = TradePhase.none,
  }) {
    return GameState(
      you: buildPlayer(),
      opponent: buildPlayer(),
      centerStacks: const {},
      diceRolled: diceRolled,
      pendingRegions: pendingRegions,
      awaitingScoutDecision: awaitingScoutDecision,
      relocationActive: relocationActive,
      handAdjustmentPhase: handAdjustmentPhase,
      tradePhase: tradePhase,
    );
  }

  test('sant när tärningen är slagen och inget annat blockerar', () {
    expect(baseState().canBuildRightNow, isTrue);
  });

  test('falskt innan tärningen slagits', () {
    expect(baseState(diceRolled: false).canBuildRightNow, isFalse);
  });

  test('falskt medan väntande regionkort inte är placerade', () {
    expect(
        baseState(pendingRegions: [BasicSetCards.forest]).canBuildRightNow,
        isFalse);
  });

  test('falskt medan Spejare-frågan väntar på svar', () {
    expect(baseState(awaitingScoutDecision: true).canBuildRightNow, isFalse);
  });

  test('falskt medan Omlokalisering är aktiv', () {
    expect(baseState(relocationActive: true).canBuildRightNow, isFalse);
  });

  test('falskt under handjustering', () {
    expect(
        baseState(handAdjustmentPhase: HandAdjustmentPhase.discarding)
            .canBuildRightNow,
        isFalse);
  });

  test('falskt under kortbytesfasen', () {
    expect(baseState(tradePhase: TradePhase.choosing).canBuildRightNow,
        isFalse);
  });
}
