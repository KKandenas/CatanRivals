import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att [GameNotifier.choosePeekStack] synkas till motståndaren
/// (via [TurnState.peekingStackIndex]) så att den som INTE kikar ser
/// vilken hög det gäller – bara index, aldrig vilka kort – och att
/// fältet rensas igen så fort kikandet är klart (se
/// [GameNotifier.peekTakeCard]/`_advanceToNextPlayer`).
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('host kikar: gästen ser peekingStackIndex, sedan rensat efter peekTakeCard',
      () async {
    final fake = FakeGameSyncService();
    final host =
        ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest =
        ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final roomCode = await host.read(gameProvider.notifier).hostRoom('Astrid');
    await pump();
    await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
    await pump();
    expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
    await pump();

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.rollProductionDie(), isNull);
    expect(hostNotifier.endActionPhase(), isNull);
    expect(hostNotifier.startPeek(), isNull);
    expect(hostNotifier.confirmPeekPayment(), isNull);
    final hostHand = host.read(gameProvider).you.hand;
    expect(hostNotifier.peekDiscardCard(hostHand.first, 0), isNull);

    // Innan hosten valt hög ska ingen se något kikande.
    expect(host.read(gameProvider).peekingStackIndex, isNull);
    expect(guest.read(gameProvider).peekingStackIndex, isNull);

    expect(hostNotifier.choosePeekStack(2), isNull);
    await pump();

    // Bara VILKEN hög syns – på båda klienterna, precis som vid ett
    // fysiskt bord där motståndaren ser vilken hög man plockar upp.
    expect(host.read(gameProvider).peekingStackIndex, 2);
    expect(guest.read(gameProvider).peekingStackIndex, 2);

    final peeked = host.read(gameProvider).peekedCards!;
    expect(hostNotifier.peekTakeCard(peeked.first), isNull);
    await pump();

    expect(host.read(gameProvider).peekingStackIndex, isNull,
        reason: 'ska rensas när kikandet är klart (peekTakeCard/_advanceToNextPlayer)');
    expect(guest.read(gameProvider).peekingStackIndex, isNull,
        reason: 'rensningen ska synkas till gästen också');
  });
}
