import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/ui/widgets/region_expansion_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpView(WidgetTester tester,
      {int stored = 0, void Function(int)? onAdjust}) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 100,
          child: RegionExpansionCardView(
              card: EraOfGoldCards.goldCache, stored: stored, onAdjust: onAdjust),
        ),
      ),
    ));
  }

  testWidgets('tryck förstorar kortet via showCardDetail', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byType(RegionExpansionCardView));
    await tester.pumpAndSettle();

    expect(find.text(EraOfGoldCards.goldCache.name), findsOneWidget);
  });

  testWidgets('utan onAdjust visas ingen +/- knapp', (tester) async {
    await pumpView(tester);

    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets('+ anropar onAdjust(1), - anropar onAdjust(-1)', (tester) async {
    var delta = 0;
    await pumpView(tester, stored: 1, onAdjust: (d) => delta = d);

    await tester.tap(find.byIcon(Icons.add));
    expect(delta, 1);

    await tester.tap(find.byIcon(Icons.remove));
    expect(delta, -1);
  });

  // De små +/- knapparna sitter i ett hörn-märke avsett för
  // PrincipalityGrids överlagringsposition, inte en fristående, väl
  // tilltagen tryckyta – ett fysiskt tester.tap kan därför missa
  // hit-testet beroende på layout. Kollar i stället knapparnas
  // GestureDetector.onTap direkt (null = avstängd), robust oavsett
  // exakt pixelposition.
  GestureDetector adjustButtonFor(WidgetTester tester, IconData icon) =>
      tester
          .widgetList<GestureDetector>(find.ancestor(
              of: find.byIcon(icon), matching: find.byType(GestureDetector)))
          .first; // närmast ikonen - kortets EGNA GestureDetector är också en ancestor

  testWidgets('- är avstängd vid 0 lagrat (onTap null)', (tester) async {
    var calls = 0;
    await pumpView(tester, stored: 0, onAdjust: (_) => calls++);

    expect(adjustButtonFor(tester, Icons.remove).onTap, isNull);
    expect(adjustButtonFor(tester, Icons.add).onTap, isNotNull);
  });

  testWidgets('+ är avstängd vid 3 lagrat (onTap null)', (tester) async {
    await pumpView(tester, stored: 3, onAdjust: (_) {});

    expect(adjustButtonFor(tester, Icons.add).onTap, isNull);
    expect(adjustButtonFor(tester, Icons.remove).onTap, isNotNull);
  });
}
