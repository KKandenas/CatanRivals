import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar Stapelhus-texten som visas direkt efter ett lyckat bygge (se
/// GameNotifier.dropExpansion-doc: "Bygger du Stapelhuset får du
/// omedelbart 2 valfria resurser") – appen flyttar inga resurser åt
/// spelarna, bara en påminnande text, precis som byggkostnader visas
/// men inte dras av automatiskt.
void main() {
  testWidgets(
      'bygger man Stapelhus visas en SnackBar om de 2 valfria resurserna',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();
    notifier.rollProductionDie();

    final before = container.read(gameProvider);
    // Stapelhus kräver en stad (se build_requirements.dart) och
    // Köpmansgille utplacerat i riket.
    before.you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    before.you.principality.placeExpansion(
        0, BuildingRow.below, 0, const PlacedCard(card: EraOfGoldCards.merchantGuild));
    final hand = List<GameCard>.of(before.you.hand)
      ..add(EraOfGoldCards.stapleHouse);
    notifier.state = before.copyWith(you: before.you.copyWith(hand: hand));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameBoardScreen()),
    ));
    await tester.pumpAndSettle();

    final handCard = find.descendant(
        of: find.byType(HandDock), matching: find.text('Stapelhus'));
    final sites = find.byWidgetPredicate((w) => w is DragTarget<GameCard>);

    final start = tester.getCenter(handCard);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(sites.at(0)));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Betalt'), findsOneWidget);
    await tester.tap(find.text('Betalt'));
    await tester.pump();

    expect(find.text('Stapelhus byggt: du får 2 valfria resurser direkt.'),
        findsOneWidget);
  });
}
