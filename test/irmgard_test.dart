import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/expansion_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Irmgard, ljusets väktare (regelhäftet: "Förlorar du ett kort
/// ur ditt rike på grund av en händelse eller ett handlingskort får du
/// 1 valfri resurs") – här via Upplopps "Kan inte betala"-flöde (samma
/// riktiga widgetflöde som riots_full_ui_flow_test.dart), eftersom
/// GameBoardScreen._handleCardLossResult är EN delad hjälpare för alla
/// tre "lägg en egen enhet/byggnad underst i en draghög"-vägarna (Fejd/
/// Upplopp/Bågskytt/Pyroman, se dess doc) – samma kod testas oavsett
/// vilken av de tre man går via.
void main() {
  const unitCard = EraOfTurmoilCards.carlForkbeard;

  Future<ProviderContainer> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    container.read(gameProvider.notifier).playLocally();
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapGestureDetector(WidgetTester tester, Finder detector) async {
    (tester.widget<GestureDetector>(detector).onTap!)();
    await tester.pumpAndSettle();
  }

  Future<void> loseUnitViaRiots(WidgetTester tester) async {
    await tester.tap(find.text('Kan inte betala'));
    await tester.pumpAndSettle();

    final unitCardView = find.byWidgetPredicate(
        (w) => w is ExpansionCardView && w.card.id == unitCard.id);
    final detector = find
        .descendant(of: unitCardView, matching: find.byType(GestureDetector))
        .first;
    await tapGestureDetector(tester, detector);

    final drawStackImages = find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == CatanAssets.backBasicSet);
    final stackDetector = find
        .ancestor(
            of: drawStackImages.first, matching: find.byType(GestureDetector))
        .first;
    await tapGestureDetector(tester, stackDetector);
  }

  testWidgets(
      'har man Irmgard visas en påminnelse om 1 valfri resurs efter förlorad enhet',
      (tester) async {
    final container = await setup(tester);
    final notifier = container.read(gameProvider.notifier);

    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
    container.read(gameProvider).you.principality.placeExpansion(2,
        BuildingRow.above, 0,
        const PlacedCard(card: EraOfTurmoilCards.irmgardKeeperOfTheLight));
    notifier.state = container
        .read(gameProvider)
        .copyWith(diceRolled: true, drawnEventCard: EraOfTurmoilCards.riots);
    await tester.pumpAndSettle();

    await loseUnitViaRiots(tester);

    expect(container.read(gameProvider).you.principality
        .settlementAt(0)!.aboveSites[0], isNull);
    expect(find.text('Du har Irmgard: du får 1 valfri resurs.'),
        findsOneWidget);
  });

  testWidgets('utan Irmgard visas ingen påminnelse', (tester) async {
    final container = await setup(tester);
    final notifier = container.read(gameProvider.notifier);

    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
    notifier.state = container
        .read(gameProvider)
        .copyWith(diceRolled: true, drawnEventCard: EraOfTurmoilCards.riots);
    await tester.pumpAndSettle();

    await loseUnitViaRiots(tester);

    expect(container.read(gameProvider).you.principality
        .settlementAt(0)!.aboveSites[0], isNull);
    expect(
        find.text('Du har Irmgard: du får 1 valfri resurs.'), findsNothing);
  });
}
