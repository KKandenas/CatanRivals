import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
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
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: CatanColors.parchment),
                      alignment: Alignment.center,
                      child: Text(
                        '${card.productionNumber}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: CatanColors.ink),
                      ),
                    ),
                  ),
                Positioned(
                  left: 2,
                  right: 2,
                  bottom: 3,
                  child: ResourcePipRow(color: Colors.white, stored: stored),
                ),
                if (onAdjust != null) ...[
                  Positioned(
                    right: 2,
                    top: 4,
                    child: _AdjustButton(
                      icon: Icons.add,
                      enabled: stored < 3,
                      onTap: () => onAdjust!(1),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 24,
                    child: _AdjustButton(
                      icon: Icons.remove,
                      enabled: stored > 0,
                      onTap: () => onAdjust!(-1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liten, tryckbar +/- knapp ovanpå regionkortet. Egen [GestureDetector]
/// med `HitTestBehavior.opaque` så att trycket inte också når kortets
/// egen [showCardDetail]-tryckyta bakom den.
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
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: enabled ? 0.72 : 0.3),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 11, color: Colors.white.withValues(alpha: enabled ? 1 : 0.5)),
      ),
    );
  }
}
