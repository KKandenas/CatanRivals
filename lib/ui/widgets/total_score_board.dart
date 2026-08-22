import 'package:flutter/material.dart';

import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Kompakt sammanställning av totalställningen (segerpoäng, inklusive
/// Hero Token/Trade Token) för båda spelarna på samma gång – till
/// skillnad från de mer detaljerade ScoreSummary-rutorna (en per
/// spelare, med alla poängtyper) ger den här bara en snabb blick på
/// vem som leder just nu. Svävar i övre högra hörnet, ovanpå både
/// DIN TUR-pillen och [TopStatusBar] (se game_board_screen.dart) i
/// stället för att pressas in i endera raden – annars skulle den
/// tvinga upp höjden på en av dem bara för att få plats med två rader
/// poäng.
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
      // Rundare "pill"-form och gyllene kant (i stället för den tunna
      // träfärgade linjen) för att matcha CarvedFrame/PillBanner-stilen
      // som ramar in resten av brädet.
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFC9A227), width: 1.4)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          constraints: const BoxConstraints(maxWidth: 92),
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
        // Segerpoängen som ett guldmynt i stället för den platta
        // VP-ikonen – det enda som faktiskt avgör vem som vinner
        // (regelhäftet), så det ska synas tydligast av allt på raden.
        _GoldCoin(points: points),
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

/// Segerpoängen som ett litet guldmynt (radiell gradient + mörkare
/// kant, samma teknik som hörnnitarna i [CarvedFrame]) i stället för
/// den platta VP-ikonen – "gyllene" är bokstavligt vad som avgör vem
/// som vinner, så det förtjänar den tydligaste behandlingen på raden.
class _GoldCoin extends StatelessWidget {
  final int points;

  const _GoldCoin({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFF4DFA0), Color(0xFFC9932A)],
        ),
        border: Border.all(color: const Color(0xFF8A6A2A), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Text(
        '$points',
        style: const TextStyle(
            color: CatanColors.ink, fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}
