import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/event_die_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar två speltestbuggar: händelsetärningen visade en generisk
/// tärningsikon (som visuellt liknar en femma) innan första kastet i
/// stället för en av dess egna sidor, och gick inte att trycka på för
/// att slå (bara produktionstärningen var klickbar).
void main() {
  testWidgets('innan första kastet (face: null) visas "?"-sidans bild, inte en generisk ikon',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EventDieIcon(face: null)),
    ));

    expect(find.byIcon(Icons.casino), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, CatanAssets.eventDieEventCard);
  });

  testWidgets('en riktig sida visar den sidans egen bild', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EventDieIcon(face: EventDieFace.trade)),
    ));

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, CatanAssets.eventDieTrade);
  });

  testWidgets('rollable+onTap gör tärningen tryckbar', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EventDieIcon(
          face: null,
          rollable: true,
          onTap: () => tapped = true,
        ),
      ),
    ));

    await tester.tap(find.byType(EventDieIcon));
    expect(tapped, isTrue);
  });

  testWidgets('utan rollable ignoreras tryck (inget GestureDetector)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EventDieIcon(face: null)),
    ));

    expect(find.byType(GestureDetector), findsNothing);
  });
}
