import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar starthands-valet (regelhäftet s. 6): den röda/startande
/// spelaren väljer en draghög och tar dess 3 översta kort, sedan väljer
/// den blå spelaren en annan hög.
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('playLocally delar ut båda starthänderna direkt', () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);

    container.read(gameProvider.notifier).playLocally();
    final state = container.read(gameProvider);

    expect(state.you.hand, hasLength(3));
    expect(state.opponent.hand, hasLength(3));
    expect(state.handsReady, isTrue);
    expect(state.centerStacks['draw1'], 6);
    expect(state.centerStacks['draw2'], 6);
    expect(state.centerStacks['draw3'], 9);
    expect(state.centerStacks['draw4'], 9);
  });

  test('host väljer en hög, sedan guest en annan – båda får 3 kort var', () async {
    final fake = FakeGameSyncService();
    final hostContainer = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guestContainer = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(hostContainer.dispose);
    addTearDown(guestContainer.dispose);

    final roomCode = await hostContainer.read(gameProvider.notifier).hostRoom('Astrid');
    await guestContainer.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    // Röd (host) går alltid först.
    expect(hostContainer.read(gameProvider).isMyTurnToChooseHand, isTrue);
    expect(guestContainer.read(gameProvider).isMyTurnToChooseHand, isFalse);

    final guestTooEarly = guestContainer.read(gameProvider.notifier).chooseStartingStack(1);
    expect(guestTooEarly, isNotNull); // inte guests tur än

    final hostError = hostContainer.read(gameProvider.notifier).chooseStartingStack(0);
    expect(hostError, isNull);
    expect(hostContainer.read(gameProvider).you.hand, hasLength(3));
    expect(hostContainer.read(gameProvider).centerStacks['draw1'], 6);
    await pump();

    // Nu är det guests (blå) tur.
    expect(guestContainer.read(gameProvider).isMyTurnToChooseHand, isTrue);

    final reclaim = guestContainer.read(gameProvider.notifier).chooseStartingStack(0);
    expect(reclaim, isNotNull); // hög 0 är redan tagen

    final guestError = guestContainer.read(gameProvider.notifier).chooseStartingStack(1);
    expect(guestError, isNull);
    expect(guestContainer.read(gameProvider).you.hand, hasLength(3));
    await pump();

    expect(hostContainer.read(gameProvider).handsReady, isTrue);
    expect(guestContainer.read(gameProvider).handsReady, isTrue);
    expect(hostContainer.read(gameProvider).opponent.hand, hasLength(3));
  });
}
