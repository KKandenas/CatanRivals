import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';

/// Kompakt sammanfattning av en spelares aktuella ställning: totala
/// segerpoäng (VP) samt styrka/handel/färdighet/framsteg – räknat från
/// alla utplacerade kort i [Player.principality] (se
/// [RealmBoard.totalVictoryPoints] med syskon-getters).
class ScoreSummary extends StatelessWidget {
  final Player player;

  const ScoreSummary({super.key, required this.player});

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
          _VictoryPointChip(amount: board.totalVictoryPoints),
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
        ],
      ),
    );
  }
}

/// VP saknar än så länge en egen symbol (kommer senare), så den visas
/// med en pokal-ikon i stället för en av kortikonerna.
class _VictoryPointChip extends StatelessWidget {
  final int amount;

  const _VictoryPointChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.emoji_events, size: 14, color: Colors.white70),
        const SizedBox(width: 3),
        Text('$amount',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ],
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
