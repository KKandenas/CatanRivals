import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Visas när ett händelsekort dragits (händelsetärningens "?", se
/// [EventDieFace.eventCard] och [GameNotifier.drawEventCard]) – inte en
/// modal dialogruta, utan en vanlig widget ovanpå motståndarens rike
/// (samma plats som [BuildConfirmCard]/`PeekStackOverlay`), så att egna
/// regioners +/- fortfarande går att trycka på medan den syns.
///
/// Samma stora, kvadratiska kortbild som kortförstoringen
/// (`showCardDetail`/`card_detail_dialog.dart`) i stället för en liten
/// miniatyr – men namn och regeltext ligger som en halvgenomskinlig
/// remsa ovanpå bildens nederkant snarare än i en egen vit sektion
/// under, så hela rutan hålls kompakt (den ska ju aldrig skymma ens
/// egen spelplan).
///
/// Kortet är draget och synkat till båda spelarna (regelhäftet: "reads
/// the event aloud") – vem som helst kan stänga rutan (samma runda
/// stäng-knapp som kortförstoringen) när det är läst och (om det
/// påverkar någon) genomfört, appen gör inget automatiskt åt själva
/// effekten.
class EventCardRevealCard extends StatelessWidget {
  final GameCard card;
  final VoidCallback onDismiss;

  const EventCardRevealCard({
    super.key,
    required this.card,
    required this.onDismiss,
  });

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
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  CatanAssets.resolveCardImage(card),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: CatanColors.woodFrame),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 36, 14, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          if (card.effectText != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              card.effectText!,
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: Colors.white.withValues(alpha: 0.92)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _CloseButton(onTap: onDismiss),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration:
            const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.close, size: 18, color: Colors.white),
      ),
    );
  }
}
