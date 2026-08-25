import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Ditt EGET ansikte-upp-kort (se [Player.faceUpExpansionCard]-doc,
/// t.ex. Köpmansgille för Gulderan) – sorterades ut FÖRE blandning och
/// ligger synligt hela matchen, i stället för dolt i en av
/// draghögarna. Bygger du det på din egen tur (se
/// [GameNotifier.buyFaceUpExpansion]) behövs ingen "kika i hög"-omväg
/// eftersom kortet redan ligger uppslaget. Varje spelare har sin egen,
/// separata plats – inte en delad hög båda kan bygga från, se
/// [Player.faceUpExpansionCard]-docen för varför.
///
/// [cards] rymmer som mest 1 kort i praktiken (ett per spelare), men
/// tar en lista för enkelhets skull – tom lista ritar ingenting, bara
/// relevant när ett tema med den här mekaniken är aktivt.
class FaceUpExpansionPile extends StatelessWidget {
  final List<GameCard> cards;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  /// Om korten går att dra ut på riket just nu (se
  /// [CenterStacksStrip.canBuild]) – annars bara tryckbara för att
  /// förstora, som vanligt.
  final bool canBuild;

  /// Kortets bredd/höjd – 48 (samma som center-högarna) som standard,
  /// men [HandDock] begär 72 för att matcha de vanliga handkorten (se
  /// [HandDock._CardFace._size]) eftersom det liggande kortet numera
  /// visas ibland handkorten i stället för i mittremsan.
  final double cardSize;

  const FaceUpExpansionPile({
    super.key,
    required this.cards,
    this.onDragStarted,
    this.onDragEnd,
    this.canBuild = true,
    this.cardSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          SizedBox(
              width: cardSize,
              child: _FaceUpCard(
                  card: cards[i],
                  canBuild: canBuild,
                  cardSize: cardSize,
                  onDragStarted: onDragStarted,
                  onDragEnd: onDragEnd)),
        ],
      ],
    );
  }
}

class _FaceUpCard extends StatelessWidget {
  final GameCard card;
  final bool canBuild;
  final double cardSize;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  const _FaceUpCard({
    required this.card,
    required this.canBuild,
    required this.cardSize,
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
            width: cardSize, child: Transform.scale(scale: 1.3, child: face)),
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
