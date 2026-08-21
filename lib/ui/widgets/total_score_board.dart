import 'package:flutter/material.dart';

import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Kompakt sammanställning av totalställningen (segerpoäng, inklusive
/// Hero Token/Trade Token) för båda spelarna på samma gång – till
/// skillnad från de mer detaljerade ScoreSummary-rutorna (en per
/// spelare, med alla poängtyper) ger den här bara en snabb blick på
/// vem som leder just nu. Läggs längst ner till höger som en flytande
/// bricka ovanpå resten av brädet (se game_board_screen.dart).
class TotalScoreBoard extends StatelessWidget {
  final String youName;
  final int youPoints;
  final bool youHaveHeroToken;
  final bool youHaveTradeToken;
  final bool amIRed;

  final String opponentName;
  final int opponentPoints;
  final bool opponentHasHeroToken;
  final bool opponentHasTradeToken;

  const TotalScoreBoard({
    super.key,
    required this.youName,
    required this.youPoints,
    this.youHaveHeroToken = false,
    this.youHaveTradeToken = false,
    required this.amIRed,
    required this.opponentName,
    required this.opponentPoints,
    this.opponentHasHeroToken = false,
    this.opponentHasTradeToken = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CatanColors.woodFrame, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        // OBS: inget `CrossAxisAlignment.stretch` här – Positioned med
        // bara left/top (ingen right/width) ger den här Column ett
        // obegränsat breddutrymme, och `.stretch` kräver en begränsad
        // korsaxel för att veta hur mycket den ska sträcka ut sig till.
        // Kombinationen gav ett layoutfel som (i release-läge, utan
        // Flutters felruta) fick hela widgeten att renderas osynlig
        // utan varken felmeddelande eller innehåll.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(
              name: youName,
              points: youPoints,
              isRed: amIRed,
              hasHeroToken: youHaveHeroToken,
              hasTradeToken: youHaveTradeToken,
            ),
            const SizedBox(height: 3),
            _Row(
              name: opponentName,
              points: opponentPoints,
              isRed: !amIRed,
              hasHeroToken: opponentHasHeroToken,
              hasTradeToken: opponentHasTradeToken,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String name;
  final int points;
  final bool isRed;
  final bool hasHeroToken;
  final bool hasTradeToken;

  const _Row({
    required this.name,
    required this.points,
    required this.isRed,
    required this.hasHeroToken,
    required this.hasTradeToken,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRed ? const Color(0xFFB33A3A) : const Color(0xFF3A6FB3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 72),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.asset(CatanAssets.pointVictory,
              width: 14, height: 14, fit: BoxFit.cover),
        ),
        const SizedBox(width: 3),
        Text('$points',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
        if (hasHeroToken) ...[
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(CatanAssets.heroToken,
                width: 14, height: 14, fit: BoxFit.cover),
          ),
        ],
        if (hasTradeToken) ...[
          const SizedBox(width: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(CatanAssets.tradeToken,
                width: 14, height: 14, fit: BoxFit.cover),
          ),
        ],
      ],
    );
  }
}
