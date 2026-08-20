import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_notifier.dart';
import '../../state/game_state.dart';
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

    return Scaffold(
      appBar: state.roomCode == null
          ? null
          : AppBar(
              title: Text('Rum: ${state.roomCode}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Lämna rummet',
                  onPressed: () {
                    notifier.playLocally();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          if (state.sessionError != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                state.sessionError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            )
          else if (state.mode == SessionMode.host && !state.opponentConnected)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                'Väntar på att motståndaren ska gå med rummet ${state.roomCode} …',
                textAlign: TextAlign.center,
              ),
            )
          else if (state.isOnline && !state.handsReady)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                state.isMyTurnToChooseHand
                    ? 'Din tur: tryck på en draghög för att ta dina 3 starthandkort'
                    : 'Väntar på att ${state.opponent.name} väljer en draghög …',
                textAlign: TextAlign.center,
              ),
            ),
          TopStatusBar(opponent: state.opponent, opponentIsRed: !state.amIRed),
          Expanded(
            flex: 4,
            child: PrincipalityGrid(
              board: state.opponent.principality,
              unit: 58,
              gap: 4,
            ),
          ),
          CenterStacksStrip(
            stackCounts: state.centerStacks,
            onDragStarted: notifier.startDrag,
            onDragEnd: notifier.endDrag,
            isChoosingHand: state.isOnline && !state.handsReady,
            isMyTurnToChooseHand: state.isMyTurnToChooseHand,
            onChooseStack: (index) => _handleResult(context, notifier.chooseStartingStack(index)),
          ),
          Expanded(
            flex: 5,
            child: PrincipalityGrid(
              board: state.you.principality,
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
