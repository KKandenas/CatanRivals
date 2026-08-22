import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Motståndarens öppna hand under Brödrafejd (regelhäftet: "selects 2
/// cards from the opponent's hand") – bara lokalt läge (se
/// [GameNotifier.startFraternalFeudsPick]). Samma icke-modala mönster
/// som [ScoutRegionPicker]: hela handen visas på en gång, ett tryck
/// förstorar och frågar innan kortet väljs.
class FraternalFeudsHandPicker extends StatelessWidget {
  final List<GameCard> hand;
  final int pickedCount;
  final void Function(GameCard card) onPick;

  const FraternalFeudsHandPicker({
    super.key,
    required this.hand,
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
                  'Brödrafejd: välj $pickedCount/2 kort från motståndarens hand '
                  '(tryck för att förstora)',
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
                        for (final card in hand)
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: ExpansionCardView(
                              card: card,
                              showCost: false,
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
