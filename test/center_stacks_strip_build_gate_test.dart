import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/center_stacks_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att väg-/by-/stadshögarna inte går att dra ut när
/// [CenterStacksStrip.canBuild] är falskt (speltestad bugg: gick
/// tidigare att dra ut ett kort och först mötas av ett felmeddelande
/// efter "Betalt", i stället för att kortet inte gick att dra alls).
/// De ska fortfarande gå att trycka på för att förstora.
void main() {
  Future<void> pumpStrip(WidgetTester tester, {required bool canBuild}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: const {
            'roads': 5,
            'settlements': 3,
            'cities': 2,
            'regions': 8,
            'draw1': 9,
            'draw2': 9,
            'draw3': 9,
            'draw4': 9,
            'event': 9,
          },
          diceRolled: true,
          canBuild: canBuild,
        ),
      ),
    ));
  }

  testWidgets('canBuild=false: ingen LongPressDraggable för väg/by/stad',
      (tester) async {
    await pumpStrip(tester, canBuild: false);

    expect(find.byType(LongPressDraggable<GameCard>), findsNothing);
  });

  testWidgets('canBuild=true: väg/by/stad är dragbara', (tester) async {
    await pumpStrip(tester, canBuild: true);

    expect(find.byType(LongPressDraggable<GameCard>), findsNWidgets(3));
  });
}
