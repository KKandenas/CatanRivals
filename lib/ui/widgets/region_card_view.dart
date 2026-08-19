import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'resource_pip_row.dart';

/// Förenklad vy av ett landskapskort: resursikon, tärningstal och
/// resurspärlor. Ingen regeltext – det tillhör detaljvyn (senare steg).
class RegionCardView extends StatelessWidget {
  final GameCard card;
  final int stored;

  const RegionCardView({super.key, required this.card, this.stored = 0});

  @override
  Widget build(BuildContext context) {
    final color = CatanColors.resourceColor(card.resource);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.55)],
        ),
        border: Border.all(color: CatanColors.woodFrame, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (card.productionNumber != null)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: CatanColors.parchment),
              alignment: Alignment.center,
              child: Text(
                '${card.productionNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: CatanColors.ink,
                ),
              ),
            ),
          Icon(CatanColors.iconFor(card.resource), color: Colors.white, size: 22),
          Text(
            card.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          ResourcePipRow(color: Colors.white, stored: stored),
        ],
      ),
    );
  }
}
