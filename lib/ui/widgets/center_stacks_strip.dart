import 'package:flutter/material.dart';

import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Mittremsan mellan de två rikena: dragstaplarna (vägar/byar/städer/
/// regioner), händelsekortsstapeln, tärningsslaget och turindikatorn –
/// precis som i det fysiska spelets uppställning, där dessa ligger
/// mellan de två furstendömena (se regelhäftet s. 5).
///
/// Rent visuellt – staplarna går inte att dra kort ifrån ännu.
/// `stackCounts` är mock-data tills en riktig dragstapel-modell finns.
class CenterStacksStrip extends StatelessWidget {
  final Map<String, int> stackCounts;
  final int lastProductionRoll;
  final bool isYourTurn;

  const CenterStacksStrip({
    super.key,
    required this.stackCounts,
    this.lastProductionRoll = 6,
    this.isYourTurn = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StackPile(asset: CatanAssets.backRoads, count: stackCounts['roads'] ?? 0),
                _StackPile(asset: CatanAssets.backSettlements, count: stackCounts['settlements'] ?? 0),
                _StackPile(asset: CatanAssets.backCities, count: stackCounts['cities'] ?? 0),
                _StackPile(asset: CatanAssets.backRegions, count: stackCounts['regions'] ?? 0),
                _StackPile(asset: CatanAssets.backEvent, count: stackCounts['event'] ?? 0),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _DiceBadge(value: lastProductionRoll),
          const SizedBox(width: 8),
          _TurnIndicator(isYourTurn: isYourTurn),
        ],
      ),
    );
  }
}

class _StackPile extends StatelessWidget {
  final String asset;
  final int count;

  const _StackPile({required this.asset, required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: CatanColors.woodFrame, width: 1)),
                child: Image.asset(asset, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text('$count', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DiceBadge extends StatelessWidget {
  final int value;

  const _DiceBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: CatanColors.parchment,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))],
      ),
      alignment: Alignment.center,
      child: Text('$value', style: const TextStyle(color: CatanColors.ink, fontWeight: FontWeight.bold)),
    );
  }
}

class _TurnIndicator extends StatelessWidget {
  final bool isYourTurn;

  const _TurnIndicator({required this.isYourTurn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isYourTurn ? const Color(0xFF4F6F45) : Colors.black26,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isYourTurn ? 'Din tur' : 'Motst.',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
