import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Sebastian, den vandrande predikanten (Oroligheternas tid):
/// "spelbar vid händelserna Upplopp, Fejd eller Brödrafejd – gäller
/// inte dig, inget händer" (se
/// [GameNotifier.playSebastianForCurrentEvent]/
/// TurnState.sebastianProtectedPlayerIds-doc). Samma
/// giveStrength/giveBuilding/forceFeudCard-hjälpare som feud_test.dart.
void main() {
  // _discardToPile (se GameNotifier-doc) är bara aktiv med minst ett
  // tema aktivt, så till skillnad från feud_test.dart:s
  // temalösa readyContainer() krävs playLocally med Oroligheternas
  // tid här för att kunna verifiera att Sebastian faktiskt hamnar i
  // slänghögen.
  ProviderContainer readyContainer() {
    final container = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())]);
    container
        .read(gameProvider.notifier)
        .playLocally(expansions: {ExpansionSet.eraOfTurmoil});
    return container;
  }

  void giveStrength(Player player, int strength) {
    player.principality.placeExpansion(
      0,
      BuildingRow.above,
      0,
      PlacedCard(
          card: BasicSetCards.harald.copyWith(strengthPoints: strength)),
    );
  }

  void giveBuilding(Player player) {
    player.principality.placeExpansion(
        2, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));
  }

  void forceEventCard(ProviderContainer container, GameCard card) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state =
        container.read(gameProvider).copyWith(drawnEventCard: card);
  }

  void giveSebastian(ProviderContainer container) {
    final notifier = container.read(gameProvider.notifier);
    final you = container.read(gameProvider).you;
    notifier.state = container.read(gameProvider).copyWith(
        you: you.copyWith(hand: [
      ...you.hand,
      EraOfTurmoilCards.sebastianTheItinerantPreacher
    ]));
  }

  group('playSebastianForCurrentEvent – grundfall', () {
    test('no-op utan uppslaget händelsekort', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveSebastian(container);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.playSebastianForCurrentEvent(), isNull);
      expect(container.read(gameProvider).sebastianProtectedPlayerIds, isEmpty);
    });

    test('no-op för ett händelsekort som inte går att skydda sig mot (Jul)',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveSebastian(container);
      forceEventCard(container, BasicSetCards.yule);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.playSebastianForCurrentEvent(), isNull);
      expect(container.read(gameProvider).sebastianProtectedPlayerIds, isEmpty);
      expect(
          container.read(gameProvider).you.hand.any((c) =>
              c.baseId == EraOfTurmoilCards.sebastianTheItinerantPreacher.id),
          isTrue);
    });

    test('no-op utan Sebastian på handen', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      forceEventCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.playSebastianForCurrentEvent(), isNull);
      expect(container.read(gameProvider).sebastianProtectedPlayerIds, isEmpty);
    });

    test('no-op om du redan skyddat dig mot det uppslagna kortet', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      forceEventCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);
      notifier.state = container
          .read(gameProvider)
          .copyWith(sebastianProtectedPlayerIds: const {'you'});

      // Ett andra Sebastian-kort (om spelaren mot förmodan hade ett kvar
      // efter att redan ha skyddat sig) ska inte gå att spela igen mot
      // samma kort.
      giveSebastian(container);
      expect(notifier.playSebastianForCurrentEvent(), isNull);
      expect(
          container.read(gameProvider).you.hand.where((c) =>
              c.baseId == EraOfTurmoilCards.sebastianTheItinerantPreacher.id),
          hasLength(1),
          reason: 'det andra Sebastian-kortet ska ligga kvar orört');
    });
  });

  group('Fejd', () {
    test(
        'du (utan övertaget) spelar Sebastian: skyddad, kortet läggs i slänghögen, startFeudBuildingPick blir no-op',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      giveBuilding(container.read(gameProvider).you);
      forceEventCard(container, BasicSetCards.feud);
      giveSebastian(container);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.playSebastianForCurrentEvent(), isNull);
      final state = container.read(gameProvider);
      expect(state.sebastianProtectedPlayerIds, contains('you'));
      expect(
          state.you.hand.any((c) =>
              c.baseId == EraOfTurmoilCards.sebastianTheItinerantPreacher.id),
          isFalse);
      expect(state.discardPile.last.baseId,
          EraOfTurmoilCards.sebastianTheItinerantPreacher.id);
      // Byggnaden ska vara orörd – Fejd gäller inte längre dig.
      expect(state.you.principality.settlementAt(2)!.belowSites[0], isNotNull);

      final pickError = notifier.startFeudBuildingPick();
      expect(pickError, isNull);
      expect(container.read(gameProvider).feudBuildingPickActive, isFalse);
    });

    test(
        'motståndaren (den drabbade) redan skyddad: startFeudBuildingPick förblir no-op även om du saknar övertaget',
        () {
      // Detta testar bara att skyddet gäller den SKYDDADE sidan, inte
      // att du plötsligt får övertaget – här är det ändå du som saknar
      // övertaget och skulle behövt välja bort en byggnad, men eftersom
      // DU är den som markerats skyddad (samma spelare, se
      // playSebastianForCurrentEvent-doc: skyddet sätts alltid på
      // state.myPlayerId) blir det no-op.
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      giveBuilding(container.read(gameProvider).you);
      forceEventCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);
      notifier.state = container
          .read(gameProvider)
          .copyWith(sebastianProtectedPlayerIds: const {'you'});

      expect(notifier.startFeudBuildingPick(), isNull);
      expect(container.read(gameProvider).feudBuildingPickActive, isFalse);
    });
  });

  group('Brödrafejd', () {
    test(
        'du (utan övertaget) spelar Sebastian: skyddad, kortet läggs i slänghögen',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      forceEventCard(container, BasicSetCards.fraternalFeuds);
      giveSebastian(container);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.playSebastianForCurrentEvent(), isNull);
      final state = container.read(gameProvider);
      expect(state.sebastianProtectedPlayerIds, contains('you'));
      expect(state.discardPile.last.baseId,
          EraOfTurmoilCards.sebastianTheItinerantPreacher.id);
    });

    test(
        'motståndaren (den med övertaget) kan inte starta handväljaren när den drabbade redan är skyddad',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).you, 2);
      forceEventCard(container, BasicSetCards.fraternalFeuds);
      final notifier = container.read(gameProvider.notifier);
      // Simulerar att motståndaren (state.opponentPlayerId) redan
      // skyddat sig – i lokalt läge kan bara "you" faktiskt anropa
      // playSebastianForCurrentEvent, så här sätts flaggan direkt
      // (samma mönster som forceEventCard/andra direkta state-override
      // i feud_test.dart) för att testa startFraternalFeudsPicks EGEN
      // spärr.
      notifier.state = container
          .read(gameProvider)
          .copyWith(sebastianProtectedPlayerIds: const {'opponent'});

      final error = notifier.startFraternalFeudsPick();

      expect(error, isNull);
      expect(container.read(gameProvider).fraternalFeudsPicking, isFalse);
    });
  });

  group('Upplopp', () {
    test(
        'spelar Sebastian: skyddad, kortet läggs i slänghögen, räknas som din egen färdiga hantering',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      forceEventCard(container, EraOfTurmoilCards.riots);
      giveSebastian(container);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.playSebastianForCurrentEvent(), isNull);
      final state = container.read(gameProvider);
      expect(state.sebastianProtectedPlayerIds, contains('you'));
      expect(state.riotsResolvedPlayerIds, contains('you'));
      expect(state.discardPile.last.baseId,
          EraOfTurmoilCards.sebastianTheItinerantPreacher.id);
      // Lokalt läge: ingen egen motståndarvy, så båda räknas klara så
      // fort du är det (samma bothDone-resonemang som riots_test.dart).
      expect(state.drawnEventCard, isNull);
    });
  });

  group('online (två klienter) – Fejd', () {
    test(
        'gästen (drabbad) spelar Sebastian: hostens dismissEventCard väntar inte längre på gästen',
        () async {
      Future<void> pump() => Future<void>.delayed(Duration.zero);
      final fake = FakeGameSyncService();
      final host = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      final guest = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(host.dispose);
      addTearDown(guest.dispose);

      final roomCode =
          await host.read(gameProvider.notifier).hostRoom('Astrid');
      await pump();
      await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
      await pump();
      expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
      await pump();
      expect(
          guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
      await pump();

      // Host har övertaget, gästen har en byggnad att förlora och
      // Sebastian på handen.
      host.read(gameProvider).you.principality.placeExpansion(
          0,
          BuildingRow.above,
          0,
          PlacedCard(card: BasicSetCards.harald.copyWith(strengthPoints: 3)));
      guest.read(gameProvider).you.principality.placeExpansion(
          2, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));
      host.read(gameProvider.notifier).adjustRegionResource(-1, BuildingRow.above, 0);
      final guestNotifier = guest.read(gameProvider.notifier);
      guestNotifier.state = guest.read(gameProvider).copyWith(
          you: guest.read(gameProvider).you.copyWith(hand: [
        ...guest.read(gameProvider).you.hand,
        EraOfTurmoilCards.sebastianTheItinerantPreacher
      ]));
      guestNotifier.adjustRegionResource(-1, BuildingRow.above, 0);
      await pump();

      final hostNotifier = host.read(gameProvider.notifier);
      hostNotifier.state =
          host.read(gameProvider).copyWith(drawnEventCard: BasicSetCards.feud);
      guestNotifier.state = guest
          .read(gameProvider)
          .copyWith(drawnEventCard: BasicSetCards.feud);

      // Gästen (utan övertaget, drabbad) skyddar sig innan hosten
      // hinner trycka OK.
      expect(guestNotifier.playSebastianForCurrentEvent(), isNull);
      await pump();
      expect(guest.read(gameProvider).sebastianProtectedPlayerIds,
          contains('guest'));
      expect(host.read(gameProvider).sebastianProtectedPlayerIds,
          contains('guest'),
          reason: 'skyddet ska synkas till hostens klient via TurnState');

      // Hosten trycker OK – ska INTE fastna och vänta på gästen, eftersom
      // gästen redan är skyddad (se dismissEventCard-fixen).
      expect(hostNotifier.dismissEventCard(), isNull);
      await pump();

      expect(host.read(gameProvider).drawnEventCard, isNull);
      expect(guest.read(gameProvider).drawnEventCard, isNull);
      // Byggnaden ska vara orörd.
      expect(guest.read(gameProvider).you.principality.settlementAt(2)!
          .belowSites[0], isNotNull);
    });
  });
}
