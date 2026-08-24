import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/principality_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att en redan bebyggd byggplats bara är ett giltigt drop-mål
/// (för "byt ut byggnad") när [PrincipalityGrid.allowReplaceExpansion]
/// är sant – annars ska den vara statisk exakt som utan temaset, precis
/// som innan byt-ut-mekaniken fanns (rapporterad bugg: mekaniken var
/// aktiv även i rent grundspel, se GameNotifier._checkReplaceAllowed).
void main() {
  RealmBoard buildBoardWithOccupiedSite() {
    final board = RealmBoard(ownerId: 'test');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
    board.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.storehouse));
    return board;
  }

  Widget buildGrid(RealmBoard board, {required bool allowReplaceExpansion}) {
    return MaterialApp(
      home: Scaffold(
        body: PrincipalityGrid(
          board: board,
          interactive: true,
          allowReplaceExpansion: allowReplaceExpansion,
          onDropExpansion: (_, __, ___, ____) {},
          onRequestBuildConfirm: (_, __, {replacedCard}) {},
        ),
      ),
    );
  }

  testWidgets(
      'allowReplaceExpansion: false – en upptagen byggplats är INTE ett drop-mål',
      (tester) async {
    final board = buildBoardWithOccupiedSite();
    await tester.pumpWidget(buildGrid(board, allowReplaceExpansion: false));

    final occupiedSiteTargets = find.ancestor(
      of: find.text(BasicSetCards.storehouse.name),
      matching: find.byType(DragTarget<GameCard>),
    );
    expect(occupiedSiteTargets, findsNothing);
  });

  testWidgets(
      'allowReplaceExpansion: true – en upptagen byggplats ÄR ett drop-mål (byt ut)',
      (tester) async {
    final board = buildBoardWithOccupiedSite();
    await tester.pumpWidget(buildGrid(board, allowReplaceExpansion: true));

    final occupiedSiteTargets = find.ancestor(
      of: find.text(BasicSetCards.storehouse.name),
      matching: find.byType(DragTarget<GameCard>),
    );
    expect(occupiedSiteTargets, findsOneWidget);
  });
}
