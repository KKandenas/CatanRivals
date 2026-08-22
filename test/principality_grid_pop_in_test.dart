import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/pop_in.dart';
import 'package:catan_rivals/ui/widgets/principality_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att en tidigare tom byggplats som blir bebyggd (ny väg/by/
/// stad/region/utbyggnad) toppas in med PopIn (se "motståndaren ser
/// vilka actions man gör"-designen i game_board_screen.dart) – men att
/// en redan synlig, redan intonad byggnad INTE spelar om intoningen
/// bara för att andra delar av riket ritas om (annars skulle t.ex.
/// varje ny väg få hela riket att blinka om).
void main() {
  Widget buildGrid(RealmBoard board) {
    return MaterialApp(
      home: Scaffold(body: PrincipalityGrid(board: board)),
    );
  }

  testWidgets(
      'ny väg toppas in med en egen, färsk intoning – befintlig by påverkas inte',
      (tester) async {
    final board = RealmBoard(ownerId: 'test');
    board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));

    await tester.pumpWidget(buildGrid(board));
    await tester.pumpAndSettle();

    // Bara PopIns EGNA FadeTransition räknas – MaterialApp/PageRoute
    // lägger på egna FadeTransition-widgetar (sidövergången) som inte
    // har med kortens intoning att göra.
    final popInFades =
        find.descendant(of: find.byType(PopIn), matching: find.byType(FadeTransition));
    expect(popInFades, findsOneWidget, reason: 'bara byns egen PopIn hittills');
    final settledOpacity =
        tester.widget<FadeTransition>(popInFades).opacity.value;
    expect(settledOpacity, 1.0);

    board.placeRoad(1, const PlacedCard(card: BasicSetCards.road));
    await tester.pumpWidget(buildGrid(board));

    final fadeTransitions = tester.widgetList<FadeTransition>(popInFades).toList();
    expect(fadeTransitions, hasLength(2),
        reason: 'byn + den nya vägen, var sin PopIn');

    final opacities = fadeTransitions.map((w) => w.opacity.value).toList();
    expect(opacities.where((v) => v >= 0.999).length, 1,
        reason: 'byns intoning var redan klar och ska INTE spelas om');
    expect(opacities.where((v) => v < 0.999).length, 1,
        reason: 'vägens intoning är helt ny och ska börja om från 0');
  });
}
