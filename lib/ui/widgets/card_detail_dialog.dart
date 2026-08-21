import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'dice_face.dart';

/// Visar ett kort förstorat i en dialogruta: hela bilden, namn,
/// kostnad, alla poängtyper och regeltext/krav – allt som är för
/// litet för att läsas på det vanliga (kvadratiska, ofta bara ~70–90
/// punkter stora) kortet i handen/på brädet.
Future<void> showCardDetail(BuildContext context, GameCard card) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: _CardDetailContent(card: card),
    ),
  );
}

class _CardDetailContent extends StatelessWidget {
  final GameCard card;

  const _CardDetailContent({required this.card});

  @override
  Widget build(BuildContext context) {
    final hasPoints = card.victoryPoints > 0 ||
        card.strengthPoints > 0 ||
        card.commercePoints > 0 ||
        card.skillPoints > 0 ||
        card.progressPoints > 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Material(
        color: CatanColors.parchment,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      CatanAssets.resolveCardImage(card),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: CatanColors.woodFrame),
                    ),
                    if (card.buildingCost.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in card.buildingCost.entries)
                              _BigCostPip(type: entry.key, amount: entry.value),
                          ],
                        ),
                      ),
                    if (card.productionNumber != null)
                      Positioned(
                          top: 8,
                          left: 8,
                          child: _NumberBadge(number: card.productionNumber!)),
                    if (card.isUnique)
                      const Positioned(top: 8, right: 8, child: _UniqueBadge()),
                    if (hasPoints)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (card.strengthPoints > 0)
                              _BigPointPip(
                                  asset: CatanAssets.pointStrength,
                                  amount: card.strengthPoints),
                            if (card.commercePoints > 0)
                              _BigPointPip(
                                  asset: CatanAssets.pointCommerce,
                                  amount: card.commercePoints),
                            if (card.skillPoints > 0)
                              _BigPointPip(
                                  asset: CatanAssets.pointSkill,
                                  amount: card.skillPoints),
                            if (card.progressPoints > 0)
                              _BigPointPip(
                                  asset: CatanAssets.pointProgress,
                                  amount: card.progressPoints),
                            if (card.victoryPoints > 0)
                              _BigPointPip(
                                  asset: CatanAssets.pointVictory,
                                  amount: card.victoryPoints),
                          ],
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: card.isUnique ? 40 : 8,
                      child: _CloseButton(
                          onTap: () => Navigator.of(context).pop()),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (card.affectsBothNeighboringRegions)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.arrow_back,
                                size: 16, color: CatanColors.ink),
                          ),
                        Flexible(
                          child: Text(
                            card.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CatanColors.ink),
                          ),
                        ),
                        if (card.affectsBothNeighboringRegions)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.arrow_forward,
                                size: 16, color: CatanColors.ink),
                          ),
                      ],
                    ),
                    if (card.requirement != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Kräver: ${card.requirement}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: CatanColors.ink),
                      ),
                    ],
                    if (card.effectText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        card.effectText!,
                        style: const TextStyle(
                            fontSize: 14, color: CatanColors.ink, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigCostPip extends StatelessWidget {
  final ResourceType type;
  final int amount;

  const _BigCostPip({required this.type, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              CatanAssets.resourceCostIcon(type),
              width: 26,
              height: 26,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                  width: 26,
                  height: 26,
                  color: CatanColors.resourceColor(type)),
            ),
          ),
          if (amount > 1)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                    color: Colors.black87, shape: BoxShape.circle),
                child: Text('$amount',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white, height: 1.3)),
              ),
            ),
        ],
      ),
    );
  }
}

class _BigPointPip extends StatelessWidget {
  final String asset;
  final int amount;

  const _BigPointPip({required this.asset, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$amount',
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(asset, width: 26, height: 26, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;

  const _NumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: CatanColors.parchment,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: CatanColors.woodFrame, width: 1),
      ),
      alignment: Alignment.center,
      child: DiceFace(value: number, size: 22, dotColor: CatanColors.ink),
    );
  }
}

class _UniqueBadge extends StatelessWidget {
  const _UniqueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: CatanColors.parchment, borderRadius: BorderRadius.circular(4)),
      child: const Text('1x',
          style: TextStyle(
              fontSize: 12,
              color: CatanColors.ink,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration:
            const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.close, size: 18, color: Colors.white),
      ),
    );
  }
}
