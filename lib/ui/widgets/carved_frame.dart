import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Utsmyckad "träram" runt en panel – tjock mörk träkant, en tunn
/// guldinlagd linje innanför, och (valfritt) fyra små runda
/// "nitar"/knappar i hörnen. Ren dekoration, ritad med vanliga
/// Flutter-decorations (ingen ny bildtillgång behövs) – ett första
/// steg mot att ge brädet mer av brädspels-känslan från referensbilden
/// (se game_board_screen.dart) utan att röra själva innehållet eller
/// layouten inuti.
///
/// Används runt de stora panelerna (spelarnas riken) där den ger som
/// mest effekt – för små, redan kompakta rutor (som [TotalScoreBoard])
/// är den för grov, de behåller sin egen tunnare kant.
class CarvedFrame extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool showRivets;

  const CarvedFrame({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.showRivets = true,
  });

  static const _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    final innerRadius = borderRadius > 3 ? borderRadius - 3 : 0.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: CatanColors.woodFrameDark,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(innerRadius),
          border: Border.all(color: _gold, width: 1.4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Stack(
            children: [
              child,
              if (showRivets) ..._rivets(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _rivets() => const [
        Positioned(top: 5, left: 5, child: _Rivet()),
        Positioned(top: 5, right: 5, child: _Rivet()),
        Positioned(bottom: 5, left: 5, child: _Rivet()),
        Positioned(bottom: 5, right: 5, child: _Rivet()),
      ];
}

class _Rivet extends StatelessWidget {
  const _Rivet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFEBD08A), Color(0xFF8A6A2A)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}
