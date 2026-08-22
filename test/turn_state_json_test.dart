import 'package:catan_rivals/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar json-serialiseringen av [TurnState.peekingStackIndex] –
/// avgörande för Firebase-synken (se [GameNotifier._syncTurnState]/
/// `_turnStateSub`), som skiljer sig från t.ex. [FakeGameSyncService]
/// (används i övriga synk-tester) genom att faktiskt gå via json.
void main() {
  test('toJson/fromJson: peekingStackIndex följer med när satt', () {
    const state = TurnState(activePlayerId: 'you', peekingStackIndex: 3);
    final json = state.toJson();

    expect(json['peekingStackIndex'], 3);

    final restored = TurnState.fromJson(json);
    expect(restored.peekingStackIndex, 3);
  });

  test('toJson/fromJson: peekingStackIndex utelämnas/blir null när ingen kikar', () {
    const state = TurnState(activePlayerId: 'you');
    final json = state.toJson();

    expect(json.containsKey('peekingStackIndex'), isFalse);

    final restored = TurnState.fromJson(json);
    expect(restored.peekingStackIndex, isNull);
  });
}
