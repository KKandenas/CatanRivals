import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar HandDocks handlingskortslogik och handjusteringens
/// slängval – tre buggar som upptäcktes vid speltest:
/// 1) Brigitta ska inte gå att "använda" efter att tärningen redan
///    slagits (kortet måste spelas INNAN, regelhäftet).
/// 3) Bygg-/enhetskort ska inte gå att dra ut när [HandDock.canBuild]
///    är falskt (annars går det att dra och mötas av ett
///    felmeddelande efter "Betalt").
/// 5) Under handjusteringens slängval (`onSelectForDiscard`) ska ALLA
///    handkort – inte bara handlingskort – gå att trycka på och
///    välja. Bakomliggande orsak: en dekorativ, osynlig ram
///    (`DecoratedBox` utan `IgnorePointer`) låg ovanpå kortet i
///    Stacken och fångade trycket självt för alla
///    [CardCategory.expansion]-kort (byggnader/hjältar/handelsskepp).
void main() {
  Future<void> pumpDock(
    WidgetTester tester, {
    required List<GameCard> hand,
    void Function(GameCard card)? onUseActionCard,
    void Function(GameCard card)? onSelectForDiscard,
    bool diceRolled = false,
    bool canBuild = true,
  }) async {
    tester.view.physicalSize = const Size(1200, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final player = Player(id: 'you', name: 'Du', hand: hand);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HandDock(
          player: player,
          totalVictoryPoints: 0,
          onUseActionCard: onUseActionCard,
          onSelectForDiscard: onSelectForDiscard,
          diceRolled: diceRolled,
          canBuild: canBuild,
        ),
      ),
    ));
    // Handkorten tonar in/glider upp när de först läggs till (se
    // PopIn i hand_dock.dart) – precis som en riktig tärningsanimation
    // skulle en riktig fingertryck aldrig hinna landa mitt i den första
    // (osynliga, opacitet 0) bildrutan, men testernas tap() gör exakt
    // det om vi inte väntar in animationen först.
    await tester.pumpAndSettle();
  }

  group('Brigitta – tärningsfasens gräns', () {
    testWidgets('innan tärningen slagits visar tryck "Vill du använda kortet?"',
        (tester) async {
      await pumpDock(tester,
          hand: [BasicSetCards.brigittaTheWiseWoman], onUseActionCard: (_) {});

      await tester.tap(find.text('Brigitta, den visa kvinnan'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
    });

    testWidgets('efter att tärningen slagits visas bara vanlig kortförstoring',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [BasicSetCards.brigittaTheWiseWoman],
          onUseActionCard: (_) => used = true,
          diceRolled: true);

      await tester.tap(find.text('Brigitta, den visa kvinnan'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsNothing);
      expect(used, isFalse);
      // Kortet förstoras ändå (går att läsa regeltexten).
      expect(find.text('Brigitta, den visa kvinnan'), findsWidgets);
    });
  });

  group('canBuild styr dragbarhet', () {
    testWidgets(
        'canBuild=false gör byggkort otryckbara att dra – ingen drag startar',
        (tester) async {
      var dragStarted = false;
      await pumpDock(
        tester,
        hand: [BasicSetCards.storehouse],
        canBuild: false,
      );

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Lagerhus')));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      await gesture.up();

      // LongPressDraggable finns inte alls i trädet.
      expect(find.byType(LongPressDraggable<GameCard>), findsNothing);
      expect(dragStarted, isFalse);
    });

    testWidgets(
        'canBuild=true gör byggkort dragbara (LongPressDraggable finns)',
        (tester) async {
      await pumpDock(tester, hand: [BasicSetCards.storehouse], canBuild: true);

      expect(find.byType(LongPressDraggable<GameCard>), findsOneWidget);
    });
  });

  group('Handjusteringens slängval fungerar för alla kortkategorier', () {
    testWidgets(
        'byggnads-/hjältekort (expansion) går att välja, inte bara handlingskort',
        (tester) async {
      GameCard? selected;
      await pumpDock(
        tester,
        hand: [
          BasicSetCards.merchantCaravan, // action
          BasicSetCards.storehouse, // expansion/building
          BasicSetCards.siglind, // expansion/hero
        ],
        onSelectForDiscard: (c) => selected = c,
      );

      await tester.tap(find.text('Lagerhus'));
      await tester.pump();
      expect(selected?.id, BasicSetCards.storehouse.id);

      await tester.tap(find.text('Siglind'));
      await tester.pump();
      expect(selected?.id, BasicSetCards.siglind.id);

      await tester.tap(find.text('Handelskaravan'));
      await tester.pump();
      expect(selected?.id, BasicSetCards.merchantCaravan.id);
    });
  });
}
