import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Beskriver vad spelaren håller på att göra, för rubriken i kortet.
String _actionPhrase(GameCard card) {
  switch (card.category) {
    case CardCategory.road:
      return 'placera ut en väg';
    case CardCategory.settlement:
      return 'bygga en by';
    case CardCategory.city:
      return 'bygga en stad';
    default:
      return 'spela ${card.name}';
  }
}

/// Bekräftelsekortet som visas ovanpå motståndarens rike när ett kort
/// släpps på en giltig plats – inte en modal dialogruta, utan en vanlig
/// widget som läggs ovanpå motståndarens (inte ditt eget) rike, så att
/// dina egna regioners +/- knappar fortfarande går att trycka på medan
/// den syns, och den stängs aldrig av misstag genom att man trycker
/// utanför.
///
/// Appen håller inte koll på om spelaren har råd (regelhäftet s. 9:
/// spelarna betalar och tar resurser själva) – kortet visar bara
/// kostnaden och påminner om att betala genom att trycka − på
/// respektive resurs, sedan avgör spelaren själv med "Betalt" eller
/// "Avbryt". Kortet byggs bara om "Betalt" trycks; "Avbryt" struntar
/// helt i draget.
class BuildConfirmCard extends StatelessWidget {
  final GameCard card;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BuildConfirmCard({
    super.key,
    required this.card,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      CatanAssets.resolveCardImage(card),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: CatanColors.woodFrame),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Du har valt att ${_actionPhrase(card)}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                if (card.buildingCost.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Betala genom att trycka − på respektive resurs:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: CatanColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final entry in card.buildingCost.entries)
                        _CostBadge(type: entry.key, amount: entry.value),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: CatanColors.ink,
                            side: const BorderSide(color: CatanColors.woodFrame)),
                        onPressed: onCancel,
                        child: const Text('Avbryt'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F6F45)),
                        onPressed: onConfirm,
                        child: const Text('Betalt'),
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

class _CostBadge extends StatelessWidget {
  final ResourceType type;
  final int amount;

  const _CostBadge({required this.type, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: CatanColors.parchmentDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CatanColors.woodFrame),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.asset(
              CatanAssets.resourceCostIcon(type),
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                  width: 18, height: 18, color: CatanColors.resourceColor(type)),
            ),
          ),
          const SizedBox(width: 5),
          Text('×$amount',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, color: CatanColors.ink)),
        ],
      ),
    );
  }
}
