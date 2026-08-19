import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';

/// Förenklad vy av en by eller stad.
class SettlementCardView extends StatelessWidget {
  final GameCard card;

  const SettlementCardView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isCity = card.category == CardCategory.city;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isCity ? const Color(0xFF8B5E3C) : const Color(0xFFB98955),
        border: Border.all(color: CatanColors.woodFrame, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isCity ? Icons.location_city : Icons.home, color: Colors.white, size: 22),
          Text(
            card.name,
            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
          ),
          if (card.victoryPoints > 0)
            Text(
              '${card.victoryPoints} VP',
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

/// Förenklad vy av en väg – en smal bjälke mellan två byar/städer.
class RoadCardView extends StatelessWidget {
  const RoadCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CatanColors.woodFrame,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF9B7B54),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// Tom byggplats – dashad platshållare där ett bygg-/enhetskort kan
/// placeras.
class BuildingSiteView extends StatelessWidget {
  const BuildingSiteView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: CustomPaint(painter: _DashedBorderPainter()));
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
