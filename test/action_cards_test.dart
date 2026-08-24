import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar handlingskortens "tvåstegsraket"-effekter i GameNotifier
/// (se card_detail_dialog.dart/onUseCard för själva UI-frågan) –
/// Brigitta, de självbevakade Handelskaravan/Guldsmed, och
/// Omlokaliseringens byt-plats-interaktion. Spejare (som triggas
/// automatiskt vid by-bygge i stället) testas i scout_test.dart.
void main() {
  group('Brigitta, den visa kvinnan', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('väljer produktionstärningens resultat och tar bort kortet från handen', () {
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.hand.add(BasicSetCards.brigittaTheWiseWoman);

      final error = notifier.useBrigitta(5);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.productionRoll, 5);
      expect(state.diceRolled, isTrue);
      expect(state.eventDieFace, isNotNull);
      expect(
          state.you.hand.any((c) => c.id == BasicSetCards.brigittaTheWiseWoman.id),
          isFalse);
    });

    test('går inte att använda efter att tärningen redan slagits', () {
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.hand.add(BasicSetCards.brigittaTheWiseWoman);
      notifier.rollProductionDie();
      final rollAfterNormalRoll = container.read(gameProvider).productionRoll;

      final error = notifier.useBrigitta(3);

      expect(error, isNotNull);
      expect(container.read(gameProvider).productionRoll, rollAfterNormalRoll);
      // Kortet ligger kvar – försöket avvisades helt.
      expect(
          container
              .read(gameProvider)
              .you
              .hand
              .any((c) => c.id == BasicSetCards.brigittaTheWiseWoman.id),
          isTrue);
    });

    test('no-op utan kortet på hand', () {
      final notifier = container.read(gameProvider.notifier);
      // Mock-handen (MockGame.buildYou) saknar Brigitta.

      final error = notifier.useBrigitta(2);

      expect(error, isNull);
      expect(container.read(gameProvider).diceRolled, isFalse);
    });
  });

  group('Handelskaravan/Guldsmed (självbevakade)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      // discardActionCard kräver numera action-fasen (samma villkor som
      // ett bygge, se GameNotifier._checkCanBuild) – precis som
      // Omlokaliseringens setUp nedan.
      container.read(gameProvider.notifier).rollProductionDie();
    });

    test(
        'discardActionCard tar bort kortet från handen utan att röra resurser, och lägger det i slänghögen (med ett tema aktivt)',
        () {
      final notifier = container.read(gameProvider.notifier);
      // Slänghögen är bara synlig/aktiv med minst ett tema aktivt (se
      // GameNotifier._discardToPile-doc) – utan tema försvinner kortet
      // i stället spårlöst, precis som innan mekaniken fanns.
      notifier.state = notifier.state.copyWith(activeExpansions: {ExpansionSet.eraOfGold});
      final before = container.read(gameProvider);
      final card =
          before.you.hand.firstWhere((c) => c.id == BasicSetCards.merchantCaravan.id);
      final lumberBefore = before.you.resourceCount(ResourceType.lumber);

      final error = notifier.discardActionCard(card);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(card), isFalse);
      expect(after.you.resourceCount(ResourceType.lumber), lumberBefore);
      expect(after.discardPile, hasLength(1));
      expect(after.discardPile.last.id, card.id);
    });

    test(
        'utan tema aktivt: kortet försvinner spårlöst, ingen slänghög',
        () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final card =
          before.you.hand.firstWhere((c) => c.id == BasicSetCards.merchantCaravan.id);

      final error = notifier.discardActionCard(card);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(card), isFalse);
      expect(after.discardPile, isEmpty);
    });

    test('no-op om kortet inte finns på handen', () {
      final notifier = container.read(gameProvider.notifier);
      final handCountBefore = container.read(gameProvider).you.hand.length;

      final error = notifier.discardActionCard(BasicSetCards.goldsmith);

      expect(error, isNull);
      expect(container.read(gameProvider).you.hand, hasLength(handCountBefore));
    });

    test('avvisas med tydligt fel innan tärningen slagits', () {
      // Ny container – ingen rollProductionDie() i den här gruppens
      // setUp (till skillnad från Omlokalisering nedan), så tärningen
      // är fortfarande oslagen.
      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      final notifier = freshContainer.read(gameProvider.notifier);
      final card = freshContainer
          .read(gameProvider)
          .you
          .hand
          .firstWhere((c) => c.id == BasicSetCards.merchantCaravan.id);

      final error = notifier.discardActionCard(card);

      expect(error, isNotNull);
      expect(freshContainer.read(gameProvider).you.hand.contains(card), isTrue);
    });
  });

  group('Omlokalisering', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).rollProductionDie();
    });

    test('byter plats på 2 egna regioner – resurserna följer med kortet', () {
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      state.you.hand.add(BasicSetCards.relocation);
      // Startuppställningen: Skog (-1, ovanför, 1 lagrad) och Guldfält
      // (1, ovanför, 0 lagrat) – se starter_cards.dart.
      state.you.principality.addResourceToRegion(-1, BuildingRow.above, 2);
      final forestCard =
          state.you.principality.regionAt(-1, BuildingRow.above)!.card;
      final goldFieldCard =
          state.you.principality.regionAt(1, BuildingRow.above)!.card;

      expect(notifier.startRelocation(), isNull);
      expect(container.read(gameProvider).relocationActive, isTrue);
      expect(
          notifier.selectRelocationTarget(
              RelocationTargetKind.region, -1, BuildingRow.above, 0),
          isNull);
      expect(container.read(gameProvider).relocationFirst, isNotNull);
      expect(
          notifier.selectRelocationTarget(
              RelocationTargetKind.region, 1, BuildingRow.above, 0),
          isNull);

      final after = container.read(gameProvider);
      expect(after.relocationActive, isFalse);
      expect(after.relocationFirst, isNull);
      expect(after.you.principality.regionAt(-1, BuildingRow.above)!.card.id,
          goldFieldCard.id);
      expect(
          after.you.principality.regionAt(-1, BuildingRow.above)!.storedResources,
          0);
      expect(after.you.principality.regionAt(1, BuildingRow.above)!.card.id,
          forestCard.id);
      expect(
          after.you.principality.regionAt(1, BuildingRow.above)!.storedResources,
          3);
      expect(after.you.hand.any((c) => c.id == BasicSetCards.relocation.id),
          isFalse);
    });

    test('avbryter utan att röra brädet eller ta bort kortet', () {
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      state.you.hand.add(BasicSetCards.relocation);

      notifier.startRelocation();
      notifier.selectRelocationTarget(
          RelocationTargetKind.region, -1, BuildingRow.above, 0);
      final error = notifier.cancelRelocation();

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.relocationActive, isFalse);
      expect(after.relocationFirst, isNull);
      expect(
          after.you.hand.any((c) => c.id == BasicSetCards.relocation.id), isTrue);
      expect(after.you.principality.regionAt(-1, BuildingRow.above)!.card.id,
          'region-forest-start');
    });

    test('avvisar blandat val (en region + ett byggkort) – första valet står kvar',
        () {
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      state.you.hand.add(BasicSetCards.relocation);
      state.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.storehouse));

      notifier.startRelocation();
      notifier.selectRelocationTarget(
          RelocationTargetKind.region, -1, BuildingRow.above, 0);
      final error = notifier.selectRelocationTarget(
          RelocationTargetKind.expansion, 0, BuildingRow.above, 0);

      expect(error, isNotNull);
      expect(container.read(gameProvider).relocationFirst, isNotNull);
      expect(container.read(gameProvider).relocationActive, isTrue);
    });

    test('ett tryck till på samma plats avmarkerar valet', () {
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      state.you.hand.add(BasicSetCards.relocation);

      notifier.startRelocation();
      notifier.selectRelocationTarget(
          RelocationTargetKind.region, -1, BuildingRow.above, 0);
      notifier.selectRelocationTarget(
          RelocationTargetKind.region, -1, BuildingRow.above, 0);

      expect(container.read(gameProvider).relocationFirst, isNull);
      expect(container.read(gameProvider).relocationActive, isTrue);
    });

    test('tryck på en tom platshållare ignoreras', () {
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      state.you.hand.add(BasicSetCards.relocation);

      notifier.startRelocation();
      final error = notifier.selectRelocationTarget(
          RelocationTargetKind.expansion, 0, BuildingRow.above, 0);

      expect(error, isNull);
      expect(container.read(gameProvider).relocationFirst, isNull);
    });

    test('byter plats på 2 egna byggkort', () {
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      state.you.hand.add(BasicSetCards.relocation);
      state.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.storehouse));
      state.you.principality.placeExpansion(
          0, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.tollBridge));

      notifier.startRelocation();
      notifier.selectRelocationTarget(
          RelocationTargetKind.expansion, 0, BuildingRow.above, 0);
      notifier.selectRelocationTarget(
          RelocationTargetKind.expansion, 0, BuildingRow.below, 0);

      final after = container.read(gameProvider);
      expect(
          after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          BasicSetCards.tollBridge.id);
      expect(
          after.you.principality.settlementAt(0)!.belowSites[0]!.card.id,
          BasicSetCards.storehouse.id);
      expect(after.you.hand.any((c) => c.id == BasicSetCards.relocation.id),
          isFalse);
    });

    test('startRelocation är no-op utan kortet på hand', () {
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.startRelocation();

      expect(error, isNull);
      expect(container.read(gameProvider).relocationActive, isFalse);
    });

    test('startRelocation avvisas med tydligt fel innan tärningen slagits',
        () {
      // Ny container – ingen rollProductionDie() här (till skillnad
      // från gruppens setUp ovan), så tärningen är fortfarande oslagen.
      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      freshContainer.read(gameProvider).you.hand.add(BasicSetCards.relocation);

      final error =
          freshContainer.read(gameProvider.notifier).startRelocation();

      expect(error, isNotNull);
      expect(freshContainer.read(gameProvider).relocationActive, isFalse);
    });
  });
}
