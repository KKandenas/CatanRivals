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
    // Bygg listan av (asset, antal) för de fyra "övriga" poängtyperna
    // först, filtrerad på >0 – annars skulle den som råkar hamna FÖRST
    // (t.ex. handel, om styrka är 0) få fel mellanrum till kanten (se
    // [_ScorePip.leadingGap]-doc).
    final otherPips = [
      if (board.totalStrengthPoints > 0)
        (CatanAssets.pointStrength, board.totalStrengthPoints),
      if (board.totalCommercePoints > 0)
        (CatanAssets.pointCommerce, board.totalCommercePoints),
      if (board.totalSkillPoints > 0)
        (CatanAssets.pointSkill, board.totalSkillPoints),
      if (board.totalProgressPoints > 0)
        (CatanAssets.pointProgress, board.totalProgressPoints),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segerpoängen (VP) på egen rad, större än de andra poängtyperna
          // – det är den enda poängen som faktiskt avgör vem som vinner,
          // så den ska stå ut tydligast. Hero Token/Trade Token hör hemma
          // här (inte på raden nedan) – de är redan inräknade i
          // totalVictoryPoints, se klassdoc.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScorePip(
                  asset: CatanAssets.pointVictory,
                  amount: totalVictoryPoints,
                  large: true,
                  leadingGap: 0),
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
          if (otherPips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < otherPips.length; i++)
                    _ScorePip(
                        asset: otherPips[i].$1,
                        amount: otherPips[i].$2,
                        leadingGap: i == 0 ? 0 : 8),
                ],
              ),
            ),
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

  /// Segerpoängen (VP) – den enda poängen som faktiskt avgör vem som
  /// vinner – ritas märkbart större än styrka/handel/färdighet/framsteg
  /// för att sticka ut tydligast på sin egen rad (se [ScoreSummary]).
  final bool large;

  /// Mellanrummet FÖRE den här pippen – 8 mellan flera pips på samma
  /// rad, 0 för den allra första (annars dubblas det upp med
  /// [ScoreSummary]s egen containerpadding).
  final double leadingGap;

  const _ScorePip({
    required this.asset,
    required this.amount,
    this.large = false,
    this.leadingGap = 8,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 20.0 : 14.0;
    final fontSize = large ? 16.0 : 12.5;
    return Padding(
      padding: EdgeInsets.only(left: leadingGap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(asset,
                width: iconSize, height: iconSize, fit: BoxFit.cover),
          ),
          const SizedBox(width: 3),
          Text('$amount',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
