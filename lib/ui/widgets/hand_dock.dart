import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';

/// Bottenfältet (~10%): halvtransparent docka med handkort samt en
/// sammanfattande resursmätare. Rent visuellt – kort går inte att dra
/// upp på brädet ännu.
class HandDock extends StatelessWidget {
  final Player player;

  const HandDock({super.key, required this.player});

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
                    ? const Center(child: Text('Inga handkort', style: TextStyle(color: Colors.white54, fontSize: 12)))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: player.hand.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => _HandCard(card: player.hand[i]),
                      ),
              ),
              const SizedBox(width: 12),
              _ResourceMeter(resources: player.resources),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandCard extends StatelessWidget {
  final GameCard card;

  const _HandCard({required this.card});

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: CatanColors.parchment,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CatanColors.woodFrame, width: 1),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        card.name,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 9.5, color: CatanColors.ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ResourceMeter extends StatelessWidget {
  final Map<ResourceType, int> resources;

  const _ResourceMeter({required this.resources});

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
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in types) ...[
            Icon(CatanColors.iconFor(type), size: 15, color: CatanColors.resourceColor(type)),
            const SizedBox(width: 3),
            Text(
              '${resources[type] ?? 0}',
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}
