import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Motståndarens öppna hand under Brödrafejd (regelhäftet: "selects 2
/// cards from the opponent's hand") eller Förrädare (regelhäftet:
/// "titta på motståndarens kort ... välj ett som läggs till den egna
/// handen", se [GameNotifier.pickTraitorCard]) – bara lokalt läge för
/// Brödrafejd (se [GameNotifier.startFraternalFeudsPick]), men både
/// lokalt och online för Förrädare (kortet läggs direkt till din egen
/// hand, ingen mellanlagring behövs). Samma icke-modala mönster som
/// [ScoutRegionPicker]: hela handen visas på en gång, ett tryck
/// förstorar och frågar innan kortet väljs.
class FraternalFeudsHandPicker extends StatelessWidget {
  final List<GameCard> hand;

  /// Rubriktexten ovanför korten – anroparen bygger den själv (t.ex.
  /// "Brödrafejd: välj 1/2 kort..." eller "Förrädare: välj 1 kort...")
  /// eftersom de två händelserna räknar val olika.
  final String label;
  final void Function(GameCard card) onPick;

  const FraternalFeudsHandPicker({
    super.key,
    required this.hand,
    required this.label,
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
                  label,
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
