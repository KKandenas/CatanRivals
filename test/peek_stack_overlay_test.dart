import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/peek_stack_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cards = [
    BasicSetCards.grainMill,
    BasicSetCards.abbey,
    BasicSetCards.largeTradeShip,
  ];

  Future<void> pumpOverlay(WidgetTester tester, void Function(GameCard) onTakeCard) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PeekStackOverlay(cards: cards, onTakeCard: onTakeCard),
      ),
    ));
  }

  testWidgets('visar alla kort i högen och begränsar bredden till 640',
      (tester) async {
    await pumpOverlay(tester, (_) {});

    for (final card in cards) {
      expect(find.text(card.name), findsOneWidget);
    }

    final constrainedBox = tester
        .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
        .firstWhere((w) => w.constraints.maxWidth == 640);
    expect(constrainedBox.constraints.maxWidth, 640);
  });

  testWidgets(
      'tryck på ett kort förstorar det och frågar innan det tas – Avbryt stänger utan att ta kortet',
      (tester) async {
    GameCard? taken;
    await pumpOverlay(tester, (card) => taken = card);

    await tester.tap(find.text(cards.first.name));
    await tester.pumpAndSettle();

    expect(find.text('Vill du ta detta kort?'), findsOneWidget);
    expect(find.text('Ta kortet'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Avbryt'));
    await tester.pumpAndSettle();

    expect(find.text('Vill du ta detta kort?'), findsNothing);
    expect(taken, isNull);
  });

  testWidgets('tryck på Ta kortet i förstoringen anropar onTakeCard med rätt kort',
      (tester) async {
    GameCard? taken;
    await pumpOverlay(tester, (card) => taken = card);

    await tester.tap(find.text(cards[1].name));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Ta kortet'));
    await tester.pumpAndSettle();

    expect(taken, cards[1]);
    expect(find.text('Vill du ta detta kort?'), findsNothing);
  });
}
