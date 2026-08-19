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
/// Håller spelarna och dragstaplarnas antal som lokalt widget-state
/// (StatefulWidget) tills riktig spelstate (Riverpod) finns –
/// tillräckligt för att dra bygg-/enhetskort från handen, och
/// vägar/byar/städer direkt från center-dragstaplarna, till det egna
/// riket.
class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  late Player _you;
  late Player _opponent;
  late Map<String, int> _centerStacks;
  GameCard? _draggingCard;

  @override
  void initState() {
    super.initState();
    _you = MockGame.buildYou();
    _opponent = MockGame.buildOpponent();
    _centerStacks = MockGame.centerStackCounts();
  }

  bool _canAfford(GameCard card) {
    return card.buildingCost.entries.every((entry) => _you.resourceCount(entry.key) >= entry.value);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  /// Kollar att stapeln inte är slut och att spelaren har råd. Visar ett
  /// snackbar-meddelande och returnerar false om något inte stämmer.
  bool _canBuildFromStack(String stackKey, GameCard card) {
    if ((_centerStacks[stackKey] ?? 0) <= 0) {
      _showMessage('Inga fler ${card.name.toLowerCase()}or kvar i stapeln');
      return false;
    }
    if (!_canAfford(card)) {
      _showMessage('Inte råd med ${card.name}');
      return false;
    }
    return true;
  }

  Player _spend(Player player, GameCard card) {
    var updated = player;
    for (final entry in card.buildingCost.entries) {
      updated = updated.addResource(entry.key, -entry.value);
    }
    return updated;
  }

  void _handleDropExpansion(int column, BuildingRow row, int slotIndex, GameCard card) {
    if (!_you.hand.contains(card)) return;
    if (!_canAfford(card)) {
      _showMessage('Inte råd med ${card.name}');
      return;
    }

    _you.principality.placeExpansion(column, row, slotIndex, PlacedCard(card: card));
    final updated = _spend(_you.copyWith(hand: List.of(_you.hand)..remove(card)), card);

    setState(() {
      _you = updated;
      _draggingCard = null;
    });
  }

  void _handleDropRoad(int column, GameCard card) {
    if (!_canBuildFromStack('roads', card)) return;

    _you.principality.placeRoad(column, PlacedCard(card: card));
    final updated = _spend(_you, card);

    setState(() {
      _you = updated;
      _centerStacks = Map.of(_centerStacks)..update('roads', (v) => v - 1);
      _draggingCard = null;
    });
  }

  void _handleDropSettlement(int column, GameCard card) {
    if (!_canBuildFromStack('settlements', card)) return;

    final oldLeft = _you.principality.leftmostColumn;
    final oldRight = _you.principality.rightmostColumn;

    _you.principality.placeSettlement(column, PlacedCard(card: card));

    // Regelhäftet s. 8: en ny by ger automatiskt de 2 översta korten
    // från regionstapeln, placerade i den nya, ännu tomma knutpunkten.
    final newJunction = column < oldLeft ? column - 1 : column + 1;
    final wasNewSettlementFurtherOut = column < oldLeft || column > oldRight;
    if (wasNewSettlementFurtherOut) {
      _you.principality.placeRegion(newJunction, BuildingRow.above, PlacedCard(card: MockGame.drawRandomRegion()));
      _you.principality.placeRegion(newJunction, BuildingRow.below, PlacedCard(card: MockGame.drawRandomRegion()));
    }

    final updated = _spend(_you, card);

    setState(() {
      _you = updated;
      _centerStacks = Map.of(_centerStacks)
        ..update('settlements', (v) => v - 1)
        ..update('regions', (v) => wasNewSettlementFurtherOut ? v - 2 : v);
      _draggingCard = null;
    });
  }

  void _handleDropCityUpgrade(int column, GameCard card) {
    if (!_canBuildFromStack('cities', card)) return;

    _you.principality.upgradeToCity(column, PlacedCard(card: card));
    final updated = _spend(_you, card);

    setState(() {
      _you = updated;
      _centerStacks = Map.of(_centerStacks)..update('cities', (v) => v - 1);
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
          CenterStacksStrip(
            stackCounts: _centerStacks,
            onDragStarted: (card) => setState(() => _draggingCard = card),
            onDragEnd: () => setState(() => _draggingCard = null),
          ),
          Expanded(
            flex: 5,
            child: PrincipalityGrid(
              board: _you.principality,
              resourceStorage: yourStorage,
              interactive: true,
              draggingCard: _draggingCard,
              onDropExpansion: _handleDropExpansion,
              onDropRoad: _handleDropRoad,
              onDropSettlement: _handleDropSettlement,
              onDropCityUpgrade: _handleDropCityUpgrade,
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
