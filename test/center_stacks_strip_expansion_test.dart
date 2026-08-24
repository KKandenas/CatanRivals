import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/center_stacks_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att [CenterStacksStrip] anpassar sig efter Gulderan (se
/// [GameState.initialDrawStackSizes]): 5 draghögar i stället för 4, med
/// olika kortbaksbild för grundspelets respektive Gulderans egna högar.
/// Den öppna ansikte-upp-högen visas inte längre här (flyttad till
/// [TopStatusBar]/[HandDock], se face_up_expansion_split_test.dart).
void main() {
  int imageCount(WidgetTester tester, String assetName) {
    return tester
        .widgetList<Image>(find.byType(Image))
        .where((img) => (img.image as AssetImage).assetName == assetName)
        .length;
  }

  int backBasicSetImageCount(WidgetTester tester) =>
      imageCount(tester, CatanAssets.backBasicSet);

  int backEraGoldImageCount(WidgetTester tester) =>
      imageCount(tester, CatanAssets.backEraGold);

  testWidgets('utan tema: 4 draghögar, alla med grundspelets kortbaksbild',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: {
            'roads': 5,
            'settlements': 3,
            'cities': 2,
            'draw1': 9,
            'draw2': 9,
            'draw3': 9,
            'draw4': 9,
            'event': 9,
          },
        ),
      ),
    ));

    expect(backBasicSetImageCount(tester), 4);
    expect(backEraGoldImageCount(tester), 0);
  });

  testWidgets(
      'med Gulderan: 5 draghögar, olika kortbaksbild för grundspel/Gulderan',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: {
            'roads': 5,
            'settlements': 3,
            'cities': 2,
            'draw1': 12,
            'draw2': 12,
            'draw3': 12,
            'draw4': 11,
            'draw5': 11,
            'event': 12,
          },
          initialStackSizes: [12, 12, 12, 11, 11],
        ),
      ),
    ));

    // De 3 grundspelshögarna (draw1-3) har grundspelets kortbaksbild,
    // de 2 Gulderan-egna högarna (draw4-5) en annan (se
    // CenterStacksStrip._backAssetFor) – annars skulle man inte kunna
    // se skillnad på högarna när man ska slänga ett kort tillbaka.
    expect(backBasicSetImageCount(tester), 3);
    expect(backEraGoldImageCount(tester), 2);
  });
}
