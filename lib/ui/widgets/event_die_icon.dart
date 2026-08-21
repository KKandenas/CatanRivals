import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Symbolen för en av händelsetärningens sex sidor (se [EventDieFace]),
/// med bilderna från regelhäftets referenskort. `face: null` visar en
/// tärningsplatta som väntar på sitt första kast den här matchen –
/// samma "väntar"-utseende (tärningsikon på pergament) som
/// [DiceRollButton] innan produktionstärningen slagits första gången,
/// så båda tärningarna alltid syns tillsammans, i samma storlek.
class EventDieIcon extends StatelessWidget {
  final EventDieFace? face;
  final double size;

  const EventDieIcon({super.key, required this.face, this.size = 56});

  static const Map<EventDieFace, String> _images = {
    EventDieFace.brigandAttack: CatanAssets.eventDieBrigandAttack,
    EventDieFace.trade: CatanAssets.eventDieTrade,
    EventDieFace.celebration: CatanAssets.eventDieCelebration,
    EventDieFace.plentifulHarvest: CatanAssets.eventDiePlentifulHarvest,
    EventDieFace.eventCard: CatanAssets.eventDieEventCard,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CatanColors.parchment,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 3),
        ],
      ),
      alignment: Alignment.center,
      child: face == null
          ? Icon(Icons.casino, size: size * 0.57, color: CatanColors.inkSoft)
          : ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                _images[face]!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.help, size: size * 0.57, color: CatanColors.ink),
              ),
            ),
    );
  }
}
