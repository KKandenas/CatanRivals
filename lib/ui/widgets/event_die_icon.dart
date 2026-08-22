import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Symbolen för en av händelsetärningens sex sidor (se [EventDieFace]),
/// med bilderna från regelhäftets referenskort. `face: null` (innan
/// första kastet den här matchen) visar "?"-sidan i stället för en
/// generisk platshållarikon – tärningen HAR faktiskt två sådana sidor
/// (se [EventDieFace.eventCard]/`_sixSides`), så det är en riktig sida
/// den kan visa, inte en gissning på vad kastet blir.
class EventDieIcon extends StatelessWidget {
  final EventDieFace? face;
  final double size;

  /// Om satt (och [rollable]) går tärningen att trycka på för att slå,
  /// precis som [DiceRollButton] – de två tärningarna slås alltid
  /// tillsammans (se [GameNotifier.rollProductionDie]).
  final bool rollable;
  final VoidCallback? onTap;

  const EventDieIcon({
    super.key,
    required this.face,
    this.size = 56,
    this.rollable = false,
    this.onTap,
  });

  static const Map<EventDieFace, String> _images = {
    EventDieFace.brigandAttack: CatanAssets.eventDieBrigandAttack,
    EventDieFace.trade: CatanAssets.eventDieTrade,
    EventDieFace.celebration: CatanAssets.eventDieCelebration,
    EventDieFace.plentifulHarvest: CatanAssets.eventDiePlentifulHarvest,
    EventDieFace.eventCard: CatanAssets.eventDieEventCard,
  };

  @override
  Widget build(BuildContext context) {
    final image = face == null ? CatanAssets.eventDieEventCard : _images[face]!;
    final die = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: rollable ? const Color(0xFF7CBF6A) : CatanColors.parchment,
        borderRadius: BorderRadius.circular(10),
        border: rollable ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          BoxShadow(
              color: rollable
                  ? const Color(0xFF7CBF6A).withValues(alpha: 0.6)
                  : Colors.black45,
              blurRadius: rollable ? 10 : 3,
              spreadRadius: rollable ? 1 : 0),
        ],
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(
          image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.help, size: size * 0.57, color: CatanColors.ink),
        ),
      ),
    );

    if (!rollable || onTap == null) return die;
    return GestureDetector(onTap: onTap, child: die);
  }
}
