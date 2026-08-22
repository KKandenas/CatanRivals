import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Frågan "Vill du använda Spejare?" som väcks automatiskt när en ny
/// by (bortom rikets yttergräns) just gett dig 2 nya regionkort, om du
/// har Spejare på hand (regelhäftet: "Play this card when building a
/// settlement") – se [GameNotifier.dropSettlement]/`useScout`/
/// `declineScout`. Läggs ovanpå motståndarens rike, precis som
/// [BuildConfirmCard] och de andra icke-modala popuprutorna.
class ScoutPromptCard extends StatelessWidget {
  final VoidCallback onUseScout;
  final VoidCallback onDecline;

  const ScoutPromptCard({
    super.key,
    required this.onUseScout,
    required this.onDecline,
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
                  'Vill du använda Spejare?',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Välj 2 valfria kort från hela regionstapeln i stället för '
                  'att dra de 2 översta slumpmässigt. Resten av stapeln '
                  'blandas om efteråt.',
                  style: TextStyle(fontSize: 12.5, color: CatanColors.ink),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: CatanColors.ink,
                            side: const BorderSide(
                                color: CatanColors.woodFrame)),
                        onPressed: onDecline,
                        child: const Text('Nej, dra slumpmässigt'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F6F45)),
                        onPressed: onUseScout,
                        child: const Text('Ja, välj själv'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
