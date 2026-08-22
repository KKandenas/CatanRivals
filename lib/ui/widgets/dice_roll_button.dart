import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';
import 'dice_face.dart';
import 'spin_on_change.dart';

/// Produktionstärningen (regelhäftet s. 7). Visar det senaste kastet
/// som prickar (som en riktig tärning), eller ett tärningsikon att
/// trycka på för att slå när det är din tur och tärningen inte redan
/// är slagen den här omgången – då får den också en ljusgrön ram och
/// texten "Tryck för att slå" under sig, så att det inte går att missa
/// att den väntar på ett tryck.
class DiceRollButton extends StatelessWidget {
  final int? value;
  final bool rollable;
  final VoidCallback? onTap;

  const DiceRollButton(
      {super.key, required this.value, required this.rollable, this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = SpinOnChange<int?>(
      value: value,
      child: Container(
        width: 56,
        height: 56,
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
                spreadRadius: rollable ? 1 : 0,
                offset: const Offset(0, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: value == null
            ? Icon(Icons.casino,
                size: 32, color: rollable ? Colors.white : CatanColors.inkSoft)
            : DiceFace(
                value: value!,
                size: 40,
                dotColor: CatanColors.ink,
              ),
      ),
    );

    final withLabel = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        if (rollable) ...[
          const SizedBox(height: 4),
          const Text(
            'Tryck för\natt slå',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );

    if (!rollable) return withLabel;
    return GestureDetector(onTap: onTap, child: withLabel);
  }
}
