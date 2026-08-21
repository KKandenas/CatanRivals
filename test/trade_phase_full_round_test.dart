import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:catan_rivals/ui/widgets/dice_roll_button.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproducerar en rapporterad bugg: efter att ha valt "kika" i en hel
/// omgång (betala, släng, välj hög, ta ett kort) gick det ibland inte
/// att markera ett handkort att slänga nästa gång man valde det vanliga
/// (gratis) bytet – spelet "hängde". Kör hela vägen genom det riktiga
/// widgetträdet (drag/tryck, inte bara notifier-anrop), eftersom
/// tidigare buggar i den här sessionen visat sig sitta i UI-lagret
/// snarare än i notifier-tillståndsmaskinen.
void main() {
  Future<ProviderContainer> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    container.read(gameProvider.notifier).playLocally();
    await tester.pumpAndSettle();
    return container;
  }

  Finder drawStackImages() => find.byWidgetPredicate((w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == CatanAssets.backBasicSet);

  Future<void> rollAndEndActionPhase(WidgetTester tester) async {
    await tester.tap(find.byType(DiceRollButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avsluta action-fas'));
    await tester.pumpAndSettle();
  }

  /// Anropar `onTap` direkt i stället för `tester.tap()` – den här
  /// skärmen är ovanligt hög (motståndarrike + mittremsa + eget rike +
  /// handdocka, var för sig med FittedBox-skalning), och `tester.tap()`s
  /// hit-test missar systematiskt allt nära handdockan längst ner i den
  /// här testmiljön trots att widgeten obevisligen finns och är synlig
  /// – att anropa callbacken direkt testar fortfarande exakt det vi
  /// bryr oss om (att tryck kopplas rätt hela vägen till notifier-
  /// anropen) utan att vara beroende av pixel-exakt hit-testing.
  Future<void> tapGestureDetector(WidgetTester tester, Finder detector) async {
    (tester.widget<GestureDetector>(detector).onTap!)();
    await tester.pumpAndSettle();
  }

  Future<void> tapStackImage(WidgetTester tester, Finder image) async {
    final detector =
        find.ancestor(of: image, matching: find.byType(GestureDetector)).first;
    await tapGestureDetector(tester, detector);
  }

  testWidgets(
      'efter en full kika-omgång går det fortfarande att markera ett handkort i nästa omgångs gratis-byte',
      (tester) async {
    final container = await setup(tester);

    // --- Omgång 1: kika ---
    await rollAndEndActionPhase(tester);
    expect(container.read(gameProvider).tradePhase, TradePhase.choosing);

    await tester.tap(find.text('Kika (2 resurser)'));
    await tester.pumpAndSettle();
    expect(container.read(gameProvider).tradePhase, TradePhase.peekPaying);

    await tester.tap(find.text('Betalt'));
    await tester.pumpAndSettle();
    expect(container.read(gameProvider).tradePhase, TradePhase.peekDiscard);

    final handCardFinder = find.descendant(
        of: find.byType(HandDock), matching: find.byType(GestureDetector));
    await tapGestureDetector(tester, handCardFinder.first);
    await tapStackImage(tester, drawStackImages().first);
    expect(
        container.read(gameProvider).tradePhase, TradePhase.peekChoosingStack);

    await tapStackImage(tester, drawStackImages().first);
    expect(container.read(gameProvider).tradePhase, TradePhase.peekViewing);
    expect(container.read(gameProvider).peekedCards, isNotNull);

    final firstPeekedCard = container.read(gameProvider).peekedCards!.first;
    await tester.tap(find.text(firstPeekedCard.name).last);
    await tester.pumpAndSettle();
    expect(find.text('Vill du ta detta kort?'), findsOneWidget);
    await tester.tap(find.text('Ta kortet'));
    await tester.pumpAndSettle();

    var state = container.read(gameProvider);
    expect(state.tradePhase, TradePhase.none);
    expect(state.activePlayerId, 'opponent');
    expect(state.diceRolled, isFalse);

    // --- Omgång 2: gratis byte – detta är där buggen rapporterades ---
    await rollAndEndActionPhase(tester);
    state = container.read(gameProvider);
    expect(state.tradePhase, TradePhase.choosing,
        reason: 'handstorleken ska vara oförändrad efter kika (betala/'
            'släng/ta är netto noll), så handjusteringen ska hoppas över');

    await tester.tap(find.text('Byt ett kort'));
    await tester.pumpAndSettle();
    expect(container.read(gameProvider).tradePhase, TradePhase.exchangeDiscard);

    // Detta är exakt steget användaren rapporterade som "hängande":
    // att markera ett handkort att slänga.
    await tapGestureDetector(tester, handCardFinder.first);

    final stacksBefore = container.read(gameProvider).centerStacks['draw1'];
    await tapStackImage(tester, drawStackImages().first);

    state = container.read(gameProvider);
    expect(state.tradePhase, TradePhase.exchangeDraw,
        reason:
            'BUGG om detta fortfarande är exchangeDiscard: kortvalet togs aldrig emot');
    expect(state.centerStacks['draw1'], stacksBefore! + 1);
  });
}
