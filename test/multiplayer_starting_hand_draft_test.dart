import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar starthandsutdelningen (kika-och-välj-3) OCH den fria
/// regionomflyttningen som följer direkt efter, med ett tema aktivt
/// (se starting_hand_draft_test.dart/starting_region_rearrangement_test.dart
/// för notifier-nivå-testerna var för sig) över två riktiga klienter,
/// delar en [FakeGameSyncService] – motsvarande mönster som
/// multiplayer_fraternal_feuds_test.dart. Fokus här: att
/// centerStacks/handsReady/isMyTurnToChooseHand hos BÅDA klienterna
/// bara ändras efter HELA sekvensen (kortval -> ev. regionbyten ->
/// "Klar"), aldrig stegvis och aldrig redan vid tredje kortvalet.
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

  test(
      'host drar sin starthand och flyttar om regioner: gästens tur väntar genom HELA sekvensen, ända till "Klar"',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    expect(host.read(gameProvider).isMyTurnToChooseHand, isTrue);
    expect(guest.read(gameProvider).isMyTurnToChooseHand, isFalse);

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.startHandDraft(0), isNull);
    final pool = host.read(gameProvider).startingHandDraftPool!;
    await pump();

    // Rent lokalt UI-state hos host tills tredje kortet är valt - inget
    // ska ha synkats till gästen än.
    expect(guest.read(gameProvider).centerStacks['draw1'], 12);
    expect(guest.read(gameProvider).opponent.hand, isEmpty);
    expect(guest.read(gameProvider).isMyTurnToChooseHand, isFalse);

    expect(hostNotifier.pickHandDraftCard(pool[0]), isNull);
    await pump();
    expect(guest.read(gameProvider).centerStacks['draw1'], 12);
    expect(guest.read(gameProvider).isMyTurnToChooseHand, isFalse);

    expect(hostNotifier.pickHandDraftCard(pool[1]), isNull);
    await pump();
    expect(guest.read(gameProvider).centerStacks['draw1'], 12);
    expect(guest.read(gameProvider).isMyTurnToChooseHand, isFalse);

    // Tredje kortet: handen/centerStacks synkas i ett svep, men
    // hasDrawnStartingHand sätts INTE än – regionomflyttningen börjar.
    expect(hostNotifier.pickHandDraftCard(pool[2]), isNull);
    await pump();

    var guestState = guest.read(gameProvider);
    expect(guestState.centerStacks['draw1'], 9);
    expect(guestState.opponent.hand, hasLength(3));
    expect(host.read(gameProvider).startingRegionRearrangementActive, isTrue);
    expect(guestState.isMyTurnToChooseHand, isFalse,
        reason: 'regionomflyttningen pågår fortfarande hos host, gästens '
            'tur ska inte börja förrän host trycker Klar');

    // Några regionbyten – fortfarande inte gästens tur.
    expect(
        hostNotifier.selectRegionRearrangementTarget(-1, BuildingRow.above),
        isNull);
    expect(
        hostNotifier.selectRegionRearrangementTarget(1, BuildingRow.above),
        isNull);
    await pump();
    expect(guest.read(gameProvider).isMyTurnToChooseHand, isFalse);

    // "Klar": nu, och först nu, släpps gästens tur fram.
    expect(hostNotifier.finishRegionRearrangement(), isNull);
    await pump();

    guestState = guest.read(gameProvider);
    expect(guestState.isMyTurnToChooseHand, isTrue);
    expect(host.read(gameProvider).startingRegionRearrangementActive, isFalse);

    // Gästen tar sin egen starthand och flyttar om, precis som host.
    final guestNotifier = guest.read(gameProvider.notifier);
    expect(guestNotifier.startHandDraft(1), isNull);
    final guestPool = guest.read(gameProvider).startingHandDraftPool!;
    guestNotifier.pickHandDraftCard(guestPool[0]);
    guestNotifier.pickHandDraftCard(guestPool[1]);
    guestNotifier.pickHandDraftCard(guestPool[2]);
    await pump();

    expect(host.read(gameProvider).handsReady, isFalse,
        reason: 'gästens regionomflyttning pågår fortfarande');
    expect(guestNotifier.finishRegionRearrangement(), isNull);
    await pump();

    expect(host.read(gameProvider).handsReady, isTrue);
    expect(guest.read(gameProvider).handsReady, isTrue);
    expect(host.read(gameProvider).opponent.hand, hasLength(3));
  });

  test('gästen kan inte välja en Gulderan-egen hög för sin starthand',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    hostNotifier.startHandDraft(0);
    final pool = host.read(gameProvider).startingHandDraftPool!;
    hostNotifier.pickHandDraftCard(pool[0]);
    hostNotifier.pickHandDraftCard(pool[1]);
    hostNotifier.pickHandDraftCard(pool[2]);
    hostNotifier.finishRegionRearrangement();
    await pump();

    final guestNotifier = guest.read(gameProvider.notifier);
    expect(guestNotifier.startHandDraft(3), isNull);
    expect(guest.read(gameProvider).startingHandDraftStackIndex, isNull);
  });
}
