import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att slänghögen (se GameState.discardPile) synkas mellan två
/// riktiga klienter, precis som centerStacks – både spelade
/// handlingskort (discardActionCard) och kort som bytts ut vid ett
/// nytt bygge (dropExpansion, se game_notifier_test.dart för den
/// lokala varianten av byt-ut-mekaniken).
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  Future<(ProviderContainer, ProviderContainer)> connectedRoom() async {
    final fake = FakeGameSyncService();
    final host = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);

    // Slänghögen/byt-ut-mekaniken är bara aktiv med minst ett tema (se
    // GameNotifier._discardToPile/_checkReplaceAllowed-doc).
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
      'ett spelat handlingskort hamnar i slänghögen och synkas till motståndarens klient',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.rollProductionDie(), isNull);
    // Starthanden lottas fram ur en riktigt blandad stapel online (till
    // skillnad från game_notifier_test.dart:s fasta mock-hand), så
    // kortet vi vill spela läggs till direkt i stället för att antas
    // finnas där redan.
    const card = BasicSetCards.merchantCaravan;
    host.read(gameProvider).you.hand.add(card);

    expect(hostNotifier.discardActionCard(card), isNull);
    await pump();

    final guestState = guest.read(gameProvider);
    expect(guestState.discardPile, hasLength(1),
        reason: 'gästens klient ska se det spelade kortet i slänghögen');
    expect(guestState.discardPile.last.id, card.id);
  });

  test(
      'ett utbytt byggkort (dropExpansion på en upptagen plats) hamnar i slänghögen och synkas',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.rollProductionDie(), isNull);
    const storehouse = BasicSetCards.storehouse;
    const siglind = BasicSetCards.siglind;
    host.read(gameProvider).you.hand.addAll([storehouse, siglind]);

    expect(
        hostNotifier.dropExpansion(0, BuildingRow.above, 0, storehouse),
        isNull);
    expect(
        hostNotifier.dropExpansion(0, BuildingRow.above, 0, siglind), isNull);
    await pump();

    final guestState = guest.read(gameProvider);
    expect(guestState.discardPile, hasLength(1));
    expect(guestState.discardPile.last.id, storehouse.id);
    expect(guestState.opponent.principality.settlementAt(0)!.aboveSites[0]!.card.id,
        siglind.id);
  });
}
