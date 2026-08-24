import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Regressionstest för soft-locken som annars skulle uppstå vid en
/// sidladdning EFTER starthandsutdelningens tredje kortval (hand/
/// centerStacks redan synkade, se pickHandDraftCard) men FÖRE "Klar"
/// på den efterföljande regionomflyttningen: hasDrawnStartingHand
/// sätts aldrig (den väntar på finishRegionRearrangement), och
/// startingRegionRearrangementActive är rent lokalt UI-state som
/// annars skulle nollställas av en ny GameNotifier – motståndaren
/// skulle då aldrig få sin tur. Se GameNotifier.resumeRoom för fixen.
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test(
      'sidladdning mitt i regionomflyttningen: den nya klienten hamnar direkt tillbaka i den fasen',
      () async {
    final fake = FakeGameSyncService();
    final host = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final roomCode = await host
        .read(gameProvider.notifier)
        .hostRoom('Astrid', expansions: {ExpansionSet.eraOfGold});
    await pump();
    await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    final hostNotifier = host.read(gameProvider.notifier);
    hostNotifier.startHandDraft(0);
    final pool = host.read(gameProvider).startingHandDraftPool!;
    hostNotifier.pickHandDraftCard(pool[0]);
    hostNotifier.pickHandDraftCard(pool[1]);
    hostNotifier.pickHandDraftCard(pool[2]);
    await pump();

    expect(host.read(gameProvider).you.hasDrawnStartingHand, isFalse);
    expect(host.read(gameProvider).startingRegionRearrangementActive, isTrue);

    // Simulerar sidladdningen: en helt ny GameNotifier, som bara känner
    // till det som redan synkats till Firebase (handen/centerStacks),
    // inte det lokala startingRegionRearrangementActive-flaggan.
    final resumed = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(resumed.dispose);
    final error = await resumed
        .read(gameProvider.notifier)
        .resumeRoom(roomCode, 'host', 'Astrid');

    expect(error, isNull);
    final resumedState = resumed.read(gameProvider);
    expect(resumedState.you.hand, hasLength(3));
    expect(resumedState.you.hasDrawnStartingHand, isFalse);
    expect(resumedState.startingRegionRearrangementActive, isTrue,
        reason: 'annars skulle motståndaren aldrig få sin tur');

    // Och spelaren kan faktiskt slutföra regionomflyttningen och
    // komma vidare därifrån.
    final resumedNotifier = resumed.read(gameProvider.notifier);
    expect(resumedNotifier.finishRegionRearrangement(), isNull);
    expect(resumed.read(gameProvider).you.hasDrawnStartingHand, isTrue);
  });

  test(
      'sidladdning EFTER "Klar": ingen falsk regionomflyttningsfas (hasDrawnStartingHand redan satt)',
      () async {
    final fake = FakeGameSyncService();
    final host = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final roomCode = await host
        .read(gameProvider.notifier)
        .hostRoom('Astrid', expansions: {ExpansionSet.eraOfGold});
    await pump();
    await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    final hostNotifier = host.read(gameProvider.notifier);
    hostNotifier.startHandDraft(0);
    final pool = host.read(gameProvider).startingHandDraftPool!;
    hostNotifier.pickHandDraftCard(pool[0]);
    hostNotifier.pickHandDraftCard(pool[1]);
    hostNotifier.pickHandDraftCard(pool[2]);
    hostNotifier.finishRegionRearrangement();
    await pump();

    final resumed = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(resumed.dispose);
    await resumed.read(gameProvider.notifier).resumeRoom(roomCode, 'host', 'Astrid');

    expect(resumed.read(gameProvider).startingRegionRearrangementActive, isFalse);
    expect(resumed.read(gameProvider).you.hasDrawnStartingHand, isTrue);
  });
}
