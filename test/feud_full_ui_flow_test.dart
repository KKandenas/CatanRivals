import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/expansion_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Fejds bygg-väljare genom HELA den riktiga widgetträdet (inte
/// bara notifier-anrop, se feud_test.dart, eller FeudResolutionCard i
/// isolering, se feud_resolution_card_test.dart) – rapporterad bugg:
/// "Välj byggnad" ska gå att trycka på, sedan byggnaden i det egna
/// riket, sedan en draghög, men användaren får aldrig den möjligheten.
void main() {
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

  testWidgets(
      'motståndaren har övertaget: "Välj byggnad" -> tryck på byggnaden -> tryck på en draghög tar bort den',
      (tester) async {
    final container = await setup(tester);
    final notifier = container.read(gameProvider.notifier);

    // Ge motståndaren styrkeövertaget och dig själv en byggnad att välja
    // bort, precis som feud_test.dart.
    container.read(gameProvider).opponent.principality.placeExpansion(
        0,
        BuildingRow.above,
        0,
        PlacedCard(card: BasicSetCards.harald.copyWith(strengthPoints: 2)));
    container.read(gameProvider).you.principality.placeExpansion(
        2, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));
    notifier.state = container
        .read(gameProvider)
        .copyWith(drawnEventCard: BasicSetCards.feud);
    await tester.pumpAndSettle();

    expect(container.read(gameProvider).strengthAdvantagePlayerId, 'opponent');
    expect(find.text('Välj byggnad'), findsOneWidget,
        reason: 'knappen ska visas för den UTAN styrkeövertaget');

    await tester.tap(find.text('Välj byggnad'));
    await tester.pumpAndSettle();
    expect(container.read(gameProvider).feudBuildingPickActive, isTrue);

    // Tryck på byggnaden (Kloster) i det egna riket – hittar den exakta
    // ExpansionCardView via kortets id (inte namntext, som kan kollidera
    // med ett annat Kloster-exemplar som råkat delas ut i handen).
    final buildingCardView = find.byWidgetPredicate((w) =>
        w is ExpansionCardView && w.card.id == BasicSetCards.abbey.id);
    expect(buildingCardView, findsOneWidget,
        reason: 'byggnaden ska synas i det egna riket');
    final detector = find
        .descendant(
            of: buildingCardView, matching: find.byType(GestureDetector))
        .first;
    await tapGestureDetector(tester, detector);

    expect(container.read(gameProvider).feudPickedBuilding, isNotNull,
        reason: 'ett tryck på byggnaden ska markera den som vald');

    // Tryck på en draghög för att lägga byggnaden underst i den.
    expect(find.text('Vilken draghög ska byggnaden läggas underst i?'),
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
    expect(state.feudBuildingPickActive, isFalse,
        reason: 'Fejd ska vara avslutad efter att draghögen valts');
    expect(state.you.principality.settlementAt(2)!.belowSites[0], isNull,
        reason: 'byggnaden ska ha tagits bort ur riket');
    expect(state.drawnEventCard, isNull);
  });
}
