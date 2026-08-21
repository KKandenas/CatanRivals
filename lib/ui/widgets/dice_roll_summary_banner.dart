import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'dice_face.dart';
import 'event_die_icon.dart';

/// Popup som visar vad de två tärningarna (produktions- och
/// händelsetärningen, se [EventDieFace]) slog och vad som ska göras,
/// synlig för båda spelarna (utfallen synkas redan via [TurnState]).
/// Samma rundade pergaments-kortstil som kortförstoringen
/// (`showCardDetail`)/`BuildConfirmCard` – produktionstärningens
/// prickar står till vänster om "Du slog en X:a ...", händelsetärningens
/// symbol till vänster om dess rad.
///
/// Ordningen på raderna beror på [EventDieFace.resolveBeforeResources]
/// (regelhäftets referenskort: allt utom brigadanfallet görs EFTER att
/// resurserna tagits, brigadanfallet görs INNAN) – bara instruktionen
/// visas, appen genomför inget automatiskt.
///
/// Läggs ovanpå motståndarens rike i game_board_screen.dart (samma
/// `Positioned.fill`-mönster som `BuildConfirmCard`/`PeekStackOverlay`)
/// i stället för att trycka ner hela brädet i sidflödet – täcker bara
/// motståndarens planhalva, dina egna regioners +/- går fortfarande
/// att trycka på. Stängs manuellt med "OK", eller visas på nytt för
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

    final resourceLine = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CatanColors.parchmentDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CatanColors.woodFrame),
          ),
          alignment: Alignment.center,
          child: DiceFace(
              value: widget.productionRoll, size: 30, dotColor: CatanColors.ink),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$who slog en ${widget.productionRoll}:a. Ta dina resurser genom '
            'att trycka på +.',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: CatanColors.ink),
          ),
        ),
      ],
    );

    final eventLine = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventDieIcon(face: face, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: CatanColors.ink, fontSize: 12.5),
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (face.resolveBeforeResources) ...[
                  eventLine,
                  const SizedBox(height: 10),
                  resourceLine,
                ] else ...[
                  resourceLine,
                  const SizedBox(height: 10),
                  eventLine,
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => setState(() => _dismissed = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
