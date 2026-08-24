import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/expansion_card_view.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar den delade ansikte-upp-högen (se
/// GameState.faceUpExpansionCards, t.ex. Gulderans Köpmansgille) i
/// [HandDock] – bara ETT kort visas, mellan handkorten och
/// poängrutan, i samma format (72×72) som ett vanligt handkort.
/// Motståndarens sida visar inget kort alls (se
/// game_board_screen.dart:s `faceUpExpansionCards.first`-uppdelning –
/// TopStatusBar har ingen sådan funktion längre).
void main() {
  const card = EraOfGoldCards.merchantGuild;

  testWidgets('utan faceUpExpansionCard visas inget kort', (tester) async {
    final you = Player(id: 'you', name: 'Du');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HandDock(player: you, totalVictoryPoints: 0)),
    ));

    expect(find.byType(ExpansionCardView), findsNothing);
  });

  testWidgets(
      'med faceUpExpansionCard: visas i samma format (72×72) som ett handkort, dragbart bara när canBuild',
      (tester) async {
    final you = Player(id: 'you', name: 'Du');
    Future<void> pump(bool canBuild) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: HandDock(
              player: you,
              totalVictoryPoints: 0,
              faceUpExpansionCard: card,
              canBuild: canBuild,
            ),
          ),
        ));

    await pump(true);
    expect(find.byType(ExpansionCardView), findsOneWidget);
    expect(find.byType(LongPressDraggable<GameCard>), findsOneWidget);
    final size = tester.getSize(find.byType(ExpansionCardView));
    expect(size, const Size(72, 72));

    await pump(false);
    expect(find.byType(ExpansionCardView), findsOneWidget);
    expect(find.byType(LongPressDraggable<GameCard>), findsNothing);
  });
}
