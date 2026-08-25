import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/event_die_resolution.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Upplopp (Oroligheternas tid, EraOfTurmoilCards.riots):
/// "En spelare som har 1-2 enheter med styrke- eller handelspoäng
/// betalar 1 guld. Har spelaren fler betalar hen 2 guld. Betalar
/// spelaren inte måste hen ta bort en av dessa enheter och lägga den
/// underst i motsvarande draghög." Till skillnad från Fejd/Brödrafejd
/// (bara EN sida agerar) kan BÅDA spelarna behöva agera oberoende av
/// varandra (se GameNotifier._finishRiotsForMe/
/// TurnState.riotsResolvedPlayerIds).
void main() {
  // Ett enkelt "enhet med styrkepoäng"-testkort (hjälte, 5 styrkepoäng).
  const unitCard = EraOfTurmoilCards.carlForkbeard;

  group('riotsQualifyingUnitCount / riotsGoldOwed (rena funktioner)', () {
    test('0 enheter: 0 guld', () {
      expect(riotsGoldOwed(0), 0);
    });
    test('1-2 enheter: 1 guld', () {
      expect(riotsGoldOwed(1), 1);
      expect(riotsGoldOwed(2), 1);
    });
    test('fler än 2 enheter: 2 guld', () {
      expect(riotsGoldOwed(3), 2);
      expect(riotsGoldOwed(7), 2);
    });

    test('räknar bara enheter med styrke- ELLER handelspoäng, inte regioner',
        () {
      final board = RealmBoard(ownerId: 'test');
      board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
      final player = Player(id: 'you', name: 'Astrid', principality: board);

      expect(riotsQualifyingUnitCount(player), 1);
    });
  });

  group('lokalt läge (bara du spelar, se playLocally-doc)', () {
    ProviderContainer buildContainer() {
      final container = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
      );
      final notifier = container.read(gameProvider.notifier);
      notifier.playLocally(expansions: {ExpansionSet.eraOfTurmoil});
      final state = container.read(gameProvider);
      notifier.state = state.copyWith(
          diceRolled: true, drawnEventCard: EraOfTurmoilCards.riots);
      return container;
    }

    test('resolveRiotsPay: stänger kortet direkt (ingen motståndare att vänta på)',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: unitCard));

      expect(notifier.resolveRiotsPay(), isNull);

      final state = container.read(gameProvider);
      expect(state.drawnEventCard, isNull);
      expect(state.riotsResolvedPlayerIds, contains('you'));
    });

    test('startRiotsUnitPick: no-op utan kvalificerande enhet', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      // MockGame-startriket har inga enheter placerade från start.

      expect(notifier.startRiotsUnitPick(), isNull);
      expect(container.read(gameProvider).riotsUnitPickActive, isFalse);
    });

    test(
        'Kan inte betala: väljer en enhet och lägger den underst i rätt draghög',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: unitCard));

      expect(notifier.startRiotsUnitPick(), isNull);
      expect(container.read(gameProvider).riotsUnitPickActive, isTrue);

      expect(notifier.selectRiotsUnit(0, BuildingRow.above, 0), isNull);
      expect(container.read(gameProvider).riotsPickedUnit, isNotNull);

      // I den aktiva 3+2-uppställningen (Oroligheternas tid) är index
      // 0-2 grundspelet, 3-4 Oroligheternas tid – unitCard är ett bart
      // mallkort (inget "-turmoil-draw-"-suffix) och hör därför hemma i
      // en grundspelshög.
      final wrongError = notifier.resolveRiotsUnitRemoval(3);
      expect(wrongError, isNotNull);
      expect(
          container
              .read(gameProvider)
              .you
              .principality
              .settlementAt(0)!
              .aboveSites[0],
          isNotNull,
          reason: 'enheten ska ligga kvar tills rätt hög väljs');

      final okError = notifier.resolveRiotsUnitRemoval(0);
      expect(okError, isNull);
      final state = container.read(gameProvider);
      expect(
          state.you.principality.settlementAt(0)!.aboveSites[0], isNull);
      expect(notifier.drawStack(0).last.id, unitCard.id);
      expect(state.drawnEventCard, isNull);
      expect(state.riotsUnitPickActive, isFalse);
      expect(state.riotsResolvedPlayerIds, contains('you'));
    });

    test('avbryter enhetsväljaren utan att ta bort något', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
      notifier.startRiotsUnitPick();
      notifier.selectRiotsUnit(0, BuildingRow.above, 0);

      expect(notifier.cancelRiotsUnitPick(), isNull);

      final state = container.read(gameProvider);
      expect(state.riotsUnitPickActive, isFalse);
      expect(state.riotsPickedUnit, isNull);
      expect(
          state.you.principality.settlementAt(0)!.aboveSites[0], isNotNull,
          reason: 'enheten ska inte ha tagits bort');
    });
  });

  group('_checkCanBuild-spärr', () {
    test('går inte att bygga medan enhetsväljaren är aktiv', () {
      final container = ProviderContainer(
        overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
      );
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.playLocally(expansions: {ExpansionSet.eraOfTurmoil});
      final state = container.read(gameProvider);
      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
      notifier.state = state.copyWith(
          diceRolled: true, drawnEventCard: EraOfTurmoilCards.riots);
      notifier.startRiotsUnitPick();

      final error = notifier.discardActionCard(BasicSetCards.merchantCaravan);
      expect(error, isNotNull);
      expect(error, contains('händelsekortet'));
    });
  });

  group('online (två klienter)', () {
    test(
        'kortet stängs inte förrän BÅDA spelarna avslutat sin egen Upplopp-hantering',
        () async {
      Future<void> pump() => Future<void>.delayed(Duration.zero);
      final fake = FakeGameSyncService();
      final host = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      final guest = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(host.dispose);
      addTearDown(guest.dispose);

      final roomCode = await host.read(gameProvider.notifier).hostRoom('Astrid');
      await pump();
      await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
      await pump();
      host.read(gameProvider.notifier).chooseStartingStack(0);
      await pump();
      guest.read(gameProvider.notifier).chooseStartingStack(1);
      await pump();

      final hostNotifier = host.read(gameProvider.notifier);
      hostNotifier.state = host
          .read(gameProvider)
          .copyWith(diceRolled: true, drawnEventCard: EraOfTurmoilCards.riots);
      await pump();

      // Bara host betalar/löser sin del än så länge.
      expect(hostNotifier.resolveRiotsPay(), isNull);
      await pump();

      // Kortet ska fortfarande vara uppslaget hos BÅDA – gästen har inte
      // avslutat sin egen hantering än.
      expect(host.read(gameProvider).drawnEventCard, isNotNull);
      expect(guest.read(gameProvider).drawnEventCard, isNotNull);
      expect(guest.read(gameProvider).riotsResolvedPlayerIds, contains('host'));

      final guestNotifier = guest.read(gameProvider.notifier);
      expect(guestNotifier.resolveRiotsPay(), isNull);
      await pump();

      // Nu är båda klara – kortet stängs för båda.
      expect(host.read(gameProvider).drawnEventCard, isNull);
      expect(guest.read(gameProvider).drawnEventCard, isNull);
    });
  });
}
