import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Visas ovanför ditt eget rike medan Fejds bygg-väljare är aktiv (se
/// [GameNotifier.startFeudBuildingPick]/[selectFeudBuilding]) – samma
/// mönster som [RelocationInstructionBar].
class FeudBuildingInstructionBar extends StatelessWidget {
  final VoidCallback onCancel;

  const FeudBuildingInstructionBar({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Fejd: tryck på en av dina egna byggnader (inte skepp eller '
              'hjältar) för att ta bort den.',
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
