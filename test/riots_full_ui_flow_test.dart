import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/expansion_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Upplopps hela flöde genom det RIKTIGA widgetträdet (inte bara
/// notifier-anrop, se riots_test.dart) – samma mönster som
/// feud_full_ui_flow_test.dart: "Kan inte betala" -> tryck på enheten i
/// det egna riket -> tryck på en draghög tar bort den.
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

  testWidgets('Betalt: visar rätt antal enheter/guld och stänger kortet',
      (tester) async {
    final container = await setup(tester);
    final notifier = container.read(gameProvider.notifier);

    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
    notifier.state = container
        .read(gameProvider)
        .copyWith(diceRolled: true, drawnEventCard: EraOfTurmoilCards.riots);
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Du har 1 enhet med styrke- eller handelspoäng och ska betala 1 guld.'),
        findsOneWidget);
    expect(find.text('Betalt'), findsOneWidget);
    expect(find.text('Kan inte betala'), findsOneWidget);

    await tester.tap(find.text('Betalt'));
    await tester.pumpAndSettle();

    final state = container.read(gameProvider);
    expect(state.drawnEventCard, isNull);
    expect(state.riotsResolvedPlayerIds, contains('you'));
  });

  testWidgets(
      'Kan inte betala -> tryck på enheten -> tryck på en draghög tar bort den',
      (tester) async {
    final container = await setup(tester);
    final notifier = container.read(gameProvider.notifier);

    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
    notifier.state = container
        .read(gameProvider)
        .copyWith(diceRolled: true, drawnEventCard: EraOfTurmoilCards.riots);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kan inte betala'));
    await tester.pumpAndSettle();
    expect(container.read(gameProvider).riotsUnitPickActive, isTrue);
    expect(
        find.text(
            'Upplopp: tryck på en av dina egna enheter (byggnad, skepp '
            'eller hjälte) med styrke- eller handelspoäng för att ta '
            'bort den.'),
        findsOneWidget);

    // Tryck på enheten (Carl Kluvskägg) i det egna riket.
    final unitCardView = find.byWidgetPredicate(
        (w) => w is ExpansionCardView && w.card.id == unitCard.id);
    expect(unitCardView, findsOneWidget,
        reason: 'enheten ska synas i det egna riket');
    final detector = find
        .descendant(of: unitCardView, matching: find.byType(GestureDetector))
        .first;
    await tapGestureDetector(tester, detector);

    expect(container.read(gameProvider).riotsPickedUnit, isNotNull,
        reason: 'ett tryck på enheten ska markera den som vald');

    // Tryck på en draghög för att lägga enheten underst i den.
    expect(find.text('Vilken draghög ska enheten läggas underst i?'),
        findsOneWidget);
    final drawStackImages = find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == CatanAssets.backBasicSet);
    expect(drawStackImages, findsWidgets,
        reason: 'draghögarna ska gå att trycka på i väljarläget');
    final stackDetector = find
        .ancestor(
            of: drawStackImages.first, matching: find.byType(GestureDetector))
        .first;
    await tapGestureDetector(tester, stackDetector);

    final state = container.read(gameProvider);
    expect(state.riotsUnitPickActive, isFalse,
        reason: 'väljaren ska vara avslutad efter att draghögen valts');
    expect(state.you.principality.settlementAt(0)!.aboveSites[0], isNull,
        reason: 'enheten ska ha tagits bort ur riket');
    expect(state.drawnEventCard, isNull);
  });
}
