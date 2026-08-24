import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'face_up_expansion_pile.dart';
import 'score_summary.dart';

/// Smal remsa längst upp: motståndarens namn, VP och handkortsantal.
/// Motståndarens rike ritas separat under den här remsan (se
/// [GameBoardScreen]) – tärning/turindikator sitter i mittremsan mellan
/// riken, precis som i det fysiska spelets uppställning. Den
/// övergripande totalställningen ([TotalScoreBoard]) svävar i stället
/// ovanpå den här remsan och DIN TUR-pillen tillsammans (se
/// game_board_screen.dart) – den här remsan behöver därför inte göra
/// plats för den, förutom att lämna kvar lite marginal längst till
/// höger (se [_scoreBoardClearance]) så inte [faceUpExpansionCard]
/// hamnar under den.
class TopStatusBar extends StatelessWidget {
  final Player opponent;
  final bool opponentIsRed;
  final int totalVictoryPoints;
  final bool hasHeroToken;
  final bool hasTradeToken;

  /// Ett av de (högst 2) korten i den delade ansikte-upp-högen (se
  /// [GameState.faceUpExpansionCards], t.ex. Gulderans Köpmansgille) –
  /// visas längst till höger i den här remsan (det andra kortet, om
  /// något, visas i stället vid [HandDock]) så det känns tillgängligt
  /// för båda spelarna, i stället för en klump mitt i mittremsan.
  /// Fortfarande samma delade pool – vem som helst bygger det på sin
  /// egen tur oavsett var det visas, se
  /// [GameNotifier.buyFaceUpExpansion].
  final GameCard? faceUpExpansionCard;
  final void Function(GameCard card)? onFaceUpDragStarted;
  final VoidCallback? onFaceUpDragEnd;

  /// Om [faceUpExpansionCard] går att dra ut just nu (se
  /// [GameState.canBuildRightNow]) – annars bara tryckbart för att
  /// förstora, som vanligt.
  final bool canBuild;

  const TopStatusBar({
    super.key,
    required this.opponent,
    this.opponentIsRed = false,
    required this.totalVictoryPoints,
    this.hasHeroToken = false,
    this.hasTradeToken = false,
    this.faceUpExpansionCard,
    this.onFaceUpDragStarted,
    this.onFaceUpDragEnd,
    this.canBuild = true,
  });

  /// Ungefärlig bredd att lämna fritt längst till höger – [TotalScoreBoard]
  /// svävar ovanpå den här remsan där, se klassdoc.
  static const double _scoreBoardClearance = 108;

  @override
  Widget build(BuildContext context) {
    final color =
        opponentIsRed ? const Color(0xFFB33A3A) : const Color(0xFF3A6FB3);
    return DecoratedBox(
      // Lätt genomskinlig (samma mönster som HandDock) så den delade
      // träbakgrunden bakom hela brädet (se game_board_screen.dart)
      // syns igenom en aning i stället för att helt dölja den.
      decoration: BoxDecoration(
        color: CatanColors.woodFrameDark.withValues(alpha: 0.75),
        border:
            const Border(bottom: BorderSide(color: Colors.black26, width: 1)),
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
              const SizedBox(width: 10),
              ScoreSummary(
                player: opponent,
                totalVictoryPoints: totalVictoryPoints,
                hasHeroToken: hasHeroToken,
                hasTradeToken: hasTradeToken,
              ),
              const SizedBox(width: 6),
              _StatChip(
                  icon: Icons.style, label: '${opponent.hand.length} kort'),
              if (faceUpExpansionCard != null) ...[
                const Spacer(),
                Padding(
                  padding:
                      const EdgeInsets.only(right: _scoreBoardClearance),
                  child: FaceUpExpansionPile(
                    cards: [faceUpExpansionCard!],
                    onDragStarted: onFaceUpDragStarted,
                    onDragEnd: onFaceUpDragEnd,
                    canBuild: canBuild,
                  ),
                ),
              ],
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
