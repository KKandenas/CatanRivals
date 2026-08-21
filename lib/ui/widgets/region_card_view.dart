import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'dice_face.dart';
import 'resource_pip_row.dart';

/// Förenklad, kvadratisk vy av ett landskapskort: fotobakgrund,
/// tärningstal och resurspärlor. Ett tryck förstorar kortet via
/// [showCardDetail].
///
/// Om [onAdjust] ges (bara på ditt eget, interaktiva rike) visas små
/// +/- knappar för att manuellt öka/minska lagrade resurser – tills
/// vidare hur man bokför produktionstärningens utdelning (se
/// regelhäftet s. 7), i stället för att det sker automatiskt.
class RegionCardView extends StatelessWidget {
  final GameCard card;
  final int stored;
  final void Function(int delta)? onAdjust;

  const RegionCardView({super.key, required this.card, this.stored = 0, this.onAdjust});

  @override
  Widget build(BuildContext context) {
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
                Image.asset(CatanAssets.resourcePhoto(card.resource),
                    fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black45,
                        Colors.transparent,
                        Colors.black54
                      ],
                      stops: [0, 0.5, 1],
                    ),
                  ),
                ),
                if (card.productionNumber != null)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onAdjust != null) ...[
                          _AdjustButton(
                            icon: Icons.remove,
                            enabled: stored > 0,
                            onTap: () => onAdjust!(-1),
                          ),
                          const SizedBox(width: 4),
                        ],
                        _ProductionDie(number: card.productionNumber!),
                        if (onAdjust != null) ...[
                          const SizedBox(width: 4),
                          _AdjustButton(
                            icon: Icons.add,
                            enabled: stored < 3,
                            onTap: () => onAdjust!(1),
                          ),
                        ],
                      ],
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
      ),
    );
  }
}

/// Tärningstalet som ger utdelning på den här regionen – kvadratisk
/// som en tärning, mitt på kortet (i stället för en cirkel i hörnet),
/// med +/- knapparna på varsin sida (se [_AdjustButton]).
class _ProductionDie extends StatelessWidget {
  final int number;

  const _ProductionDie({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: CatanColors.parchment,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CatanColors.woodFrame, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))
        ],
      ),
      alignment: Alignment.center,
      child: DiceFace(value: number, size: 16, dotColor: CatanColors.ink),
    );
  }
}

/// Tryckbar +/- knapp intill tärningstalet. Egen [GestureDetector] med
/// `HitTestBehavior.opaque` så att trycket inte också når kortets egen
/// [showCardDetail]-tryckyta bakom den.
class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _AdjustButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: enabled ? 0.72 : 0.3),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: Colors.white.withValues(alpha: enabled ? 1 : 0.5)),
      ),
    );
  }
}
