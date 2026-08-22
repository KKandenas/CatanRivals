import 'package:flutter/material.dart';

import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'carved_frame.dart';

/// Visas när någon vunnit (regelhäftet: 7 eller fler segerpoäng vid
/// slutet av sin egen runda, se [GameState.winnerId]/
/// [GameNotifier._advanceToNextPlayer]) – täcker HELA skärmen (samma
/// `Positioned.fill`-mönster som ScoutPromptCard/FeudResolutionCard
/// m.fl., men medvetet odismissbar genom att bara trycka utanför:
/// spelet är faktiskt slut, inte en fråga att svara på och gå vidare
/// från) med vinnarens namn, slutställningen för båda spelarna, och
/// två sätt att gå vidare.
class GameOverOverlay extends StatelessWidget {
  final bool youWon;
  final String youName;
  final int youPoints;
  final bool youHaveHeroToken;
  final bool youHaveTradeToken;
  final String opponentName;
  final int opponentPoints;
  final bool opponentHasHeroToken;
  final bool opponentHasTradeToken;

  /// Bara i lokalt läge – i onlineläge finns ingen "revansch"-synk än,
  /// så bara "Till huvudmenyn" visas (se `onToMainMenu`).
  final VoidCallback? onNewLocalMatch;
  final VoidCallback onToMainMenu;

  const GameOverOverlay({
    super.key,
    required this.youWon,
    required this.youName,
    required this.youPoints,
    this.youHaveHeroToken = false,
    this.youHaveTradeToken = false,
    required this.opponentName,
    required this.opponentPoints,
    this.opponentHasHeroToken = false,
    this.opponentHasTradeToken = false,
    this.onNewLocalMatch,
    required this.onToMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: CarvedFrame(
            child: ColoredBox(
              color: CatanColors.parchment,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 6),
                    Text(
                      youWon ? 'Du vinner!' : '$opponentName vinner!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8A6A2A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '7 eller fler segerpoäng vid slutet av en runda avgör.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 11.5, color: CatanColors.inkSoft),
                    ),
                    const SizedBox(height: 16),
                    _ScoreRow(
                      name: youName,
                      points: youPoints,
                      hasHeroToken: youHaveHeroToken,
                      hasTradeToken: youHaveTradeToken,
                      isWinner: youWon,
                    ),
                    const SizedBox(height: 8),
                    _ScoreRow(
                      name: opponentName,
                      points: opponentPoints,
                      hasHeroToken: opponentHasHeroToken,
                      hasTradeToken: opponentHasTradeToken,
                      isWinner: !youWon,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        if (onNewLocalMatch != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: CatanColors.ink,
                                  side: const BorderSide(
                                      color: CatanColors.woodFrame)),
                              onPressed: onNewLocalMatch,
                              child: const Text('Ny match'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: CatanColors.woodFrameDark),
                            onPressed: onToMainMenu,
                            child: const Text('Till huvudmenyn'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String name;
  final int points;
  final bool hasHeroToken;
  final bool hasTradeToken;
  final bool isWinner;

  const _ScoreRow({
    required this.name,
    required this.points,
    required this.hasHeroToken,
    required this.hasTradeToken,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? const Color(0xFFF4DFA0).withValues(alpha: 0.55)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: isWinner
            ? Border.all(color: const Color(0xFFC9A227), width: 1.4)
            : null,
      ),
      child: Row(
        children: [
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Text('👑', style: TextStyle(fontSize: 16)),
            ),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CatanColors.ink),
            ),
          ),
          if (hasHeroToken) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Image.asset(CatanAssets.heroToken,
                  width: 18, height: 18, fit: BoxFit.cover),
            ),
            const SizedBox(width: 4),
          ],
          if (hasTradeToken) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Image.asset(CatanAssets.tradeToken,
                  width: 18, height: 18, fit: BoxFit.cover),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Color(0xFFF4DFA0), Color(0xFFC9932A)],
              ),
              border: Border.all(color: const Color(0xFF8A6A2A), width: 1),
            ),
            child: Text(
              '$points',
              style: const TextStyle(
                  color: CatanColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
