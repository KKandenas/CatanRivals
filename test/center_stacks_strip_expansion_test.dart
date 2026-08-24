import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/center_stacks_strip.dart';
import 'package:catan_rivals/ui/widgets/expansion_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att [CenterStacksStrip] anpassar sig efter Gulderan (se
/// [GameState.initialDrawStackSizes]/[GameState.faceUpExpansionCards]):
/// 5 draghögar i stället för 4, och den öppna ansikte-upp-högen visas
/// (och går att dra ut) när den inte är tom.
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

  testWidgets('utan tema: 4 draghögar', (tester) async {
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
    expect(find.byType(ExpansionCardView), findsNothing);
  });

  testWidgets('med Gulderan: 5 draghögar och den öppna ansikte-upp-högen',
      (tester) async {
    final faceUp = [
      EraOfGoldCards.merchantGuild.copyWith(id: 'city-expansion-merchant-guild-faceup-0'),
      EraOfGoldCards.merchantGuild.copyWith(id: 'city-expansion-merchant-guild-faceup-1'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: const {
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
          initialStackSizes: const [12, 12, 12, 11, 11],
          faceUpExpansionCards: faceUp,
        ),
      ),
    ));

    // De 3 grundspelshögarna (draw1-3) har grundspelets kortbaksbild,
    // de 2 Gulderan-egna högarna (draw4-5) en annan (se
    // CenterStacksStrip._backAssetFor) – annars skulle man inte kunna
    // se skillnad på högarna när man ska slänga ett kort tillbaka.
    expect(backBasicSetImageCount(tester), 3);
    expect(backEraGoldImageCount(tester), 2);
    expect(find.byType(ExpansionCardView), findsNWidgets(2));
  });

  testWidgets('ansikte-upp-kort är dragbara när canBuild är true, inte annars',
      (tester) async {
    final faceUp = [
      EraOfGoldCards.merchantGuild.copyWith(id: 'city-expansion-merchant-guild-faceup-0'),
    ];

    Future<void> pump(bool canBuild) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: CenterStacksStrip(
              stackCounts: const {
                'roads': 5,
                'settlements': 3,
                'cities': 2,
                'draw1': 9,
                'draw2': 9,
                'draw3': 9,
                'draw4': 9,
                'event': 9,
              },
              faceUpExpansionCards: faceUp,
              canBuild: canBuild,
            ),
          ),
        ));

    await pump(true);
    // 3 (väg/by/stad) + 1 ansikte-upp-kort.
    expect(find.byType(LongPressDraggable<GameCard>), findsNWidgets(4));

    await pump(false);
    expect(find.byType(LongPressDraggable<GameCard>), findsNothing);
    // Kortet ska fortfarande synas, bara inte dragbart.
    expect(find.byType(ExpansionCardView), findsOneWidget);
  });
}
