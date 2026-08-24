import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Visas ovanför ditt eget rike direkt efter starthandsutdelningen med
/// ett tema aktivt (bekräftad regel: "Fri omflyttning av egna 6
/// regioner", se [GameNotifier.selectRegionRearrangementTarget]) –
/// till skillnad från [RelocationInstructionBar] finns inget
/// avbryt-läge: fri, obegränsad omflyttning behöver ett uttryckligt
/// slutsteg i stället (se [GameNotifier.finishRegionRearrangement]).
class StartingRegionRearrangementBar extends StatelessWidget {
  final bool hasFirstSelection;
  final VoidCallback onFinish;

  const StartingRegionRearrangementBar({
    super.key,
    required this.hasFirstSelection,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasFirstSelection
                  ? 'Tryck på ännu en egen region för att byta plats med den första.'
                  : 'Fri omflyttning: byt plats på så många av dina 6 regioner du vill, tryck sedan Klar.',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F6F45)),
            onPressed: onFinish,
            child: const Text('Klar'),
          ),
        ],
      ),
    );
  }
}
