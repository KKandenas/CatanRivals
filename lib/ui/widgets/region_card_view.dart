import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'resource_pip_row.dart';

/// Förenklad, kvadratisk vy av ett landskapskort: fotobakgrund,
/// tärningstal och resurspärlor. Ingen regeltext – det tillhör
/// detaljvyn (senare steg).
class RegionCardView extends StatelessWidget {
  final GameCard card;
  final int stored;

  const RegionCardView({super.key, required this.card, this.stored = 0});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: CatanColors.woodFrame, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(CatanAssets.resourcePhoto(card.resource), fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black45, Colors.transparent, Colors.black54],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
              if (card.productionNumber != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: CatanColors.parchment),
                    alignment: Alignment.center,
                    child: Text(
                      '${card.productionNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: CatanColors.ink),
                    ),
                  ),
                ),
              Positioned(
                left: 2,
                right: 2,
                bottom: 3,
                child: ResourcePipRow(color: Colors.white, stored: stored),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
