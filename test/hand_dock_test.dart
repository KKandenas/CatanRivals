import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar HandDocks handlingskortslogik och handjusteringens
/// slängval – flera buggar som upptäcktes vid speltest:
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
/// 6) Övriga handlingskort (Omlokalisering m.fl., inte Brigitta) ska
///    inte gå att "använda" innan tärningen slagits, eller på
///    motståndarens tur – annars visas "Vill du använda kortet?" och
///    man möter i stället ett felmeddelande (t.ex. "Inte din tur")
///    EFTER att man redan valt/bekräftat, se [HandDock.canBuild]/
///    [HandDock.isMyTurn]. Brigitta har omvänt villkor (bara INNAN
///    tärningen slagits) men ska på samma sätt inte gå att använda på
///    motståndarens tur.
void main() {
  Future<void> pumpDock(
    WidgetTester tester, {
    required List<GameCard> hand,
    void Function(GameCard card)? onUseActionCard,
    void Function(GameCard card)? onSelectForDiscard,
    bool isMyTurn = true,
    bool diceRolled = false,
    bool canBuild = true,
    bool hasStrengthAdvantage = false,
    RealmBoard? principality,
    Size viewSize = const Size(1200, 300),
  }) async {
    tester.view.physicalSize = viewSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final player =
        Player(id: 'you', name: 'Du', hand: hand, principality: principality);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HandDock(
          player: player,
          totalVictoryPoints: 0,
          onUseActionCard: onUseActionCard,
          onSelectForDiscard: onSelectForDiscard,
          isMyTurn: isMyTurn,
          diceRolled: diceRolled,
          canBuild: canBuild,
          hasStrengthAdvantage: hasStrengthAdvantage,
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

    testWidgets(
        'på motståndarens tur visas bara vanlig kortförstoring, även innan tärningen slagits',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [BasicSetCards.brigittaTheWiseWoman],
          onUseActionCard: (_) => used = true,
          isMyTurn: false);

      await tester.tap(find.text('Brigitta, den visa kvinnan'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsNothing);
      expect(used, isFalse);
    });
  });

  group('Reiner härolden – samma tärningsfasens gräns som Brigitta', () {
    testWidgets('innan tärningen slagits visar tryck "Vill du använda kortet?"',
        (tester) async {
      await pumpDock(tester,
          hand: [EraOfGoldCards.reinerTheHerald], onUseActionCard: (_) {});

      await tester.tap(find.text('Reiner härolden'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
    });

    testWidgets('efter att tärningen slagits visas bara vanlig kortförstoring',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [EraOfGoldCards.reinerTheHerald],
          onUseActionCard: (_) => used = true,
          diceRolled: true);

      await tester.tap(find.text('Reiner härolden'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsNothing);
      expect(used, isFalse);
      expect(find.text('Reiner härolden'), findsWidgets);
    });

    testWidgets(
        'på motståndarens tur visas bara vanlig kortförstoring, även innan tärningen slagits',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [EraOfGoldCards.reinerTheHerald],
          onUseActionCard: (_) => used = true,
          isMyTurn: false);

      await tester.tap(find.text('Reiner härolden'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsNothing);
      expect(used, isFalse);
    });
  });

  group('Övriga handlingskort (t.ex. Omlokalisering) styrs av canBuild', () {
    testWidgets(
        'canBuild=false (innan tärningen slagits eller motståndarens tur) visar bara vanlig kortförstoring',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [BasicSetCards.relocation],
          onUseActionCard: (_) => used = true,
          canBuild: false);

      await tester.tap(find.text('Omlokalisering'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsNothing);
      expect(used, isFalse);
      expect(find.text('Omlokalisering'), findsWidgets);
    });

    testWidgets('canBuild=true visar "Vill du använda kortet?" som vanligt',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [BasicSetCards.relocation],
          onUseActionCard: (_) => used = true,
          canBuild: true,
          viewSize: const Size(1200, 1600));

      await tester.tap(find.text('Omlokalisering'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Använd kortet'));
      await tester.pumpAndSettle();
      expect(used, isTrue);
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

  group('Handelskaravan/Guldsmed – resurskrav för att gå att spela', () {
    testWidgets(
        'Handelskaravan: färre än 2 resurser visar en förklarande text i stället för "Använd kortet"',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [BasicSetCards.merchantCaravan],
          onUseActionCard: (_) => used = true,
          principality: RealmBoard(ownerId: 'you', regionsAbove: {
            0: const PlacedCard(
                card: BasicSetCards.goldField, storedResources: 1),
          }));

      await tester.tap(find.text('Handelskaravan'));
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Du behöver minst 2 resurser för att kunna använda det här kortet.'),
          findsOneWidget);
      expect(find.text('Använd kortet'), findsNothing);
      expect(used, isFalse);
    });

    testWidgets(
        'Handelskaravan: minst 2 resurser (oavsett typ) visar "Använd kortet" som vanligt',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [BasicSetCards.merchantCaravan],
          onUseActionCard: (_) => used = true,
          viewSize: const Size(1200, 1600),
          principality: RealmBoard(ownerId: 'you', regionsAbove: {
            0: const PlacedCard(
                card: BasicSetCards.goldField, storedResources: 1),
            1: const PlacedCard(
                card: BasicSetCards.forest, storedResources: 1),
          }));

      await tester.tap(find.text('Handelskaravan'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Använd kortet'));
      await tester.pumpAndSettle();
      expect(used, isTrue);
    });

    testWidgets(
        'Guldsmed: färre än 3 guld visar en förklarande text i stället för "Använd kortet"',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [BasicSetCards.goldsmith],
          onUseActionCard: (_) => used = true,
          principality: RealmBoard(ownerId: 'you', regionsAbove: {
            0: const PlacedCard(
                card: BasicSetCards.goldField, storedResources: 2),
          }));

      await tester.tap(find.text('Guldsmed'));
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Du behöver minst 3 guld för att kunna använda det här kortet.'),
          findsOneWidget);
      expect(find.text('Använd kortet'), findsNothing);
      expect(used, isFalse);
    });

    testWidgets('Guldsmed: minst 3 guld visar "Använd kortet" som vanligt',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [BasicSetCards.goldsmith],
          onUseActionCard: (_) => used = true,
          viewSize: const Size(1200, 1600),
          principality: RealmBoard(ownerId: 'you', regionsAbove: {
            0: const PlacedCard(
                card: BasicSetCards.goldField, storedResources: 3),
          }));

      await tester.tap(find.text('Guldsmed'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Använd kortet'));
      await tester.pumpAndSettle();
      expect(used, isTrue);
    });
  });

  group('Rövare/Köpman/Handelsmästare – Gulderans kravspärrar', () {
    testWidgets(
        'Rövare: utan styrkeövertag visas en förklarande text i stället för "Använd kortet"',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [EraOfGoldCards.brigands],
          onUseActionCard: (_) => used = true,
          hasStrengthAdvantage: false);

      await tester.tap(find.text('Rövare'));
      await tester.pumpAndSettle();

      expect(find.text('Kräver styrkeövertag.'), findsOneWidget);
      expect(find.text('Använd kortet'), findsNothing);
      expect(used, isFalse);
    });

    testWidgets('Rövare: med styrkeövertag visas "Använd kortet" som vanligt',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [EraOfGoldCards.brigands],
          onUseActionCard: (_) => used = true,
          hasStrengthAdvantage: true,
          viewSize: const Size(1200, 1600));

      await tester.tap(find.text('Rövare'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Använd kortet'));
      await tester.pumpAndSettle();
      expect(used, isTrue);
    });

    testWidgets(
        'Köpman: färre än 3 handelspoäng och ingen stad visar en förklarande text',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [EraOfGoldCards.merchant],
          onUseActionCard: (_) => used = true,
          principality: RealmBoard(ownerId: 'you'));

      await tester.tap(find.text('Köpman'));
      await tester.pumpAndSettle();

      expect(find.text('Kräver 3 handelspoäng eller en stad.'), findsOneWidget);
      expect(used, isFalse);
    });

    testWidgets('Köpman: minst 3 handelspoäng räcker, även utan stad',
        (tester) async {
      var used = false;
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(
        0,
        BuildingRow.above,
        0,
        const PlacedCard(
          card: GameCard(
            id: 'test-commerce-unit',
            name: 'Testenhet',
            category: CardCategory.expansion,
            commercePoints: 3,
            imageAsset: 'assets/images/cards/heroes/test.png',
          ),
        ),
      );
      await pumpDock(tester,
          hand: [EraOfGoldCards.merchant],
          onUseActionCard: (_) => used = true,
          principality: board,
          viewSize: const Size(1200, 1600));

      await tester.tap(find.text('Köpman'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Använd kortet'));
      await tester.pumpAndSettle();
      expect(used, isTrue);
    });

    testWidgets('Köpman: en stad räcker, även med färre än 3 handelspoäng',
        (tester) async {
      var used = false;
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
      await pumpDock(tester,
          hand: [EraOfGoldCards.merchant],
          onUseActionCard: (_) => used = true,
          principality: board,
          viewSize: const Size(1200, 1600));

      await tester.tap(find.text('Köpman'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Använd kortet'));
      await tester.pumpAndSettle();
      expect(used, isTrue);
    });

    testWidgets(
        'Handelsmästare: utan Köpmansgille visas en förklarande text i stället för "Använd kortet"',
        (tester) async {
      var used = false;
      await pumpDock(tester,
          hand: [EraOfGoldCards.tradeMaster],
          onUseActionCard: (_) => used = true,
          principality: RealmBoard(ownerId: 'you'));

      await tester.tap(find.text('Handelsmästare'));
      await tester.pumpAndSettle();

      expect(find.text('Kräver Köpmansgille i ditt rike.'), findsOneWidget);
      expect(used, isFalse);
    });

    testWidgets('Handelsmästare: med Köpmansgille utplacerat visas "Använd kortet"',
        (tester) async {
      var used = false;
      final board = RealmBoard(ownerId: 'you');
      board.placeSettlement(0, const PlacedCard(card: BasicSetCards.city));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: EraOfGoldCards.merchantGuild));
      await pumpDock(tester,
          hand: [EraOfGoldCards.tradeMaster],
          onUseActionCard: (_) => used = true,
          principality: board,
          viewSize: const Size(1200, 1600));

      await tester.tap(find.text('Handelsmästare'));
      await tester.pumpAndSettle();

      expect(find.text('Vill du använda kortet?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Använd kortet'));
      await tester.pumpAndSettle();
      expect(used, isTrue);
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
