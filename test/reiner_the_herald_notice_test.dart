import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar texten som visas direkt efter att Reiner härolden spelats
/// (se GameNotifier.useReinerTheHerald-doc: den extra resursen som
/// kortets egen effectText utlovar dras inte av automatiskt, bara en
/// påminnande text, precis som Stapelhus-texten).
void main() {
  testWidgets(
      'spelar man Reiner härolden visas en SnackBar om att man får en extra resurs',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();
    // INGEN rollProductionDie() – Reiner härolden måste spelas innan
    // tärningen slås (se useReinerTheHerald-doc).

    final before = container.read(gameProvider);
    notifier.state =
        before.copyWith(you: before.you.copyWith(hand: [
          ...before.you.hand,
          EraOfGoldCards.reinerTheHerald,
        ]));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    final handCard = find.descendant(
        of: find.byType(HandDock), matching: find.text('Reiner härolden'));
    await tester.tap(handCard);
    await tester.pumpAndSettle();

    expect(find.text('Vill du använda kortet?'), findsOneWidget);
    await tester.tap(find.text('Använd kortet'));
    await tester.pump();

    expect(
        find.text('Du spelade Reiner härolden och får en extra resurs.'),
        findsOneWidget);
  });
}
