import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar hela drag-och-släpp-flödet för byggnation (inte bara
/// notifier-metoderna direkt), eftersom en riktig bugg visade sig sitta
/// mellan de två lagren: [GameNotifier.dropExpansion] blockerar redan
/// korrekt ett dubbelt unikt byggnadskort (se game_notifier_test.dart),
/// men bekräftelserutan i game_board_screen.dart kunde tyst skriva över
/// en väntande bekräftelse om man drog ett andra kort till en annan
/// byggplats innan det första hunnit bekräftas – kortet försvann
/// spårlöst ur bekräftelserutan utan felmeddelande.
void main() {
  Future<ProviderContainer> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();
    notifier.rollProductionDie();

    // Ge handen två riktiga Församlingshus (unikt kort, fysiskt 2
    // kopior i grundspelsleken) att bygga med.
    final before = container.read(gameProvider);
    final hand = List<GameCard>.of(before.you.hand)
      ..add(BasicSetCards.parishHall)
      ..add(BasicSetCards.parishHall);
    container.read(gameProvider.notifier).state =
        before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  Finder handCard() => find.descendant(
      of: find.byType(HandDock), matching: find.text('Församlingshus'));

  Future<void> longPressDragTo(
      WidgetTester tester, Finder source, Offset target) async {
    final start = tester.getCenter(source);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  int countPlaced(ProviderContainer container) => container
      .read(gameProvider)
      .you
      .principality
      .settlements
      .values
      .expand((n) => [...n.aboveSites, ...n.belowSites])
      .where((s) => s?.card.id == 'building-parish-hall')
      .length;

  testWidgets(
      'sekventiellt bygge: bekräfta kort 1 innan kort 2 dras – kort 2 avvisas med tydligt fel',
      (tester) async {
    final container = await setup(tester);
    final sites = find.byWidgetPredicate((w) => w is DragTarget<GameCard>);

    await longPressDragTo(tester, handCard().first, tester.getCenter(sites.at(0)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Betalt'), findsOneWidget);
    await tester.tap(find.text('Betalt'));
    await tester.pumpAndSettle();

    expect(countPlaced(container), 1);

    final sitesAfterFirst =
        find.byWidgetPredicate((w) => w is DragTarget<GameCard>);
    await longPressDragTo(
        tester, handCard().first, tester.getCenter(sitesAfterFirst.at(0)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Betalt'), findsOneWidget);
    await tester.tap(find.text('Betalt'));
    await tester.pumpAndSettle();

    expect(find.text('Du kan bara ha en Församlingshus i ditt rike.'),
        findsOneWidget);
    expect(countPlaced(container), 1,
        reason: 'kort 2 ska inte ha byggts');
  });

  testWidgets(
      'ett andra kort som dras till en annan byggplats innan det första bekräftats '
      'skriver inte över den väntande bekräftelsen – den visar ett fel i stället',
      (tester) async {
    final container = await setup(tester);
    final sites = find.byWidgetPredicate((w) => w is DragTarget<GameCard>);

    await longPressDragTo(tester, handCard().first, tester.getCenter(sites.at(0)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Betalt'), findsOneWidget,
        reason: 'bekräftelsen för kort 1 väntar');

    // Kort 2 till en ANNAN byggplats, utan att bekräfta/avbryta kort 1.
    await longPressDragTo(tester, handCard().first, tester.getCenter(sites.at(1)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bekräfta eller avbryt förra byggnationen först.'),
        findsOneWidget);
    // Bekräftelserutan visar fortfarande kort 1, inte överskriven.
    expect(find.text('Betalt'), findsOneWidget);

    await tester.tap(find.text('Betalt'));
    await tester.pumpAndSettle();

    expect(countPlaced(container), 1,
        reason: 'kort 1 ska ha byggts, ingenting förlorat spårlöst');
    expect(container.read(gameProvider).you.hand
        .where((c) => c.id == 'building-parish-hall').length, 1,
        reason: 'kort 2 ska fortfarande ligga kvar i handen');
  });
}
