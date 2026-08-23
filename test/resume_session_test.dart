import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att en "sidladdning" (se lobby_screen.dart:s
/// [SessionStorage]-koll och [GameNotifier.resumeRoom]/
/// `resumeLocalSnapshot`) kan återuppta både ett online-rum och ett
/// helt lokalt spel utan att tappa spelarnas hand/rike eller synken
/// mellan klienterna.
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('resumeRoom (online)', () {
    test(
        'host: en ny klient som återansluter får samma hand/rike/omgång, och draghögarna stämmer i antal',
        () async {
      final fake = FakeGameSyncService();
      final host = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      final guest = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(host.dispose);
      addTearDown(guest.dispose);

      final roomCode = await host.read(gameProvider.notifier).hostRoom('Astrid');
      await pump();
      await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
      await pump();

      expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
      await pump();
      expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
      await pump();

      final hostNotifier = host.read(gameProvider.notifier);
      expect(hostNotifier.rollProductionDie(), isNull);
      // Bygg en väg så att riket (och alltså också "kända kort" som
      // ombyggnaden av draghögarna ska räkna bort) skiljer sig från
      // startuppställningen.
      final before = host.read(gameProvider);
      before.you.principality.addResourceToRegion(-1, BuildingRow.below, 1);
      expect(hostNotifier.dropRoad(-1, BasicSetCards.road), isNull);
      await pump();

      final beforeState = host.read(gameProvider);

      // Simulerar att host-klienten laddar om sidan: en helt ny
      // ProviderContainer/GameNotifier, utan någon lokal kunskap om
      // vare sig handen eller draghögarnas innehåll – bara rumskoden
      // och rollen (sparad i localStorage före omladdningen).
      final resumed = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(resumed.dispose);
      final error = await resumed
          .read(gameProvider.notifier)
          .resumeRoom(roomCode, 'host', 'Astrid');

      expect(error, isNull);
      final resumedState = resumed.read(gameProvider);
      expect(resumedState.you.hand.map((c) => c.id).toSet(),
          beforeState.you.hand.map((c) => c.id).toSet());
      expect(resumedState.you.principality.roads.containsKey(-1), isTrue);
      expect(resumedState.centerStacks, beforeState.centerStacks);
      expect(resumedState.activePlayerId, beforeState.activePlayerId);
      expect(resumedState.mode, SessionMode.host);
      expect(resumedState.myPlayerId, 'host');
      expect(resumedState.opponentPlayerId, 'guest');
      expect(resumedState.opponent.name, 'Björn');

      // Kritiskt: de ombyggda draghögarnas STORLEK måste stämma exakt
      // med det synkade antalet – annars kraschar ett senare drag.
      final resumedNotifier = resumed.read(gameProvider.notifier);
      for (var i = 0; i < 4; i++) {
        expect(resumedNotifier.drawStack(i).length,
            resumedState.centerStacks['draw${i + 1}']);
      }

      // Och spelet ska gå att fortsätta spela efter återanslutningen.
      expect(resumedNotifier.endActionPhase(), isNull);
    });

    test(
        'en väntande Brödrafejd-förfrågan (skickad medan klienten var nere) tillämpas vid återanslutningen',
        () async {
      final fake = FakeGameSyncService();
      final host = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      final guest = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(host.dispose);
      addTearDown(guest.dispose);

      final roomCode = await host.read(gameProvider.notifier).hostRoom('Astrid');
      await pump();
      await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
      await pump();
      expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
      await pump();
      expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
      await pump();

      final guestHand = List<GameCard>.of(guest.read(gameProvider).you.hand);
      expect(guestHand.length, greaterThanOrEqualTo(2));

      // Motsvarar att host (med styrkeövertaget) valde 2 kort ur
      // gästens hand precis INNAN gästen laddade om sidan – förfrågan
      // hann alltså skrivas, men gästens (nu nedstängda) klient hann
      // aldrig se den live.
      await fake.writeFraternalFeudsRequest(
        roomCode,
        FraternalFeudsRequest(
          requesterId: 'host',
          cardIds: [guestHand[0].id, guestHand[1].id],
          stackIndices: [0, 2],
        ),
      );

      final resumedGuest = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(resumedGuest.dispose);
      final error = await resumedGuest
          .read(gameProvider.notifier)
          .resumeRoom(roomCode, 'guest', 'Björn');

      expect(error, isNull);
      final resumedState = resumedGuest.read(gameProvider);
      expect(resumedState.you.hand.any((c) => c.id == guestHand[0].id), isFalse,
          reason: 'den väntande förfrågan ska ha tillämpats vid återanslutningen');
      expect(resumedState.you.hand.any((c) => c.id == guestHand[1].id), isFalse);

      // Förfrågan ska vara rensad så den inte tillämpas igen.
      final stillPending =
          await fake.watchFraternalFeudsRequest(roomCode).first;
      expect(stillPending, isNull);
    });

    test('okänt rum: felmeddelande i stället för krasch', () async {
      final fake = FakeGameSyncService();
      final container = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);

      final error = await container
          .read(gameProvider.notifier)
          .resumeRoom('SAKNAS', 'host', 'Astrid');

      expect(error, isNotNull);
    });
  });

  group('buildLocalSnapshotJson / resumeLocalSnapshot (lokalt läge)', () {
    test('rundtur bevarar hand, rike, draghögar och omgångsläge', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.playLocally();
      notifier.rollProductionDie();
      final before = container.read(gameProvider);
      before.you.principality.addResourceToRegion(-1, BuildingRow.below, 1);
      expect(notifier.dropRoad(-1, BasicSetCards.road), isNull);

      final beforeState = container.read(gameProvider);
      final beforeDrawStacks = [for (var i = 0; i < 4; i++) notifier.drawStack(i)];
      final json = notifier.buildLocalSnapshotJson();

      // En ny notifier (motsvarar en sidladdning) återställs helt från
      // det sparade JSON-ögonblicket.
      final resumedContainer = ProviderContainer();
      addTearDown(resumedContainer.dispose);
      final resumedNotifier = resumedContainer.read(gameProvider.notifier);
      resumedNotifier.resumeLocalSnapshot(json);

      final resumedState = resumedContainer.read(gameProvider);
      expect(resumedState.you.hand.map((c) => c.id).toList(),
          beforeState.you.hand.map((c) => c.id).toList());
      expect(resumedState.you.principality.roads.containsKey(-1), isTrue);
      expect(resumedState.centerStacks, beforeState.centerStacks);
      expect(resumedState.activePlayerId, beforeState.activePlayerId);
      expect(resumedState.diceRolled, beforeState.diceRolled);
      for (var i = 0; i < 4; i++) {
        expect(resumedNotifier.drawStack(i).map((c) => c.id).toList(),
            beforeDrawStacks[i].map((c) => c.id).toList());
      }
    });
  });

  group('leaveGame', () {
    test('återställer till lokalt läge', () async {
      final fake = FakeGameSyncService();
      final container = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      await notifier.hostRoom('Astrid');

      notifier.leaveGame();

      expect(container.read(gameProvider).mode, SessionMode.local);
      expect(container.read(gameProvider).roomCode, isNull);
    });
  });
}
