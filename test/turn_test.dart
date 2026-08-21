import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar omgångens första steg (regelhäftet s. 7): slå produktions-
/// och händelsetärningen samtidigt (se [EventDieFace]), justera
/// resurser manuellt, och lämna över turen.
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('lokalt läge: röd ("du") går först och kan slå tärningen', () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.playLocally();
    expect(container.read(gameProvider).isMyTurn, isTrue);
    expect(container.read(gameProvider).diceRolled, isFalse);

    final error = notifier.rollProductionDie();

    expect(error, isNull);
    final state = container.read(gameProvider);
    expect(state.diceRolled, isTrue);
    expect(state.productionRoll, inInclusiveRange(1, 6));
    expect(state.eventDieFace, isNotNull);
  });

  test('tärningen går bara att slå en gång per omgång', () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();

    notifier.rollProductionDie();
    final firstRoll = container.read(gameProvider).productionRoll;
    final firstEventFace = container.read(gameProvider).eventDieFace;
    notifier.rollProductionDie();

    expect(container.read(gameProvider).productionRoll, firstRoll);
    expect(container.read(gameProvider).eventDieFace, firstEventFace);
  });

  test('adjustRegionResource justerar lagrade resurser på ditt eget rike, klämt 0-3', () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();

    notifier.adjustRegionResource(-1, BuildingRow.above, 1);
    expect(container.read(gameProvider).you.principality.regionAt(-1, BuildingRow.above)!.storedResources, 2);

    notifier.adjustRegionResource(-1, BuildingRow.above, 10);
    expect(container.read(gameProvider).you.principality.regionAt(-1, BuildingRow.above)!.storedResources, 3);

    notifier.adjustRegionResource(-1, BuildingRow.above, -10);
    expect(container.read(gameProvider).you.principality.regionAt(-1, BuildingRow.above)!.storedResources, 0);
  });

  test('endActionPhase kräver att tärningen är slagen, sedan väntar kortbytesfasen innan turen lämnas över', () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();

    final tooEarly = notifier.endActionPhase();
    expect(tooEarly, isNotNull);

    notifier.rollProductionDie();
    expect(container.read(gameProvider).eventDieFace, isNotNull);
    final error = notifier.endActionPhase();

    expect(error, isNull);
    // Handen har redan rätt antal kort (3 = handLimit vid spelstart),
    // så det går direkt vidare till kortbytesfasens tre val i stället
    // för att lämna över turen direkt – se trade_test.dart för själva
    // bytesflödet.
    expect(container.read(gameProvider).tradePhase, TradePhase.choosing);
    expect(container.read(gameProvider).activePlayerId, 'you');

    notifier.skipTrade();
    final state = container.read(gameProvider);
    expect(state.tradePhase, TradePhase.none);
    expect(state.activePlayerId, 'opponent');
    expect(state.diceRolled, isFalse);
    expect(state.productionRoll, isNull);
    expect(state.eventDieFace, isNull);
  });

  test('bygga är blockerat tills tärningen är slagen på din tur', () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();
    final before = container.read(gameProvider);
    before.you.principality.addResourceToRegion(-1, BuildingRow.below, 1);

    final tooEarly = notifier.dropRoad(-1, BasicSetCards.road);
    expect(tooEarly, isNotNull);
    expect(container.read(gameProvider).you.principality.roads.containsKey(-1), isFalse);

    notifier.rollProductionDie();
    final error = notifier.dropRoad(-1, BasicSetCards.road);

    expect(error, isNull);
    expect(container.read(gameProvider).you.principality.roads.containsKey(-1), isTrue);
  });

  test('online: bara den aktiva spelaren får slå tärningen och avsluta action-fasen', () async {
    final fake = FakeGameSyncService();
    final hostContainer = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guestContainer = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(hostContainer.dispose);
    addTearDown(guestContainer.dispose);

    final roomCode = await hostContainer.read(gameProvider.notifier).hostRoom('Astrid');
    await guestContainer.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    // Host är röd och går alltid först.
    expect(hostContainer.read(gameProvider).isMyTurn, isTrue);
    expect(guestContainer.read(gameProvider).isMyTurn, isFalse);

    // Innan starthänderna är klara går tärningen inte att slå än.
    expect(hostContainer.read(gameProvider).handsReady, isFalse);
    expect(hostContainer.read(gameProvider.notifier).rollProductionDie(), isNull);
    expect(hostContainer.read(gameProvider).diceRolled, isFalse);

    // Dela ut starthänderna direkt (annars gäller `handsReady`-spärren).
    hostContainer.read(gameProvider.notifier).chooseStartingStack(0);
    await pump();
    guestContainer.read(gameProvider.notifier).chooseStartingStack(1);
    await pump();

    final guestTooEarly = guestContainer.read(gameProvider.notifier).rollProductionDie();
    expect(guestTooEarly, isNotNull); // inte guests tur

    final hostRollError = hostContainer.read(gameProvider.notifier).rollProductionDie();
    expect(hostRollError, isNull);
    await pump();

    // Guests klient ska se samma tärningskast, synkat – både produktions-
    // och händelsetärningen (se EventDieFace).
    expect(guestContainer.read(gameProvider).productionRoll, hostContainer.read(gameProvider).productionRoll);
    expect(guestContainer.read(gameProvider).eventDieFace, hostContainer.read(gameProvider).eventDieFace);
    expect(guestContainer.read(gameProvider).diceRolled, isTrue);

    final guestEndTooEarly = guestContainer.read(gameProvider.notifier).endActionPhase();
    expect(guestEndTooEarly, isNotNull); // inte guests tur

    final hostEndError = hostContainer.read(gameProvider.notifier).endActionPhase();
    expect(hostEndError, isNull);
    hostContainer.read(gameProvider.notifier).skipTrade();
    await pump();

    expect(guestContainer.read(gameProvider).isMyTurn, isTrue);
    expect(guestContainer.read(gameProvider).diceRolled, isFalse);
    expect(guestContainer.read(gameProvider).productionRoll, isNull);
    expect(guestContainer.read(gameProvider).eventDieFace, isNull);
  });
}
