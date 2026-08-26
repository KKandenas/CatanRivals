import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/models/models.dart';
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
      {GameCard card = BasicSetCards.storehouse,
      required replacedCard,
      String? blockedReason,
      String? costReminder,
      VoidCallback? onConfirm,
      VoidCallback? onCancel}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BuildConfirmCard(
          card: card,
          replacedCard: replacedCard,
          blockedReason: blockedReason,
          costReminder: costReminder,
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

  testWidgets(
      'Rådhus ovanpå Församlingshus visar en annan text – Församlingshus läggs INTE i slänghögen',
      (tester) async {
    await pumpCard(tester,
        card: EraOfProgressCards.townHall,
        replacedCard: BasicSetCards.parishHall);

    expect(
        find.text(
            'Läggs ovanpå ${BasicSetCards.parishHall.name}, som ligger kvar (övertäckt).'),
        findsOneWidget);
    expect(find.textContaining('läggs i slänghögen'), findsNothing);
  });

  group('costReminder (t.ex. Övningsplats, se GameBoardScreen._costReminderFor)',
      () {
    testWidgets('visas bredvid kostnaden, INNAN spelaren trycker Betalt',
        (tester) async {
      await pumpCard(tester,
          replacedCard: null,
          costReminder: 'Du har Övningsplats: betala 1 valfri resurs mindre.');

      expect(
          find.text('Du har Övningsplats: betala 1 valfri resurs mindre.'),
          findsOneWidget);
      expect(find.text('Betalt'), findsOneWidget,
          reason: 'påminnelsen ska synas TILLSAMMANS med kostnaden, inte i stället för den');
    });

    testWidgets('utan costReminder visas ingen sådan text', (tester) async {
      await pumpCard(tester, replacedCard: null);

      expect(find.textContaining('Övningsplats'), findsNothing);
    });

    testWidgets('visas inte när blockedReason är satt (ingen kostnad visas då heller)',
        (tester) async {
      await pumpCard(tester,
          replacedCard: null,
          blockedReason: 'Kräver Köpmansgille i ditt rike.',
          costReminder: 'Du har Övningsplats: betala 1 valfri resurs mindre.');

      expect(
          find.text('Du har Övningsplats: betala 1 valfri resurs mindre.'),
          findsNothing);
    });
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
