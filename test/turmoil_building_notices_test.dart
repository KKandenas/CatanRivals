import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar de rena påminnelsetexterna (SnackBar/dialog, inga faktiska
/// resurser flyttas – se GameBoardScreen._confirmPendingBuild-doc,
/// samma mönster som Stapelhus i staple_house_build_notice_test.dart)
/// för Övningsplats, Marknadsfält och Tiondelada. Övningsplats
/// (rabatt på nästa hjältes kostnad) visas numera TILLSAMMANS med
/// kostnaden i BuildConfirmCard, INNAN spelaren betalar – inte som en
/// SnackBar efteråt (rapporterad bugg: för sent för att faktiskt
/// påverka vad spelaren betalar) – se
/// GameBoardScreen._costReminderFor-doc. Widgeten testas isolerat i
/// build_confirm_card_test.dart; testerna här kollar att den faktiska
/// spel-integrationen räknar ut rätt text.
void main() {
  Future<ProviderContainer> readyGame(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfTurmoil});
    notifier.rollProductionDie();
    return container;
  }

  Future<void> dragHandCardToSite(
      WidgetTester tester, String cardName, int siteIndex) async {
    final handCard = find.descendant(
        of: find.byType(HandDock), matching: find.text(cardName));
    final sites = find.byWidgetPredicate((w) => w is DragTarget<GameCard>);

    final start = tester.getCenter(handCard);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(sites.at(siteIndex)));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
      'bygger man en hjälte med Övningsplats i riket visas rabattpåminnelsen redan i bekräftelserutan, INNAN Betalt trycks',
      (tester) async {
    final container = await readyGame(tester);
    addTearDown(container.dispose);
    final before = container.read(gameProvider);
    before.you.principality.placeExpansion(0, BuildingRow.below, 0,
        const PlacedCard(card: EraOfTurmoilCards.drillGround));
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfTurmoilCards.carlForkbeard);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    await dragHandCardToSite(tester, 'Carl Kluvskägg', 0);

    // Påminnelsen ska synas TILLSAMMANS med "Betalt" – innan spelaren
    // betalar, inte i en SnackBar efteråt (rapporterad bugg: annars
    // hinner spelaren aldrig faktiskt utnyttja rabatten).
    expect(find.text('Betalt'), findsOneWidget);
    expect(
        find.text('Du har Övningsplats: betala 1 valfri resurs mindre.'),
        findsOneWidget);
  });

  testWidgets(
      'bygger man en hjälte UTAN Övningsplats i riket visas ingen rabattpåminnelse',
      (tester) async {
    final container = await readyGame(tester);
    addTearDown(container.dispose);
    final before = container.read(gameProvider);
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfTurmoilCards.carlForkbeard);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    await dragHandCardToSite(tester, 'Carl Kluvskägg', 0);

    expect(find.text('Betalt'), findsOneWidget);
    expect(
        find.text('Du har Övningsplats: betala 1 valfri resurs mindre.'),
        findsNothing);
  });

  testWidgets(
      'bygger man Marknadsfält med flest kunskapspoäng visas en påminnelse om 2 resurser',
      (tester) async {
    final container = await readyGame(tester);
    addTearDown(container.dispose);
    final before = container.read(gameProvider);
    before.you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    before.you.principality.placeExpansion(
        2,
        BuildingRow.above,
        0,
        PlacedCard(
            card: EraOfTurmoilCards.irmgardKeeperOfTheLight
                .copyWith(skillPoints: 3)));
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfTurmoilCards.fairgrounds);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    await dragHandCardToSite(tester, 'Marknadsfält', 0);
    expect(find.text('Betalt'), findsOneWidget);
    await tester.tap(find.text('Betalt'));
    await tester.pump();

    expect(
        find.text(
            'Marknadsfält byggt: du har flest kunskapspoäng – du får 2 valfria resurser direkt.'),
        findsOneWidget);
  });

  testWidgets(
      'bygger man Marknadsfält UTAN flest kunskapspoäng visas ingen påminnelse',
      (tester) async {
    final container = await readyGame(tester);
    addTearDown(container.dispose);
    final before = container.read(gameProvider);
    before.you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfTurmoilCards.fairgrounds);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    await dragHandCardToSite(tester, 'Marknadsfält', 0);
    await tester.tap(find.text('Betalt'));
    await tester.pump();

    expect(
        find.text(
            'Marknadsfält byggt: du har flest kunskapspoäng – du får 2 valfria resurser direkt.'),
        findsNothing);
  });

  testWidgets(
      'bygger man Tiondelada visas en resurstypsväljare, sedan en påminnelse med rätt antal (1 per hjälte)',
      (tester) async {
    final container = await readyGame(tester);
    addTearDown(container.dispose);
    final before = container.read(gameProvider);
    before.you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    before.you.principality.placeExpansion(2, BuildingRow.above, 0,
        const PlacedCard(card: EraOfTurmoilCards.carlForkbeard));
    before.you.principality.placeExpansion(2, BuildingRow.below, 0,
        const PlacedCard(card: EraOfTurmoilCards.heinrichTheSentinel));
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfTurmoilCards.titheBarn);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    await dragHandCardToSite(tester, 'Tiondelada', 0);
    expect(find.text('Betalt'), findsOneWidget);
    await tester.tap(find.text('Betalt'));
    await tester.pump();

    expect(find.text('Tiondelada: välj resurstyp'), findsOneWidget);
    await tester.tap(find.text('Ull'));
    await tester.pump();

    expect(find.text('Tiondelada byggt: du får 2 ull (1 per egen hjälte).'),
        findsOneWidget);
  });
}
