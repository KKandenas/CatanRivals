import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Slänghögen (se [GameState.discardPile]/[GameNotifier.discardActionCard]/
/// [GameNotifier.dropExpansion]): spelade handlingskort och byggnader/
/// enheter/skepp som bytts ut mot ett nytt kort på samma plats. Bara
/// det översta kortet (sist tillagt) är synligt – regelhäftets vanliga
/// princip för en slänghög – ett tryck förstorar det precis som andra
/// kort ([showCardDetail]). Visas inte alls när högen är tom, i stället
/// för en tom platshållare – det finns inget att titta på än.
class DiscardPileView extends StatelessWidget {
  final List<GameCard> discardPile;

  const DiscardPileView({super.key, required this.discardPile});

  @override
  Widget build(BuildContext context) {
    if (discardPile.isEmpty) return const SizedBox.shrink();
    final topCard = discardPile.last;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Text('Slänghög:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CatanColors.ink)),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: ExpansionCardView(
              card: topCard,
              showCost: false,
              onTap: () => showCardDetail(context, topCard),
            ),
          ),
        ],
      ),
    );
  }
}
