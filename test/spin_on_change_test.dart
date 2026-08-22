import 'dart:math' as math;

import 'package:catan_rivals/ui/widgets/spin_on_change.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar snurr-animationen på tärningarna (se DiceRollButton/
/// EventDieIcon) – ett helt varv (360°) varje gång [SpinOnChange.value]
/// ändras, tillbaka till exakt samma vinkel (0) när den är klar.
///
/// Finder scopas till just SpinOnChanges egen Transform – MaterialApp/
/// Scaffold kan innehålla andra Transform-widgetar internt, så en
/// oscopad `find.byType(Transform)` riskerar att matcha fler än en.
Finder _spinTransform() => find.descendant(
    of: find.byType(SpinOnChange<int>), matching: find.byType(Transform));

void main() {
  testWidgets('samma värde snurrar inte igen vid en vanlig ombyggnad',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SpinOnChange<int>(value: 3, child: Text('3'))),
    ));
    await tester.pumpAndSettle();

    // Bygg om med exakt samma värde.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SpinOnChange<int>(value: 3, child: Text('3'))),
    ));
    await tester.pump();

    // Ingen ny TweenAnimationBuilder-instans startades – findsOneWidget
    // (inte en overksam animation som fortfarande snurrar) räcker för
    // att visa att inget nytt kast triggades.
    expect(find.text('3'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
      'nytt värde snurrar (Transform.rotate icke-identitet mitt i animationen)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SpinOnChange<int>(value: 3, child: Text('3'))),
    ));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SpinOnChange<int>(value: 5, child: Text('5'))),
    ));
    // Mitt i animationen (250ms av 500ms) ska vinkeln inte vara 0.
    await tester.pump(const Duration(milliseconds: 250));

    final transform = tester.widget<Transform>(_spinTransform());
    final angle = _rotationAngle(transform);
    expect(angle, isNot(closeTo(0, 0.001)));
    expect(angle, isNot(closeTo(2 * math.pi, 0.001)));

    await tester.pumpAndSettle();
    final settledTransform = tester.widget<Transform>(_spinTransform());
    expect(_rotationAngle(settledTransform), closeTo(0, 0.001));
  });
}

double _rotationAngle(Transform transform) {
  final m = transform.transform;
  // atan2(m[1], m[0]) ger rotationsvinkeln för en ren 2D-rotation kring
  // Z-axeln, exakt det Transform.rotate(angle: ...) bygger.
  return math.atan2(m.getColumn(0)[1], m.getColumn(0)[0]);
}
