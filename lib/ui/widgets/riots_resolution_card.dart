import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Visas i stället för [EventCardRevealCard] när det uppslagna
/// händelsekortet är Upplopp (Oroligheternas tid, EraOfTurmoilCards.
/// riots) – till skillnad från Fejd/Brödrafejd (se [FeudResolutionCard],
/// bara EN sida agerar utifrån ett gemensamt jämfört styrkeövertag)
/// visar den här kortet DIN EGEN enhetsräkning ([unitCount]/[goldOwed]),
/// eftersom Upplopp gäller varje spelare oberoende av den andra – båda
/// klienterna kan alltså visa den här rutan samtidigt, var och en med
/// sin egen räkning (se [GameNotifier.resolveRiotsPay]/
/// [riotsQualifyingUnitCount]).
class RiotsResolutionCard extends StatelessWidget {
  final GameCard card;
  final int unitCount;
  final int goldOwed;

  /// Om du redan spelat Sebastian, den vandrande predikanten mot just
  /// det här kortet (se [GameNotifier.playSebastianForCurrentEvent]) –
  /// räknas som din egen färdiga hantering, se
  /// TurnState.sebastianProtectedPlayerIds-doc.
  final bool youProtected;

  /// Du har Sebastian på handen, har kvalificerande enheter (annars
  /// inget att skydda), och har inte redan skyddat dig.
  final bool canPlaySebastian;

  final VoidCallback onPay;
  final VoidCallback onCannotPay;
  final VoidCallback onPlaySebastian;

  const RiotsResolutionCard({
    super.key,
    required this.card,
    required this.unitCount,
    required this.goldOwed,
    this.youProtected = false,
    this.canPlaySebastian = false,
    required this.onPay,
    required this.onCannotPay,
    required this.onPlaySebastian,
  });

  bool get _hasQualifyingUnits => unitCount > 0;

  String get _statusLine {
    if (youProtected) {
      return 'Du spelade Sebastian, den vandrande predikanten – gäller '
          'inte dig. Inget händer.';
    }
    if (!_hasQualifyingUnits) {
      return 'Du har inga enheter med styrke- eller handelspoäng. Inget händer.';
    }
    final unitWord = unitCount == 1 ? 'enhet' : 'enheter';
    return 'Du har $unitCount $unitWord med styrke- eller handelspoäng och '
        'ska betala $goldOwed guld.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          // Samma layout-resonemang som FeudResolutionCard: liten
          // kortbild bredvid texten i stället för ovanpå, så knapparna
          // aldrig riskerar att hamna utanför synligt område.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.asset(
                          CatanAssets.resolveCardImage(card),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: CatanColors.woodFrame),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: CatanColors.ink),
                          ),
                          if (card.effectText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              card.effectText!,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: CatanColors.ink,
                                  height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _statusLine,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 12),
                if (youProtected || !_hasQualifyingUnits)
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F6F45)),
                    onPressed: onPay,
                    child: const Text('OK'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4F6F45)),
                          onPressed: onPay,
                          child: const Text('Betalt'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: CatanColors.ink,
                              side: const BorderSide(
                                  color: CatanColors.woodFrame)),
                          onPressed: onCannotPay,
                          child: const Text('Kan inte betala'),
                        ),
                      ),
                    ],
                  ),
                if (canPlaySebastian) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: CatanColors.ink,
                        side: const BorderSide(color: CatanColors.woodFrame)),
                    onPressed: onPlaySebastian,
                    child: const Text(
                        'Spela Sebastian, den vandrande predikanten (skydda dig)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
