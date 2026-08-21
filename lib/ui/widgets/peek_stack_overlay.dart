import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'expansion_card_view.dart';

/// Visar alla kort i den uppslagna draghögen (kortbytesfasens
/// betal-och-kika-alternativ, se [TradePhase.peekViewing] i
/// game_state.dart) i den ordning de faktiskt ligger – ett tryck
/// väljer vilket man behåller, resten läggs automatiskt tillbaka i
/// samma ordning (se [GameNotifier.peekTakeCard]).
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
        constraints: const BoxConstraints(maxWidth: 420),
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
                  'Välj ett kort att behålla – resten läggs tillbaka i samma ordning.',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => SizedBox(
                      width: 84,
                      child: ExpansionCardView(
                        card: cards[i],
                        onTap: () => onTakeCard(cards[i]),
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
