import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/expansion_card_view.dart';
import 'package:catan_rivals/ui/widgets/starting_hand_draft_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pool = [
    BasicSetCards.grainMill,
    BasicSetCards.abbey,
    BasicSetCards.largeTradeShip,
    BasicSetCards.harald,
  ];

  Future<void> pumpPicker(
      WidgetTester tester, int pickedCount, void Function(GameCard) onPick) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StartingHandDraftPicker(
            pool: pool, pickedCount: pickedCount, onPick: onPick),
      ),
    ));
  }

  testWidgets('renderar alla kort i poolen och visar hur många som valts',
      (tester) async {
    await pumpPicker(tester, 1, (_) {});

    expect(find.byType(ExpansionCardView), findsNWidgets(pool.length));
    expect(find.text('Starthand: välj 1/3 kort ur högen (tryck för att förstora)'),
        findsOneWidget);
  });

  testWidgets(
      'tryck på ett kort förstorar det, och "Ta kortet" anropar onPick med rätt kort',
      (tester) async {
    GameCard? picked;
    await pumpPicker(tester, 0, (card) => picked = card);

    await tester.tap(find.byType(ExpansionCardView).at(2));
    await tester.pumpAndSettle();

    expect(find.text('Vill du ta detta kort?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Ta kortet'));
    await tester.pumpAndSettle();

    expect(picked, pool[2]);
  });
}
