import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'region_card_view.dart';

/// Den öppna regionstapeln under Spejare (regelhäftet: "Take 2 cards
/// of your choice from the region card stack") – hela den kvarvarande
/// stapeln (se [GameNotifier.useScout]) visas på en gång så spelaren
/// kan välja fritt, till skillnad från [PeekStackOverlay] (som bara
/// visar en enda draghög under kortbytesfasen). [pickedCount] styr
/// rubrikens räknare ("1/2 valda") – bygger på samma icke-modala
/// mönster som [BuildConfirmCard]: läggs ovanpå motståndarens rike.
class ScoutRegionPicker extends StatelessWidget {
  final List<GameCard> cards;
  final int pickedCount;
  final void Function(GameCard card) onPick;

  const ScoutRegionPicker({
    super.key,
    required this.cards,
    required this.pickedCount,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 420),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Spejare: välj $pickedCount/2 regionkort (tryck för att förstora)',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final card in cards)
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: RegionCardView(
                              card: card,
                              onTap: () => showCardDetail(context, card,
                                  onTakeCard: () => onPick(card)),
                            ),
                          ),
                      ],
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
