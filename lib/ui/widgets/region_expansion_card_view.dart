import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'resource_pip_row.dart';

/// Kvadratisk vy för ett landskapsutbyggnadskort (brun textruta, t.ex.
/// Guldgömma) – sitter intill en region (se
/// [RealmBoard.regionExpansionAt]/[GameNotifier.dropRegionExpansion]).
/// Ett tryck förstorar kortet via [showCardDetail].
///
/// Om [onAdjust] ges (bara på ditt eget, interaktiva rike) visas
/// samma +/- mönster som [RegionCardView] för kortets EGNA lagrade
/// resurser (t.ex. guld i Guldgömman, se
/// [GameNotifier.adjustRegionExpansionResource]).
class RegionExpansionCardView extends StatelessWidget {
  final GameCard card;
  final int stored;
  final void Function(int delta)? onAdjust;

  const RegionExpansionCardView({
    super.key,
    required this.card,
    this.stored = 0,
    this.onAdjust,
  });

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
              border: Border.all(color: CatanColors.woodFrame, width: 1.2),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  card.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: CatanColors.woodFrame),
                ),
                if (onAdjust != null)
                  Positioned(
                    left: 1,
                    right: 1,
                    top: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AdjustButton(
                            icon: Icons.remove,
                            enabled: stored > 0,
                            onTap: () => onAdjust!(-1)),
                        _AdjustButton(
                            icon: Icons.add,
                            enabled: stored < 3,
                            onTap: () => onAdjust!(1)),
                      ],
                    ),
                  ),
                Positioned(
                  left: 1,
                  right: 1,
                  bottom: 2,
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

/// Tryckbar +/- knapp, samma mönster som RegionCardViews egen
/// `_AdjustButton` – egen kopia här eftersom den ursprungliga är
/// privat för sin fil.
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
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: enabled ? 0.72 : 0.3),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 10, color: Colors.white.withValues(alpha: enabled ? 1 : 0.5)),
      ),
    );
  }
}
