import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/widgets/dice_roll_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att Församlingshus (BasicSetCards.parishHall: "Du betalar
/// bara 1 resurs för att välja ett kort från en draghög") faktiskt
/// sänker kika-kostnaden i kortbytesfasens banner (se
/// trade_phase_card.dart:peekCost), i stället för att bara vara en
/// obekräftad regeltext på kortet.
void main() {
  Future<ProviderContainer> setup(WidgetTester tester,
      {bool withParishHall = false}) async {
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

    if (withParishHall) {
      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.parishHall));
    }

    await tester.pumpAndSettle();

    await tester.tap(find.byType(DiceRollButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avsluta action-fas'));
    await tester.pumpAndSettle();
    expect(container.read(gameProvider).tradePhase, TradePhase.choosing);

    return container;
  }

  testWidgets('utan Församlingshus kostar det 2 resurser att kika',
      (tester) async {
    await setup(tester);

    expect(find.text('Kika (2 resurser)'), findsOneWidget);
    expect(find.text('Kika (1 resurs)'), findsNothing);
  });

  testWidgets(
      'med Församlingshus i riket kostar det bara 1 resurs att kika, i knappen och i betaltexten',
      (tester) async {
    final container = await setup(tester, withParishHall: true);

    expect(find.text('Kika (1 resurs)'), findsOneWidget);
    expect(find.text('Kika (2 resurser)'), findsNothing);

    await tester.tap(find.text('Kika (1 resurs)'));
    await tester.pumpAndSettle();
    expect(container.read(gameProvider).tradePhase, TradePhase.peekPaying);

    expect(
        find.text(
            'Betala 1 valfri resurs genom att trycka − på valfria regioner.'),
        findsOneWidget);
  });
}
