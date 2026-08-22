import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/ui/widgets/feud_resolution_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att [FeudResolutionCard] ryms och är tryckbart även i det
/// begränsade utrymme den faktiskt visas i (ovanpå motståndarens rike,
/// se game_board_screen.dart) – bara ~260 punkter högt på en del
/// skärmar. Tidigare låg en stor kvadratisk bild ovanpå all text, vilket
/// gjorde att Brödrafejds längre instruktionstext + knapp hamnade
/// utanför synligt område utan att gå att nå.
void main() {
  Widget wrap(Widget child, {double height = 260}) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 340, height: height, child: child),
          ),
        ),
      );

  testWidgets(
      'Brödrafejd (längst instruktionstext): knappen syns och går att trycka på i ett lågt utrymme',
      (tester) async {
    var pressed = false;
    await tester.pumpWidget(wrap(FeudResolutionCard(
      card: BasicSetCards.fraternalFeuds,
      isTie: false,
      youHaveAdvantage: true,
      isOnline: false,
      opponentName: 'Björn',
      hasBuildingToRemove: true,
      onDismiss: () {},
      onStartFeudPick: () {},
      onStartFraternalFeudsPick: () => pressed = true,
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final button = find.widgetWithText(FilledButton, 'Välj kort');
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('Fejd: knappen syns och går att trycka på i ett lågt utrymme',
      (tester) async {
    var pressed = false;
    await tester.pumpWidget(wrap(FeudResolutionCard(
      card: BasicSetCards.feud,
      isTie: false,
      youHaveAdvantage: false,
      isOnline: false,
      opponentName: 'Björn',
      hasBuildingToRemove: true,
      onDismiss: () {},
      onStartFeudPick: () => pressed = true,
      onStartFraternalFeudsPick: () {},
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final button = find.widgetWithText(FilledButton, 'Välj byggnad');
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('oavgjort: visar informationstexten och en OK-knapp som stänger',
      (tester) async {
    var dismissed = false;
    await tester.pumpWidget(wrap(FeudResolutionCard(
      card: BasicSetCards.feud,
      isTie: true,
      youHaveAdvantage: false,
      isOnline: false,
      opponentName: 'Björn',
      hasBuildingToRemove: true,
      onDismiss: () => dismissed = true,
      onStartFeudPick: () {},
      onStartFraternalFeudsPick: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Oavgjort – ingen spelare har styrkeövertaget.'),
        findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'OK');
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();

    expect(dismissed, isTrue);
  });

  testWidgets(
      'Fejd utan byggnad hos den som ska välja bort: "inget händer" med en OK-knapp som stänger direkt, aldrig "Välj byggnad"',
      (tester) async {
    var dismissed = false;
    await tester.pumpWidget(wrap(FeudResolutionCard(
      card: BasicSetCards.feud,
      isTie: false,
      youHaveAdvantage: false,
      isOnline: false,
      opponentName: 'Björn',
      hasBuildingToRemove: false,
      onDismiss: () => dismissed = true,
      onStartFeudPick: () =>
          fail('ska inte kunna starta bygg-väljaren utan byggnader'),
      onStartFraternalFeudsPick: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Du har inga byggnader att ta bort. Inget händer.'),
        findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Välj byggnad'), findsNothing);
    final button = find.widgetWithText(FilledButton, 'OK');
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();

    expect(dismissed, isTrue);
  });

  testWidgets(
      'Fejd utan byggnad hos motståndaren: visar motståndarens namn i "inget händer"-texten',
      (tester) async {
    await tester.pumpWidget(wrap(FeudResolutionCard(
      card: BasicSetCards.feud,
      isTie: false,
      youHaveAdvantage: true,
      isOnline: false,
      opponentName: 'Björn',
      hasBuildingToRemove: false,
      onDismiss: () {},
      onStartFeudPick: () {},
      onStartFraternalFeudsPick: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Björn har inga byggnader att ta bort. Inget händer.'),
        findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'OK'), findsOneWidget);
  });
}
