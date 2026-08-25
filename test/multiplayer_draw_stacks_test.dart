import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att de delade dragstaplarna (se GameNotifier._drawStacks-doc)
/// verkligen är en DELAD, synkad resurs mellan host och gäst – rapporterad
/// bugg: både spelare 1 och spelare 2 kunde välja samma unika hjälte
/// (Candamir, bara 1 fysisk kopia) ur varsin egen hög, eftersom varje
/// klient tidigare blandade sin egen, oberoende dragstapel (bara det
/// synliga ANTALET synkades, inte de faktiska korten).
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

    return (host, guest);
  }

  List<String> stackIds(ProviderContainer container, int index) =>
      container.read(gameProvider.notifier).drawStack(index).map((c) => c.id).toList();

  test(
      'host och gäst bygger upp EXAKT samma 4 dragstaplar vid rumsskapande, inte varsin egen slumpad blandning',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    for (var i = 0; i < 4; i++) {
      expect(stackIds(guest, i), stackIds(host, i),
          reason: 'hög $i ska vara ordagrant samma på båda klienterna');
    }
  });

  test(
      'host väljer en starthög: gästens klient ser samma hög krympa – kortet kan inte längre dras av gästen också',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final beforeIds = stackIds(host, 0);
    expect(beforeIds, hasLength(9)); // grundspelets 4 högar à 9 kort

    expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
    await pump();

    final drawnIds = host.read(gameProvider).you.hand.map((c) => c.id).toSet();
    expect(drawnIds, hasLength(3), reason: 'starthanden är alltid 3 kort');
    expect(beforeIds.toSet().intersection(drawnIds), drawnIds,
        reason: 'de dragna korten kom från hög 0');

    // Kritiskt: gästens EGEN, lokala kopia av samma hög ska ha krympt på
    // exakt samma sätt – annars skulle gästen fortfarande kunna dra (och
    // få) något av de 3 korten host redan har i handen.
    final guestRemaining = stackIds(guest, 0);
    expect(guestRemaining, hasLength(6));
    expect(guestRemaining.toSet().intersection(drawnIds), isEmpty,
        reason: 'inget av de kort host redan fått ska finnas kvar i '
            'gästens lokala kopia av högen');
    expect(guestRemaining, stackIds(host, 0),
        reason: 'gästens och hosts kopia av hög 0 ska fortfarande stämma exakt');
  });

  test(
      'det unika kortet Candamir (1 fysisk kopia totalt) finns bara EN gång, oavsett var det hamnar, efter att båda spelare valt varsin starthög – rapporterad bugg',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    bool isCandamir(String id) => id.startsWith('hero-candamir');

    expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
    await pump();
    expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
    await pump();

    // Räkna EN gång, från hostens synvinkel (dess egen hand + gästens
    // synkade hand + hostens 4 kvarvarande, synkade högar) – hittar
    // Candamir oavsett om den redan blivit dragen av någon, eller
    // fortfarande ligger kvar i en outnyttjad hög.
    final hostState = host.read(gameProvider);
    var occurrences = 0;
    occurrences += hostState.you.hand.where((c) => isCandamir(c.id)).length;
    occurrences +=
        hostState.opponent.hand.where((c) => isCandamir(c.id)).length;
    for (var i = 0; i < 4; i++) {
      occurrences += stackIds(host, i).where(isCandamir).length;
    }
    expect(occurrences, 1,
        reason: 'Candamir har bara 1 fysisk kopia – ska aldrig kunna '
            'räknas två gånger (varken i två högar eller i båda '
            'spelarnas händer samtidigt)');

    // Och gästens klient ska hålla med om VAR den fysiska kopian är –
    // inte ha sin egen, separata uppfattning.
    expect(guest.read(gameProvider).you.hand.any((c) => isCandamir(c.id)),
        hostState.opponent.hand.any((c) => isCandamir(c.id)));
    for (var i = 0; i < 4; i++) {
      expect(stackIds(guest, i), stackIds(host, i));
    }
  });
}
