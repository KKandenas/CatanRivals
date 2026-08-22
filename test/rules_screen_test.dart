import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/screens/rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar regelsidan (se rules_screen.dart): att den visar de
/// efterfrågade sektionerna (omgångsöversikt, vinstvillkor,
/// händelsetärningen, och samtliga 39 korttyper i grundspelet), och att
/// ett tryck på ett kort öppnar den vanliga förstorade kortvyn
/// ([showCardDetail], samma dialog som resten av spelet redan använder).
void main() {
  Future<void> pumpRules(WidgetTester tester) async {
    // Ovanligt hög yta med flit – annars byggs bara det som är synligt
    // (plus lite cache-marginal) i ListView:n, och find.text()/tap()
    // skulle missa allt som är längre ner än så (t.ex. "Hjältar" och
    // resten av kortkatalogen) utan att behöva scrolla dit steg för
    // steg för var och en av de 39 korten.
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: RulesScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('visar omgångsöversikt, vinstvillkor och händelsetärningen',
      (tester) async {
    await pumpRules(tester);

    expect(find.text('Så funkar en omgång'), findsOneWidget);
    expect(find.text('Vinstvillkor'), findsOneWidget);
    expect(
        find.textContaining('7 eller fler segerpoäng'), findsOneWidget);
    expect(find.text('Händelsetärningen'), findsOneWidget);
    for (final face in EventDieFace.values) {
      expect(find.text(face.swedishName), findsWidgets);
    }
  });

  testWidgets('visar alla 39 korttyper i grundspelet, grupperade', (tester) async {
    await pumpRules(tester);

    expect(find.text('Alla kort i grundspelet'), findsOneWidget);
    expect(find.text('Regioner'), findsOneWidget);
    expect(find.text('Byggnader'), findsOneWidget);
    expect(find.text('Hjältar'), findsOneWidget);
    expect(find.text('Handelsskepp'), findsOneWidget);
    expect(find.text('Handlingskort'), findsOneWidget);
    // Kolliderar med händelsetärningens "?"-sida (EventDieFace.eventCard
    // heter också "Händelsekort") – bara "minst en gång" är meningsfullt
    // att testa här.
    expect(find.text('Händelsekort'), findsWidgets);

    // Varje korttyp har en egen tumnagel – ett namn kan förekomma mer
    // än en gång i trädet (rubrik + eventuell dubblett bland kortnamnen
    // är inte aktuellt i grundspelet), så det viktiga är att alla finns
    // med minst en gång.
    for (final card in BasicSetCards.all) {
      expect(find.text(card.name), findsWidgets,
          reason: '${card.name} (${card.id}) saknas i regelsidans kortlista');
    }
  });

  testWidgets('tryck på ett kort öppnar den förstorade kortvyn', (tester) async {
    await pumpRules(tester);

    await tester.tap(find.text(BasicSetCards.abbey.name).first);
    await tester.pumpAndSettle();

    expect(find.text(BasicSetCards.abbey.effectText!), findsOneWidget);
  });
}
