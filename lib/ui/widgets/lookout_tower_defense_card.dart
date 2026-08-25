import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Vakttorn (regelhäftet: "får man slå med tärningen. Slår du 1 eller
/// 2 har kortet ingen effekt") – visas när motståndaren spelat
/// Bågskytt, Pyroman eller Förrädare och DU har Vakttorn utplacerat
/// (se [GameNotifier.rollLookoutTowerDefense]/
/// [TurnState.pendingDefenseRollCard]-doc). Regelhäftets "får" (inte
/// "måste") gör slaget frivilligt i grunden, men eftersom det aldrig
/// finns någon nackdel med att slå (bästa möjliga utfall du kan få) har
/// den här rutan bara en enda knapp i stället för ett fullt tackla/
/// avstå-val, till skillnad från t.ex. [ScoutPromptCard].
class LookoutTowerDefenseCard extends StatelessWidget {
  final String attackCardName;
  final VoidCallback onRoll;

  const LookoutTowerDefenseCard({
    super.key,
    required this.attackCardName,
    required this.onRoll,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Vakttorn',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Motståndaren spelade $attackCardName. Du har Vakttorn – '
                  'slå tärningen för att eventuellt avvärja det. Slår du '
                  '1 eller 2 har kortet ingen effekt.',
                  style: const TextStyle(fontSize: 12.5, color: CatanColors.ink),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F6F45)),
                  onPressed: onRoll,
                  child: const Text('Slå tärningen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
