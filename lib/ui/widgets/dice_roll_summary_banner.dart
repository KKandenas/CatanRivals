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
/// att trycka på. Stängs manuellt med "OK" (se [onDismiss] – hela
/// `Positioned.fill`-täckningen, inte bara den här widgeten, måste
/// försvinna då, annars blockerar den svarta bakgrunden fortfarande
/// motståndarens rike/kortförstoring resten av action-fasen, se
/// game_board_screen.dart), eller visas på nytt för varje nytt kast
/// (se `key: ValueKey(...)` i game_board_screen.dart).
class DiceRollSummaryBanner extends StatelessWidget {
  final int productionRoll;
  final EventDieFace eventDieFace;
  final bool rolledByMe;
  final String opponentName;
  final VoidCallback onDismiss;

  const DiceRollSummaryBanner({
    super.key,
    required this.productionRoll,
    required this.eventDieFace,
    required this.rolledByMe,
    required this.opponentName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final who = rolledByMe ? 'Du' : opponentName;
    final face = eventDieFace;

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
              value: productionRoll, size: 30, dotColor: CatanColors.ink),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$who slog en $productionRoll:a. Ta dina resurser genom '
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
                    onTap: onDismiss,
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
