import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Visas ovanför ditt eget rike medan Omlokalisering är aktiv (se
/// [GameNotifier.startRelocation]/[GameNotifier.selectRelocationTarget])
/// – förklarar vad som ska göras och ger en väg att avbryta utan att
/// förlora kortet (se [GameNotifier.cancelRelocation]).
class RelocationInstructionBar extends StatelessWidget {
  final bool hasFirstSelection;
  final VoidCallback onCancel;

  const RelocationInstructionBar({
    super.key,
    required this.hasFirstSelection,
    required this.onCancel,
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
                  ? 'Omlokalisering: tryck på ännu en egen region eller eget byggkort (samma sort) för att byta plats med den första.'
                  : 'Omlokalisering: tryck på 2 av dina egna regioner, eller 2 av dina egna byggkort, för att byta plats på dem.',
              style: const TextStyle(
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
