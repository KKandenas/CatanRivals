import 'package:catan_rivals/state/game_state.dart';
import 'package:catan_rivals/ui/widgets/center_stacks_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att ett handkort bara går att slänga till en draghög av samma
/// set som kortet ursprungligen kom ifrån (se
/// GameNotifier._checkStackMatchesCardOrigin) – ett grundspelskort ska
/// bara highlighta/gå att trycka på de 3 grundspelshögarna (draw1-3),
/// ett Gulderan-kort bara de 2 Gulderan-egna högarna (draw4-5). Olika
/// antal per hög (5/6/7/8/9) så varje pile hittas unikt via sin
/// räknarbricka.
void main() {
  const goldCounts = {
    'roads': 1,
    'settlements': 1,
    'cities': 1,
    'draw1': 5,
    'draw2': 6,
    'draw3': 7,
    'draw4': 8,
    'draw5': 9,
    'event': 12,
  };

  Widget buildStrip({
    required bool hasSelectedDiscardCard,
    required bool? selectedDiscardCardIsThemeCard,
    required void Function(int) onDiscardToStack,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: goldCounts,
          initialStackSizes: const [5, 6, 7, 8, 9],
          handAdjustmentPhase: HandAdjustmentPhase.discarding,
          hasSelectedDiscardCard: hasSelectedDiscardCard,
          selectedDiscardCardIsThemeCard: selectedDiscardCardIsThemeCard,
          onDiscardToStack: onDiscardToStack,
        ),
      ),
    );
  }

  /// `count` identifierar en unik pile (se [goldCounts]) – hittar dess
  /// egen GestureDetector (bara dragbara/tryckbara pile har en, se
  /// CenterStacksStrip._StackPile) om den finns.
  Finder pileGestureDetector(int count) => find.ancestor(
      of: find.text('$count'), matching: find.byType(GestureDetector));

  testWidgets(
      'grundspelskort valt: bara draw1-3 (grundspelshögarna) går att trycka på',
      (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(buildStrip(
      hasSelectedDiscardCard: true,
      selectedDiscardCardIsThemeCard: false,
      onDiscardToStack: tapped.add,
    ));

    expect(pileGestureDetector(5), findsOneWidget); // draw1
    expect(pileGestureDetector(6), findsOneWidget); // draw2
    expect(pileGestureDetector(7), findsOneWidget); // draw3
    expect(pileGestureDetector(8), findsNothing); // draw4 (Gulderan)
    expect(pileGestureDetector(9), findsNothing); // draw5 (Gulderan)

    await tester.tap(pileGestureDetector(6));
    expect(tapped, [1]); // draw2 = index 1
  });

  testWidgets(
      'Gulderan-kort valt: bara draw4-5 (Gulderan-högarna) går att trycka på',
      (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(buildStrip(
      hasSelectedDiscardCard: true,
      selectedDiscardCardIsThemeCard: true,
      onDiscardToStack: tapped.add,
    ));

    expect(pileGestureDetector(5), findsNothing);
    expect(pileGestureDetector(6), findsNothing);
    expect(pileGestureDetector(7), findsNothing);
    expect(pileGestureDetector(8), findsOneWidget); // draw4
    expect(pileGestureDetector(9), findsOneWidget); // draw5

    await tester.tap(pileGestureDetector(9));
    expect(tapped, [4]); // draw5 = index 4
  });

  testWidgets('inget kort valt: ingen hög går att trycka på', (tester) async {
    await tester.pumpWidget(buildStrip(
      hasSelectedDiscardCard: false,
      selectedDiscardCardIsThemeCard: null,
      onDiscardToStack: (_) {},
    ));

    for (final count in [5, 6, 7, 8, 9]) {
      expect(pileGestureDetector(count), findsNothing);
    }
  });
}
