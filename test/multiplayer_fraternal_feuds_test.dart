import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att Brödrafejd (regelhäftet: spelaren MED styrkeövertaget
/// väljer 2 kort från motståndarens hand) faktiskt fungerar över två
/// riktiga klienter (host + guest, delar en [FakeGameSyncService]) –
/// tidigare var det bara byggt för lokalt läge (samma [GameNotifier]
/// äger båda spelarnas data där), online visades bara en påminnelsetext
/// utan någon fungerande knapp. Se [FraternalFeudsRequest] och
/// GameNotifier.pickFraternalFeudsCard/_fulfillFraternalFeudsRequest.
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

  /// Ger [player]s rike ett hjältekort med [strength] styrkepoäng, så
  /// [GameState.strengthAdvantagePlayerId] går att styra deterministiskt
  /// – samma knep som feud_test.dart.
  void giveStrength(Player player, int strength) {
    player.principality.placeExpansion(
      0,
      BuildingRow.above,
      0,
      PlacedCard(
          card: BasicSetCards.harald.copyWith(strengthPoints: strength)),
    );
  }

  test(
      'host har övertaget: väljer 2 kort ur gästens hand, gästens klient tillämpar det på sig själv',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    // principality är en mutabel klass (se RealmBoard) och
    // strengthAdvantagePlayerId räknas ut live ur host-klientens EGET
    // `you`/`opponent`-par, så det krävs ingen synk mot gästen för att
    // host-klientens egen jämförelse ska stämma direkt.
    giveStrength(host.read(gameProvider).you, 3);
    final hostNotifier = host.read(gameProvider.notifier);
    hostNotifier.state = host
        .read(gameProvider)
        .copyWith(drawnEventCard: BasicSetCards.fraternalFeuds);
    expect(host.read(gameProvider).strengthAdvantagePlayerId, 'host');

    final error = hostNotifier.startFraternalFeudsPick();
    expect(error, isNull);
    expect(host.read(gameProvider).fraternalFeudsPicking, isTrue);

    final guestHandBefore =
        List<GameCard>.of(host.read(gameProvider).opponent.hand);
    expect(guestHandBefore, hasLength(3));

    expect(hostNotifier.pickFraternalFeudsCard(guestHandBefore[0], 1), isNull);
    var hostState = host.read(gameProvider);
    expect(hostState.fraternalFeudsPicking, isTrue);
    // Fortfarande opåverkad lokalt hos host – online muteras inte
    // motståndarens hand direkt.
    expect(hostState.opponent.hand, guestHandBefore);

    expect(hostNotifier.pickFraternalFeudsCard(guestHandBefore[1], 3), isNull);
    hostState = host.read(gameProvider);
    expect(hostState.fraternalFeudsPicking, isFalse);
    expect(hostState.drawnEventCard, isNull);

    // Väntar in Firebase-tur-och-retur: förfrågan -> gästens klient
    // tillämpar den -> synkar tillbaka sin nya hand -> host ser den.
    await pump();
    await pump();

    final guestState = guest.read(gameProvider);
    expect(guestState.you.hand.contains(guestHandBefore[0]), isFalse,
        reason: 'gästens klient ska ha tagit bort det första valda kortet '
            'ur sin EGEN hand, som svar på förfrågan');
    expect(guestState.you.hand.contains(guestHandBefore[1]), isFalse);
    expect(guestState.centerStacks['draw2']! >= 1, isTrue,
        reason: 'draghög 1 (index 1) ska ha fått ett extra kort');
    expect(guestState.centerStacks['draw4']! >= 1, isTrue,
        reason: 'draghög 3 (index 3) ska ha fått ett extra kort');

    final hostAfterSync = host.read(gameProvider);
    expect(hostAfterSync.opponent.hand.contains(guestHandBefore[0]), isFalse,
        reason:
            'host ska se gästens uppdaterade (kortare) hand via den vanliga '
            'players-synken');
    expect(hostAfterSync.opponent.hand.contains(guestHandBefore[1]), isFalse);
    expect(hostAfterSync.opponent.hand, hasLength(1));
  });

  test('gästen har övertaget: väljer 2 kort ur hostens hand', () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    giveStrength(guest.read(gameProvider).you, 2);
    final guestNotifier = guest.read(gameProvider.notifier);
    guestNotifier.state = guest
        .read(gameProvider)
        .copyWith(drawnEventCard: BasicSetCards.fraternalFeuds);
    expect(guest.read(gameProvider).strengthAdvantagePlayerId, 'guest');

    expect(guestNotifier.startFraternalFeudsPick(), isNull);
    final hostHandBefore =
        List<GameCard>.of(guest.read(gameProvider).opponent.hand);
    expect(hostHandBefore, hasLength(3));

    expect(guestNotifier.pickFraternalFeudsCard(hostHandBefore[0], 0), isNull);
    expect(guestNotifier.pickFraternalFeudsCard(hostHandBefore[1], 2), isNull);
    expect(guest.read(gameProvider).fraternalFeudsPicking, isFalse);

    await pump();
    await pump();

    final hostState = host.read(gameProvider);
    expect(hostState.you.hand.contains(hostHandBefore[0]), isFalse);
    expect(hostState.you.hand.contains(hostHandBefore[1]), isFalse);
  });

  test(
      'samma buggmönster som Fejd: gästen (utan övertaget) trycker "OK" direkt – ska INTE hindra host från att sedan välja 2 kort',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    giveStrength(host.read(gameProvider).you, 3);
    host.read(gameProvider.notifier).adjustRegionResource(-1, BuildingRow.above, 0);
    await pump();

    final roomCode = host.read(gameProvider).roomCode!;
    final fakeSync =
        host.read(gameSyncServiceProvider) as FakeGameSyncService;
    await fakeSync.writeTurnState(
        roomCode,
        const TurnState(
            activePlayerId: 'host',
            diceRolled: true,
            drawnEventCard: BasicSetCards.fraternalFeuds));
    await pump();
    expect(host.read(gameProvider).strengthAdvantagePlayerId, 'host');

    // Gästen (utan övertaget) ser bara en passiv "OK"-knapp för
    // Brödrafejd (se FeudResolutionCard._primaryAction) och trycker
    // den direkt, INNAN host hunnit trycka "Välj kort".
    final guestNotifier = guest.read(gameProvider.notifier);
    expect(guest.read(gameProvider).drawnEventCard, isNotNull);
    expect(guestNotifier.dismissEventCard(), isNull);
    await pump();

    final hostNotifier = host.read(gameProvider.notifier);
    expect(host.read(gameProvider).drawnEventCard, isNotNull,
        reason: 'gästens tidiga "OK" fick inte rensa hosts uppslagna kort');
    expect(hostNotifier.startFraternalFeudsPick(), isNull);
    expect(host.read(gameProvider).fraternalFeudsPicking, isTrue);
  });
}
