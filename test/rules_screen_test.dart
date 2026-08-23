import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
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
    expect(find.text('Handelsskepp'), findsOneWidget);
    // "Handlingskort"/"Händelsekort"/"Byggnader"/"Hjältar" kolliderar
    // med temasetens egna grupper längre ner (samma titlar återanvänds
    // där, t.ex. Oroligheternas tids "Byggnader"/"Hjältar") – och
    // "Händelsekort" dessutom med händelsetärningens "?"-sida
    // (EventDieFace.eventCard heter också "Händelsekort") – bara
    // "minst en gång" är meningsfullt att testa här.
    expect(find.text('Handlingskort'), findsWidgets);
    expect(find.text('Händelsekort'), findsWidgets);
    expect(find.text('Byggnader'), findsWidgets);
    expect(find.text('Hjältar'), findsWidgets);

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

  testWidgets(
      'visar Gulderan (Era of Gold) som en egen sektion, med "Bild saknas" för kort utan bild och en lista på återanvända grundspelskort',
      (tester) async {
    await pumpRules(tester);

    expect(find.textContaining('Gulderan'), findsOneWidget);
    expect(find.text('Landskapsutbyggnad'), findsOneWidget);
    // "Stadsutbyggnader"/"Enheter" kolliderar med Utvecklingens tid-
    // sektionens egna grupper längre ner (samma titlar återanvänds där).
    expect(find.text('Stadsutbyggnader'), findsWidgets);
    for (final card in EraOfGoldCards.all) {
      expect(find.text(card.name), findsWidgets,
          reason: '${card.name} (${card.id}) saknas i Gulderan-listan');
    }

    // De flesta Gulderan-korten saknar fortfarande en riktig bild –
    // just det är hela poängen med den här granskningssektionen.
    expect(find.text('Bild\nsaknas'), findsWidgets);

    // Korten som återanvänds rakt av från grundspelet (t.ex. Guldsmed)
    // ska nämnas i klartext (som en del av granskningsnotisen) – utan
    // att kräva EXAKT en träff, eftersom Guldsmed redan har sin egen
    // kortruta i grundspelssektionen ovanför.
    expect(find.textContaining(BasicSetCards.goldsmith.name), findsWidgets);
  });

  testWidgets(
      'visar Utvecklingens tid (Era of Progress) som en egen sektion, med "Bild saknas" för kort utan bild och en lista på återanvända grundspelskort',
      (tester) async {
    await pumpRules(tester);

    expect(find.textContaining('Utvecklingens tid'), findsOneWidget);
    expect(find.text('Enheter'), findsWidgets);
    expect(find.text('Stadsutbyggnader'), findsWidgets);
    for (final card in EraOfProgressCards.all) {
      expect(find.text(card.name), findsWidgets,
          reason: '${card.name} (${card.id}) saknas i Utvecklingens tid-listan');
    }

    expect(find.text('Bild\nsaknas'), findsWidgets);

    // Korten som återanvänds rakt av från grundspelet (t.ex. Brigitta)
    // ska nämnas i klartext – utan att kräva EXAKT en träff, eftersom
    // Brigitta redan har sin egen kortruta i grundspelssektionen ovanför.
    expect(find.textContaining(BasicSetCards.brigittaTheWiseWoman.name),
        findsWidgets);
  });

  testWidgets(
      'visar Oroligheternas tid (Era of Turmoil) som en egen sektion, med "Bild saknas" för kort utan bild och en lista på återanvända kort (grundspel + Gulderan)',
      (tester) async {
    await pumpRules(tester);

    expect(find.textContaining('Oroligheternas tid'), findsOneWidget);
    expect(find.text('Byggnader'), findsWidgets);
    expect(find.text('Hjältar'), findsWidgets);
    expect(find.text('Stadsutbyggnader'), findsWidgets);
    for (final card in EraOfTurmoilCards.all) {
      expect(find.text(card.name), findsWidgets,
          reason: '${card.name} (${card.id}) saknas i Oroligheternas tid-listan');
    }

    expect(find.text('Bild\nsaknas'), findsWidgets);

    // Återanvänds från grundspelet (Fejd/Brödrafejd) OCH från Gulderan
    // (Rövare, action-brigands) – footnoten ska hitta bägge källorna,
    // inte bara BasicSetCards (se _EraSection:byId).
    expect(
        find.textContaining(BasicSetCards.feud.name), findsWidgets);
    expect(find.textContaining(BasicSetCards.fraternalFeuds.name),
        findsWidgets);
    expect(
        find.textContaining(EraOfGoldCards.brigands.name), findsWidgets);
  });
}
