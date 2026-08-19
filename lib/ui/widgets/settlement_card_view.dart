import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Förenklad, kvadratisk vy av en by eller stad – fotobakgrund plus
/// segerpoäng.
class SettlementCardView extends StatelessWidget {
  final GameCard card;

  const SettlementCardView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isCity = card.category == CardCategory.city;
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
              Image.asset(isCity ? CatanAssets.city : CatanAssets.settlement, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              if (card.victoryPoints > 0)
                Positioned(
                  right: 3,
                  bottom: 2,
                  child: Text(
                    '${card.victoryPoints} VP',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Förenklad, kvadratisk vy av en väg.
class RoadCardView extends StatelessWidget {
  const RoadCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: CatanColors.woodFrame, width: 1.5)),
          child: Image.asset(CatanAssets.road, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Tom byggplats – dashad kvadratisk platshållare där ett
/// bygg-/enhetskort kan placeras.
class BuildingSiteView extends StatelessWidget {
  const BuildingSiteView({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _DashedBorderPainter()),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CatanColors.buildingSiteBorder
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
