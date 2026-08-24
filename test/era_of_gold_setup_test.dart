import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Gulderan-uppställningen (Steg 3–4 i utökningsplanen): 3
/// grundspels-draghögar à 12 + 2 Gulderan-draghögar à 11 (i stället för
/// 4 à 9 utan tema), samt den öppna ansikte-upp-högen med 2×
/// Köpmansgille som vem som helst kan bygga direkt från (se
/// [GameNotifier.buyFaceUpExpansion]).
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    return container;
  }

  group('uppställning (playLocally)', () {
    test('utan tema: 4 draghögar à 9, ingen ansikte-upp-hög', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).playLocally();

      final state = container.read(gameProvider);
      expect(state.faceUpExpansionCards, isEmpty);
      // you/opponent har redan fått sina starthänder (3 kort var) från
      // hög 1 respektive 2 (se playLocally-doc), så de är 9-3=6.
      expect(state.centerStacks['draw1'], 6);
      expect(state.centerStacks['draw2'], 6);
      expect(state.centerStacks['draw3'], 9);
      expect(state.centerStacks['draw4'], 9);
      expect(state.centerStacks.containsKey('draw5'), isFalse);
    });

    test('med Gulderan: 5 draghögar (3x12, 2x11) och 2 Köpmansgille ansikte-upp',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      container
          .read(gameProvider.notifier)
          .playLocally(expansions: {ExpansionSet.eraOfGold});

      final state = container.read(gameProvider);
      expect(state.faceUpExpansionCards, hasLength(2));
      expect(
        state.faceUpExpansionCards.map((c) => c.baseId).toSet(),
        {'city-expansion-merchant-guild'},
      );
      // Starthänderna dras från hög 1/2 (12 vardera), så 12-3=9.
      expect(state.centerStacks['draw1'], 9);
      expect(state.centerStacks['draw2'], 9);
      expect(state.centerStacks['draw3'], 12);
      expect(state.centerStacks['draw4'], 11);
      expect(state.centerStacks['draw5'], 11);
      expect(state.initialDrawStackSizes, [12, 12, 12, 11, 11]);
    });
  });

  group('buyFaceUpExpansion', () {
    late ProviderContainer container;
    late GameNotifier notifier;

    setUp(() {
      container = buildContainer();
      notifier = container.read(gameProvider.notifier);
      notifier.playLocally(expansions: {ExpansionSet.eraOfGold});
      notifier.rollProductionDie();
    });
    tearDown(() => container.dispose());

    test('bygger kortet, tar bort det ur den delade ansikte-upp-högen', () {
      final card = container.read(gameProvider).faceUpExpansionCards.first;

      final error = notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, card);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.faceUpExpansionCards, hasLength(1));
      expect(state.faceUpExpansionCards.contains(card), isFalse);
      expect(state.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          card.id);
    });

    test('avvisas om det inte är din tur/tärningen inte slagen', () {
      final container2 = buildContainer();
      addTearDown(container2.dispose);
      final notifier2 = container2.read(gameProvider.notifier);
      notifier2.playLocally(expansions: {ExpansionSet.eraOfGold});
      // Ingen rollProductionDie() här.
      final card = container2.read(gameProvider).faceUpExpansionCards.first;

      final error = notifier2.buyFaceUpExpansion(0, BuildingRow.above, 0, card);

      expect(error, isNotNull);
      expect(container2.read(gameProvider).faceUpExpansionCards, hasLength(2));
    });

    test('avvisar en andra kopia av samma unika kort (Köpmansgille)', () {
      final firstCard = container.read(gameProvider).faceUpExpansionCards.first;
      expect(notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, firstCard),
          isNull);

      final secondCard = container.read(gameProvider).faceUpExpansionCards.first;
      final error =
          notifier.buyFaceUpExpansion(2, BuildingRow.above, 0, secondCard);

      expect(error, 'Du kan bara ha en ${secondCard.name} i ditt rike.');
      expect(container.read(gameProvider).faceUpExpansionCards, hasLength(1));
    });

    test('en redan bebyggd plats byts ut mot det köpta kortet, det gamla hamnar i slänghögen',
        () {
      // Placerar direkt på riket (utan att gå via handen/dropExpansion)
      // – starthanden delas nu ut slumpmässigt från en riktig blandad
      // hög (se playLocally), så vi kan inte längre lita på att ett
      // specifikt grundspelskort råkar finnas där.
      const existing = BasicSetCards.storehouse;
      container.read(gameProvider).you.principality
          .placeExpansion(0, BuildingRow.above, 0, const PlacedCard(card: existing));
      expect(container.read(gameProvider).discardPile, isEmpty);

      final card = container.read(gameProvider).faceUpExpansionCards.first;
      final error = notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, card);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          card.id);
      expect(state.discardPile, hasLength(1));
      expect(state.discardPile.last.id, existing.id);
    });
  });

  group('online: activeExpansions/faceUpExpansionCards synkas till gästen', () {
    test('gästen ärver hostens temaval och ser samma ansikte-upp-hög/draghögsantal',
        () async {
      final fake = FakeGameSyncService();
      final hostContainer = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      final guestContainer = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(hostContainer.dispose);
      addTearDown(guestContainer.dispose);

      final roomCode = await hostContainer
          .read(gameProvider.notifier)
          .hostRoom('Astrid', expansions: {ExpansionSet.eraOfGold});
      await guestContainer.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');

      final hostState = hostContainer.read(gameProvider);
      final guestState = guestContainer.read(gameProvider);

      expect(guestState.activeExpansions, {ExpansionSet.eraOfGold});
      expect(guestState.victoryPointTarget, 12);
      expect(guestState.faceUpExpansionCards, hasLength(2));
      expect(
        guestState.faceUpExpansionCards.map((c) => c.id).toSet(),
        hostState.faceUpExpansionCards.map((c) => c.id).toSet(),
      );
      expect(guestState.centerStacks['draw5'], hostState.centerStacks['draw5']);
      expect(guestState.initialDrawStackSizes, [12, 12, 12, 11, 11]);
    });

    test(
        'resumeRoom (Gulderan): 5 draghögar byggs om med rätt storlek, ansikte-upp-högen (även efter ett köpt kort) stämmer',
        () async {
      final fake = FakeGameSyncService();
      final host = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      final guest = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(host.dispose);
      addTearDown(guest.dispose);

      final roomCode = await host
          .read(gameProvider.notifier)
          .hostRoom('Astrid', expansions: {ExpansionSet.eraOfGold});
      await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
      await pump();

      final hostNotifier = host.read(gameProvider.notifier);
      expect(hostNotifier.chooseStartingStack(0), isNull);
      await pump();
      expect(guest.read(gameProvider.notifier).chooseStartingStack(3), isNull);
      await pump();
      expect(hostNotifier.rollProductionDie(), isNull);
      await pump();

      // Köper ett av de två Köpmansgillena innan "omladdningen" – det
      // ska INTE räknas bort en gång till från Gulderans draghögspool
      // (se GameNotifier._reconstructDrawStacksFromKnownCards-doc: det
      // köpta kortet spåras via den synkade ansikte-upp-högen, inte via
      // draghögarna).
      final boughtCard = host.read(gameProvider).faceUpExpansionCards.first;
      expect(hostNotifier.buyFaceUpExpansion(0, BuildingRow.above, 0, boughtCard),
          isNull);
      await pump();

      final beforeState = host.read(gameProvider);
      expect(beforeState.faceUpExpansionCards, hasLength(1));

      final resumed = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(resumed.dispose);
      final error = await resumed
          .read(gameProvider.notifier)
          .resumeRoom(roomCode, 'host', 'Astrid');

      expect(error, isNull);
      final resumedState = resumed.read(gameProvider);
      expect(resumedState.activeExpansions, {ExpansionSet.eraOfGold});
      expect(resumedState.faceUpExpansionCards.map((c) => c.id).toSet(),
          beforeState.faceUpExpansionCards.map((c) => c.id).toSet());
      expect(resumedState.centerStacks, beforeState.centerStacks);

      final resumedNotifier = resumed.read(gameProvider.notifier);
      for (var i = 0; i < 5; i++) {
        expect(resumedNotifier.drawStack(i).length,
            resumedState.centerStacks['draw${i + 1}'],
            reason: 'draghög $i ska ha ombyggts med rätt antal kort');
      }

      // Spelet ska gå att fortsätta spela efter återanslutningen.
      expect(resumedNotifier.endActionPhase(), isNull);
    });
  });
}
