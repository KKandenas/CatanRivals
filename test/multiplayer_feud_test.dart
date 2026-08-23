import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Fejd (till skillnad från Brödrafejd, se
/// multiplayer_fraternal_feuds_test.dart) över två riktiga klienter –
/// rapporterad bugg: "Välj byggnad" (och draghögsvalet efter) fungerar
/// inte online, bara Brödrafejd gör. Fejd rör bara den egna spelarens
/// data (ingen FraternalFeudsRequest behövs, se feud_resolution_card.dart)
/// så den BORDE redan fungera – det här testet försöker återskapa
/// buggen över riktig host/guest-synk i stället för en enda container.
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

    expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
    await pump();
    expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
    await pump();
    expect(host.read(gameProvider).handsReady, isTrue);
    expect(guest.read(gameProvider).handsReady, isTrue);

    return (host, guest);
  }

  test(
      'host har övertaget: gästens klient ser "feudBuildingPickActive" bli tillgängligt och kan ta bort sin egen byggnad',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    // Ge host styrkeövertaget (byggd direkt på host-klientens EGEN
    // "you", precis som strengthAdvantagePlayerId redan testas i
    // feud_test.dart) och gästen en byggnad att välja bort.
    host.read(gameProvider).you.principality.placeExpansion(
        0,
        BuildingRow.above,
        0,
        PlacedCard(card: BasicSetCards.harald.copyWith(strengthPoints: 3)));
    guest.read(gameProvider).you.principality.placeExpansion(
        2, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));

    // principality.placeExpansion muterar bara den lokala kopian – till
    // skillnad från t.ex. dropExpansion (som kräver slagen tärning/rätt
    // tur, vilket vi inte bryr oss om att sätta upp här) synkas den
    // INTE automatiskt. adjustRegionResource(delta: 0) är en enkel,
    // ofarlig genväg för att trigga en riktig _syncMyPlayer() från
    // vardera klienten, precis som en riktig handling redan skulle gjort.
    host.read(gameProvider.notifier).adjustRegionResource(-1, BuildingRow.above, 0);
    guest.read(gameProvider.notifier).adjustRegionResource(-1, BuildingRow.above, 0);
    await pump();

    // Simulerar att händelsetärningen slogs och Fejd drogs upp, synkat
    // till båda via turnState (precis som drawEventCard gör på riktigt).
    final hostNotifier = host.read(gameProvider.notifier);
    hostNotifier.state =
        host.read(gameProvider).copyWith(drawnEventCard: BasicSetCards.feud);
    final guestNotifier = guest.read(gameProvider.notifier);
    guestNotifier.state =
        guest.read(gameProvider).copyWith(drawnEventCard: BasicSetCards.feud);

    // KRITISKT: känner GÄSTENS klient (utan övertaget) igen att HOST
    // har övertaget, baserat på synkad styrka? Om inte – det här är
    // buggen.
    expect(guest.read(gameProvider).strengthAdvantagePlayerId, 'host',
        reason:
            'gästens klient ska känna igen hosts styrkeövertag via den '
            'redan synkade principality-datan (players-strömmen)');

    final error = guestNotifier.startFeudBuildingPick();
    expect(error, isNull);
    expect(guest.read(gameProvider).feudBuildingPickActive, isTrue,
        reason: '"Välj byggnad" ska gå att starta hos den UTAN övertaget, '
            'oavsett online/lokalt (Fejd rör bara den egna spelarens data)');

    final pickError =
        guestNotifier.selectFeudBuilding(2, BuildingRow.below, 0);
    expect(pickError, isNull);
    expect(guest.read(gameProvider).feudPickedBuilding, isNotNull);

    final removeError = guestNotifier.resolveFeudBuildingRemoval(0);
    expect(removeError, isNull);
    final guestState = guest.read(gameProvider);
    expect(guestState.feudBuildingPickActive, isFalse);
    expect(guestState.you.principality.settlementAt(2)!.belowSites[0], isNull);
    expect(guestState.drawnEventCard, isNull);
  });

  test(
      'DEN RIKTIGA BUGGEN: host (med övertaget) trycker "OK" direkt – ska INTE hindra gästen från att sedan välja bort sin byggnad',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    host.read(gameProvider).you.principality.placeExpansion(
        0,
        BuildingRow.above,
        0,
        PlacedCard(card: BasicSetCards.harald.copyWith(strengthPoints: 3)));
    guest.read(gameProvider).you.principality.placeExpansion(
        2, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));
    host.read(gameProvider.notifier).adjustRegionResource(-1, BuildingRow.above, 0);
    guest.read(gameProvider.notifier).adjustRegionResource(-1, BuildingRow.above, 0);
    await pump();

    // Simulerar att kortet faktiskt dras och synkas via riktig
    // TurnState (till skillnad från testet ovan, som bara sätter
    // drawnEventCard lokalt på varje klient var för sig) – annars skulle
    // gästen aldrig ha sett kortet i första läget, och det här testet
    // skulle inte fånga buggen (host skrev tidigare ALLTID över
    // gästens `drawnEventCard` med `null` när den trycker "OK", oavsett
    // om gästen hunnit agera).
    final roomCode = host.read(gameProvider).roomCode!;
    final fakeSync =
        host.read(gameSyncServiceProvider) as FakeGameSyncService;
    await fakeSync.writeTurnState(
        roomCode,
        const TurnState(
            activePlayerId: 'host',
            diceRolled: true,
            drawnEventCard: BasicSetCards.feud));
    await pump();
    expect(guest.read(gameProvider).drawnEventCard, isNotNull,
        reason: 'gästen ska ha sett det synkade Fejd-kortet');

    final hostNotifier = host.read(gameProvider.notifier);
    expect(host.read(gameProvider).strengthAdvantagePlayerId, 'host');

    // Host ser bara en passiv "OK"-knapp för Fejd (se
    // FeudResolutionCard._primaryAction) och trycker den direkt, INNAN
    // gästen hunnit trycka "Välj byggnad".
    expect(hostNotifier.dismissEventCard(), isNull);
    expect(host.read(gameProvider).drawnEventCard, isNull,
        reason: 'stängs ändå direkt lokalt hos host själv');
    await pump();

    // Gästen ska fortfarande se kortet (dismiss fick INTE synkas bort
    // det, eftersom gästen fortfarande har en byggnad att välja bort)
    // och därmed fortfarande kunna starta bygg-väljaren.
    final guestNotifier = guest.read(gameProvider.notifier);
    expect(guest.read(gameProvider).drawnEventCard, isNotNull,
        reason: 'hosts tidiga "OK" fick inte rensa gästens uppslagna kort');
    expect(guestNotifier.startFeudBuildingPick(), isNull);
    expect(guest.read(gameProvider).feudBuildingPickActive, isTrue);

    expect(guestNotifier.selectFeudBuilding(2, BuildingRow.below, 0), isNull);
    expect(guestNotifier.resolveFeudBuildingRemoval(0), isNull);
    final guestState = guest.read(gameProvider);
    expect(guestState.you.principality.settlementAt(2)!.belowSites[0], isNull);
    expect(guestState.drawnEventCard, isNull);
  });
}
