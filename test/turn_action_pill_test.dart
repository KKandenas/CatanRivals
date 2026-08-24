import 'package:catan_rivals/state/game_state.dart';
import 'package:catan_rivals/ui/widgets/turn_action_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar TurnActionPill – flyttades hit från mittremsan
/// (CenterStacksStrip, se center_stacks_strip_peek_flash_test.dart för
/// resten av mittremsans egna tester) för att lämna mer plats åt
/// draghögarna där, se widgetens klassdoc.
void main() {
  Widget pillWidget({
    bool isYourTurn = true,
    bool diceRolled = true,
    bool isChoosingHand = false,
    HandAdjustmentPhase handAdjustmentPhase = HandAdjustmentPhase.none,
    TradePhase tradePhase = TradePhase.none,
    int handCount = 0,
    int handLimit = 3,
    VoidCallback? onEndTurn,
    int? peekingStackIndex,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TurnActionPill(
          isYourTurn: isYourTurn,
          diceRolled: diceRolled,
          isChoosingHand: isChoosingHand,
          handAdjustmentPhase: handAdjustmentPhase,
          tradePhase: tradePhase,
          handCount: handCount,
          handLimit: handLimit,
          onEndTurn: onEndTurn,
          peekingStackIndex: peekingStackIndex,
        ),
      ),
    );
  }

  testWidgets(
      'din tur, tärningen slagen, inget annat pågår: "Avsluta action-fas" och trycket anropar onEndTurn',
      (tester) async {
    var tapped = false;
    await tester
        .pumpWidget(pillWidget(onEndTurn: () => tapped = true));

    expect(find.text('Avsluta action-fas'), findsOneWidget);
    await tester.tap(find.text('Avsluta action-fas'));
    expect(tapped, isTrue);
  });

  testWidgets('handjustering (dra) visar "Dra kort: X/Y" i stället',
      (tester) async {
    await tester.pumpWidget(pillWidget(
        handAdjustmentPhase: HandAdjustmentPhase.drawing,
        handCount: 2,
        handLimit: 4));

    expect(find.text('Dra kort: 2/4'), findsOneWidget);
    expect(find.text('Avsluta action-fas'), findsNothing);
  });

  testWidgets('handjustering (släng) visar "Släng kort: X/Y" i stället',
      (tester) async {
    await tester.pumpWidget(pillWidget(
        handAdjustmentPhase: HandAdjustmentPhase.discarding,
        handCount: 5,
        handLimit: 4));

    expect(find.text('Släng kort: 5/4'), findsOneWidget);
  });

  testWidgets(
      'kortbytesfasen: ingen etikett här (visas i stället i TradePhaseCard)',
      (tester) async {
    await tester.pumpWidget(pillWidget(tradePhase: TradePhase.choosing));

    expect(find.text('Avsluta action-fas'), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('starthandsvalet: ingen etikett trots diceRolled=true',
      (tester) async {
    await tester.pumpWidget(pillWidget(isChoosingHand: true));

    expect(find.text('Avsluta action-fas'), findsNothing);
  });

  testWidgets(
      'motståndarens tur: peekingStackIndex visar en etikett med rätt högnummer (1-indexerat)',
      (tester) async {
    await tester
        .pumpWidget(pillWidget(isYourTurn: false, peekingStackIndex: 2));

    expect(find.text('Kikar i hög 3'), findsOneWidget);
  });

  testWidgets('motståndarens tur: ingen etikett när peekingStackIndex är null',
      (tester) async {
    await tester.pumpWidget(pillWidget(isYourTurn: false));

    expect(find.textContaining('Kikar i hög'), findsNothing);
  });

  testWidgets(
      'din egen tur: peekingStackIndex visas INTE (du kikar redan i din egen overlay)',
      (tester) async {
    await tester
        .pumpWidget(pillWidget(isYourTurn: true, peekingStackIndex: 1));

    expect(find.textContaining('Kikar i hög'), findsNothing);
  });
}
