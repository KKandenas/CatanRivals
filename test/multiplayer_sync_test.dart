import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar rum-synken (hostRoom/joinRoom + ström-prenumerationerna) mot
/// en fejkad in-memory-tjänst i stället för riktig Firebase, eftersom
/// den här miljön inte har nätverksåtkomst till Firebase. Två separata
/// [ProviderContainer] (en per "iPad") delar samma [FakeGameSyncService]
/// -instans, precis som två riktiga klienter skulle dela samma
/// Firebase-databas.
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('host skapar rum, väntar, och ser motståndaren när den går med', () async {
    final fake = FakeGameSyncService();
    final hostContainer = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guestContainer = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(hostContainer.dispose);
    addTearDown(guestContainer.dispose);

    final roomCode = await hostContainer.read(gameProvider.notifier).hostRoom('Astrid');
    await pump();

    var hostState = hostContainer.read(gameProvider);
    expect(hostState.mode, SessionMode.host);
    expect(hostState.roomCode, roomCode);
    expect(hostState.opponentConnected, isFalse);

    final joinError = await guestContainer.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    expect(joinError, isNull);

    hostState = hostContainer.read(gameProvider);
    expect(hostState.opponentConnected, isTrue);
    expect(hostState.opponent.name, 'Björn');

    final guestState = guestContainer.read(gameProvider);
    expect(guestState.mode, SessionMode.guest);
    expect(guestState.opponent.name, 'Astrid');
    expect(guestState.centerStacks, hostState.centerStacks);
  });

  test('går med i okänd rumskod ger felmeddelande', () async {
    final fake = FakeGameSyncService();
    final container = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    final error = await container.read(gameProvider.notifier).joinRoom('ZZZZ', 'Björn');

    expect(error, isNotNull);
    expect(container.read(gameProvider).mode, SessionMode.local);
  });

  test('rummet blir fullt efter två spelare', () async {
    final fake = FakeGameSyncService();
    final hostContainer = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest1Container = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest2Container = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(hostContainer.dispose);
    addTearDown(guest1Container.dispose);
    addTearDown(guest2Container.dispose);

    final roomCode = await hostContainer.read(gameProvider.notifier).hostRoom('Astrid');
    final firstJoin = await guest1Container.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    final secondJoin = await guest2Container.read(gameProvider.notifier).joinRoom(roomCode, 'Cecilia');

    expect(firstJoin, isNull);
    expect(secondJoin, isNotNull);
  });

  test('playLocally återställer till lokalt läge utan rum', () async {
    final fake = FakeGameSyncService();
    final container = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    await container.read(gameProvider.notifier).hostRoom('Astrid');
    container.read(gameProvider.notifier).playLocally();

    final state = container.read(gameProvider);
    expect(state.mode, SessionMode.local);
    expect(state.roomCode, isNull);
  });
}
