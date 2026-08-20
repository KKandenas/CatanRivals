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
      'shows flanking arrows for cards that affect both neighboring regions',
      (tester) async {
    await pumpCard(tester, BasicSetCards.grainMill);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });

  testWidgets('does not show arrows for cards without the effect',
      (tester) async {
    await pumpCard(tester, BasicSetCards.abbey);

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.arrow_forward), findsNothing);
  });
}
