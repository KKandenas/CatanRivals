import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/screens/lobby_screen.dart';
import 'package:catan_rivals/ui/screens/rules_screen.dart';
import 'package:catan_rivals/ui/widgets/top_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar den nya regel-knappen och exit-knappen uppe till vänster
/// under spelet (se rules_button.dart/game_board_screen.dart:s
/// `_ExitButton`/`_confirmLeaveGame`) – att de finns, att exit-knappen
/// frågar innan den faktiskt lämnar matchen, och att de döljs bakom
/// [GameOverOverlay] när matchen redan är slut (annars två
/// "lämna"-vägar samtidigt).
void main() {
  Future<ProviderContainer> pumpBoard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier).playLocally();

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('"?"-knappen öppnar regelsidan', (tester) async {
    await pumpBoard(tester);

    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();

    expect(find.byType(RulesScreen), findsOneWidget);
  });

  testWidgets('exit-knappen frågar innan den lämnar, Avbryt stannar kvar',
      (tester) async {
    final container = await pumpBoard(tester);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Lämna spelet?'), findsOneWidget);
    await tester.tap(find.text('Avbryt'));
    await tester.pumpAndSettle();

    expect(find.byType(GameBoardScreen), findsOneWidget);
    expect(container.read(gameProvider).you.hand, isNotEmpty);
  });

  testWidgets('exit-knappen: "Lämna" går tillbaka till startskärmen',
      (tester) async {
    await pumpBoard(tester);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lämna'));
    await tester.pumpAndSettle();

    expect(find.byType(LobbyScreen), findsOneWidget);
  });

  testWidgets(
      'regel-/exit-knapparna döljs när matchen redan är slut (GameOverOverlay tar över)',
      (tester) async {
    final container = await pumpBoard(tester);
    final state = container.read(gameProvider);
    container.read(gameProvider.notifier).state =
        state.copyWith(winnerId: state.myPlayerId);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.logout), findsNothing);
    expect(find.text('?'), findsNothing);
    expect(find.text('Till huvudmenyn'), findsOneWidget);
  });

  testWidgets(
      '"DIN TUR"/"Avsluta action-fas" ligger i samma rad som Regler/Lämna, inte bakom dem',
      (tester) async {
    final container = await pumpBoard(tester);
    container.read(gameProvider.notifier).rollProductionDie();
    await tester.pumpAndSettle();

    expect(find.textContaining('DIN TUR'), findsOneWidget);
    expect(find.text('Avsluta action-fas'), findsOneWidget);

    // Regler, Lämna, "DIN TUR"-etiketten och "Avsluta action-fas" ska
    // alla ligga i EN OCH SAMMA Row – annars riskerar de överlappa
    // varandra igen (rapporterad bugg: "Avsluta action-fas" hamnade
    // dolt bakom Regler-/Lämna-knapparna, se commit-doc).
    final row = tester.widget<Row>(find.ancestor(
      of: find.text('Avsluta action-fas'),
      matching: find.byType(Row),
    ).first);
    expect(find.descendant(of: find.byWidget(row), matching: find.text('?')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byWidget(row), matching: find.byIcon(Icons.logout)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byWidget(row), matching: find.textContaining('DIN TUR')),
        findsOneWidget);

    // Regel-/Lämna-raden ska ligga OVANFÖR motståndarraden
    // (TopStatusBar), inte ovanpå den – annars (rapporterad bugg) ser
    // det ut som att de delar rad.
    final rowTop = tester.getTopLeft(find.byWidget(row)).dy;
    final statusBarTop = tester.getTopLeft(find.byType(TopStatusBar)).dy;
    expect(rowTop, lessThan(statusBarTop));

    await tester.tap(find.text('Avsluta action-fas'));
    await tester.pumpAndSettle();
    // Action-fasen är slut: antingen väntar handjusteringen (för
    // få/många kort) eller så gick det direkt vidare till
    // kortbytesfasen (rätt antal kort från start) – i det förra fallet
    // syns knappen inte längre, i det senare har fasen bytt.
    final state = container.read(gameProvider);
    expect(
        state.handAdjustmentPhase != HandAdjustmentPhase.none ||
            state.tradePhase != TradePhase.none,
        isTrue,
        reason: 'action-fasen ska ha avslutats');
  });
}
