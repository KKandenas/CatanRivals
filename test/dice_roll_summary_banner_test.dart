import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/dice_roll_summary_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder richTextContaining(String substring) => find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(substring));

  Future<void> pumpBanner(WidgetTester tester, EventDieFace face,
      {VoidCallback? onDismiss}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DiceRollSummaryBanner(
          productionRoll: 5,
          eventDieFace: face,
          rolledByMe: true,
          opponentName: 'Björn',
          onDismiss: onDismiss ?? () {},
        ),
      ),
    ));
  }

  testWidgets('visar produktionstalet, händelsenamnet och regeltexten',
      (tester) async {
    await pumpBanner(tester, EventDieFace.trade);

    expect(find.textContaining('5:a'), findsOneWidget);
    expect(richTextContaining(EventDieFace.trade.ruleText), findsOneWidget);
  });

  testWidgets(
      'brigadanfall visas ovanför resursraden (görs FÖRE), övriga händelser under (görs EFTER)',
      (tester) async {
    await pumpBanner(tester, EventDieFace.brigandAttack);
    final resourceY =
        tester.getTopLeft(find.textContaining('Ta dina resurser')).dy;
    final eventNameY = tester
        .getTopLeft(richTextContaining(EventDieFace.brigandAttack.swedishName))
        .dy;
    expect(eventNameY, lessThan(resourceY),
        reason: 'brigadanfallet ska stå ovanför resursraden');

    await pumpBanner(tester, EventDieFace.plentifulHarvest);
    final resourceY2 =
        tester.getTopLeft(find.textContaining('Ta dina resurser')).dy;
    final eventNameY2 = tester
        .getTopLeft(
            richTextContaining(EventDieFace.plentifulHarvest.swedishName))
        .dy;
    expect(eventNameY2, greaterThan(resourceY2),
        reason: 'riklig skörd ska stå under resursraden');
  });

  testWidgets('OK anropar onDismiss', (tester) async {
    var dismissed = false;
    await pumpBanner(tester, EventDieFace.celebration,
        onDismiss: () => dismissed = true);

    await tester.tap(find.text('OK'));
    await tester.pump();

    expect(dismissed, isTrue);
  });
}
