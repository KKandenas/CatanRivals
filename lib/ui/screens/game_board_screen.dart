import 'package:flutter/material.dart';

import '../../data/mock_game.dart';
import '../widgets/hand_dock.dart';
import '../widgets/principality_grid.dart';
import '../widgets/top_status_bar.dart';

/// Huvudskärmen: toppfält (motståndare/global info, ~10%), huvudområde
/// (ditt rike, ~80%) och bottenfält (handkort/resurser, ~10%).
///
/// Statisk vy byggd på mock-data – ingen interaktion eller
/// spelstate-koppling än (kommer i ett senare steg).
class GameBoardScreen extends StatelessWidget {
  const GameBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final you = MockGame.buildYou();
    final opponent = MockGame.buildOpponent();
    final storage = MockGame.resourceStorageFor(you.principality);

    return Scaffold(
      body: Column(
        children: [
          TopStatusBar(opponent: opponent),
          Expanded(
            child: PrincipalityGrid(board: you.principality, resourceStorage: storage),
          ),
          HandDock(player: you),
        ],
      ),
    );
  }
}
