import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/center_stacks_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att draghögarnas kortbaksida (se
/// GameNotifier._isThemeStackIndex/CenterStacksStrip._backAssetFor)
/// matchar det FAKTISKT aktiva temaset – rapporterad bugg: temasetets
/// egna högar (index 3-4) visade alltid Gulderans baksida, oavsett om
/// Oroligheternas tid faktiskt var aktivt.
void main() {
  const counts = {
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

  bool hasAsset(WidgetTester tester, String asset) => tester
      .widgetList<Image>(find.byType(Image))
      .any((img) => img.image is AssetImage &&
          (img.image as AssetImage).assetName == asset);

  testWidgets('utan tema: alla högar visar grundspelets baksida',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: counts,
          initialStackSizes: [9, 9, 9, 9],
        ),
      ),
    ));

    expect(hasAsset(tester, CatanAssets.backBasicSet), isTrue);
    expect(hasAsset(tester, CatanAssets.backEraGold), isFalse);
    expect(hasAsset(tester, CatanAssets.backEraTurmoil), isFalse);
  });

  testWidgets('med Gulderan: de två sista högarna visar Gulderans baksida',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: counts,
          initialStackSizes: [5, 6, 7, 8, 9],
          activeExpansions: {ExpansionSet.eraOfGold},
        ),
      ),
    ));

    expect(hasAsset(tester, CatanAssets.backBasicSet), isTrue);
    expect(hasAsset(tester, CatanAssets.backEraGold), isTrue);
    expect(hasAsset(tester, CatanAssets.backEraTurmoil), isFalse);
  });

  testWidgets(
      'med Oroligheternas tid: de två sista högarna visar Oroligheternas tids baksida',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: counts,
          initialStackSizes: [5, 6, 7, 8, 9],
          activeExpansions: {ExpansionSet.eraOfTurmoil},
        ),
      ),
    ));

    expect(hasAsset(tester, CatanAssets.backBasicSet), isTrue);
    expect(hasAsset(tester, CatanAssets.backEraTurmoil), isTrue);
    expect(hasAsset(tester, CatanAssets.backEraGold), isFalse);
  });
}
