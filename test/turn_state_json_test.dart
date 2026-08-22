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

  test('toJson/fromJson: winnerId följer med när satt', () {
    const state = TurnState(activePlayerId: 'you', winnerId: 'you');
    final json = state.toJson();

    expect(json['winnerId'], 'you');

    final restored = TurnState.fromJson(json);
    expect(restored.winnerId, 'you');
  });

  test('toJson/fromJson: winnerId utelämnas/blir null innan någon vunnit', () {
    const state = TurnState(activePlayerId: 'you');
    final json = state.toJson();

    expect(json.containsKey('winnerId'), isFalse);

    final restored = TurnState.fromJson(json);
    expect(restored.winnerId, isNull);
  });
}
