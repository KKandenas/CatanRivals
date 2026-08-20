import 'package:flutter/material.dart';

import '../../data/basic_set_cards.dart';
import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';

/// Förenklad, kvadratisk vy av en by eller stad – fotobakgrund plus
/// segerpoäng. Ett tryck förstorar kortet via [showCardDetail].
class SettlementCardView extends StatelessWidget {
  final GameCard card;

  const SettlementCardView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isCity = card.category == CardCategory.city;
    return GestureDetector(
      onTap: () => showCardDetail(context, card),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: CatanColors.woodFrame, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(isCity ? CatanAssets.city : CatanAssets.settlement,
                    fit: BoxFit.cover),
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
      ),
    );
  }
}

/// Förenklad, kvadratisk vy av en väg. Ett tryck förstorar kortet via
/// [showCardDetail] – vägar är alla identiska (regelhäftet s. 4), så
/// det finns bara en korttyp att visa ([BasicSetCards.road]).
class RoadCardView extends StatelessWidget {
  const RoadCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showCardDetail(context, BasicSetCards.road),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: CatanColors.woodFrame, width: 1.5)),
            child: Image.asset(CatanAssets.road, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

/// Tom byggplats – dashad kvadratisk platshållare där ett
/// bygg-/enhetskort kan placeras.
///
/// `highlighted` tänds i en mjuk grön glöd när ett kort dras (så att
/// spelaren ser alla giltiga rutor samtidigt); `hovering` skiftar till
/// starkare fyllning när pekaren/fingret faktiskt svävar över just den
/// här rutan.
class BuildingSiteView extends StatelessWidget {
  final bool highlighted;
  final bool hovering;

  const BuildingSiteView(
      {super.key, this.highlighted = false, this.hovering = false});

  @override
  Widget build(BuildContext context) {
    final color =
        highlighted ? const Color(0xFF7CBF6A) : CatanColors.buildingSiteBorder;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: hovering
              ? color.withValues(alpha: 0.35)
              : (highlighted ? color.withValues(alpha: 0.12) : null),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: hovering ? 1 : 0)
                ]
              : null,
        ),
        child: CustomPaint(painter: _DashedBorderPainter(color: color)),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(6)));
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
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
