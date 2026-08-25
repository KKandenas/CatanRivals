import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/ui/widgets/build_confirm_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar BuildConfirmCard direkt (inte hela bräd-/drag-flödet, se
/// build_confirm_test.dart för det) – specifikt den nya
/// "Ersätter X"-texten som visas när ett bygge på en redan bebyggd
/// plats faktiskt byter ut ett annat kort (se
/// GameNotifier.dropExpansion/PrincipalityGrid.onRequestBuildConfirm).
void main() {
  Future<void> pumpCard(WidgetTester tester,
      {required replacedCard,
      String? blockedReason,
      VoidCallback? onConfirm,
      VoidCallback? onCancel}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BuildConfirmCard(
          card: BasicSetCards.storehouse,
          replacedCard: replacedCard,
          blockedReason: blockedReason,
          onConfirm: onConfirm ?? () {},
          onCancel: onCancel ?? () {},
        ),
      ),
    ));
  }

  testWidgets('utan replacedCard visas ingen "Ersätter"-text', (tester) async {
    await pumpCard(tester, replacedCard: null);

    expect(find.textContaining('Ersätter'), findsNothing);
  });

  testWidgets(
      'med replacedCard visas en varning om att det gamla kortet läggs i slänghögen',
      (tester) async {
    await pumpCard(tester, replacedCard: BasicSetCards.road);

    expect(
        find.text('Ersätter ${BasicSetCards.road.name}, som läggs i slänghögen.'),
        findsOneWidget);
  });

  group('blockedReason (se build_requirements.dart)', () {
    testWidgets('visar texten och en "Stäng"-knapp, ingen "Betalt"', (tester) async {
      await pumpCard(tester,
          replacedCard: null,
          blockedReason: 'Kräver Köpmansgille i ditt rike.');

      expect(find.text('Kräver Köpmansgille i ditt rike.'), findsOneWidget);
      expect(find.text('Stäng'), findsOneWidget);
      expect(find.text('Betalt'), findsNothing);
      expect(find.text('Avbryt'), findsNothing);
    });

    testWidgets('utan blockedReason visas kostnad/Betalt/Avbryt som vanligt',
        (tester) async {
      await pumpCard(tester, replacedCard: null);

      expect(find.text('Betalt'), findsOneWidget);
      expect(find.text('Avbryt'), findsOneWidget);
      expect(find.text('Stäng'), findsNothing);
    });

    testWidgets('"Stäng" anropar onCancel', (tester) async {
      var cancelled = false;
      await pumpCard(tester,
          replacedCard: null,
          blockedReason: 'Kräver Köpmansgille i ditt rike.',
          onCancel: () => cancelled = true);

      await tester.tap(find.text('Stäng'));
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });
}
