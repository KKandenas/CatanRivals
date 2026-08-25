import 'package:flutter/material.dart';

import '../../state/game_state.dart';
import '../theme/catan_colors.dart';

/// Banner för kortbytesfasen (regelhäftet s. 9), sist i omgången efter
/// handjusteringen – visas som en vanlig, icke-modal rad högst upp i
/// sidflödet, inte en dialogruta, så att regionernas +/- knappar
/// fortfarande går att trycka på under [TradePhase.peekPaying] (man
/// betalar ju genom att trycka − där).
///
/// Byter innehåll efter [TradePhase]:
/// - [TradePhase.choosing]: de tre huvudvalen (behåll handen / byt ett
///   kort gratis / kika i en hög mot betalning).
/// - [TradePhase.exchangeDiscard]/[exchangeDraw]: en instruktionsrad –
///   själva högarna (tryckbara) sitter i [CenterStacksStrip].
/// - [TradePhase.peekPaying]: kostnaden (2 valfria resurser – 1 om
///   spelaren har byggt Församlingshus, 0 (och fasen hoppas över helt,
///   se [GameNotifier.startPeek]) med Rådhus, se [peekCost] –
///   självbevakat precis som byggkostnader) + Betalt/Avbryt.
/// - [TradePhase.peekDiscard]: en instruktionsrad – man slänger ett
///   kort innan man kikar, precis som det gratis bytet (annars skulle
///   handen bara växa).
/// - [TradePhase.peekChoosingStack]: en instruktionsrad.
/// - [TradePhase.peekViewing] visas inte här alls – se
///   [PeekStackOverlay], som täcker motståndarens rike i stället,
///   eftersom den behöver plats för att visa flera kort.
class TradePhaseCard extends StatelessWidget {
  final TradePhase phase;
  final VoidCallback? onSkip;
  final VoidCallback? onStartExchange;
  final VoidCallback? onStartPeek;
  final VoidCallback? onConfirmPeekPayment;
  final VoidCallback? onCancelPeek;

  /// Vad det kostar att kika i en hel draghög (regelhäftet s. 9: 2
  /// valfria resurser, men bara 1 med Församlingshus i spel – se
  /// BasicSetCards.parishHall.effectText). Styr både knapptexten
  /// ("Kika (N resurs/er)") och betaltexten under [TradePhase.peekPaying].
  final int peekCost;

  const TradePhaseCard({
    super.key,
    required this.phase,
    this.onSkip,
    this.onStartExchange,
    this.onStartPeek,
    this.onConfirmPeekPayment,
    this.onCancelPeek,
    this.peekCost = 2,
  });

  @override
  Widget build(BuildContext context) {
    final resourceWord = peekCost == 1 ? 'resurs' : 'resurser';
    switch (phase) {
      case TradePhase.none:
      case TradePhase.peekViewing:
        return const SizedBox.shrink();
      case TradePhase.choosing:
        return _Banner(
          label: 'Vill du byta ut något kort innan turen går vidare?',
          actions: [
            _ActionButton(label: 'Behåll handen', onTap: onSkip),
            _ActionButton(label: 'Byt ett kort', onTap: onStartExchange),
            _ActionButton(
                label: peekCost == 0
                    ? 'Kika (gratis)'
                    : 'Kika ($peekCost $resourceWord)',
                onTap: onStartPeek),
          ],
        );
      case TradePhase.exchangeDiscard:
        return const _Banner(
          label: 'Byt: välj ett handkort, tryck sedan på en draghög.',
        );
      case TradePhase.exchangeDraw:
        return const _Banner(
          label: 'Byt: tryck på en draghög för att dra ett kort.',
        );
      case TradePhase.peekPaying:
        final valfri = peekCost == 1 ? 'valfri' : 'valfria';
        return _Banner(
          label:
              'Betala $peekCost $valfri $resourceWord genom att trycka − på valfria regioner.',
          actions: [
            _ActionButton(label: 'Avbryt', onTap: onCancelPeek, filled: false),
            _ActionButton(label: 'Betalt', onTap: onConfirmPeekPayment),
          ],
        );
      case TradePhase.peekDiscard:
        return const _Banner(
          label: 'Kika: slängkort – välj ett handkort, tryck sedan på en draghög.',
        );
      case TradePhase.peekChoosingStack:
        return const _Banner(
          label: 'Tryck på draghögen du vill kika i.',
        );
    }
  }
}

class _Banner extends StatelessWidget {
  final String label;
  final List<Widget> actions;

  const _Banner({required this.label, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 6,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 6, children: actions),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _ActionButton(
      {required this.label, this.onTap, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF7CBF6A) : Colors.transparent,
          border: filled ? null : Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
