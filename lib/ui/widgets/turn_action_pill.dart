import 'package:flutter/material.dart';

import '../../state/game_state.dart';

/// Visar den enda relevanta åtgärds-/statusetiketten för den aktiva
/// spelarens omgång, bredvid "DIN TUR"-pillen högst upp (se
/// game_board_screen.dart) – tidigare låg den här längst till höger i
/// [CenterStacksStrip], men flyttades hit för att ge mittremsans kort
/// (draghögarna) mer plats, särskilt med fler draghögar när ett
/// temaset är aktivt (se [ExpansionSet]).
///
/// Bara en av de tre lägena visas åt gången: "Avsluta action-fas" (din
/// tur, tärningen slagen, ingen handjustering/kortbytesfas pågår),
/// hand­justeringens läge ("Dra kort: X/Y"/"Släng kort: X/Y"), eller
/// (motståndarens tur) en gyllene etikett om du kikar i en av
/// motståndarens draghögar. Kortbytesfasens egna instruktioner visas i
/// stället i TradePhaseCard – ingen etikett här då.
class TurnActionPill extends StatelessWidget {
  final bool isYourTurn;
  final bool diceRolled;
  final bool isChoosingHand;
  final HandAdjustmentPhase handAdjustmentPhase;
  final TradePhase tradePhase;
  final int handCount;
  final int handLimit;
  final VoidCallback? onEndTurn;

  /// Bibliotek (se [GameState.libraryDrawPending]): döljer "Avsluta
  /// action-fas" och visar en etikett i stället, precis som
  /// [handAdjustmentPhase] – draghögarna är tryckbara i
  /// [CenterStacksStrip] under tiden.
  final bool libraryDrawPending;

  /// Vilken draghög (0–3) MOTSTÅNDAREN just nu kikar i (se
  /// [GameState.peekingStackIndex]) – bara meningsfullt att visa på
  /// din egen tur (annars ser den kikande spelaren redan hela högen i
  /// sin egen overlay). Anroparen skickar redan bara med motståndarens
  /// index (se game_board_screen.dart), men [isYourTurn] dubbelkollas
  /// här också, precis som innan flytten från CenterStacksStrip.
  final int? peekingStackIndex;

  const TurnActionPill({
    super.key,
    required this.isYourTurn,
    required this.diceRolled,
    required this.isChoosingHand,
    required this.handAdjustmentPhase,
    required this.tradePhase,
    this.handCount = 0,
    this.handLimit = 3,
    this.onEndTurn,
    this.peekingStackIndex,
    this.libraryDrawPending = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isYourTurn && diceRolled && !isChoosingHand) {
      if (handAdjustmentPhase == HandAdjustmentPhase.none &&
          tradePhase == TradePhase.none &&
          !libraryDrawPending) {
        return _EndTurnButton(onTap: onEndTurn);
      }
      if (handAdjustmentPhase != HandAdjustmentPhase.none) {
        return _HandAdjustmentLabel(
            phase: handAdjustmentPhase, count: handCount, limit: handLimit);
      }
      if (libraryDrawPending) {
        return const _SimplePillLabel(label: 'Dra ett bibliotekskort');
      }
      return const SizedBox.shrink();
    }
    if (!isYourTurn && peekingStackIndex != null) {
      return _PeekingLabel(stackIndex: peekingStackIndex!);
    }
    return const SizedBox.shrink();
  }
}

class _EndTurnButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _EndTurnButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF7CBF6A),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Text(
          'Avsluta action-fas',
          style: TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Enkel grön etikett utan räknare – används i stället för
/// "Avsluta action-fas" när något annat kräver spelarens
/// uppmärksamhet just nu men inte behöver visa en räknare som
/// [_HandAdjustmentLabel] (t.ex. Bibliotekets kortdragning).
class _SimplePillLabel extends StatelessWidget {
  final String label;

  const _SimplePillLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7CBF6A),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Visas för motståndaren när den aktiva spelaren kikar i en draghög
/// (regelhäftet s. 9) – bara VILKEN hög, aldrig vilka kort som ligger
/// där (se [TurnActionPill.peekingStackIndex]). Guldfärgad, samma
/// accent som den gyllene glöden på själva högen (se
/// [CenterStacksStrip]s `_StackPile`).
class _PeekingLabel extends StatelessWidget {
  final int stackIndex;

  const _PeekingLabel({required this.stackIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A227),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        'Kikar i hög ${stackIndex + 1}',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Visas i stället för "Avsluta action-fas" medan handjusteringen
/// pågår – talar om vad spelaren ska göra och hur långt kvar det är
/// (t.ex. "Dra kort: 2/4" eller "Släng kort: 5/4").
class _HandAdjustmentLabel extends StatelessWidget {
  final HandAdjustmentPhase phase;
  final int count;
  final int limit;

  const _HandAdjustmentLabel(
      {required this.phase, required this.count, required this.limit});

  @override
  Widget build(BuildContext context) {
    final label = phase == HandAdjustmentPhase.drawing
        ? 'Dra kort: $count/$limit'
        : 'Släng kort: $count/$limit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7CBF6A),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
