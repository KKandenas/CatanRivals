import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Byggkrans rena påminnelsetext (SnackBar, inga faktiska
/// resurser dras av – se GameBoardScreen._confirmPendingBuild-doc,
/// samma mönster som Övningsplats/Marknadsfält/Tiondelada i
/// turmoil_building_notices_test.dart): "Varje stadsutbyggnad du bygger
/// som kostar mer än 4 resurser kostar 1 resurs mindre" – gäller ALLA
/// stadsutbyggnader (inte bara Utvecklingens tids egna), så testet
/// bygger Köpmansgille (Gulderan, kostar 5 resurser) för att visa det.
void main() {
  Future<ProviderContainer> readyGame(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfProgress});
    notifier.rollProductionDie();
    return container;
  }

  Future<void> dragHandCardToSite(
      WidgetTester tester, String cardName, int siteIndex) async {
    final handCard = find.descendant(
        of: find.byType(HandDock), matching: find.text(cardName));
    final sites = find.byWidgetPredicate((w) => w is DragTarget<GameCard>);

    final start = tester.getCenter(handCard);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(sites.at(siteIndex)));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
      'bygger man en stadsutbyggnad som kostar mer än 4 resurser med Byggkran i riket visas en påminnelse',
      (tester) async {
    final container = await readyGame(tester);
    addTearDown(container.dispose);
    final before = container.read(gameProvider);
    before.you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    before.you.principality.placeExpansion(0, BuildingRow.below, 0,
        const PlacedCard(card: EraOfProgressCards.buildingCrane));
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfGoldCards.merchantGuild);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    await dragHandCardToSite(tester, 'Köpmansgille', 0);
    expect(find.text('Betalt'), findsOneWidget);
    await tester.tap(find.text('Betalt'));
    await tester.pump();

    expect(
        find.text(
            'Du har Byggkran: betala 1 resurs mindre för stadsutbyggnaden.'),
        findsOneWidget);
  });

  testWidgets(
      'bygger man samma kort UTAN Byggkran i riket visas ingen påminnelse',
      (tester) async {
    final container = await readyGame(tester);
    addTearDown(container.dispose);
    final before = container.read(gameProvider);
    before.you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfGoldCards.merchantGuild);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    await dragHandCardToSite(tester, 'Köpmansgille', 0);
    await tester.tap(find.text('Betalt'));
    await tester.pump();

    expect(
        find.text(
            'Du har Byggkran: betala 1 resurs mindre för stadsutbyggnaden.'),
        findsNothing);
  });

  testWidgets(
      'bygger man en stadsutbyggnad som kostar 4 resurser eller mindre visas ingen påminnelse ens med Byggkran',
      (tester) async {
    final container = await readyGame(tester);
    addTearDown(container.dispose);
    final before = container.read(gameProvider);
    before.you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    before.you.principality.placeExpansion(0, BuildingRow.below, 0,
        const PlacedCard(card: EraOfProgressCards.buildingCrane));
    // Badhus kostar exakt 4 resurser (brick2+wool1+ore1) – inte "MER än
    // 4", så Byggkran ska inte trigga här.
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfProgressCards.bathHouse);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    await dragHandCardToSite(tester, 'Badhus', 0);
    await tester.tap(find.text('Betalt'));
    await tester.pump();

    expect(
        find.text(
            'Du har Byggkran: betala 1 resurs mindre för stadsutbyggnaden.'),
        findsNothing);
  });
}
