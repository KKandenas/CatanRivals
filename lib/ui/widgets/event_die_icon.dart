import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';

/// Symbolen för en av händelsetärningens sex sidor (se [EventDieFace]).
/// Ingen egen tärningsbild finns i tillgångarna, så symbolerna ritas som
/// en färgad platta med en Material-ikon i stället – samma kvadratiska,
/// rundade form som produktionstärningens [DiceFace]-platta.
class EventDieIcon extends StatelessWidget {
  final EventDieFace face;
  final double size;

  const EventDieIcon({super.key, required this.face, this.size = 40});

  static const Map<EventDieFace, IconData> _icons = {
    EventDieFace.brigandAttack: Icons.gavel,
    EventDieFace.trade: Icons.balance,
    EventDieFace.celebration: Icons.celebration,
    EventDieFace.plentifulHarvest: Icons.eco,
    EventDieFace.eventCard: Icons.help,
  };

  static const Map<EventDieFace, Color> _backgrounds = {
    EventDieFace.brigandAttack: Color(0xFFB33A3A),
    EventDieFace.trade: CatanColors.parchment,
    EventDieFace.celebration: Color(0xFF4F6F45),
    EventDieFace.plentifulHarvest: Color(0xFFD3A038),
    EventDieFace.eventCard: Color(0xFF9B9B9B),
  };

  @override
  Widget build(BuildContext context) {
    final background = _backgrounds[face]!;
    final onDark = background == const Color(0xFFB33A3A) ||
        background == const Color(0xFF4F6F45);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: CatanColors.woodFrame, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Icon(
        _icons[face],
        size: size * 0.6,
        color: onDark ? Colors.white : CatanColors.ink,
      ),
    );
  }
}
