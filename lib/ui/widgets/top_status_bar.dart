import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';

/// Toppfältet (~10% av skärmen): motståndarens status och global
/// spelinfo (tärningskast, turindikator). Rent visuellt just nu – ingen
/// koppling till levande spelstate än.
class TopStatusBar extends StatelessWidget {
  final Player opponent;
  final int lastProductionRoll;
  final bool isYourTurn;

  const TopStatusBar({
    super.key,
    required this.opponent,
    this.lastProductionRoll = 6,
    this.isYourTurn = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CatanColors.woodFrameDark,
        border: Border(bottom: BorderSide(color: Colors.black26, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: CatanColors.woodFrame, child: Icon(Icons.person, color: Colors.white70)),
              const SizedBox(width: 10),
              Text(opponent.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              _StatChip(icon: Icons.emoji_events, label: '${opponent.principality.totalVictoryPoints} VP'),
              const SizedBox(width: 8),
              _StatChip(icon: Icons.style, label: '${opponent.hand.length} kort'),
              const Spacer(),
              _DiceBadge(value: lastProductionRoll),
              const SizedBox(width: 12),
              _TurnIndicator(isYourTurn: isYourTurn),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
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
      width: 30,
      height: 30,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isYourTurn ? const Color(0xFF4F6F45) : Colors.black26,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isYourTurn ? 'Din tur' : 'Motståndarens tur',
        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
