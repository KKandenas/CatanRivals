import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Vakttorn över två riktiga klienter (se lookout_tower_test.dart
/// för notifier-testerna med en enda container) – host spelar Bågskytt
/// mot gästen, som har Vakttorn: gästens klient ska se det väntande
/// försvarsslaget (synkat via TurnState.pendingDefenseRollCard), och
/// utfallet av gästens tärningsslag ska synkas tillbaka till host.
void main() {
  const heroUnit = EraOfTurmoilCards.carlForkbeard;
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  Future<(ProviderContainer, ProviderContainer)> connectedRoom() async {
    final fake = FakeGameSyncService();
    final host = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);

    final roomCode = await host
        .read(gameProvider.notifier)
        .hostRoom('Astrid', expansions: {ExpansionSet.eraOfTurmoil});
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
      'host spelar Bågskytt mot gästen (som har Vakttorn): gästen ser försvarsslaget, utfallet synkas till host',
      () async {
    final (host, guest) = await connectedRoom();
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    guest.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.lookoutTower));
    guest.read(gameProvider).you.principality.placeExpansion(
        2, BuildingRow.above, 0, const PlacedCard(card: heroUnit));
    guest.read(gameProvider.notifier).adjustRegionResource(-1, BuildingRow.above, 0);
    await pump();

    final hostNotifier = host.read(gameProvider.notifier);
    host.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.hedgeTavern));
    hostNotifier.state = host.read(gameProvider).copyWith(
        diceRolled: true,
        you: host.read(gameProvider).you.copyWith(
            hand: [...host.read(gameProvider).you.hand, EraOfTurmoilCards.archer]));

    expect(hostNotifier.useArcher(), isNull);
    await pump();

    expect(host.read(gameProvider).pendingDefenseRollCard,
        EraOfTurmoilCards.archer.id);
    expect(guest.read(gameProvider).pendingDefenseRollCard,
        EraOfTurmoilCards.archer.id,
        reason: 'gästens klient ska se det synkade försvarsslaget');
    expect(host.read(gameProvider).pendingAttackCard, isNull,
        reason: 'attacken väntar på gästens tärningsslag');

    final guestNotifier = guest.read(gameProvider.notifier);
    final message = guestNotifier.rollLookoutTowerDefense();
    expect(message, isNotNull);
    await pump();

    final guestState = guest.read(gameProvider);
    expect(guestState.pendingDefenseRollCard, isNull);
    final hostState = host.read(gameProvider);
    expect(hostState.pendingDefenseRollCard, isNull,
        reason: 'utfallet ska synkas tillbaka till host via TurnState');
    expect(hostState.pendingAttackCard, guestState.pendingAttackCard,
        reason: 'båda klienterna ska se samma utfall (skyddad eller inte)');
  });
}
