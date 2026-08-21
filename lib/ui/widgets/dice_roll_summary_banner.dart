import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'event_die_icon.dart';

/// Popup högst upp (inte en dialogruta – se nedan) som visar vad de två
/// tärningarna (produktions- och händelsetärningen, se [EventDieFace])
/// slog och vad som ska göras, synlig för båda spelarna (produktions-
/// och händelsetärningens utfall synkas redan via [TurnState]).
/// Ersätter den gamla, enklare banner-raden som bara visade
/// produktionstalet.
///
/// Ordningen på raderna beror på [EventDieFace.resolveBeforeResources]
/// (regelhäftets referenskort: allt utom brigadanfallet görs EFTER att
/// resurserna tagits, brigadanfallet görs INNAN) – bara instruktionen
/// visas, appen genomför inget automatiskt.
///
/// En vanlig rad i sidflödet (inte en dialogruta), precis som
/// [TradePhaseCard] – så att regionernas +/- knappar går att trycka på
/// medan den syns. Stängs manuellt med "OK", eller visas på nytt för
/// varje nytt kast (se `key: ValueKey(...)` i game_board_screen.dart).
class DiceRollSummaryBanner extends StatefulWidget {
  final int productionRoll;
  final EventDieFace eventDieFace;
  final bool rolledByMe;
  final String opponentName;

  const DiceRollSummaryBanner({
    super.key,
    required this.productionRoll,
    required this.eventDieFace,
    required this.rolledByMe,
    required this.opponentName,
  });

  @override
  State<DiceRollSummaryBanner> createState() => _DiceRollSummaryBannerState();
}

class _DiceRollSummaryBannerState extends State<DiceRollSummaryBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final who = widget.rolledByMe ? 'Du' : widget.opponentName;
    final face = widget.eventDieFace;

    const resourceLine = Text(
      'Ta dina resurser genom att trycka på +.',
      style: TextStyle(
          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
    );

    final eventLine = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventDieIcon(face: face, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              children: [
                TextSpan(
                    text: '${face.swedishName}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: face.ruleText),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$who slog en ${widget.productionRoll}:a.',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7CBF6A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (face.resolveBeforeResources) ...[
            eventLine,
            const SizedBox(height: 6),
            resourceLine,
          ] else ...[
            resourceLine,
            const SizedBox(height: 6),
            eventLine,
          ],
        ],
      ),
    );
  }
}
