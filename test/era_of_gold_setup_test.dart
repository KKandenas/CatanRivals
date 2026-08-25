import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Gulderan-uppställningen: 3 grundspels-draghögar à 12 + 2
/// Gulderan-draghögar à 11 (i stället för 4 à 9 utan tema), samt
/// ansikte-upp-kortet Köpmansgille – VARJE spelare har sin EGEN,
/// separata plats med som mest 1 eget kort (se
/// [Player.faceUpExpansionCard]-doc), inte en delad hög båda kan bygga
/// från: bygger den ena spelaren sitt kort påverkas inte den andras
/// (se [GameNotifier.buyFaceUpExpansion]).
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    return container;
  }

  group('uppställning (playLocally)', () {
    test('utan tema: 4 draghögar à 9, inget ansikte-upp-kort', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).playLocally();

      final state = container.read(gameProvider);
      expect(state.you.faceUpExpansionCard, isNull);
      expect(state.opponent.faceUpExpansionCard, isNull);
      // you/opponent har redan fått sina starthänder (3 kort var) från
      // hög 1 respektive 2 (se playLocally-doc), så de är 9-3=6.
      expect(state.centerStacks['draw1'], 6);
      expect(state.centerStacks['draw2'], 6);
      expect(state.centerStacks['draw3'], 9);
      expect(state.centerStacks['draw4'], 9);
      expect(state.centerStacks.containsKey('draw5'), isFalse);
    });

    test(
        'med Gulderan: 5 draghögar (3x12, 2x11) och varsitt eget Köpmansgille',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      container
          .read(gameProvider.notifier)
          .playLocally(expansions: {ExpansionSet.eraOfGold});

      final state = container.read(gameProvider);
      expect(state.you.faceUpExpansionCard?.baseId,
          EraOfGoldCards.merchantGuild.id);
      expect(state.opponent.faceUpExpansionCard?.baseId,
          EraOfGoldCards.merchantGuild.id);
      // Två SKILDA fysiska kopior, inte samma kort visat två gånger.
      expect(state.you.faceUpExpansionCard!.id,
          isNot(state.opponent.faceUpExpansionCard!.id));
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

    test(
        'bygger DITT EGET kort, tar bort det från din plats – motståndarens eget kort påverkas inte',
        () {
      final before = container.read(gameProvider);
      final card = before.you.faceUpExpansionCard!;
      final opponentCard = before.opponent.faceUpExpansionCard;

      final error = notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, card);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.you.faceUpExpansionCard, isNull);
      expect(state.opponent.faceUpExpansionCard, opponentCard,
          reason: 'motståndarens separata kort ska inte påverkas alls');
      expect(state.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          card.id);
    });

    test('avvisas om det inte är din tur/tärningen inte slagen', () {
      final container2 = buildContainer();
      addTearDown(container2.dispose);
      final notifier2 = container2.read(gameProvider.notifier);
      notifier2.playLocally(expansions: {ExpansionSet.eraOfGold});
      // Ingen rollProductionDie() här.
      final card = container2.read(gameProvider).you.faceUpExpansionCard!;

      final error = notifier2.buyFaceUpExpansion(0, BuildingRow.above, 0, card);

      expect(error, isNotNull);
      expect(container2.read(gameProvider).you.faceUpExpansionCard, card);
    });

    test('kan inte bygga motståndarens eget ansikte-upp-kort', () {
      final opponentCard = container.read(gameProvider).opponent.faceUpExpansionCard!;

      final error =
          notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, opponentCard);

      expect(error, isNull); // no-op, inte ett fel
      final state = container.read(gameProvider);
      expect(state.opponent.faceUpExpansionCard, opponentCard);
      expect(state.you.principality.settlementAt(0)!.aboveSites[0], isNull);
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

      final card = container.read(gameProvider).you.faceUpExpansionCard!;
      final error = notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, card);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          card.id);
      expect(state.discardPile, hasLength(1));
      expect(state.discardPile.last.id, existing.id);
    });

    test(
        'byts ett byggt Köpmansgille ut mot ett annat kort hamnar det INTE i slänghögen utan tillbaka på din egen ansikte-upp-plats',
        () {
      final card = container.read(gameProvider).you.faceUpExpansionCard!;
      expect(notifier.buyFaceUpExpansion(0, BuildingRow.above, 0, card), isNull);
      expect(container.read(gameProvider).you.faceUpExpansionCard, isNull);

      // Bygg om samma plats med ett annat kort – kräver ett tema aktivt
      // för att "byt ut"-mekaniken alls ska vara tillåten.
      const replacement = BasicSetCards.storehouse;
      container.read(gameProvider).you.hand.add(replacement);
      final error =
          notifier.dropExpansion(0, BuildingRow.above, 0, replacement);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.discardPile, isEmpty,
          reason: 'Köpmansgille ska inte hamna i slänghögen');
      expect(state.you.faceUpExpansionCard?.id, card.id,
          reason: 'kortet ska ligga tillbaka på din egen plats, oplacerat');
      expect(state.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          replacement.id);
    });
  });

  group('online: ansikte-upp-kortet synkas till gästen', () {
    test(
        'gästen ärver hostens temaval och får sitt eget, skilda Köpmansgille',
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
      await pump();

      final hostState = hostContainer.read(gameProvider);
      final guestState = guestContainer.read(gameProvider);

      expect(guestState.activeExpansions, {ExpansionSet.eraOfGold});
      expect(guestState.victoryPointTarget, 12);
      expect(guestState.you.faceUpExpansionCard, isNotNull);
      expect(hostState.you.faceUpExpansionCard, isNotNull);
      expect(guestState.you.faceUpExpansionCard!.id,
          isNot(hostState.you.faceUpExpansionCard!.id),
          reason: 'varsin skild fysisk kopia');
      // Gästens syn på hostens (motståndarens) kort ska matcha vad
      // hosten själv ser.
      expect(guestState.opponent.faceUpExpansionCard?.id,
          hostState.you.faceUpExpansionCard!.id);
      expect(guestState.centerStacks['draw5'], hostState.centerStacks['draw5']);
      expect(guestState.initialDrawStackSizes, [12, 12, 12, 11, 11]);
    });

    test(
        'resumeRoom (Gulderan): 5 draghögar byggs om med rätt storlek, ditt eget ansikte-upp-kort (även efter ett köpt kort) stämmer',
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

      // Köper sitt eget Köpmansgille innan "omladdningen".
      final boughtCard = host.read(gameProvider).you.faceUpExpansionCard!;
      expect(hostNotifier.buyFaceUpExpansion(0, BuildingRow.above, 0, boughtCard),
          isNull);
      await pump();

      final beforeState = host.read(gameProvider);
      expect(beforeState.you.faceUpExpansionCard, isNull);

      final resumed = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      addTearDown(resumed.dispose);
      final error = await resumed
          .read(gameProvider.notifier)
          .resumeRoom(roomCode, 'host', 'Astrid');

      expect(error, isNull);
      final resumedState = resumed.read(gameProvider);
      expect(resumedState.activeExpansions, {ExpansionSet.eraOfGold});
      expect(resumedState.you.faceUpExpansionCard, isNull,
          reason: 'redan byggt, ska inte dyka upp igen efter återanslutning');
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
