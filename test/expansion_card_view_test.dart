import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/expansion_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, GameCard card) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
            width: 80, height: 80, child: ExpansionCardView(card: card)),
      ),
    ));
  }

  testWidgets(
      'shows flanking neighbor ribbons for cards that affect both neighboring regions',
      (tester) async {
    await pumpCard(tester, BasicSetCards.grainMill);

    // De två pilbanderollerna (se _NeighborRibbon) är privata, men
    // formen ritas alltid med ett ClipPath – två stycken (vänster och
    // höger) är ett tillförlitligt, publikt sätt att räkna dem.
    expect(find.byType(ClipPath), findsNWidgets(2));
    expect(find.text('2x'), findsNWidgets(2));
  });

  testWidgets('does not show ribbons for cards without the effect',
      (tester) async {
    await pumpCard(tester, BasicSetCards.abbey);

    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('large trade ship shows 2:1 ribbons, a resource-specific ship shows a corner badge',
      (tester) async {
    await pumpCard(tester, BasicSetCards.largeTradeShip);
    expect(find.byType(ClipPath), findsNWidgets(2));
    expect(find.text('2:1'), findsNWidgets(2));

    await pumpCard(tester, BasicSetCards.grainShip);
    expect(find.byType(ClipPath), findsNothing);
    expect(find.text('2:1'), findsOneWidget);
  });
}
