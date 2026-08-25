import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Visas ovanför ditt eget rike medan Upplopps enhetsväljare är aktiv
/// (se [GameNotifier.startRiotsUnitPick]/[selectRiotsUnit]) – samma
/// mönster som [FeudBuildingInstructionBar], fast för Upplopps bredare
/// urvalskriterium (alla enheter, inte bara byggnader).
class RiotsUnitInstructionBar extends StatelessWidget {
  final VoidCallback onCancel;

  const RiotsUnitInstructionBar({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Upplopp: tryck på en av dina egna enheter (byggnad, skepp '
              'eller hjälte) med styrke- eller handelspoäng för att ta '
              'bort den.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54)),
            onPressed: onCancel,
            child: const Text('Avbryt'),
          ),
        ],
      ),
    );
  }
}
