import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att en placerad landskapsutbyggnad (Guldgömma, se
/// GameNotifier.dropRegionExpansion) synkas till motståndarens klient,
/// och att den överlever en sidladdning (resumeRoom) utan att kunna
/// dyka upp igen i en ombyggd draghög (se
/// RealmBoard.placedExpansionCards-doc).
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  Future<(ProviderContainer, ProviderContainer)> connectedRoom() async {
    final fake = FakeGameSyncService();
    final host = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);

    final roomCode = await host
        .read(gameProvider.notifier)
        .hostRoom('Astrid', expansions: {ExpansionSet.eraOfGold});
    await pump();
    await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
    await pump();
    expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
    await pump();

    return (host, guest);
  }

  test(
      'en placerad Guldgömma syns hos motståndarens klient efter synk',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.rollProductionDie(), isNull);
    host.read(gameProvider).you.hand.add(EraOfGoldCards.goldCache);

    expect(
        hostNotifier.dropRegionExpansion(-1, BuildingRow.above, EraOfGoldCards.goldCache),
        isNull);
    hostNotifier.adjustRegionExpansionResource(-1, BuildingRow.above, 2);
    await pump();

    final guestState = guest.read(gameProvider);
    final placed =
        guestState.opponent.principality.regionExpansionAt(-1, BuildingRow.above);
    expect(placed, isNotNull);
    expect(placed!.card.id, EraOfGoldCards.goldCache.id);
    expect(placed.storedResources, 2);
  });

  test(
      'en placerad Guldgömma dyker inte upp igen i en ombyggd draghög efter resumeRoom',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.rollProductionDie(), isNull);
    host.read(gameProvider).you.hand.add(EraOfGoldCards.goldCache);
    expect(
        hostNotifier.dropRegionExpansion(-1, BuildingRow.above, EraOfGoldCards.goldCache),
        isNull);
    await pump();

    final roomCode = host.read(gameProvider).roomCode!;
    final fake = host.read(gameSyncServiceProvider) as FakeGameSyncService;
    final resumed =
        ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(resumed.dispose);

    final error =
        await resumed.read(gameProvider.notifier).resumeRoom(roomCode, 'host', 'Astrid');

    expect(error, isNull);
    final resumedNotifier = resumed.read(gameProvider.notifier);
    for (var i = 0; i < 5; i++) {
      expect(
          resumedNotifier
              .drawStack(i)
              .any((c) => c.baseId == EraOfGoldCards.goldCache.id),
          isFalse,
          reason: 'Guldgömman ligger redan på brädet, ska inte finnas kvar i '
              'någon ombyggd draghög');
    }
  });
}
