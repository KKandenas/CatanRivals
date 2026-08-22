import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/ui/widgets/card_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar handlingskortens "tvåstegsraket" (se HandDock/game_notifier.dart):
/// [showCardDetail]s [onUseCard]-krok, som visar "Vill du använda
/// kortet?" i stället för [onTakeCard]s "Vill du ta detta kort?".
void main() {
  Future<void> pumpAndOpen(WidgetTester tester, VoidCallback onUseCard) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCardDetail(
                context, BasicSetCards.merchantCaravan,
                onUseCard: onUseCard),
            child: const Text('öppna'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('öppna'));
    await tester.pumpAndSettle();
  }

  testWidgets('visar "Vill du använda kortet?" och Avbryt stänger utan att anropa onUseCard',
      (tester) async {
    var used = false;
    await pumpAndOpen(tester, () => used = true);

    expect(find.text('Vill du använda kortet?'), findsOneWidget);
    expect(find.text('Använd kortet'), findsOneWidget);
    // Inte samma fråga/knapp som "ta kort"-varianten.
    expect(find.text('Vill du ta detta kort?'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Avbryt'));
    await tester.pumpAndSettle();

    expect(used, isFalse);
    expect(find.text('Vill du använda kortet?'), findsNothing);
  });

  testWidgets('tryck på Använd kortet anropar onUseCard och stänger dialogrutan',
      (tester) async {
    var used = false;
    await pumpAndOpen(tester, () => used = true);

    await tester.tap(find.widgetWithText(FilledButton, 'Använd kortet'));
    await tester.pumpAndSettle();

    expect(used, isTrue);
    expect(find.text('Vill du använda kortet?'), findsNothing);
  });

  testWidgets('utan onUseCard/onTakeCard visas ingen fråga alls', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showCardDetail(context, BasicSetCards.merchantCaravan),
            child: const Text('öppna'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('öppna'));
    await tester.pumpAndSettle();

    expect(find.text('Vill du använda kortet?'), findsNothing);
    expect(find.text('Vill du ta detta kort?'), findsNothing);
  });
}
