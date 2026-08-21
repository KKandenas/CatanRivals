import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'region_card_view.dart';

/// Visas ovanför ditt eget rike när en nybyggd by (bortom rikets
/// yttergräns) just gett dig 2 nya, ännu oplacerade regionkort
/// (regelhäftet s. 8) – dra vardera kortet till den tomma platsen
/// ovanför eller nedanför den nya byn för att välja var det ska ligga.
class PendingRegionsBar extends StatelessWidget {
  final List<GameCard> cards;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  const PendingRegionsBar(
      {super.key, required this.cards, this.onDragStarted, this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Nya regioner – dra till fältet ovanför eller nedanför den nya byn',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          for (final card in cards) ...[
            _PendingRegionCard(
                card: card, onDragStarted: onDragStarted, onDragEnd: onDragEnd),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PendingRegionCard extends StatelessWidget {
  final GameCard card;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  const _PendingRegionCard(
      {required this.card, this.onDragStarted, this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    final face = RegionCardView(card: card);
    return SizedBox(
      width: 48,
      child: LongPressDraggable<GameCard>(
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
        // Samma tillförlitlighetsfix som handkorts- och mitthögs-korten
        // (se hand_dock.dart/center_stacks_strip.dart): ett riktigt
        // fingertryck varar ofta längre än 180ms, så utan den här
        // tolkas ett släppt-men-inte-landat drag som ett tryck och
        // visar kortet förstorat.
        onDraggableCanceled: (_, __) {
          onDragEnd?.call();
          showCardDetail(context, card);
        },
        child: face,
      ),
    );
  }
}
