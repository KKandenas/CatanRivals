import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/ui/widgets/event_card_reveal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('visar kortets namn och regeltext, och stäng-knappen anropar onDismiss',
      (tester) async {
    var dismissed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EventCardRevealCard(
          card: BasicSetCards.feud,
          onDismiss: () => dismissed = true,
        ),
      ),
    ));

    expect(find.text(BasicSetCards.feud.name), findsOneWidget);
    expect(find.text(BasicSetCards.feud.effectText!), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(dismissed, isTrue);
  });
}
