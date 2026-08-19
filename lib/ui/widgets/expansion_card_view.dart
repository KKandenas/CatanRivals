import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Kvadratisk vy för ett bygg-/enhetskort (byggnad, hjälte,
/// handelsskepp) – fotobakgrund om kortet har en, annars en enkel
/// träfärgad platshållare med namnet. Visar byggkostnaden som små
/// resursikoner i hörnet.
///
/// Delas mellan handkortsdockan och byggplatserna på spelbrädet så att
/// kort ser likadana ut oavsett var de visas.
class ExpansionCardView extends StatelessWidget {
  final GameCard card;
  final bool showCost;

  const ExpansionCardView({super.key, required this.card, this.showCost = true});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: CatanColors.woodFrame, width: 1.2)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                card.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(color: CatanColors.woodFrame),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.55, 1],
                  ),
                ),
              ),
              Positioned(
                left: 3,
                right: 3,
                bottom: 2,
                child: Text(
                  card.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ),
              if (showCost && card.buildingCost.isNotEmpty)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Row(
                    children: [
                      for (final entry in card.buildingCost.entries) _CostPip(type: entry.key, amount: entry.value),
                    ],
                  ),
                ),
              if (card.isUnique)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: _UniqueBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostPip extends StatelessWidget {
  final ResourceType type;
  final int amount;

  const _CostPip({required this.type, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(
              CatanAssets.resourceCostIcon(type),
              width: 12,
              height: 12,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(width: 12, height: 12, color: CatanColors.resourceColor(type)),
            ),
          ),
          if (amount > 1)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                child: Text('$amount', style: const TextStyle(fontSize: 7, color: Colors.white, height: 1.2)),
              ),
            ),
        ],
      ),
    );
  }
}

class _UniqueBadge extends StatelessWidget {
  const _UniqueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(color: CatanColors.parchment, borderRadius: BorderRadius.circular(3)),
      child: const Text('1x', style: TextStyle(fontSize: 7, color: CatanColors.ink, fontWeight: FontWeight.bold)),
    );
  }
}
