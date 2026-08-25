import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att regionstapeln (se GameNotifier._regionDeck-doc) och
/// händelsekortsstapeln (se GameNotifier._eventDeck-doc) – precis som
/// draghögarna (se multiplayer_draw_stacks_test.dart) – är riktigt
/// DELADE, synkade resurser mellan host och gäst, i stället för att
/// varje klient blandar sin egen, oberoende kopia.
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  Future<(ProviderContainer, ProviderContainer)> connectedRoom() async {
    final fake = FakeGameSyncService();
    final host = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);

    final roomCode = await host.read(gameProvider.notifier).hostRoom('Astrid');
    await pump();
    await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    // rollProductionDie kräver handsReady (se GameNotifier.rollProductionDie)
    // – båda spelarna måste välja sin starthög innan action-fasen kan
    // börja.
    expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
    await pump();
    expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
    await pump();

    return (host, guest);
  }

  List<String> regionIds(ProviderContainer container) =>
      container.read(gameProvider.notifier).regionDeck.map((c) => c.id).toList();

  List<String> eventIds(ProviderContainer container) =>
      container.read(gameProvider.notifier).eventDeck.map((c) => c.id).toList();

  test(
      'host och gäst bygger upp EXAKT samma region- och händelsekortsstapel vid rumsskapande',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    expect(regionIds(guest), regionIds(host),
        reason: 'regionstapeln ska vara ordagrant samma på båda klienterna');
    expect(eventIds(guest), eventIds(host),
        reason: 'händelsekortsstapeln ska vara ordagrant samma på båda klienterna');
  });

  test(
      'host bygger en by bortom rikets yttergräns: regionstapeln synkas exakt till gästen',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    final regionBefore = regionIds(host);
    expect(regionBefore, hasLength(12)); // grundspelets 12 kvarvarande regionkort

    expect(hostNotifier.rollProductionDie(), isNull);
    final before = host.read(gameProvider);
    before.you.principality.addResourceToRegion(-1, BuildingRow.below, 2);
    before.you.principality.addResourceToRegion(-1, BuildingRow.above, 1);
    expect(hostNotifier.dropRoad(-1, BasicSetCards.road), isNull);
    expect(hostNotifier.dropSettlement(-2, BasicSetCards.settlement), isNull);
    // Hosten (en riktig, tom online-starthand, se MockGame.buildStartingPlayer)
    // har inte Spejare i handen, så de 2 regionkorten dras direkt – men
    // avvisa frågan om den ändå skulle dyka upp (defensivt, inte beroende
    // av att handen förblir tom).
    if (host.read(gameProvider).awaitingScoutDecision) {
      expect(hostNotifier.declineScout(), isNull);
    }
    await pump();

    final pending = host.read(gameProvider).pendingRegions;
    expect(pending, hasLength(2));

    final regionAfter = regionIds(host);
    expect(regionAfter, hasLength(10));
    expect(regionBefore.toSet().difference(regionAfter.toSet()),
        pending.map((c) => c.id).toSet(),
        reason: 'exakt de 2 dragna korten ska saknas ur den kvarvarande stapeln');

    // Kritiskt: gästens EGEN, lokala kopia av regionstapeln ska ha
    // krympt på exakt samma sätt.
    expect(regionIds(guest), regionAfter,
        reason: 'gästens och hosts kopia av regionstapeln ska stämma exakt');
  });

  test(
      'host drar ett händelsekort: händelsekortsstapeln synkas exakt till gästen',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    final eventBefore = eventIds(host);
    expect(eventBefore, hasLength(9)); // grundspelets 9 händelsekort

    expect(hostNotifier.rollProductionDie(), isNull);
    hostNotifier.state = host
        .read(gameProvider)
        .copyWith(eventDieFace: EventDieFace.eventCard);

    final error = hostNotifier.drawEventCard();
    expect(error, isNull);
    await pump();

    final drawn = host.read(gameProvider).drawnEventCard;
    expect(drawn, isNotNull);

    final eventAfter = eventIds(host);
    // Yule kan ha blandat om och lagt sig själv 4:e från botten (se
    // _drawEventCardResolvingYule-doc) – då är stapelns STORLEK
    // oförändrad (9), annars krympt med 1. Antingen fall: bara kolla att
    // det dragna kortet inte längre ligger överst/kvar i samma
    // ursprungliga position, och att gästen håller med.
    expect(eventAfter, isNot(eventBefore),
        reason: 'stapeln ska ha ändrats av dragningen (kortet borttaget, '
            'eller omblandad vid Jul)');

    // Kritiskt: gästens EGEN, lokala kopia ska stämma exakt.
    expect(eventIds(guest), eventAfter,
        reason: 'gästens och hosts kopia av händelsekortsstapeln ska stämma exakt');
  });
}
