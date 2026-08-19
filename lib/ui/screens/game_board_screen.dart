import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_game.dart';
import '../../state/game_notifier.dart';
import '../widgets/center_stacks_strip.dart';
import '../widgets/hand_dock.dart';
import '../widgets/principality_grid.dart';
import '../widgets/top_status_bar.dart';

/// Huvudskärmen, stående layout: motståndarens namn/status (smal remsa),
/// motståndarens rike (kompakt), dragstaplar + tärning + turindikator i
/// mitten (som i det fysiska spelets uppställning), ditt eget rike
/// (större, i fokus) och din handkortsdocka längst ner.
///
/// Rent presentationslager – allt spelstate bor i [gameProvider]
/// (state/game_notifier.dart).
class GameBoardScreen extends ConsumerWidget {
  const GameBoardScreen({super.key});

  void _handleResult(BuildContext context, String? error) {
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final yourStorage = MockGame.resourceStorageFor(state.you.principality);
    final opponentStorage = MockGame.resourceStorageFor(state.opponent.principality);

    return Scaffold(
      body: Column(
        children: [
          TopStatusBar(opponent: state.opponent),
          Expanded(
            flex: 4,
            child: PrincipalityGrid(
              board: state.opponent.principality,
              resourceStorage: opponentStorage,
              unit: 58,
              gap: 4,
            ),
          ),
          CenterStacksStrip(
            stackCounts: state.centerStacks,
            onDragStarted: notifier.startDrag,
            onDragEnd: notifier.endDrag,
          ),
          Expanded(
            flex: 5,
            child: PrincipalityGrid(
              board: state.you.principality,
              resourceStorage: yourStorage,
              interactive: true,
              draggingCard: state.draggingCard,
              onDropExpansion: (column, row, slotIndex, card) =>
                  _handleResult(context, notifier.dropExpansion(column, row, slotIndex, card)),
              onDropRoad: (column, card) => _handleResult(context, notifier.dropRoad(column, card)),
              onDropSettlement: (column, card) => _handleResult(context, notifier.dropSettlement(column, card)),
              onDropCityUpgrade: (column, card) => _handleResult(context, notifier.dropCityUpgrade(column, card)),
            ),
          ),
          HandDock(
            player: state.you,
            onDragStarted: notifier.startDrag,
            onDragEnd: notifier.endDrag,
          ),
        ],
      ),
    );
  }
}
