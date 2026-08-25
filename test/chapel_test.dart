import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Kapell (1–3)/(4–6) (regelhäftet: "Slås 1, 2 eller 3 [resp. 4,
/// 5 eller 6] på produktionstärningen gäller inte händelsen Upplopp
/// dig") – via det RIKTIGA widgetflödet (samma mönster som
/// riots_full_ui_flow_test.dart), eftersom skyddet avgörs helt
/// automatiskt av redan känt state (produktionstärningens resultat +
/// utplacerat Kapell), ingen egen notifier-metod behövs (se
/// GameBoardScreen._chapelProtectsRiots).
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

  testWidgets(
      'Kapell (1-3) med matchande produktionsslag: skyddad, OK markerar klar utan att röra enheten',
      (tester) async {
    final container = await setup(tester);
    final notifier = container.read(gameProvider.notifier);

    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
    container.read(gameProvider).you.principality.placeExpansion(2,
        BuildingRow.above, 0,
        const PlacedCard(card: EraOfTurmoilCards.chapelLowRoll));
    notifier.state = container.read(gameProvider).copyWith(
        diceRolled: true, productionRoll: 2, drawnEventCard: EraOfTurmoilCards.riots);
    await tester.pumpAndSettle();

    expect(
        find.text('Du har rätt Kapell för produktionstärningens '
            'resultat – gäller inte dig. Inget händer.'),
        findsOneWidget);
    expect(find.text('Betalt'), findsNothing);
    expect(find.text('Kan inte betala'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final state = container.read(gameProvider);
    expect(state.drawnEventCard, isNull);
    expect(state.riotsResolvedPlayerIds, contains('you'));
    expect(state.you.principality.settlementAt(0)!.aboveSites[0], isNotNull,
        reason: 'enheten ska vara orörd');
  });

  testWidgets(
      'Kapell (1-3) med ICKE-matchande produktionsslag: vanligt Upplopp-flöde',
      (tester) async {
    final container = await setup(tester);
    final notifier = container.read(gameProvider.notifier);

    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
    container.read(gameProvider).you.principality.placeExpansion(2,
        BuildingRow.above, 0,
        const PlacedCard(card: EraOfTurmoilCards.chapelLowRoll));
    notifier.state = container.read(gameProvider).copyWith(
        diceRolled: true, productionRoll: 5, drawnEventCard: EraOfTurmoilCards.riots);
    await tester.pumpAndSettle();

    expect(find.text('Betalt'), findsOneWidget);
    expect(find.text('Kan inte betala'), findsOneWidget);
  });

  testWidgets(
      'Kapell (4-6) med matchande produktionsslag: skyddad',
      (tester) async {
    final container = await setup(tester);
    final notifier = container.read(gameProvider.notifier);

    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: unitCard));
    container.read(gameProvider).you.principality.placeExpansion(2,
        BuildingRow.above, 0,
        const PlacedCard(card: EraOfTurmoilCards.chapelHighRoll));
    notifier.state = container.read(gameProvider).copyWith(
        diceRolled: true, productionRoll: 6, drawnEventCard: EraOfTurmoilCards.riots);
    await tester.pumpAndSettle();

    expect(
        find.text('Du har rätt Kapell för produktionstärningens '
            'resultat – gäller inte dig. Inget händer.'),
        findsOneWidget);
  });
}
