import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Den öppna "ansikte-upp"-högen (se [GameState.faceUpExpansionCards],
/// t.ex. 2× Köpmansgille för Gulderan) – korten sorterades ut FÖRE
/// blandning och ligger synliga för båda spelarna hela matchen, i
/// stället för dolda i en av draghögarna. Vem som helst kan bygga
/// direkt härifrån på sin egen tur genom att dra ut ett kort och
/// betala byggkostnaden som vanligt (se
/// [GameNotifier.buyFaceUpExpansion]) – ingen "kika i hög"-omväg
/// behövs eftersom korten redan ligger uppslagna.
///
/// Tom lista ritar ingenting (se `if (faceUpExpansionCards.isNotEmpty)`
/// i [CenterStacksStrip]) – bara relevant när ett tema med en sådan hög
/// är aktivt.
class FaceUpExpansionPile extends StatelessWidget {
  final List<GameCard> cards;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  /// Om korten går att dra ut på riket just nu (se
  /// [CenterStacksStrip.canBuild]) – annars bara tryckbara för att
  /// förstora, som vanligt.
  final bool canBuild;

  const FaceUpExpansionPile({
    super.key,
    required this.cards,
    this.onDragStarted,
    this.onDragEnd,
    this.canBuild = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          SizedBox(width: 48, child: _FaceUpCard(card: cards[i], canBuild: canBuild, onDragStarted: onDragStarted, onDragEnd: onDragEnd)),
        ],
      ],
    );
  }
}

class _FaceUpCard extends StatelessWidget {
  final GameCard card;
  final bool canBuild;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  const _FaceUpCard({
    required this.card,
    required this.canBuild,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final face = ExpansionCardView(card: card);
    if (!canBuild) return face;

    return LongPressDraggable<GameCard>(
      data: card,
      delay: const Duration(milliseconds: 180),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
            width: 48, child: Transform.scale(scale: 1.3, child: face)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: face),
      onDragStarted: () => onDragStarted?.call(card),
      onDragEnd: (_) => onDragEnd?.call(),
      // Samma resonemang som _StackPile/_HandCard: släpps kortet utan
      // att träffa ett giltigt mål tolkar vi som ett tryck och visar
      // kortet förstorat i stället.
      onDraggableCanceled: (_, __) {
        onDragEnd?.call();
        showCardDetail(context, card);
      },
      child: face,
    );
  }
}
