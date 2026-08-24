import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Slänghögen (se [GameState.discardPile]/[GameNotifier.discardActionCard]/
/// [GameNotifier.dropExpansion]): spelade handlingskort och byggnader/
/// enheter/skepp som bytts ut mot ett nytt kort på samma plats. Bara
/// det översta kortet (sist tillagt) är synligt – regelhäftets vanliga
/// princip för en slänghög – ett tryck förstorar det precis som andra
/// kort ([showCardDetail]). Visas inte alls när högen är tom, i stället
/// för en tom platshållare – det finns inget att titta på än.
///
/// Sitter under tärningarna (se game_board_screen.dart) i en smal
/// 76-punkters kolumn, precis som [EventDieIcon] där ovanför – därför
/// bara själva korttumnageln utan någon "Slänghög:"-etikett bredvid
/// (skulle inte få plats), samma ikon-utan-text-stil som resten av den
/// kolumnen redan använder.
class DiscardPileView extends StatelessWidget {
  final List<GameCard> discardPile;

  const DiscardPileView({super.key, required this.discardPile});

  @override
  Widget build(BuildContext context) {
    if (discardPile.isEmpty) return const SizedBox.shrink();
    final topCard = discardPile.last;

    return SizedBox(
      width: 48,
      height: 48,
      child: ExpansionCardView(
        card: topCard,
        showCost: false,
        onTap: () => showCardDetail(context, topCard),
      ),
    );
  }
}

