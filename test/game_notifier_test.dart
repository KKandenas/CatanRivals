import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      // Bygga/köpa kräver nu att tärningen är slagen på din tur
      // (regelhäftet s. 7) – slå den här så byggtesterna nedan inte
      // behöver upprepa det själva.
      container.read(gameProvider.notifier).rollProductionDie();
    });

    test('initial state has starting principalities and center stacks', () {
      final state = container.read(gameProvider);

      expect(state.you.principality.settlements, hasLength(2));
      expect(state.opponent.principality.settlements, hasLength(2));
      expect(state.centerStacks['roads'], greaterThan(0));
      expect(state.draggingCard, isNull);
    });

    test('dropExpansion places a hand card without touching resources', () {
      // Appen håller inte längre koll på om spelaren har råd – kostnaden
      // visas i bekräftelserutan (build_confirm_dialog.dart) och
      // spelarna betalar själva med +/- på sina regioner, precis som i
      // det fysiska spelet (regelhäftet s. 9).
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final storehouse = before.you.hand.firstWhere((c) => c.id == 'building-storehouse');
      final lumberBefore = before.you.resourceCount(ResourceType.lumber);

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, storehouse);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(storehouse), isFalse);
      expect(after.you.resourceCount(ResourceType.lumber), lumberBefore);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id, storehouse.id);
    });

    test('dropExpansion places a hand card the player cannot afford (no affordability check)', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final siglind = before.you.hand.firstWhere((c) => c.id == 'hero-siglind');

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, siglind);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(siglind), isFalse);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id, siglind.id);
    });

    test('dropExpansion refuses a duplicate unique card (t.ex. Kloster/Marknadsplats/Församlingshus)', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);

      // Placerar en första kopia direkt (motsvarar ett tidigare drag) –
      // storehouse i sig är inte unikt, men eftersom GameCard-likhet
      // bara jämför id (se GameCard.==) räcker en kopia med samma id
      // markerad `isUnique: true` för att testa regeln isolerat, utan
      // att behöva ett riktigt unikt kort i den fasta mock-handen.
      before.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.storehouse));
      final uniqueCopy = BasicSetCards.storehouse.copyWith(isUnique: true);
      expect(before.you.hand.contains(uniqueCopy), isTrue);

      final error = notifier.dropExpansion(2, BuildingRow.above, 0, uniqueCopy);

      expect(error, 'Du kan bara ha en ${uniqueCopy.name} i ditt rike.');
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(uniqueCopy), isTrue); // slängdes inte
      expect(after.you.principality.settlementAt(2)!.aboveSites[0], isNull);
    });

    test(
        'dropExpansion avvisar en stadsutbyggnad på en vanlig by (kräver en stad, se build_requirements.dart)',
        () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      before.you.hand.add(EraOfGoldCards.merchantGuild);
      // Kolumn 0 är en by, inte en stad, i mock-uppställningen.
      expect(before.you.principality.settlementAt(0)!.isCity, isFalse);

      final error =
          notifier.dropExpansion(0, BuildingRow.above, 0, EraOfGoldCards.merchantGuild);

      expect(error, 'Köpmansgille kräver en stad, inte bara en by.');
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(EraOfGoldCards.merchantGuild), isTrue);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0], isNull);
    });

    test('dropExpansion tillåter en stadsutbyggnad på en riktig stad', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      before.you.hand.add(EraOfGoldCards.merchantGuild);
      before.you.principality
          .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));

      final error =
          notifier.dropExpansion(0, BuildingRow.above, 0, EraOfGoldCards.merchantGuild);

      expect(error, isNull);
      expect(
          container.read(gameProvider).you.principality
              .settlementAt(0)!
              .aboveSites[0]!
              .card
              .id,
          EraOfGoldCards.merchantGuild.id);
    });

    test('dropExpansion avvisar Stapelhus utan Köpmansgille i riket', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      before.you.hand.add(EraOfGoldCards.stapleHouse);
      before.you.principality
          .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));

      final error =
          notifier.dropExpansion(0, BuildingRow.above, 0, EraOfGoldCards.stapleHouse);

      expect(error, 'Stapelhus kräver Köpmansgille i ditt rike.');
      expect(
          container.read(gameProvider).you.hand.contains(EraOfGoldCards.stapleHouse),
          isTrue);
    });

    test(
        'dropExpansion avvisar Rådhus på en tom plats, även om Församlingshus ligger på en ANNAN plats i riket (rapporterad bugg)',
        () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      before.you.hand.add(EraOfProgressCards.townHall);
      before.you.principality
          .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
      before.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.parishHall));

      final error = notifier.dropExpansion(
          0, BuildingRow.above, 1, EraOfProgressCards.townHall);

      expect(error, 'Rådhus måste läggas ovanpå ditt Församlingshus.');
      expect(
          container.read(gameProvider).you.hand.contains(EraOfProgressCards.townHall),
          isTrue);
      expect(
          container.read(gameProvider).you.principality.settlementAt(0)!.aboveSites[1],
          isNull);
    });

    test('dropExpansion tillåter Rådhus direkt ovanpå Församlingshus', () {
      final notifier = container.read(gameProvider.notifier);
      // Att byta ut ett redan utplacerat kort kräver att minst ett tema
      // är aktivt (se _checkReplaceAllowed-doc) – Rådhus finns bara i
      // Utvecklingens tid, så det gäller alltid i praktiken, men testet
      // behöver sätta det uttryckligen eftersom mock-uppställningen ovan
      // annars bara har grundspelet aktivt.
      notifier.state =
          notifier.state.copyWith(activeExpansions: {ExpansionSet.eraOfProgress});
      final before = container.read(gameProvider);
      before.you.hand.add(EraOfProgressCards.townHall);
      before.you.principality
          .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
      before.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.parishHall));

      final error = notifier.dropExpansion(
          0, BuildingRow.above, 0, EraOfProgressCards.townHall);

      expect(error, isNull);
      expect(
          container.read(gameProvider).you.principality.settlementAt(0)!.aboveSites[0]!
              .card.id,
          EraOfProgressCards.townHall.id);
    });

    test(
        'dropExpansion refuses en andra fysisk kopia av samma unika byggnad, även med olika draghögs-id (rapporterad bugg: 2 Marknadsplatser gick att bygga)',
        () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);

      // De två fysiska Marknadsplats-korten har OLIKA id i draghögen
      // (se BasicSetDrawDeck: "$id-draw-$i") – det är precis det som
      // gjorde att den gamla id-baserade kontrollen missade dem.
      final firstCopy =
          BasicSetCards.marketplace.copyWith(id: 'building-marketplace-draw-0');
      final secondCopy =
          BasicSetCards.marketplace.copyWith(id: 'building-marketplace-draw-1');
      before.you.hand.addAll([firstCopy, secondCopy]);

      final firstError =
          notifier.dropExpansion(0, BuildingRow.above, 0, firstCopy);
      expect(firstError, isNull);

      final secondError =
          notifier.dropExpansion(2, BuildingRow.above, 0, secondCopy);

      expect(secondError, 'Du kan bara ha en ${secondCopy.name} i ditt rike.');
      final after = container.read(gameProvider);
      expect(after.you.hand.contains(secondCopy), isTrue); // slängdes inte
      expect(after.you.principality.settlementAt(2)!.aboveSites[0], isNull);
    });

    test(
        'utan tema aktivt: dropExpansion på en redan bebyggd plats avvisas i stället för att byta ut',
        () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final storehouse = before.you.hand.firstWhere((c) => c.id == 'building-storehouse');
      final siglind = before.you.hand.firstWhere((c) => c.id == 'hero-siglind');
      expect(notifier.dropExpansion(0, BuildingRow.above, 0, storehouse), isNull);

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, siglind);

      expect(error, isNotNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          storehouse.id,
          reason: 'det gamla kortet ska ligga kvar');
      expect(after.you.hand.contains(siglind), isTrue, reason: 'slängdes inte');
      expect(after.discardPile, isEmpty);
    });

    test(
        'med ett tema aktivt: dropExpansion på en redan bebyggd plats byter ut det gamla kortet mot det nya i stället för att avvisas',
        () {
      final notifier = container.read(gameProvider.notifier);
      // "Byt ut byggnad" finns bara med minst ett tema aktivt (se
      // GameNotifier._checkReplaceAllowed-doc).
      notifier.state = notifier.state.copyWith(activeExpansions: {ExpansionSet.eraOfGold});
      final before = container.read(gameProvider);
      final storehouse = before.you.hand.firstWhere((c) => c.id == 'building-storehouse');
      final siglind = before.you.hand.firstWhere((c) => c.id == 'hero-siglind');

      expect(notifier.dropExpansion(0, BuildingRow.above, 0, storehouse), isNull);
      expect(before.discardPile, isEmpty);

      final error = notifier.dropExpansion(0, BuildingRow.above, 0, siglind);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          siglind.id,
          reason: 'det nya kortet ska stå på platsen');
      expect(after.you.hand.contains(siglind), isFalse);
      expect(after.discardPile, hasLength(1));
      expect(after.discardPile.last.id, storehouse.id,
          reason: 'det utbytta kortet ska hamna överst i slänghögen');
    });

    test(
        'byt-ut-mekaniken tar bort det gamla kortets poäng (räknas inte längre in i riket)',
        () {
      final notifier = container.read(gameProvider.notifier);
      notifier.state = notifier.state.copyWith(activeExpansions: {ExpansionSet.eraOfGold});
      final before = container.read(gameProvider);
      // Ett byggkort med segerpoäng (skiljer sig från den fasta
      // mock-handen, som normalt inte har något på hand med VP) – samma
      // teknik som victory_test.dart använder för att styra poäng
      // deterministiskt.
      final scoringCard = BasicSetCards.abbey.copyWith(victoryPoints: 3, progressPoints: 0);
      before.you.hand.add(scoringCard);
      expect(notifier.dropExpansion(0, BuildingRow.above, 0, scoringCard), isNull);
      final withCard = container.read(gameProvider);
      expect(withCard.totalVictoryPointsFor(withCard.you),
          withCard.you.principality.settlements.length + 3);

      final storehouse = withCard.you.hand.firstWhere((c) => c.id == 'building-storehouse');
      expect(notifier.dropExpansion(0, BuildingRow.above, 0, storehouse), isNull);

      final after = container.read(gameProvider);
      expect(after.totalVictoryPointsFor(after.you),
          after.you.principality.settlements.length,
          reason: 'de 3 segerpoängen ska försvinna med det utbytta kortet');
    });

    test('dropRoad builds a road at the frontier and decrements the stack', () {
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      final roadsBefore = before.centerStacks['roads']!;

      final error = notifier.dropRoad(-1, BasicSetCards.road);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.roads.containsKey(-1), isTrue);
      expect(after.centerStacks['roads'], roadsBefore - 1);
    });

    test('dropSettlement builds beyond a dangling road and queues 2 new regions to place', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.dropRoad(-1, BasicSetCards.road);
      final regionsBefore = container.read(gameProvider).centerStacks['regions']!;

      final error = notifier.dropSettlement(-2, BasicSetCards.settlement);
      // Mock-handen innehåller Spejare (se MockGame.buildYou) – den
      // väcker nu frågan "Vill du använda Spejare?" i stället för att
      // dra regionkorten direkt (se scout_test.dart). Den här testet
      // testar bara pendingRegions-flödet, så vi tackar nej precis som
      // om spelaren inte haft kortet.
      notifier.declineScout();

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.settlementAt(-2), isNotNull);
      // Regionerna dras direkt (stapeln minskar) men placeras inte förrän
      // spelaren själv drar dem till ovanför/nedanför – se
      // 'placePendingRegion' i pending_regions_test.dart.
      expect(after.you.principality.regionAt(-3, BuildingRow.above), isNull);
      expect(after.you.principality.regionAt(-3, BuildingRow.below), isNull);
      expect(after.pendingRegions, hasLength(2));
      expect(after.pendingRegionJunction, -3);
      expect(after.centerStacks['regions'], regionsBefore - 2);
    });

    test('dropSettlement without a road first is rejected by RealmBoard', () {
      final notifier = container.read(gameProvider.notifier);

      // Ingen väg utplacerad vid kolumn -1, så -2 är egentligen inte en
      // giltig plats – RealmBoard.placeSettlement kastar när kolumnen
      // redan är upptagen, men här testar vi att en helt orimlig
      // kolumn (mitt i en befintlig by) avvisas av modellen.
      expect(() => notifier.dropSettlement(0, BasicSetCards.settlement), throwsStateError);
    });

    test('dropCityUpgrade upgrades the settlement without an affordability check', () {
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.dropCityUpgrade(0, BasicSetCards.city);

      expect(error, isNull);
      final after = container.read(gameProvider);
      expect(after.you.principality.settlementAt(0)!.isCity, isTrue);
    });

    test('startDrag/endDrag toggles draggingCard', () {
      final notifier = container.read(gameProvider.notifier);

      notifier.startDrag(BasicSetCards.road);
      expect(container.read(gameProvider).draggingCard, BasicSetCards.road);

      notifier.endDrag();
      expect(container.read(gameProvider).draggingCard, isNull);
    });
  });
}
