import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/stack_choice_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att StackChoiceOverlay (Fejds bygg-borttagning/Brödrafejds
/// handkortsval) visar rätt kortbaksida per hög – rapporterad bugg:
/// alla högar visade grundspelets baksida, även temasetets egna (t.ex.
/// Oroligheternas tids högar visade i praktiken ingen egen baksida
/// alls). "Alla kort ska läggas tillbaka till rätt hög beroende på
/// vilken baksida de har" – se StackChoiceOverlay._backAssetFor, samma
/// indelning som CenterStacksStrip/GameNotifier._isThemeStackIndex.
void main() {
  List<String> assetsShown(WidgetTester tester) => tester
      .widgetList<Image>(find.byType(Image))
      .map((img) => (img.image as AssetImage).assetName)
      .toList();

  testWidgets('utan tema (4 högar): alla visar grundspelets baksida',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StackChoiceOverlay(
          title: 't',
          stackCount: 4,
          onChooseStack: (_) {},
        ),
      ),
    ));

    final assets = assetsShown(tester);
    expect(assets, hasLength(4));
    expect(assets.every((a) => a == CatanAssets.backBasicSet), isTrue);
  });

  testWidgets(
      'med Gulderan (5 högar): de tre första grundspelet, de två sista Gulderans baksida',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StackChoiceOverlay(
          title: 't',
          stackCount: 5,
          activeExpansions: const {ExpansionSet.eraOfGold},
          onChooseStack: (_) {},
        ),
      ),
    ));

    final assets = assetsShown(tester);
    expect(assets.sublist(0, 3),
        everyElement(CatanAssets.backBasicSet));
    expect(assets.sublist(3, 5), everyElement(CatanAssets.backEraGold));
  });

  testWidgets(
      'med Oroligheternas tid (5 högar): de två sista visar dess egna baksida',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StackChoiceOverlay(
          title: 't',
          stackCount: 5,
          activeExpansions: const {ExpansionSet.eraOfTurmoil},
          onChooseStack: (_) {},
        ),
      ),
    ));

    final assets = assetsShown(tester);
    expect(assets.sublist(0, 3),
        everyElement(CatanAssets.backBasicSet));
    expect(assets.sublist(3, 5), everyElement(CatanAssets.backEraTurmoil));
  });

  testWidgets(
      'Duel of the Princes (6 högar): grundspelet + var sin temabaksida, inte allihop grundspelets',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StackChoiceOverlay(
          title: 't',
          stackCount: 6,
          activeExpansions: const {
            ExpansionSet.eraOfGold,
            ExpansionSet.eraOfTurmoil,
            ExpansionSet.eraOfProgress,
          },
          onChooseStack: (_) {},
        ),
      ),
    ));

    final assets = assetsShown(tester);
    expect(assets, hasLength(6));
    expect(assets.sublist(0, 3), everyElement(CatanAssets.backBasicSet));
    expect(assets[3], CatanAssets.backEraGold);
    expect(assets[4], CatanAssets.backEraTurmoil);
    expect(assets[5], CatanAssets.backEraProgress);
  });
}
