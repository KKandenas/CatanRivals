import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';

/// Kvadratisk vy för ett bygg-/enhetskort (byggnad, hjälte,
/// handelsskepp) – fotobakgrund om kortet har en, annars en enkel
/// träfärgad platshållare med namnet. Visar byggkostnaden som små
/// resursikoner i hörnet. Ett tryck (inte ett långtryck – det startar
/// i stället en drag om kortet ligger i handen) förstorar kortet med
/// [showCardDetail] så all text/kostnad/poäng syns tydligt.
///
/// Delas mellan handkortsdockan och byggplatserna på spelbrädet så att
/// kort ser likadana ut oavsett var de visas.
class ExpansionCardView extends StatelessWidget {
  final GameCard card;
  final bool showCost;

  /// Om satt, körs den här i stället för att förstora kortet vid
  /// tryck – används t.ex. för att välja ett handkort att slänga under
  /// handjusteringen (se [HandDock]).
  final VoidCallback? onTap;

  const ExpansionCardView(
      {super.key, required this.card, this.showCost = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => showCardDetail(context, card),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: CatanColors.woodFrame, width: 1.2)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  card.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: CatanColors.woodFrame),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 3,
                  right: 3,
                  bottom: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (card.affectsBothNeighboringRegions)
                        const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(Icons.arrow_back,
                              size: 9, color: Colors.white),
                        ),
                      Flexible(
                        child: Text(
                          card.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (card.affectsBothNeighboringRegions)
                        const Padding(
                          padding: EdgeInsets.only(left: 2),
                          child: Icon(Icons.arrow_forward,
                              size: 9, color: Colors.white),
                        ),
                    ],
                  ),
                ),
                if (showCost && card.buildingCost.isNotEmpty)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in card.buildingCost.entries)
                          _CostPip(type: entry.key, amount: entry.value),
                      ],
                    ),
                  ),
                if (card.isUnique)
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: _UniqueBadge(),
                  ),
                Positioned(
                  bottom: 24,
                  right: 2,
                  child: _PointsCorner(card: card),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CostPip extends StatelessWidget {
  final ResourceType type;
  final int amount;

  const _CostPip({required this.type, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(
              CatanAssets.resourceCostIcon(type),
              width: 12,
              height: 12,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                  width: 12,
                  height: 12,
                  color: CatanColors.resourceColor(type)),
            ),
          ),
          if (amount > 1)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: const BoxDecoration(
                    color: Colors.black87, shape: BoxShape.circle),
                child: Text('$amount',
                    style: const TextStyle(
                        fontSize: 7, color: Colors.white, height: 1.2)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kortets värde: segerpoäng (VP) och ev. styrka/handel/färdighet/
/// framstegspoäng, staplade nere till höger.
class _PointsCorner extends StatelessWidget {
  final GameCard card;

  const _PointsCorner({required this.card});

  @override
  Widget build(BuildContext context) {
    final pips = <Widget>[
      if (card.strengthPoints > 0)
        _PointPip(
            asset: CatanAssets.pointStrength, amount: card.strengthPoints),
      if (card.commercePoints > 0)
        _PointPip(
            asset: CatanAssets.pointCommerce, amount: card.commercePoints),
      if (card.skillPoints > 0)
        _PointPip(asset: CatanAssets.pointSkill, amount: card.skillPoints),
      if (card.progressPoints > 0)
        _PointPip(
            asset: CatanAssets.pointProgress, amount: card.progressPoints),
      if (card.victoryPoints > 0)
        _PointPip(asset: CatanAssets.pointVictory, amount: card.victoryPoints),
    ];
    if (pips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final pip in pips)
          Padding(padding: const EdgeInsets.only(top: 1), child: pip)
      ],
    );
  }
}

class _PointPip extends StatelessWidget {
  final String asset;
  final int amount;

  const _PointPip({required this.asset, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$amount',
            style: const TextStyle(
                fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(width: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.asset(asset, width: 12, height: 12, fit: BoxFit.cover),
        ),
      ],
    );
  }
}

class _UniqueBadge extends StatelessWidget {
  const _UniqueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
          color: CatanColors.parchment, borderRadius: BorderRadius.circular(3)),
      child: const Text('1x',
          style: TextStyle(
              fontSize: 7,
              color: CatanColors.ink,
              fontWeight: FontWeight.bold)),
    );
  }
}
