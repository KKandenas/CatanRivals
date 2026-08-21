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
/// Kortet är draget och synkat till båda spelarna (regelhäftet: "reads
/// the event aloud") – vem som helst kan stänga rutan med "Klart" när
/// det är läst och (om det påverkar någon) genomfört, appen gör inget
/// automatiskt åt själva effekten.
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
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
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
                            'Händelsekort: ${card.name}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: CatanColors.ink),
                          ),
                          if (card.effectText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              card.effectText!,
                              style: const TextStyle(
                                  fontSize: 12.5, color: CatanColors.ink),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F6F45)),
                  onPressed: onDismiss,
                  child: const Text('Klart'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
