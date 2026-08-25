import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Piratskepp över två riktiga klienter (se pirate_ship_test.dart
/// för notifier-testerna med en enda container) – till skillnad från
/// Fejd (som härleds ur redan synkad data, se
/// TurnState.pirateShipDiscardPending-doc) triggas Piratskepp av ett
/// engångsbygge, så en riktig synkad flagga krävs: bygger host ett
/// Piratskepp ska GÄSTEN se väntar-flaggan (inte tvärtom), välja bort
/// sitt eget handelsskepp, och flaggan ska rensas hos BÅDA.
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
      'host bygger Piratskepp: gästen ser väntar-flaggan, väljer bort sitt handelsskepp, flaggan rensas hos båda',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    // Gästen får ett handelsskepp – muterar bara den lokala kopian,
    // synkas manuellt nedan precis som i multiplayer_feud_test.dart.
    guest.read(gameProvider).you.principality.placeExpansion(2,
        BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.largeTradeShip));
    guest.read(gameProvider.notifier).adjustRegionResource(-1, BuildingRow.above, 0);
    await pump();
    expect(
        host.read(gameProvider).opponent.principality.hasAnyTradeShip, isTrue,
        reason: 'host ska se gästens handelsskepp via den synkade principality-datan');

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.rollProductionDie(), isNull);
    host.read(gameProvider).you.hand.add(EraOfGoldCards.pirateShip);

    final buildError =
        hostNotifier.dropExpansion(0, BuildingRow.above, 0, EraOfGoldCards.pirateShip);
    expect(buildError, isNull);
    await pump();

    expect(host.read(gameProvider).pirateShipDiscardPending, isTrue);
    expect(guest.read(gameProvider).pirateShipDiscardPending, isTrue,
        reason: 'gästens klient ska se den synkade väntar-flaggan via TurnState');

    final guestNotifier = guest.read(gameProvider.notifier);
    final resolveError =
        guestNotifier.resolvePirateShipDiscard(2, BuildingRow.below, 0);
    expect(resolveError, isNull);
    await pump();

    final guestState = guest.read(gameProvider);
    expect(guestState.pirateShipDiscardPending, isFalse);
    expect(guestState.you.principality.settlementAt(2)!.belowSites[0], isNull);
    expect(guestState.discardPile, hasLength(1));
    expect(guestState.discardPile.last.id, BasicSetCards.largeTradeShip.id);

    final hostState = host.read(gameProvider);
    expect(hostState.pirateShipDiscardPending, isFalse,
        reason: 'väntar-flaggan ska rensas hos BÅDA, inte bara hos gästen som löste den');
    expect(
        hostState.opponent.principality.settlementAt(2)!.belowSites[0], isNull,
        reason: 'host ska se att skeppet försvann från gästens (motståndarens) rike');
  });

  test(
      'host bygger Piratskepp men gästen saknar handelsskepp: ingen flagga sätts hos någon',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final hostNotifier = host.read(gameProvider.notifier);
    expect(hostNotifier.rollProductionDie(), isNull);
    host.read(gameProvider).you.hand.add(EraOfGoldCards.pirateShip);

    final buildError =
        hostNotifier.dropExpansion(0, BuildingRow.above, 0, EraOfGoldCards.pirateShip);
    expect(buildError, isNull);
    await pump();

    expect(host.read(gameProvider).pirateShipDiscardPending, isFalse);
    expect(guest.read(gameProvider).pirateShipDiscardPending, isFalse);
  });
}
