import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/widgets/expansion_card_view.dart';
import 'package:catan_rivals/ui/widgets/hand_dock.dart';
import 'package:catan_rivals/ui/widgets/top_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att den delade ansikte-upp-högen (se
/// GameState.faceUpExpansionCards, t.ex. Gulderans Köpmansgille) visas
/// delad – ett kort vid [TopStatusBar] (motståndarens rad, högst upp),
/// ett vid [HandDock] (den egna handen, nedtill) – i stället för
/// samlade i mittremsan (se game_board_screen.dart:s
/// faceUpExpansionCards[0]/[1]-uppdelning).
void main() {
  const card = EraOfGoldCards.merchantGuild;
  final opponent = Player(id: 'opponent', name: 'Motståndare');

  testWidgets('TopStatusBar utan faceUpExpansionCard visar inget kort',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TopStatusBar(opponent: opponent, totalVictoryPoints: 0),
      ),
    ));

    expect(find.byType(ExpansionCardView), findsNothing);
  });

  testWidgets(
      'TopStatusBar med faceUpExpansionCard: visas, dragbart bara när canBuild',
      (tester) async {
    Future<void> pump(bool canBuild) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TopStatusBar(
              opponent: opponent,
              totalVictoryPoints: 0,
              faceUpExpansionCard: card,
              canBuild: canBuild,
            ),
          ),
        ));

    await pump(true);
    expect(find.byType(ExpansionCardView), findsOneWidget);
    expect(find.byType(LongPressDraggable<GameCard>), findsOneWidget);

    await pump(false);
    expect(find.byType(ExpansionCardView), findsOneWidget);
    expect(find.byType(LongPressDraggable<GameCard>), findsNothing);
  });

  testWidgets('HandDock utan faceUpExpansionCard visar inget kort',
      (tester) async {
    final you = Player(id: 'you', name: 'Du');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HandDock(player: you, totalVictoryPoints: 0)),
    ));

    expect(find.byType(ExpansionCardView), findsNothing);
  });

  testWidgets(
      'HandDock med faceUpExpansionCard: visas, dragbart bara när canBuild',
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

    await pump(false);
    expect(find.byType(ExpansionCardView), findsOneWidget);
    expect(find.byType(LongPressDraggable<GameCard>), findsNothing);
  });
}
