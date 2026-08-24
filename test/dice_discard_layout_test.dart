import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/widgets/center_stacks_strip.dart';
import 'package:catan_rivals/ui/widgets/dice_roll_button.dart';
import 'package:catan_rivals/ui/widgets/discard_pile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att tärningarna och slänghögen ligger i var sin ände av den
/// smala kolumnen till höger om motståndarens rike (se
/// game_board_screen.dart): tärningarna längst upp, slänghögen längst
/// ner – precis ovanför mittremsan (CenterStacksStrip) som följer
/// direkt under, i stället för centrerat eller klistrat direkt under
/// tärningarna (rapporterad bugg: stort, obalanserat tomrum i mitten).
void main() {
  testWidgets(
      'slänghögen ligger längst ner i kolumnen, nära mittremsan – inte direkt under tärningarna',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();
    // playLocally() ger en tom slänghög – lägger till ett kort direkt i
    // state (utan tema är _discardToPile ett no-op, se
    // gold_stack_origin_test.dart/game_notifier_test.dart) för att
    // testa layouten med en synlig slänghög.
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(discardPile: [BasicSetCards.storehouse]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    final diceBottom = tester.getBottomLeft(find.byType(DiceRollButton)).dy;
    final discardTop = tester.getTopLeft(find.byType(DiscardPileView)).dy;
    final centerStripTop =
        tester.getTopLeft(find.byType(CenterStacksStrip)).dy;

    expect(discardTop, greaterThan(diceBottom),
        reason: 'slänghögen ska ligga under tärningarna');
    // Avståndet ner till mittremsan ska vara mindre än avståndet upp
    // till tärningarna – annars flyter slänghögen fortfarande i mitten
    // av kolumnen i stället för att ligga nära botten.
    final gapDownToCenterStrip = centerStripTop - discardTop;
    final gapUpToDice = discardTop - diceBottom;
    expect(gapDownToCenterStrip, lessThan(gapUpToDice));
  });
}
