import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';

/// Bottenfältet (~10%): halvtransparent docka med handkort samt en
/// sammanfattande resursmätare.
///
/// Bygg-/enhetskort (kategori [CardCategory.expansion]) går att
/// långtrycka-och-dra upp på det egna riket för att spela dem – se
/// [PrincipalityGrid]. Handlingskort är inte dragbara än (att spela dem
/// är en egen, icke-rumslig interaktion som kommer i ett senare steg).
class HandDock extends StatelessWidget {
  final Player player;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  const HandDock(
      {super.key, required this.player, this.onDragStarted, this.onDragEnd});

  static const double _dockHeight = 92;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _dockHeight,
      color: CatanColors.woodFrameDark.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: player.hand.isEmpty
                    ? const Center(
                        child: Text('Inga handkort',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: player.hand.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => _HandCard(
                          card: player.hand[i],
                          onDragStarted: onDragStarted,
                          onDragEnd: onDragEnd,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              _ResourceMeter(player: player),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandCard extends StatelessWidget {
  final GameCard card;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  const _HandCard({required this.card, this.onDragStarted, this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    final playable = card.category == CardCategory.expansion;
    final face = _CardFace(card: card, playable: playable);

    if (!playable) return face;

    return LongPressDraggable<GameCard>(
      data: card,
      delay: const Duration(milliseconds: 180),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
            scale: 1.12, child: _CardFace(card: card, playable: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: face),
      onDragStarted: () => onDragStarted?.call(card),
      onDragEnd: (_) => onDragEnd?.call(),
      // En riktig fingertryck varar ofta längre än 180ms, så
      // LongPressDraggable hinner vinna gest-arenan (och starta en
      // "drag") innan ett vanligt tryck (ExpansionCardViews egen
      // GestureDetector) någonsin får chansen – annars skulle
      // dragbara handkort inte gå att trycka på alls. Släpps kortet
      // sedan utan att träffa ett giltigt mål (dvs. draget avbryts),
      // tolkar vi det som ett tryck och visar kortet förstorat.
      onDraggableCanceled: (_, __) {
        onDragEnd?.call();
        showCardDetail(context, card);
      },
      child: face,
    );
  }
}

class _CardFace extends StatelessWidget {
  final GameCard card;
  final bool playable;

  const _CardFace({required this.card, required this.playable});

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExpansionCardView(card: card, showCost: playable),
          if (playable)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF7CBF6A), width: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResourceMeter extends StatelessWidget {
  final Player player;

  const _ResourceMeter({required this.player});

  @override
  Widget build(BuildContext context) {
    final types = [
      ResourceType.lumber,
      ResourceType.brick,
      ResourceType.ore,
      ResourceType.grain,
      ResourceType.wool,
      ResourceType.gold,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.black26, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in types) ...[
            Icon(CatanColors.iconFor(type),
                size: 15, color: CatanColors.resourceColor(type)),
            const SizedBox(width: 3),
            Text(
              '${player.resourceCount(type)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}
