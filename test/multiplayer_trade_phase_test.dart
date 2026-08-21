import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Undersöker en rapporterad bugg: i onlineläge (två spelare, riktigt
/// rum) går det ibland inte att markera ett handkort att slänga när man
/// väljer det vanliga (gratis) bytet – tydligen kopplat till om man
/// föregående gång valde "kika". [TradePhase] synkas INTE mellan
/// klienterna (bara [TurnState]: vems tur, om tärningen är slagen, och
/// produktionsslaget) – bara den aktiva spelarens egen klient håller
/// reda på var i kortbytesfasen den är. En full lokal-läge-simulering
/// (se trade_phase_full_round_test.dart) kunde inte återskapa buggen,
/// så den här testar samma sekvens över två riktiga klienter (host +
/// guest, delar en [FakeGameSyncService]) för att se om synken mellan
/// dem stör host-klientens egen kortbytesfas-tillstånd.
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test(
      'host: kika en omgång, sedan en full gäst-omgång emellan, sedan gratis byte – ska gå att markera och slänga ett kort',
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

    // Starthandsval: röd (host) väljer först, sedan blå (guest).
    expect(host.read(gameProvider).isMyTurnToChooseHand, isTrue);
    expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
    await pump();
    expect(guest.read(gameProvider).isMyTurnToChooseHand, isTrue);
    expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
    await pump();

    expect(host.read(gameProvider).handsReady, isTrue);
    expect(guest.read(gameProvider).handsReady, isTrue);
    expect(host.read(gameProvider).activePlayerId, 'host');

    // --- Host: full kika-omgång ---
    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.rollProductionDie(), isNull);
    expect(hostNotifier.endActionPhase(), isNull);
    expect(host.read(gameProvider).tradePhase, TradePhase.choosing);

    expect(hostNotifier.startPeek(), isNull);
    expect(hostNotifier.confirmPeekPayment(), isNull);
    final hostHandBeforeDiscard = host.read(gameProvider).you.hand;
    expect(hostNotifier.peekDiscardCard(hostHandBeforeDiscard.first, 0), isNull);
    expect(hostNotifier.choosePeekStack(1), isNull);
    final peeked = host.read(gameProvider).peekedCards!;
    expect(hostNotifier.peekTakeCard(peeked.first), isNull);
    await pump();

    var hostState = host.read(gameProvider);
    expect(hostState.tradePhase, TradePhase.none);
    expect(hostState.activePlayerId, 'guest');

    // --- Guest: en hel, enkel omgång (skip trade) ---
    await pump();
    var guestState = guest.read(gameProvider);
    expect(guestState.activePlayerId, 'guest',
        reason: 'gästens klient ska ha fått turen via turnState-synken');
    final guestNotifier = guest.read(gameProvider.notifier);
    expect(guestNotifier.rollProductionDie(), isNull);
    expect(guestNotifier.endActionPhase(), isNull);
    expect(guest.read(gameProvider).tradePhase, TradePhase.choosing);
    expect(guestNotifier.skipTrade(), isNull);
    await pump();

    // --- Host: turen tillbaka, väljer nu det vanliga (gratis) bytet ---
    await pump();
    hostState = host.read(gameProvider);
    expect(hostState.activePlayerId, 'host',
        reason: 'host-klienten ska ha fått turen tillbaka via turnState-synken');
    expect(hostState.tradePhase, TradePhase.none,
        reason:
            'BUGG-kandidat om detta INTE är none: en kvarleva från kika-omgången');

    expect(hostNotifier.rollProductionDie(), isNull);
    expect(hostNotifier.endActionPhase(), isNull);
    hostState = host.read(gameProvider);
    expect(hostState.tradePhase, TradePhase.choosing,
        reason:
            'BUGG-kandidat om detta inte stämmer: kortbytesfasen kommer inte '
            'igång som väntat efter kika+en motståndaromgång emellan');

    expect(hostNotifier.startExchange(), isNull);
    hostState = host.read(gameProvider);
    expect(hostState.tradePhase, TradePhase.exchangeDiscard);

    // Det här är precis steget användaren rapporterade som "hängande":
    // att markera/slänga ett handkort under det vanliga bytet.
    final cardToDiscard = hostState.you.hand.first;
    final stack0Before = hostState.centerStacks['draw1']!;
    final error = hostNotifier.exchangeDiscard(cardToDiscard, 0);

    expect(error, isNull,
        reason: 'BUGG om detta INTE är null: kortet gick inte att slänga');
    final after = host.read(gameProvider);
    expect(after.tradePhase, TradePhase.exchangeDraw);
    expect(after.you.hand.contains(cardToDiscard), isFalse);
    expect(after.centerStacks['draw1'], stack0Before + 1);
  });
}
