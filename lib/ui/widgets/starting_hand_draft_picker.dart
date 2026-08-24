import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Den uppslagna draghögen under starthandsutdelningen med ett tema
/// aktivt (regelhäftet: "Man väljer en av de tre högarna som innehåller
/// korten från grundspelet. Man får kika på alla kort i högen och
/// välja ut tre.") – se [GameNotifier.startHandDraft]/
/// [GameNotifier.pickHandDraftCard]. Samma icke-modala mönster som
/// [FraternalFeudsHandPicker]: hela poolen visas på en gång, ett tryck
/// förstorar och frågar innan kortet väljs.
class StartingHandDraftPicker extends StatelessWidget {
  final List<GameCard> pool;
  final int pickedCount;
  final void Function(GameCard card) onPick;

  const StartingHandDraftPicker({
    super.key,
    required this.pool,
    required this.pickedCount,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 480),
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
                  'Starthand: välj $pickedCount/3 kort ur högen '
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
                        for (final card in pool)
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
