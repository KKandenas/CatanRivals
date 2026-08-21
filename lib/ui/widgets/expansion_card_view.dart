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
/// Texten inuti pilbanderollerna (se [_NeighborRibbon]) som flankerar
/// namnet på kort med [GameCard.affectsBothNeighboringRegions] – "2x"
/// för dubbel-byggnaderna, "2:1" för Stora handelsskeppet (gäller
/// valfri grannresurs, inte en specifik), och tom sträng för kort som
/// bara påverkar grannregionerna utan någon siffra (t.ex. Lagerhus).
String _neighborRibbonLabel(GameCard card) {
  if (card.doublesNeighborProduction) return '2x';
  if (card.expansionKind == ExpansionKind.tradeShip) return '2:1';
  return '';
}

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
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: _NeighborRibbon(
                              label: _neighborRibbonLabel(card),
                              pointLeft: true),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: _NeighborRibbon(
                              label: _neighborRibbonLabel(card),
                              pointLeft: false),
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
                  )
                else if (card.expansionKind == ExpansionKind.tradeShip &&
                    !card.affectsBothNeighboringRegions)
                  // Handelsskepp knutna till en specifik resurs (t.ex.
                  // Sädesskepp) påverkar inte grannregionerna – de har
                  // ingen pilbanderoll, så bytesförhållandet visas här
                  // som en vanlig hörnbricka i stället.
                  Positioned(
                    top: 2,
                    right: 2,
                    child: _RatioBadge(
                      label: '2:1',
                      resource: card.resource == ResourceType.none
                          ? null
                          : card.resource,
                    ),
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

/// Visar "2X"/"2:1" (dubblad produktion resp. bytesförhållande, se
/// [GameCard.doublesNeighborProduction] och [ExpansionKind.tradeShip])
/// tillsammans med resursikonen, om kortet gäller en specifik resurs
/// (t.ex. inte för Stort handelsskepp, som gäller valfri
/// grannresurs). Delar hörnet med [_UniqueBadge] – ett kort är aldrig
/// både unikt och en dubblare/handelsskepp.
class _RatioBadge extends StatelessWidget {
  final String label;
  final ResourceType? resource;

  const _RatioBadge({required this.label, this.resource});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
          color: CatanColors.parchment, borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 7,
                  color: CatanColors.ink,
                  fontWeight: FontWeight.bold)),
          if (resource != null) ...[
            const SizedBox(width: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.asset(CatanAssets.resourceCostIcon(resource!),
                  width: 9, height: 9, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}

/// Liten pilbanderoll i grönt, formad som en pil som pekar ut mot
/// kortkanten – samma stil som originalspelets fysiska kort (se
/// card_detail_dialog.dart för motsvarande, större variant). Tom
/// [label] ritar bara själva pilformen utan text (t.ex. Lagerhus).
class _NeighborRibbon extends StatelessWidget {
  final String label;
  final bool pointLeft;

  const _NeighborRibbon({required this.label, required this.pointLeft});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _RibbonClipper(pointLeft: pointLeft),
      child: Container(
        width: 16,
        height: 11,
        color: const Color(0xFF6E9B5E),
        alignment:
            pointLeft ? const Alignment(0.35, 0) : const Alignment(-0.35, 0),
        child: label.isEmpty
            ? null
            : Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 5.5,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  final bool pointLeft;

  const _RibbonClipper({required this.pointLeft});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    if (pointLeft) {
      path
        ..moveTo(w, 0)
        ..lineTo(w * 0.35, 0)
        ..lineTo(0, h / 2)
        ..lineTo(w * 0.35, h)
        ..lineTo(w, h)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(w * 0.65, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w * 0.65, h)
        ..lineTo(0, h)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _RibbonClipper oldClipper) =>
      oldClipper.pointLeft != pointLeft;
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
