import 'package:flutter/material.dart';

import '../../data/mock_game.dart';
import '../widgets/center_stacks_strip.dart';
import '../widgets/hand_dock.dart';
import '../widgets/principality_grid.dart';
import '../widgets/top_status_bar.dart';

/// Huvudskärmen, stående layout: motståndarens namn/status (smal remsa),
/// motståndarens rike (kompakt), dragstaplar + tärning + turindikator i
/// mitten (som i det fysiska spelets uppställning), ditt eget rike
/// (större, i fokus) och din handkortsdocka längst ner.
///
/// Statisk vy byggd på mock-data – ingen interaktion eller
/// spelstate-koppling än (kommer i ett senare steg).
class GameBoardScreen extends StatelessWidget {
  const GameBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final you = MockGame.buildYou();
    final opponent = MockGame.buildOpponent();
    final yourStorage = MockGame.resourceStorageFor(you.principality);
    final opponentStorage = MockGame.resourceStorageFor(opponent.principality);

    return Scaffold(
      body: Column(
        children: [
          TopStatusBar(opponent: opponent),
          Expanded(
            flex: 4,
            child: PrincipalityGrid(
              board: opponent.principality,
              resourceStorage: opponentStorage,
              unit: 58,
              gap: 4,
            ),
          ),
          CenterStacksStrip(stackCounts: MockGame.centerStackCounts()),
          Expanded(
            flex: 5,
            child: PrincipalityGrid(board: you.principality, resourceStorage: yourStorage),
          ),
          HandDock(player: you),
        ],
      ),
    );
  }
}
