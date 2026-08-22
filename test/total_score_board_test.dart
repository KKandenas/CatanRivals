import 'package:catan_rivals/ui/widgets/total_score_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar guldmyntets puls-mikroanimation (se _GoldCoin i
/// total_score_board.dart) – ska pulsera (skala upp) när segerpoängen
/// ökar, men inte när den är oförändrad eller minskar (poäng minskar
/// aldrig i praktiken, men widgeten ska ändå inte pulsera i onödan).
void main() {
  Widget board({required int youPoints}) => MaterialApp(
        home: Scaffold(
          body: TotalScoreBoard(
            youName: 'Du',
            youPoints: youPoints,
            amIRed: true,
            opponentName: 'Björn',
            opponentPoints: 2,
          ),
        ),
      );

  double maxScale(WidgetTester tester) => tester
      .widgetList<Transform>(find.byType(Transform))
      .map((t) => t.transform.getMaxScaleOnAxis())
      .reduce((a, b) => a > b ? a : b);

  testWidgets(
      'ingen puls vid första renderingen (ingen tidigare poäng att jämföra med)',
      (tester) async {
    await tester.pumpWidget(board(youPoints: 2));

    expect(maxScale(tester), closeTo(1.0, 0.001));
  });

  testWidgets('pulserar (skalar upp) när poängen ökar', (tester) async {
    await tester.pumpWidget(board(youPoints: 2));
    await tester.pumpAndSettle();

    await tester.pumpWidget(board(youPoints: 3));
    await tester.pump(const Duration(milliseconds: 150));

    expect(maxScale(tester), greaterThan(1.05));

    await tester.pumpAndSettle();
    expect(maxScale(tester), closeTo(1.0, 0.001));
  });

  testWidgets('ingen puls när poängen är oförändrad', (tester) async {
    await tester.pumpWidget(board(youPoints: 2));
    await tester.pumpAndSettle();

    await tester.pumpWidget(board(youPoints: 2));
    await tester.pump(const Duration(milliseconds: 150));

    expect(maxScale(tester), closeTo(1.0, 0.001));
  });
}
