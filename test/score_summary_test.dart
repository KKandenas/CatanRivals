import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/score_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar ScoreSummary (den kompakta poängrutan i HandDock/
/// TopStatusBar): segerpoängen (VP) ska stå på en egen rad och synas
/// tydligt större än de andra poängtyperna (styrka/handel/färdighet/
/// framsteg), i stället för att alla ligga i en enda rad med samma
/// storlek.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  Image imageFor(WidgetTester tester, String asset) =>
      tester.widget<Image>(find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == asset));

  testWidgets('VP-ikonen är större än en vanlig poängikon (t.ex. styrka)',
      (tester) async {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.placeExpansion(
        0,
        BuildingRow.above,
        0,
        PlacedCard(card: BasicSetCards.austin.copyWith(strengthPoints: 2)));
    final player = Player(id: 'you', name: 'Astrid', principality: board);

    await pump(
        tester,
        ScoreSummary(
          player: player,
          totalVictoryPoints: 5,
        ));

    final vpImage = imageFor(tester, CatanAssets.pointVictory);
    final strengthImage = imageFor(tester, CatanAssets.pointStrength);

    expect(vpImage.width, greaterThan(strengthImage.width!));
    expect(vpImage.height, greaterThan(strengthImage.height!));
  });

  testWidgets(
      'VP ligger på en egen rad ovanför de andra poängtyperna (annan vertikal position)',
      (tester) async {
    final board = RealmBoard(ownerId: 'you');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.placeExpansion(
        0,
        BuildingRow.above,
        0,
        PlacedCard(card: BasicSetCards.austin.copyWith(strengthPoints: 2)));
    final player = Player(id: 'you', name: 'Astrid', principality: board);

    await pump(
        tester,
        ScoreSummary(
          player: player,
          totalVictoryPoints: 5,
        ));

    final vpTop = tester.getTopLeft(find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == CatanAssets.pointVictory)).dy;
    final strengthTop = tester.getTopLeft(find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == CatanAssets.pointStrength)).dy;

    expect(strengthTop, greaterThan(vpTop));
  });

  testWidgets(
      'utan några övriga poäng (bara VP) visas ingen tom andra rad',
      (tester) async {
    final player =
        Player(id: 'you', name: 'Astrid', principality: RealmBoard(ownerId: 'you'));

    await pump(
        tester,
        ScoreSummary(
          player: player,
          totalVictoryPoints: 2,
        ));

    expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == CatanAssets.pointStrength),
        findsNothing);
  });
}
