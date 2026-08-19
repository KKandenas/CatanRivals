import 'package:flutter/material.dart';

import '../../data/mock_game.dart';
import '../../models/models.dart';
import '../widgets/center_stacks_strip.dart';
import '../widgets/hand_dock.dart';
import '../widgets/principality_grid.dart';
import '../widgets/top_status_bar.dart';

/// Huvudskärmen, stående layout: motståndarens namn/status (smal remsa),
/// motståndarens rike (kompakt), dragstaplar + tärning + turindikator i
/// mitten (som i det fysiska spelets uppställning), ditt eget rike
/// (större, i fokus) och din handkortsdocka längst ner.
///
/// Håller spelarna som lokalt widget-state (StatefulWidget) tills
/// riktig spelstate (Riverpod) finns – tillräckligt för att kunna dra
/// bygg-/enhetskort från handen till tomma byggplatser på ditt rike.
class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  late Player _you;
  late Player _opponent;
  GameCard? _draggingCard;

  @override
  void initState() {
    super.initState();
    _you = MockGame.buildYou();
    _opponent = MockGame.buildOpponent();
  }

  bool _canAfford(GameCard card) {
    return card.buildingCost.entries.every((entry) => _you.resourceCount(entry.key) >= entry.value);
  }

  void _handleDrop(int column, BuildingRow row, int slotIndex, GameCard card) {
    if (!_you.hand.contains(card)) return;

    if (!_canAfford(card)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inte råd med ${card.name}'), duration: const Duration(seconds: 2)),
      );
      return;
    }

    _you.principality.placeExpansion(column, row, slotIndex, PlacedCard(card: card));

    var updated = _you.copyWith(hand: List.of(_you.hand)..remove(card));
    for (final entry in card.buildingCost.entries) {
      updated = updated.addResource(entry.key, -entry.value);
    }

    setState(() {
      _you = updated;
      _draggingCard = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final yourStorage = MockGame.resourceStorageFor(_you.principality);
    final opponentStorage = MockGame.resourceStorageFor(_opponent.principality);

    return Scaffold(
      body: Column(
        children: [
          TopStatusBar(opponent: _opponent),
          Expanded(
            flex: 4,
            child: PrincipalityGrid(
              board: _opponent.principality,
              resourceStorage: opponentStorage,
              unit: 58,
              gap: 4,
            ),
          ),
          CenterStacksStrip(stackCounts: MockGame.centerStackCounts()),
          Expanded(
            flex: 5,
            child: PrincipalityGrid(
              board: _you.principality,
              resourceStorage: yourStorage,
              interactive: true,
              draggingCard: _draggingCard,
              onDropExpansion: _handleDrop,
            ),
          ),
          HandDock(
            player: _you,
            onDragStarted: (card) => setState(() => _draggingCard = card),
            onDragEnd: () => setState(() => _draggingCard = null),
          ),
        ],
      ),
    );
  }
}
