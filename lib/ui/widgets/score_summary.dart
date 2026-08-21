import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';

/// Kompakt sammanfattning av en spelares aktuella ställning: totala
/// segerpoäng (VP, inklusive Hero Token/Trade Token om spelaren har
/// dem – se [GameState.totalVictoryPointsFor]) samt styrka/handel/
/// färdighet/framsteg, räknat från alla utplacerade kort i
/// [Player.principality] (se [RealmBoard.totalVictoryPoints] med
/// syskon-getters).
class ScoreSummary extends StatelessWidget {
  final Player player;
  final int totalVictoryPoints;
  final bool hasHeroToken;
  final bool hasTradeToken;

  const ScoreSummary({
    super.key,
    required this.player,
    required this.totalVictoryPoints,
    this.hasHeroToken = false,
    this.hasTradeToken = false,
  });

  @override
  Widget build(BuildContext context) {
    final board = player.principality;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScorePip(
              asset: CatanAssets.pointVictory, amount: totalVictoryPoints),
          const SizedBox(width: 8),
          if (board.totalStrengthPoints > 0)
            _ScorePip(
                asset: CatanAssets.pointStrength,
                amount: board.totalStrengthPoints),
          if (board.totalCommercePoints > 0)
            _ScorePip(
                asset: CatanAssets.pointCommerce,
                amount: board.totalCommercePoints),
          if (board.totalSkillPoints > 0)
            _ScorePip(
                asset: CatanAssets.pointSkill, amount: board.totalSkillPoints),
          if (board.totalProgressPoints > 0)
            _ScorePip(
                asset: CatanAssets.pointProgress,
                amount: board.totalProgressPoints),
          if (hasHeroToken) ...[
            const SizedBox(width: 6),
            const _TokenIcon(asset: CatanAssets.heroToken),
          ],
          if (hasTradeToken) ...[
            const SizedBox(width: 4),
            const _TokenIcon(asset: CatanAssets.tradeToken),
          ],
        ],
      ),
    );
  }
}

/// Brickan i miniatyr – bara själva ikonen (ingen siffra, till
/// skillnad från [_ScorePip]) eftersom den alltid är värd exakt 1 VP,
/// som redan räknas in i [ScoreSummary.totalVictoryPoints].
class _TokenIcon extends StatelessWidget {
  final String asset;

  const _TokenIcon({required this.asset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Image.asset(asset, width: 16, height: 16, fit: BoxFit.cover),
    );
  }
}

class _ScorePip extends StatelessWidget {
  final String asset;
  final int amount;

  const _ScorePip({required this.asset, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(asset, width: 14, height: 14, fit: BoxFit.cover),
          ),
          const SizedBox(width: 3),
          Text('$amount',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
