import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_notifier.dart';
import '../../state/game_state.dart';
import '../theme/catan_colors.dart';
import '../widgets/center_stacks_strip.dart';
import '../widgets/dice_roll_button.dart';
import '../widgets/hand_dock.dart';
import '../widgets/pending_regions_bar.dart';
import '../widgets/principality_grid.dart';
import '../widgets/roll_info_banner.dart';
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

    // Turindikatorn (banner/ram/nedtoning) är bara meningsfull under
    // vanligt spel – inte under starthandsvalet, som redan har sin
    // egen banner och där tärningen ändå aldrig är slagen.
    final showTurnEmphasis = state.handsReady;
    final canBuildNow = state.canBuildNow;

    return Scaffold(
      // Rumskoden behövs bara medan den andra spelaren ännu inte gått
      // med – när båda är inne försvinner remsan automatiskt för att
      // ge mer plats åt själva brädet.
      appBar: (state.roomCode == null || state.opponentConnected)
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
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer),
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
            )
          else if (showTurnEmphasis)
            // Bred, permanent banner så det aldrig är oklart vems tur
            // det är – kompletterar den gröna ramen runt egna riket och
            // den lätta nedtoningen när det inte är din tur.
            Container(
              width: double.infinity,
              color: state.activePlayerIsMe
                  ? const Color(0xFF4F6F45)
                  : CatanColors.woodFrameDark,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                state.activePlayerIsMe ? 'DIN TUR' : '${state.opponent.name}s TUR',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          TopStatusBar(opponent: state.opponent, opponentIsRed: !state.amIRed),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(
                  child: PrincipalityGrid(
                    board: state.opponent.principality,
                    unit: 58,
                    gap: 4,
                  ),
                ),
                // Tärningen står till höger om motståndarens rike i
                // stället för i mittremsan, så att mittremsan (och
                // därmed alla kort) kan vara så stora som möjligt.
                Container(
                  width: 76,
                  color: CatanColors.woodFrameDark,
                  alignment: Alignment.center,
                  child: DiceRollButton(
                    value: state.productionRoll,
                    rollable: state.isMyTurn &&
                        !state.diceRolled &&
                        !(state.isOnline && !state.handsReady),
                    onTap: () =>
                        _handleResult(context, notifier.rollProductionDie()),
                  ),
                ),
              ],
            ),
          ),
          CenterStacksStrip(
            stackCounts: state.centerStacks,
            onDragStarted: notifier.startDrag,
            onDragEnd: notifier.endDrag,
            isChoosingHand: state.isOnline && !state.handsReady,
            isMyTurnToChooseHand: state.isMyTurnToChooseHand,
            onChooseStack: (index) =>
                _handleResult(context, notifier.chooseStartingStack(index)),
            isYourTurn: state.isMyTurn,
            diceRolled: state.diceRolled,
            onEndTurn: () => _handleResult(context, notifier.endTurn()),
          ),
          // Info-remsa efter tärningskastet – inte en dialogruta, så
          // den täcker aldrig regionerna och +-knapparna går att
          // trycka på medan den syns. `key: ValueKey(...)` gör att den
          // återställs (visas på nytt, oavsett tidigare "OK") för
          // varje nytt kast.
          if (state.diceRolled && state.productionRoll != null)
            RollInfoBanner(
              key: ValueKey(state.productionRoll),
              roll: state.productionRoll!,
              rolledByMe: state.activePlayerIsMe,
              opponentName: state.opponent.name,
            ),
          if (state.pendingRegions.isNotEmpty)
            PendingRegionsBar(
              cards: state.pendingRegions,
              onDragStarted: notifier.startDrag,
              onDragEnd: notifier.endDrag,
            ),
          Expanded(
            flex: 5,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: showTurnEmphasis && canBuildNow
                      ? const Color(0xFF7CBF6A)
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: showTurnEmphasis && canBuildNow
                    ? [
                        BoxShadow(
                            color: const Color(0xFF7CBF6A).withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 1),
                      ]
                    : null,
              ),
              // Lätt nedtoning (inte heltäckande) när det inte är din
              // tur att bygga – korten ska fortfarande gå att läsa och
              // trycka på för att förstora, bara se "inaktiva" ut.
              child: Opacity(
                opacity: showTurnEmphasis && !canBuildNow ? 0.6 : 1,
                child: PrincipalityGrid(
                  board: state.you.principality,
                  interactive: true,
                  draggingCard: state.draggingCard,
                  onDropExpansion: (column, row, slotIndex, card) => _handleResult(
                      context,
                      notifier.dropExpansion(column, row, slotIndex, card)),
                  onDropRoad: (column, card) =>
                      _handleResult(context, notifier.dropRoad(column, card)),
                  onDropSettlement: (column, card) =>
                      _handleResult(context, notifier.dropSettlement(column, card)),
                  onDropCityUpgrade: (column, card) => _handleResult(
                      context, notifier.dropCityUpgrade(column, card)),
                  onAdjustRegion: notifier.adjustRegionResource,
                  pendingRegionJunction: state.pendingRegionJunction,
                  onDropPendingRegion: (row, card) => _handleResult(
                      context, notifier.placePendingRegion(row, card)),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: showTurnEmphasis && !canBuildNow ? 0.6 : 1,
            child: HandDock(
              player: state.you,
              onDragStarted: notifier.startDrag,
              onDragEnd: notifier.endDrag,
            ),
          ),
        ],
      ),
    );
  }
}
