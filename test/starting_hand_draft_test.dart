import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar starthandsutdelningen (regelhäftet s. 6) när ett tema är
/// aktivt: "Man väljer en av de tre högarna som innehåller korten från
/// grundspelet. Man får kika på alla kort i högen och välja ut tre.
/// Resten av korten läggs tillbaka i samma ordning." Se
/// [GameNotifier.startHandDraft]/[GameNotifier.pickHandDraftCard].
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

    return (host, guest);
  }

  test('kikar visar alla 12 kort i den valda grundspelshögen i ordning',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    final originalStack = hostNotifier.drawStack(0);
    expect(originalStack, hasLength(12));

    expect(hostNotifier.startHandDraft(0), isNull);
    final state = host.read(gameProvider);
    expect(state.startingHandDraftStackIndex, 0);
    expect(state.startingHandDraftPool, originalStack);
    expect(state.startingHandDraftPicked, isEmpty);
    // Rent lokalt tills tredje kortet är valt – ingen sync ännu.
    expect(state.centerStacks['draw1'], 12);
  });

  test('att välja <3 kort fortsätter kikandet utan att synka något',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    hostNotifier.startHandDraft(0);
    final pool = host.read(gameProvider).startingHandDraftPool!;

    expect(hostNotifier.pickHandDraftCard(pool[3]), isNull);
    var state = host.read(gameProvider);
    expect(state.startingHandDraftPicked, [pool[3]]);
    expect(state.startingHandDraftPool, hasLength(11));
    expect(state.startingHandDraftPool!.contains(pool[3]), isFalse);
    expect(state.you.hand, isEmpty);
    expect(state.centerStacks['draw1'], 12);

    expect(hostNotifier.pickHandDraftCard(pool[7]), isNull);
    state = host.read(gameProvider);
    expect(state.startingHandDraftPicked, [pool[3], pool[7]]);
    expect(state.startingHandDraftPool, hasLength(10));
    expect(state.you.hand, isEmpty);

    await pump();
    expect(guest.read(gameProvider).opponent.hand, isEmpty);
  });

  test(
      'tredje kortet avslutar utdelningen: handen+centerStacks uppdateras i ett svep, resten läggs tillbaka i oförändrad ordning',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    final originalStack = hostNotifier.drawStack(0);
    hostNotifier.startHandDraft(0);
    final pool = host.read(gameProvider).startingHandDraftPool!;
    final picks = [pool[5], pool[0], pool[9]];

    expect(hostNotifier.pickHandDraftCard(picks[0]), isNull);
    expect(hostNotifier.pickHandDraftCard(picks[1]), isNull);
    expect(hostNotifier.pickHandDraftCard(picks[2]), isNull);

    final state = host.read(gameProvider);
    expect(state.you.hand, picks);
    expect(state.you.hasDrawnStartingHand, isTrue);
    expect(state.centerStacks['draw1'], 9);
    expect(state.startingHandDraftStackIndex, isNull);
    expect(state.startingHandDraftPool, isNull);
    expect(state.startingHandDraftPicked, isEmpty);

    final remaining = List<GameCard>.of(originalStack)
      ..removeWhere(picks.contains);
    expect(hostNotifier.drawStack(0), remaining,
        reason: 'de 9 återstående korten ska ligga kvar i sin ursprungliga '
            'inbördes ordning, bara med de tre valda borttagna');

    await pump();
    expect(guest.read(gameProvider).opponent.hand, hasLength(3));
    expect(guest.read(gameProvider).centerStacks['draw1'], 9);
  });

  test('en Gulderan-egen hög (index 3/4) går inte att välja för starthanden',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.startHandDraft(3), isNull);
    expect(host.read(gameProvider).startingHandDraftStackIndex, isNull,
        reason: 'index 3 är en Gulderan-hög, ska tyst avvisas');
    expect(hostNotifier.startHandDraft(4), isNull);
    expect(host.read(gameProvider).startingHandDraftStackIndex, isNull);
  });

  test('en redan vald hög går inte att välja igen', () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    hostNotifier.startHandDraft(0);
    final pool = host.read(gameProvider).startingHandDraftPool!;
    hostNotifier.pickHandDraftCard(pool[0]);
    hostNotifier.pickHandDraftCard(pool[1]);
    hostNotifier.pickHandDraftCard(pool[2]);
    await pump();

    final error = guest.read(gameProvider.notifier).startHandDraft(0);
    expect(error, 'Den högen är redan vald.');
  });

  test('fel spelares tur avvisas', () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final error = guest.read(gameProvider.notifier).startHandDraft(1);
    expect(error, isNotNull);
    expect(guest.read(gameProvider).startingHandDraftStackIndex, isNull);
  });
}
