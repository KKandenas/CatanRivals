import 'package:catan_rivals/ui/widgets/starting_region_rearrangement_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBar(
      WidgetTester tester, bool hasFirstSelection, VoidCallback onFinish) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StartingRegionRearrangementBar(
            hasFirstSelection: hasFirstSelection, onFinish: onFinish),
      ),
    ));
  }

  testWidgets('utan första valet: instruktionstext för fri omflyttning',
      (tester) async {
    await pumpBar(tester, false, () {});

    expect(
        find.text(
            'Fri omflyttning: byt plats på så många av dina 6 regioner du vill, tryck sedan Klar.'),
        findsOneWidget);
    expect(find.text('Klar'), findsOneWidget);
  });

  testWidgets('med första valet: byt ut instruktionstexten', (tester) async {
    await pumpBar(tester, true, () {});

    expect(
        find.text(
            'Tryck på ännu en egen region för att byta plats med den första.'),
        findsOneWidget);
  });

  testWidgets('"Klar" anropar onFinish', (tester) async {
    var finished = false;
    await pumpBar(tester, false, () => finished = true);

    await tester.tap(find.widgetWithText(FilledButton, 'Klar'));
    await tester.pump();

    expect(finished, isTrue);
  });
}
