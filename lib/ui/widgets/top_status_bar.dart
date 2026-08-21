import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'score_summary.dart';

/// Smal remsa längst upp: motståndarens namn, VP och handkortsantal.
/// Motståndarens rike ritas separat under den här remsan (se
/// [GameBoardScreen]) – tärning/turindikator sitter i mittremsan mellan
/// riken, precis som i det fysiska spelets uppställning.
class TopStatusBar extends StatelessWidget {
  final Player opponent;
  final bool opponentIsRed;
  final int totalVictoryPoints;
  final bool hasHeroToken;
  final bool hasTradeToken;

  const TopStatusBar({
    super.key,
    required this.opponent,
    this.opponentIsRed = false,
    required this.totalVictoryPoints,
    this.hasHeroToken = false,
    this.hasTradeToken = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        opponentIsRed ? const Color(0xFFB33A3A) : const Color(0xFF3A6FB3);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CatanColors.woodFrameDark,
        border: Border(bottom: BorderSide(color: Colors.black26, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                  radius: 14,
                  backgroundColor: color,
                  child: const Icon(Icons.person,
                      size: 16, color: Colors.white70)),
              const SizedBox(width: 8),
              Text(opponent.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(width: 6),
              Text(opponentIsRed ? '(röd)' : '(blå)',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const Spacer(),
              ScoreSummary(
                player: opponent,
                totalVictoryPoints: totalVictoryPoints,
                hasHeroToken: hasHeroToken,
                hasTradeToken: hasTradeToken,
              ),
              const SizedBox(width: 6),
              _StatChip(
                  icon: Icons.style, label: '${opponent.hand.length} kort'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.black26, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
