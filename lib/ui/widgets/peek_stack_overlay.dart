import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Visar alla kort i den uppslagna draghögen (kortbytesfasens
/// betal-och-kika-alternativ, se [TradePhase.peekViewing] i
/// game_state.dart) i den ordning de faktiskt ligger. Ett tryck på ett
/// kort förstorar det (samma dialogruta som annars, se
/// [showCardDetail]) så man kan läsa alla detaljer innan man
/// bestämmer sig – där får man frågan "Vill du ta detta kort?" med
/// Ta kortet/Avbryt i stället för dialogrutans vanliga rena
/// stäng-knapp. Resten av korten läggs automatiskt tillbaka i samma
/// ordning (se [GameNotifier.peekTakeCard]).
///
/// Läggs ovanpå motståndarens rike, precis som [BuildConfirmCard] –
/// inte en modal dialogruta, så det aldrig går att fastna: man måste
/// välja ett kort (regelhäftet kräver det efter att ha betalat), men
/// egna regioners +/- knappar är ändå nåbara om något skulle behöva
/// justeras samtidigt.
class PeekStackOverlay extends StatelessWidget {
  final List<GameCard> cards;
  final void Function(GameCard card) onTakeCard;

  const PeekStackOverlay(
      {super.key, required this.cards, required this.onTakeCard});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        // Bredare än t.ex. BuildConfirmCard (maxWidth 320) så fler kort
        // syns samtidigt utan att behöva skrolla lika mycket – en hög
        // kan innehålla upp till 9 kort.
        constraints: const BoxConstraints(maxWidth: 640),
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
                const Text(
                  'Tryck på ett kort för att förstora det, välj sedan om du vill ta det. Resten läggs tillbaka i samma ordning.',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => SizedBox(
                      width: 96,
                      child: ExpansionCardView(
                        card: cards[i],
                        onTap: () => showCardDetail(context, cards[i],
                            onTakeCard: () => onTakeCard(cards[i])),
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
