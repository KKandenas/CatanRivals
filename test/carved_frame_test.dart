import 'package:catan_rivals/ui/widgets/carved_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar den utsmyckade träramen (se carved_frame.dart) – rent
/// dekorativ, så testet begränsar sig till att den faktiskt renderar
/// sitt barn utan fel, och att [CarvedFrame.showRivets] styr om de
/// fyra hörn-"nitarna" finns med.
void main() {
  testWidgets('renderar sitt barn', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CarvedFrame(child: Text('Rike')),
      ),
    ));

    expect(find.text('Rike'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showRivets: false döljer hörnnitarna', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CarvedFrame(showRivets: false, child: Text('Rike')),
      ),
    ));

    expect(find.byType(Positioned), findsNothing);
  });

  testWidgets('showRivets: true (standard) visar 4 hörnnitar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CarvedFrame(child: Text('Rike')),
      ),
    ));

    expect(find.byType(Positioned), findsNWidgets(4));
  });
}
